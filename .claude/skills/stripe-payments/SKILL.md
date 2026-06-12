---
name: stripe-payments
description: Stripe integration decision rules and pitfalls for solo SaaS in Japan — Checkout vs Elements selection, JPY zero-decimal amounts, webhook signature/idempotency/ordering correctness, server-side price truth with a local subscription cache, konbini/bank-transfer async payments, and 特商法/消費税 compliance. Load for 決済, 課金, サブスクリプション, 有料プラン, Stripe, 課金実装, payments, billing, subscriptions, checkout, webhooks, or any payment feature work.
---

# Stripe Payments

Decision rules and the failure modes that actually ship bugs. Payment code always gets a
security-reviewer pass after writing (CLAUDE.md mandate — payments are in the auth/payments/PII class).

## Integration Level — decide before writing any code

| Situation | Use | Why |
|-----------|-----|-----|
| Fixed product/price, no app logic needed | **Payment Links** | Zero code; share a URL |
| MVP, standard SaaS signup → pay flow | **Stripe Checkout (hosted)** — the default | PCI SAQ A, localized UI, konbini support built in |
| Custom payment UI is a stated product requirement | Elements + PaymentIntents | Only with an explicit reason; 10x the integration surface |

- Recurring access → Checkout `mode: 'subscription'` + Stripe Billing. One-off purchase → `mode: 'payment'`.
  Usage-based pricing → metered prices on Billing, not hand-rolled counters.
- **Never build a custom card form** (raw card data APIs). It moves you out of SAQ A and Stripe
  gates those APIs anyway. If someone asks for "our own card input", that means Elements.
- Self-serve plan changes/cancellation → `stripe.billingPortal.sessions.create({ customer, return_url })`
  and redirect to `session.url`. Do not build plan-management UI from scratch.

## JPY Is Zero-Decimal — the 100x overcharge bug

Stripe amounts are in the currency's smallest unit. JPY has no minor unit:

```ts
{ unit_amount: 1000, currency: 'jpy' }   // ¥1,000 — correct
{ unit_amount: 100000, currency: 'jpy' } // ¥100,000 — USD cent-math ported to JPY; 100x overcharge
```

- Delete any `amount * 100` helper the moment the currency is JPY. If the codebase must handle
  both, branch on a zero-decimal currency list — never apply cent-math unconditionally.
- No decimals also means rounding differs: Stripe Tax and invoice proration round to whole yen.
  Don't replicate USD rounding assumptions in price displays or revenue reconciliation.

## Webhooks — the #1 failure zone

### Signature verification needs the RAW body

`stripe.webhooks.constructEvent` hashes the exact bytes Stripe sent. Any JSON parse → re-serialize
breaks it. Framework specifics:

- **Next.js (App Router)**: `await req.text()` in the route handler — never `req.json()`.
- **Express**: `express.raw({ type: 'application/json' })` on the webhook route only;
  a global `express.json()` placed before it silently breaks verification.

```ts
// app/api/webhooks/stripe/route.ts
import Stripe from 'stripe';
import { NextResponse } from 'next/server';
import { db, sql } from '@/lib/db';    // Drizzle-style — see note below the example
import { logger } from '@/lib/logger'; // pino — see backend-patterns

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

export async function POST(req: Request) {
  const body = await req.text(); // RAW body — req.json() breaks the signature
  const sig = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, process.env.STRIPE_WEBHOOK_SECRET!);
  } catch {
    // Audit signal (probing / misconfigured secret) — log a warning, never the payload
    logger.warn({ msg: 'stripe webhook: invalid signature' });
    return new NextResponse('Invalid signature', { status: 400 });
  }

  // Claim + fulfillment in ONE DB transaction. The dedup INSERT is the
  // concurrency gate — a separate check-then-mark pair is a TOCTOU race:
  // Stripe can deliver the same event.id concurrently → double fulfillment.
  try {
    await db.transaction(async (tx) => {
      const claimed = await tx.execute(sql`
        INSERT INTO processed_events (event_id) VALUES (${event.id})
        ON CONFLICT DO NOTHING RETURNING event_id`);
      if (claimed.length === 0) return; // duplicate delivery — already handled

      switch (event.type) {
        case 'checkout.session.completed': {
          const session = event.data.object;
          // konbini/bank transfer: completed fires with payment_status 'unpaid' — do NOT fulfill yet
          if (session.payment_status === 'paid') await fulfillOrder(tx, session);
          break;
        }
        case 'checkout.session.async_payment_succeeded':
          await fulfillOrder(tx, event.data.object);
          break;
        case 'customer.subscription.updated':
        case 'customer.subscription.deleted': {
          // Event order is NOT guaranteed — re-fetch instead of trusting payload state
          const sub = await stripe.subscriptions.retrieve(event.data.object.id);
          await syncSubscriptionCache(tx, sub);
          break;
        }
        case 'invoice.payment_failed':
          await startDunning(tx, event.data.object); // grace period, not instant lockout
          break;
      }
    });
  } catch {
    // Rollback released the claim; 5xx (generic body, no internals) → Stripe retries
    return new NextResponse('Handler error', { status: 500 });
  }

  return NextResponse.json({ received: true }); // 2xx fast; queue slow work
}
```

