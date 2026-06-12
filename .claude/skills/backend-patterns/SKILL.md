---
name: backend-patterns
description: Backend architecture patterns for Node.js/TypeScript APIs: repository pattern, service layer, middleware, N+1 query prevention, Redis caching, pagination, centralized error handling, JWT auth, RBAC, rate limiting (shared-store only), structured logging, and background job queues. Load for バックエンド設計, API実装, サーバーサイド, キャッシュ, 認証, レートリミット, building or reviewing server-side code.
origin: ECC
---

<!-- Vendored from ECC 2.0.0-rc.1 skills/backend-patterns -->

# Backend Development Patterns

Backend architecture patterns and best practices for scalable server-side applications.

## When to Activate

- Designing REST or GraphQL API endpoints
- Implementing repository, service, or controller layers
- Optimizing database queries (N+1, indexing, connection pooling)
- Adding caching (Redis, in-memory, HTTP cache headers)
- Setting up background jobs or async processing
- Structuring error handling and validation for APIs
- Building middleware (auth, logging, rate limiting)

## API Design Patterns

### RESTful API Structure

```typescript
// Resource-based URLs
GET    /api/markets                 # List resources
GET    /api/markets/:id             # Get single resource
POST   /api/markets                 # Create resource
PUT    /api/markets/:id             # Replace resource
PATCH  /api/markets/:id             # Update resource
DELETE /api/markets/:id             # Delete resource

// Query parameters for filtering, sorting, pagination
GET /api/markets?status=active&sort=volume&limit=20&offset=0
```

### When to Skip These Patterns

Single data source + small app → plain query modules are enough (YAGNI). Introduce the
repository/service layers below (and the caching decorator further down) only at the
second data source, the second consumer, or when test isolation demands it.

### Repository Pattern

```typescript
interface MarketRepository {
  findAll(filters?: MarketFilters): Promise<Market[]>
  findById(id: string): Promise<Market | null>
  create(data: CreateMarketDto): Promise<Market>
  update(id: string, data: UpdateMarketDto): Promise<Market>
  delete(id: string): Promise<void>
}

class SupabaseMarketRepository implements MarketRepository {
  async findAll(filters?: MarketFilters): Promise<Market[]> {
    let query = supabase.from('markets').select('id, name, status, volume')

    if (filters?.status) query = query.eq('status', filters.status)
    if (filters?.limit) query = query.limit(filters.limit)

    const { data, error } = await query
    if (error) throw new Error(error.message)
    return data
  }
}
```

### Service Layer Pattern

```typescript
class MarketService {
  constructor(private marketRepo: MarketRepository) {}

  async searchMarkets(query: string, limit = 10): Promise<Market[]> {
    const embedding = await generateEmbedding(query)
    const results = await this.vectorSearch(embedding, limit)
    const markets = await this.marketRepo.findByIds(results.map(r => r.id))
    return markets.sort((a, b) => {
      const scoreA = results.find(r => r.id === a.id)?.score ?? 0
      const scoreB = results.find(r => r.id === b.id)?.score ?? 0
      return scoreB - scoreA
    })
  }
}
```

### Middleware Pattern

```typescript
export function withAuth(handler: NextApiHandler): NextApiHandler {
  return async (req, res) => {
    const token = req.headers.authorization?.replace('Bearer ', '')
    if (!token) return res.status(401).json({ error: { code: 'unauthorized', message: 'Missing token' } })

    try {
      req.user = await verifyToken(token)
      return handler(req, res)
    } catch {
      return res.status(401).json({ error: { code: 'unauthorized', message: 'Invalid token' } })
    }
  }
}
```

## Database Patterns

### N+1 Query Prevention

The single most common backend performance bug. Always batch-fetch related data.

```typescript
// BAD: N+1 — one query per market
const markets = await getMarkets()
for (const market of markets) {
  market.creator = await getUser(market.creator_id)  // N queries
}

// GOOD: batch fetch — 2 queries total
const markets = await getMarkets()
const creatorIds = [...new Set(markets.map(m => m.creator_id))]
const creators = await getUsers(creatorIds)
const creatorMap = new Map(creators.map(c => [c.id, c]))
markets.forEach(m => { m.creator = creatorMap.get(m.creator_id) })
```

