---
name: auth-patterns
description: Authentication and authorization decision rules — managed-provider selection (Supabase Auth/Clerk/Better Auth/WorkOS), cookie-based session transport, data-layer authorization (middleware is not a security boundary), Supabase getUser() vs getSession(), OAuth/PKCE, email flows, and IDOR prevention. Load for 認証, ログイン, 会員登録, サインアップ, ソーシャルログイン, 認可, セッション管理, authentication, login, signup, OAuth, SSO, session management, Supabase Auth, Clerk, or designing/reviewing any auth flow.
---

# Authentication Patterns

Decision rules for auth in solo-builder products. Any auth change triggers a mandatory
security-reviewer pass per CLAUDE.md — auth-flow design also triggers a codex cross-vendor review.

## When to Activate

- Adding login/signup, social login, or SSO to a product
- Choosing an auth provider for a new product
- Reviewing session handling, Route Handlers, or Server Actions for authz
- Designing password reset / email verification / magic link flows

## Provider Decision Matrix

**Default = managed auth.** Hand-rolling is a last resort and requires a stated reason
(e.g., service-to-service tokens you fully control — see backend-patterns for that legacy JWT pattern).

| Situation | Choose | Why |
|-----------|--------|-----|
| Supabase/Postgres stack (most likely here) | Supabase Auth | Auth lives next to RLS — `auth.uid()` works in policies, no identity sync |
| Next.js, want polished UI/orgs/user management out of the box, budget OK | Clerk | Prebuilt components, org/multi-tenant features; per-MAU cost |
| Full control / self-hosted / no vendor lock-in | Better Auth (or Auth.js v5) | Better Auth: TypeScript-first, own DB, plugins for orgs/2FA/SSO. Auth.js v5: `export const { handlers, signIn, signOut, auth } = NextAuth({...})` |
| Enterprise SSO / SAML requirement | WorkOS or Auth0 | SAML/SCIM is not worth building; buy it |

Decision criteria: where the DB lives, org/multi-tenant needs, SAML requirement, pricing at
scale, lock-in tolerance. Managed pricing grows per-MAU — model the cost at 10k/100k users
before committing, not after.

## Session Transport

- Session cookie: `httpOnly` + `Secure` + `SameSite=Lax`. NEVER store JWTs or session
  tokens in localStorage — any XSS reads them; httpOnly cookies survive XSS.
- CSRF posture follows SameSite: `Lax` blocks cross-site POSTs (so never mutate state on GET);
  if you need `SameSite=None` (embedded/cross-site), add explicit CSRF tokens and Origin checks.
- Sliding expiry (extend on activity, e.g., 7–30 days) plus an absolute cap (e.g., 90 days)
  so a stolen cookie cannot live forever.
- **Regenerate the session identifier on every privilege transition** — login, logout,
  password change, MFA step-up. Carrying a pre-authentication session ID into an
  authenticated session is session fixation. Managed providers handle this; a hand-rolled
  session table must do it explicitly.

## The Load-Bearing Rule: Authorize at the Data Layer, Not the Edge

Next.js middleware is **optimistic UX only** (redirect unauthenticated users to /login).
It is NOT a security boundary — the CVE-2025-29927 class showed middleware can be bypassed
entirely. Every Route Handler, Server Action, and data fetch must check the session itself.
Server Actions are public HTTP endpoints callable with curl — repeat the check inside each one.

```typescript
// lib/auth.ts
import { createClient } from '@/lib/supabase/server' // official @supabase/ssr snippet

export async function requireUser() {
  const supabase = await createClient()
  // getUser() validates the JWT with the Auth server — never getSession() here
  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) throw new Error('UNAUTHORIZED')
  return user
}
```

```typescript
// app/api/posts/route.ts — check in the handler, not (only) in middleware
import { requireUser } from '@/lib/auth'

export async function GET() {
  const user = await requireUser()
  // every query scoped to the caller (RLS enforces this too — belt and suspenders)
  ...
}
```

```typescript
// app/posts/actions.ts
'use server'
import { requireUser } from '@/lib/auth'
import { createClient } from '@/lib/supabase/server'

export async function deletePost(postId: string) {
  const user = await requireUser() // Server Actions are public endpoints — re-check
  const supabase = await createClient()
  const { error } = await supabase
    .from('posts').delete().eq('id', postId).eq('user_id', user.id) // scoped
  if (error) throw error // Supabase returns errors, it does not throw — never discard them
}
```

## Supabase Specifics

- **THE classic Supabase security bug:** on the server, `supabase.auth.getUser()` validates
  the JWT against the Auth server; `getSession()` only reads cookie state — unverified, a
  crafted cookie can spoof a user ID. Never use `getSession()` for authorization decisions.
  (`getClaims()`, in recent supabase-js, also returns verified claims — locally when the
  project uses asymmetric JWT signing keys, otherwise via the Auth server. Either is safe
  for authz, unlike `getSession()`.)