(`db.transaction` shown Drizzle-style; the same shape applies to Prisma `$transaction`
or a raw `pg` client — what matters is that the claim INSERT and every fulfillment
write commit or roll back together.)

### Handler discipline

- **Return 2xx fast.** Stripe retries failures for days; a slow handler causes timeouts → retry
  storms. Enqueue emails/provisioning, don't await them inline.
- **Idempotent processing — the unique constraint IS the gate.** Retries and concurrent
  redeliveries WILL happen. `INSERT ... ON CONFLICT DO NOTHING RETURNING` on a
  unique-constrained `processed_events` table, in the same transaction as the fulfillment
  writes (as above). A read-check followed by a later mark is a race, not idempotency.
- **Fulfillment must itself be idempotent**, keyed on the Stripe object id: redeliveries and
  the `completed`(paid) / `async_payment_succeeded` pair can both reach `fulfillOrder` for the
  same session. Gate with `INSERT INTO fulfillments (session_id) ... ON CONFLICT DO NOTHING`,
  and use `SELECT ... FOR UPDATE` row locks for balance/credit/inventory writes — a plain
  `UPDATE balance = balance + x` grants twice on a duplicate event.
- **Ordering is NOT guaranteed.** `customer.subscription.updated` can arrive after `deleted`.
  Never apply payload state as a transition — re-fetch the subscription and overwrite the cache
  with current truth.
- **Minimal SaaS event set**: `checkout.session.completed`, `customer.subscription.updated`,
  `customer.subscription.deleted`, `invoice.payment_failed` — plus
  `checkout.session.async_payment_succeeded` / `async_payment_failed` if konbini or bank
  transfer is enabled. Subscribe to only what you handle.

## Server-Side Truth

Price IDs and amounts live server-side only. The client sends a plan name at most; the server
maps it to a Price ID. Any `amount` or `priceId` accepted from a request body is a
pay-what-you-want vulnerability.

```ts
const PRICE_IDS: Record<string, string> = { pro: 'price_xxx', team: 'price_yyy' }; // or env/config

// Created ONCE when the user initiates checkout and REUSED on retries —
// regenerating per request would defeat the idempotency key below.
const attemptId = crypto.randomUUID();

const session = await stripe.checkout.sessions.create(
  {
    mode: 'subscription',
    customer: user.stripeCustomerId,
    line_items: [{ price: PRICE_IDS[plan], quantity: 1 }],
    success_url: `${APP_URL}/billing?status=success`,
    cancel_url: `${APP_URL}/pricing`,
  },
  { idempotencyKey: `checkout:${user.id}:${plan}:${attemptId}` }
);
```

Stripe is the source of truth for billing state; keep a local cache **for authz only**:

```sql
ALTER TABLE users ADD COLUMN stripe_customer_id text UNIQUE;

CREATE TABLE subscriptions (
  id text PRIMARY KEY,                  -- Stripe subscription ID (sub_...)
  user_id bigint NOT NULL REFERENCES users (id),
  status text NOT NULL,                 -- active | trialing | past_due | canceled ...
  price_id text NOT NULL,
  current_period_end timestamptz NOT NULL,
  cancel_at_period_end boolean NOT NULL DEFAULT false
);
```