With an ORM, prefer eager loading (`include`/`with`) over lazy associations.

### Pagination

Always paginate list queries — never return unbounded sets.

```typescript
// Offset pagination (simple, use for small datasets or admin UIs)
const { data } = await supabase
  .from('markets')
  .select('id, name, status, volume')
  .eq('status', 'active')
  .order('volume', { ascending: false })
  .range(offset, offset + limit - 1)

// Cursor pagination (scalable, use for feeds / large tables)
const { data } = await supabase
  .from('markets')
  .select('id, name, status')
  .gt('id', lastSeenId)
  .order('id')
  .limit(limit + 1)  // fetch one extra to detect hasNext
```

### Select Only Needed Columns

```typescript
// GOOD: explicit column selection
const { data } = await supabase
  .from('markets')
  .select('id, name, status, volume')

// BAD: select-star returns all columns including large text/blob fields
const { data } = await supabase.from('markets').select('*')
```

### Transaction Pattern

```typescript
// Use database-level transactions for multi-step writes
const { data, error } = await supabase.rpc('create_market_with_position', {
  market_data: marketData,
  position_data: positionData
})
if (error) throw new Error('Transaction failed')
```

## Caching Strategies

### Cache-Aside (Read-Through)

```typescript
async function getMarketWithCache(id: string): Promise<Market> {
  const cacheKey = `market:${id}`
  const cached = await redis.get(cacheKey)
  if (cached) return JSON.parse(cached)

  const market = await db.markets.findUnique({ where: { id } })
  if (!market) throw new ApiError(404, 'Market not found')

  await redis.setex(cacheKey, 300, JSON.stringify(market))  // 5 min TTL
  return market
}
```

### Cache Invalidation

```typescript
class CachedMarketRepository implements MarketRepository {
  constructor(
    private baseRepo: MarketRepository,
    private redis: RedisClient,
  ) {}

  async findById(id: string): Promise<Market | null> {
    const cached = await this.redis.get(`market:${id}`)
    if (cached) return JSON.parse(cached)

    const market = await this.baseRepo.findById(id)
    if (market) await this.redis.setex(`market:${id}`, 300, JSON.stringify(market))
    return market
  }

  async invalidate(id: string): Promise<void> {
    await this.redis.del(`market:${id}`)
  }
}
```

Caching principles:
- Cache reads, invalidate on writes
- TTL should match acceptable staleness — prefer short TTLs with explicit invalidation over long TTLs
- Never cache user-specific data without a user-scoped key

## Error Handling

### Centralized Error Handler

Error responses follow the canonical envelope defined in `api-design`:
`{ "error": { "code", "message", "details?" } }`. Validation failures → 422; malformed syntax → 400.

```typescript
class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public code: string = 'api_error',
    public isOperational = true,
  ) {
    super(message)
    Object.setPrototypeOf(this, ApiError.prototype)
  }
}

export function errorHandler(error: unknown): Response {
  if (error instanceof ApiError) {
    return NextResponse.json(
      { error: { code: error.code, message: error.message } },
      { status: error.statusCode },
    )
  }
  if (error instanceof z.ZodError) {
    return NextResponse.json({
      error: {
        code: 'validation_error',
        message: 'Request validation failed',
        details: error.issues,
      },
    }, { status: 422 })
  }

  logger.error({ err: error }, 'Unexpected error')
  return NextResponse.json(
    { error: { code: 'internal_error', message: 'Internal server error' } },
    { status: 500 },
  )
}
```

### Retry with Exponential Backoff

```typescript
async function withRetry<T>(fn: () => Promise<T>, maxRetries = 3): Promise<T> {
  let lastError: Error

  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn()
    } catch (err) {
      lastError = err as Error
      // Never retry client errors (4xx) — they will fail identically every time
      if (err instanceof ApiError && err.statusCode >= 400 && err.statusCode < 500) throw err
      if (i < maxRetries - 1) {
        const backoff = Math.pow(2, i) * 1000
        const jitter = Math.random() * backoff  // jitter avoids thundering-herd retries
        await new Promise(r => setTimeout(r, backoff + jitter))
      }
    }
  }

  throw lastError!
}
```

