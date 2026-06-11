---
paths:
  - "**/*.ts"
  - "**/*.tsx"
---
<!-- Vendored from ECC 2.0.0-rc.1 rules/typescript/*.md -->

# TypeScript Coding Style

## Strict Types — No `any`

- Never use `any` in application code.
- Use `unknown` for external or untrusted input, then narrow with `instanceof`, `typeof`, or a type guard before use.
- Use generics when a value's type depends on the caller.

```typescript
// WRONG
function handle(error: any) { return error.message }

// CORRECT
function handle(error: unknown): string {
  if (error instanceof Error) return error.message
  return 'Unexpected error'
}
```

## Explicit Types at Boundaries

- Add parameter and return types to all exported functions, shared utilities, and public class methods.
- Let TypeScript infer obvious local variable types (no redundant annotations).
- Extract repeated inline object shapes into named `interface` or `type`.

## `interface` vs `type`

- Use `interface` for object shapes that may be extended or implemented.
- Use `type` for unions, intersections, tuples, mapped types, and utility types.
- Prefer string literal unions over `enum` unless interoperability requires an enum.

## Discriminated Unions for State

Model mutually exclusive states as discriminated unions, not optional fields:

```typescript
// WRONG
type State = { loading: boolean; data?: User; error?: string }

// CORRECT
type State =
  | { status: 'idle' }
  | { status: 'loading' }
  | { status: 'success'; data: User }
  | { status: 'error'; error: string }
```

## Immutability

Always create new objects; never mutate existing ones:

```typescript
// WRONG
function update(user: User, name: string): User {
  user.name = name   // mutation
  return user
}

// CORRECT
function update(user: Readonly<User>, name: string): User {
  return { ...user, name }
}
```

## Async Error Handling

Use `async`/`await` with `try`/`catch`. Catch type is `unknown` — narrow before use:

```typescript
async function load(id: string): Promise<User> {
  try {
    return await fetchUser(id)
  } catch (error: unknown) {
    logger.error('load failed', error)
    throw new Error(error instanceof Error ? error.message : 'Unexpected error')
  }
}
```

## Input Validation at Boundaries

Use Zod (or equivalent schema library) at system boundaries. Infer types from the schema:

```typescript
import { z } from 'zod'

const userSchema = z.object({ email: z.string().email(), age: z.number().int().min(0) })
type UserInput = z.infer<typeof userSchema>
const validated: UserInput = userSchema.parse(rawInput)
```

## Naming

- Variables and functions: `camelCase`
- Booleans: `is`, `has`, `should`, or `can` prefix
- Interfaces, types, components: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Custom hooks: `camelCase` with `use` prefix

## Import Hygiene

- No unused imports — remove them.
- Group: external packages, then internal modules, then relative imports (separated by blank lines).
- Prefer named exports over default exports for non-component modules.

## No `console.log` in Production Code

Use a proper logging library. `console.log` statements left in production code are flagged as HIGH by code-reviewer.