Rule: **gate features on the local cache; refresh the cache only from webhooks or API re-fetch.**
Never call the Stripe API in a request-path authz check, and never mutate the cache from
client-driven code paths.

## Idempotency Keys

Every mutating Stripe call (session creation, refunds, subscription changes) takes an
`{ idempotencyKey }` options argument. Network timeouts make retries mandatory, and a retry
without a key is a duplicate charge. Derive the key from the business operation
(`refund:${orderId}`, `checkout:${userId}:${plan}:${attemptId}`) — generated once per user
action and reused on retry, never a fresh UUID per attempt. Stripe remembers keys ~24h; the
same key with different params returns an error, which is the protection working.

```ts
await stripe.refunds.create({ payment_intent: pi }, { idempotencyKey: `refund:${orderId}` });
```

## Japan-Specific Rules

- **konbini決済 / 銀行振込 are async**: payment succeeds days after checkout.
  `checkout.session.completed` arrives with `payment_status: 'unpaid'` — fulfill on
  `checkout.session.async_payment_succeeded`, notify/cancel on `async_payment_failed`
  (see handler above). Fulfilling at `completed` ships product to people who never pay.
- **特定商取引法に基づく表記**: Stripe JP requires this page before activating a live account.
  Treat it as a launch blocker alongside privacy policy/terms — it belongs on the
  requirements-design regulatory checklist.
- **消費税**: enable Stripe Tax; Japanese norm is tax-inclusive display, so create Prices with
  `tax_behavior: 'inclusive'` and show 税込 amounts. Whole-yen rounding applies (zero-decimal).
- **資金決済法**: selling your own prepaid points/credits triggers prepaid-instrument
  obligations; plain pay-per-use or subscriptions via Stripe do not — confirm in
  requirements-design before designing a points system.

## Local Dev & Testing

```bash
stripe listen --forward-to localhost:3000/api/webhooks/stripe
# Prints a whsec_... — use THAT as STRIPE_WEBHOOK_SECRET locally (it differs from the Dashboard one)
stripe trigger checkout.session.completed       # fire test events at your handler
# Subscription lifecycle (renewal, trial end, dunning): use test clocks
# (Dashboard → Test clocks) instead of waiting a month
# Test cards: 4242 4242 4242 4242 (success), 4000 0000 0000 9995 (decline)
```

## Security & Operational Rules

- API keys and webhook secret in env only — never in code, logs, or conversation
  (CLAUDE.md hard rule). Use **restricted API keys** scoped to the resources the server touches,
  not the full secret key.
- Never log full card numbers, webhook payload PII, or `Stripe-Signature` headers.
- `invoice.payment_failed` → dunning flow (retry emails + grace period via `past_due` status),
  not instant lockout — Stripe Smart Retries usually recovers the payment.
- After writing or changing payment code, run **security-reviewer** (harness mandate; do not skip).

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| Accepting `amount`/`priceId` from the client | Pay-what-you-want exploit | Server-side plan → Price ID map |
| Parsing JSON before signature check | Verification always fails (or is skipped) | Raw body → `constructEvent` first |
| Fulfilling on the success-URL redirect | Users close tabs; URL is forgeable; konbini is unpaid | Fulfill from webhooks only |
| Storing card numbers | PCI scope explosion | Stripe stores cards; you store customer/PM IDs |
| Trusting webhook event order | Out-of-order delivery corrupts state | Re-fetch from API, reconcile cache |
| Check-then-mark event dedup | TOCTOU race → double fulfillment | Atomic `INSERT … ON CONFLICT DO NOTHING RETURNING` inside the fulfillment transaction |
| `amount * 100` on JPY | 100x overcharge (zero-decimal) | Amount in yen as-is |
| Hand-rolled plan-change/cancel UI | Proration and dunning edge cases | `billingPortal.sessions` redirect |

## Related

- Skill: `requirements-design` — 特商法 page, 資金決済法 check, and pricing scope before building
- Skill: `backend-patterns` — job queues for async webhook work; `postgres-patterns` — cache schema
- Review: security-reviewer after any payment code (CLAUDE.md)