## Authentication & Authorization

Decision rule: default to managed auth (Supabase Auth / Clerk / Auth0 / NextAuth) for new
products; hand-roll JWT only with a stated reason (e.g., service-to-service tokens you
fully control).

### JWT Token Validation

```typescript
interface JWTPayload {
  userId: string
  email: string
  role: 'admin' | 'user'
}

export function verifyToken(token: string): JWTPayload {
  try {
    // Always pin algorithms — prevents alg-confusion attacks (e.g., none/RS256 swap)
    return jwt.verify(token, process.env.JWT_SECRET!, { algorithms: ['HS256'] }) as JWTPayload
  } catch {
    throw new ApiError(401, 'Invalid token')
  }
}

export async function requireAuth(request: Request) {
  const token = request.headers.get('authorization')?.replace('Bearer ', '')
  if (!token) throw new ApiError(401, 'Missing authorization token')
  return verifyToken(token)
}
```

Issue short-lived access tokens (e.g., `expiresIn: '15m'`) and rotate via refresh tokens — never mint long-lived access tokens.

### Role-Based Access Control

```typescript
const rolePermissions: Record<'admin' | 'moderator' | 'user', Permission[]> = {
  admin:     ['read', 'write', 'delete', 'admin'],
  moderator: ['read', 'write', 'delete'],
  user:      ['read', 'write'],
}

export function hasPermission(user: User, permission: Permission): boolean {
  return rolePermissions[user.role].includes(permission)
}

export function requirePermission(permission: Permission) {
  return (handler: (request: Request, user: User) => Promise<Response>) =>
    async (request: Request) => {
      const user = await requireAuth(request)
      if (!hasPermission(user, permission)) throw new ApiError(403, 'Insufficient permissions')
      return handler(request, user)
    }
}
```

## Rate Limiting

Rate limiting must use a **shared store** (Redis, gateway, or the platform's native limiter). Do not use per-process in-memory counters for production APIs:

- They reset on deploy
- Split across replicas
- Fail open in serverless or multi-instance environments

Use `api-design` for the HTTP contract (`X-RateLimit-*` headers, `429` response format) and `security-review` for abuse case review.

## Background Jobs & Queues

For production workloads, use a durable queue (BullMQ, Inngest, AWS SQS). The pattern below is for lightweight in-process queuing during development or for non-critical tasks:

```typescript
class JobQueue<T> {
  private queue: T[] = []
  private processing = false

  async add(job: T): Promise<void> {
    this.queue.push(job)
    if (!this.processing) this.process()
  }

  private async process(): Promise<void> {
    this.processing = true
    while (this.queue.length > 0) {
      const job = this.queue.shift()!
      try {
        await this.execute(job)
      } catch (err) {
        logger.error({ err }, 'Job failed')
      }
    }
    this.processing = false
  }

  protected async execute(job: T): Promise<void> {
    // Override in subclass
  }
}
```

For production: use BullMQ (Redis-backed) or Inngest (serverless-friendly) with retry, dead-letter queues, and observability.

## Logging & Monitoring

No bare `console.log` strings in production code. Structured JSON to stdout via a logger
(pino or equivalent) is the standard.

```typescript
import pino from 'pino'

const logger = pino({ level: process.env.LOG_LEVEL ?? 'info' })

// Usage
export async function GET(request: Request) {
  const requestId = crypto.randomUUID()
  logger.info({ requestId, path: '/api/markets' }, 'Fetching markets')

  try {
    const markets = await fetchMarkets()
    return NextResponse.json({ data: markets })
  } catch (error) {
    logger.error({ requestId, err: error }, 'Failed to fetch markets')
    return NextResponse.json(
      { error: { code: 'internal_error', message: 'Internal server error' } },
      { status: 500 },
    )
  }
}
```

Structured logging principles:
- Always include `requestId` for tracing
- Never log PII (email, passwords, tokens, credit cards)
- Log at the boundary (entry and exit of a request), not throughout
- Use `error` level only for unexpected failures; use `warn` for expected degraded paths