- Client setup: `createServerClient` from `@supabase/ssr` with the `getAll`/`setAll` cookie
  adapter, one client per request — copy the official Next.js snippet verbatim; hand-modified
  cookie adapters are a classic source of random logouts.
- The **service-role key bypasses RLS**. Server-only, never in `NEXT_PUBLIC_*`, never sent
  to the client, never in client bundles.
- RLS on every table is the authz backbone — middleware and handler checks can be bypassed
  or forgotten; RLS cannot. Policy patterns and the `(SELECT auth.uid())` performance wrap:
  see postgres-patterns.

## OAuth / Social Login

- PKCE for all public clients (SPA, mobile); exact-match redirect URI allowlist — wildcards
  let attackers receive authorization codes; validate `state` to bind the callback to the
  session that started it.
- **The app's own post-login redirect is a separate open-redirect sink.** The IdP
  redirect-URI allowlist does NOT cover `?next=` / `returnTo` params or Supabase
  `redirectTo`/`emailRedirectTo`. Validate these as same-origin relative paths — reject
  values starting with `//`, containing a scheme, or naming another host — or match against
  an allowlist. Never pass a raw client-supplied URL to `redirect()` or
  `signInWithOAuth({ options: { redirectTo } })`: the victim authenticates for real, then
  lands on a phishing clone.
- JP consumer products: **LINE Login converts best** — most users have LINE, few want another
  password. Google for B2B. If you offer any social login on iOS, Apple requires
  Sign in with Apple too — plan for it before App Store review, not after.

## Email Flows (verification / reset / magic link)

- Tokens: single-use, short expiry (≤1h for password reset), random ≥128-bit, **hashed at
  rest** (a DB leak must not yield valid reset links).
- Respond generically — "If an account exists, we sent an email" — for reset AND signup,
  or you ship a user-enumeration oracle.
- Rate-limit every auth endpoint (login, signup, reset, magic link). Shared-store limiter
  only — see backend-patterns; in-memory counters fail open on serverless.
- Invalidate all existing sessions on password change.
- Magic-link tradeoff: removes passwords but lives or dies on deliverability — JP carrier
  domains (docomo/au/softbank) aggressively route to 迷惑メール folders. Use a transactional
  email service with proper SPF/DKIM, and keep password or social login as a fallback.

## Authorization Modeling

- Authn ("who are you") ≠ authz ("what may you do"). Logging in grants nothing by itself.
- Roles/permissions live server-side: a DB column/table or verified session claims — never
  read from client-sent headers, body fields, or unverified cookies.
- Every query scoped by `user_id` / `org_id` (or RLS). **IDOR — fetching by ID without an
  ownership check — is the most common real-world authz vuln.** `WHERE id = $1` alone is a
  bug; `WHERE id = $1 AND user_id = $2` is the pattern.
- Admin surfaces: separate explicit role check (not "logged in + obscure URL") and TOTP MFA
  for admin accounts.

## If You Must Hand-Roll (last resort)

- Passwords: argon2id, or bcrypt with cost ≥ 12 — via a maintained library, never your own crypto.
- Sessions: DB-backed table, random 256-bit IDs (`crypto.randomBytes(32)`), stored hashed.
  Issue a FRESH session ID at login — never promote a pre-auth session ID (fixation).
- Compare tokens with constant-time comparison (`crypto.timingSafeEqual`).
- Account lockout / progressive throttling on failed logins.
- The moment you need OAuth or password-reset emails, you have rebuilt a managed provider
  badly — switch to one.

## Anti-Patterns

| Avoid | Why | Instead |
|-------|-----|---------|
| JWT/tokens in localStorage | Readable by any XSS | httpOnly cookies |
| Authz only in middleware | Bypassable (CVE-2025-29927 class); middleware is UX | Check session in every handler/action |
| `getSession()` for server authz | Unverified cookie state, spoofable | `getUser()` / `getClaims()` |
| Role from client-sent claims | Client controls the value | Server-side role lookup or verified claims |
| Unscoped queries (IDOR) | Any logged-in user reads others' rows | Scope by user_id/org_id or RLS |
| Hand-rolled crypto/password hashing | Subtle failures, catastrophic blast radius | argon2id/bcrypt via maintained lib |
| Long-lived JWTs without revocation | Stolen token valid until expiry | Short-lived access + refresh rotation, or DB sessions |
| Service-role/admin keys on the client | Bypasses RLS, full DB access | Server-only env vars |
| OAuth redirect wildcard | Authorization code sent to attacker host | Exact-match allowlist |
| `redirect(searchParams.next)` after login | Open redirect → post-login phishing | Same-origin relative path check or allowlist |

## Related

- Review: any auth change → security-reviewer (mandatory per CLAUDE.md); auth-flow design → codex cross-vendor review
- PII handling (email addresses are PII): requirements-design skill's APPI checklist
- Skill: `postgres-patterns` — RLS policy patterns, `(SELECT auth.uid())` wrap
- Skill: `backend-patterns` — rate limiting (shared-store only), legacy JWT validation pattern
