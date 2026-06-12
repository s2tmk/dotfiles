---
name: tdd-workflow
description: Test-driven development workflow enforcing RED-GREEN-REFACTOR cycles with 80%+ coverage, Arrange-Act-Assert test structure, descriptive naming, unit/integration/E2E test organization, and mocking patterns. Load for feature work with testable units — テスト駆動開発, TDD, ユニットテスト, テスト作成, バグ修正, new features, bug fixes with reproducible behavior; skip for spikes, prototypes, throwaway scripts, and pure refactors with existing coverage.
origin: ECC
---

<!-- Vendored from ECC 2.0.0-rc.1 skills/tdd-workflow -->

# Test-Driven Development Workflow

This skill ensures all code development follows TDD principles with comprehensive test coverage.

## When to Activate

- Feature work with testable units: new features, API endpoints, components with logic
- Bug fixes where the bug can be captured in a failing test first

Skip this workflow for: spikes, prototypes, throwaway scripts, and pure refactors
already protected by existing coverage.

## Core Principles

### 1. Tests BEFORE Code

ALWAYS write tests first, then implement code to make tests pass.

### 2. Coverage Requirements

- Minimum 80% coverage (unit + integration + E2E)
- All edge cases covered
- Error scenarios tested
- Boundary conditions verified

### 3. Test Types

#### Unit Tests
- Individual functions and utilities
- Component logic
- Pure functions
- Helpers and utilities

#### Integration Tests
- API endpoints
- Database operations
- Service interactions
- External API calls

#### E2E Tests (Playwright)
- Critical user flows
- Complete workflows
- Browser automation
- UI interactions

### 4. Stage Tracking

- Mark each TDD stage (RED / GREEN / REFACTOR) complete, recording the exact evidence
  (test command and output)
- Never commit automatically — offer a commit at stage boundaries only if the user has
  asked for commits

## TDD Workflow Steps

### Step 1: Write User Journeys

```
As a [role], I want to [action], so that [benefit]

Example:
As a user, I want to search for markets semantically,
so that I can find relevant markets even without exact keywords.
```

### Step 2: Generate Test Cases

For each user journey, create comprehensive test cases:

```typescript
describe('Semantic Search', () => {
  it('returns relevant markets for query', async () => {
    // Test implementation
  })

  it('handles empty query gracefully', async () => {
    // Test edge case
  })

  it('falls back to substring search when Redis unavailable', async () => {
    // Test fallback behavior
  })

  it('sorts results by similarity score', async () => {
    // Test sorting logic
  })
})
```

### Step 3: Run Tests — They Must Fail (RED)

```bash
npm test
# Tests should fail — we haven't implemented yet
```

This step is mandatory. Do NOT edit production code until a valid RED state is confirmed:

- **Runtime RED:** test compiles, is executed, result is RED
- **Compile-time RED:** the new test exercises the buggy/missing code path and the compile failure is the intended RED signal

A test that was only written but not compiled and executed does not count as RED.

Mark the RED stage complete (record the test command and failing output). Offer a commit only if the user has asked for commits.

### Step 4: Implement Code (GREEN)

Write minimal code to make tests pass:

```typescript
export async function searchMarkets(query: string): Promise<Market[]> {
  // Minimal implementation guided by tests
}
```

Do not mark this stage complete until GREEN is validated in Step 5.

### Step 5: Run Tests Again — Must Pass (GREEN)

```bash
npm test
# Tests should now pass
```

Rerun the same relevant test target and confirm the previously failing test is now GREEN. Only after a valid GREEN result may you proceed to refactor.

Mark the GREEN stage complete. Offer a commit only if the user has asked for commits.

### Step 6: Refactor

Improve code quality while keeping tests green:
- Remove duplication
- Improve naming
- Optimize performance
- Enhance readability

Mark the REFACTOR stage complete. Offer a commit only if the user has asked for commits.

### Step 7: Verify Coverage

```bash
npm run test:coverage
# Verify 80%+ coverage achieved
```

## Test Structure — Arrange-Act-Assert (AAA)

Structure every test as three phases:

```typescript
test('calculates similarity correctly', () => {
  // Arrange
  const vector1 = [1, 0, 0]
  const vector2 = [0, 1, 0]

  // Act
  const similarity = calculateCosineSimilarity(vector1, vector2)

  // Assert
  expect(similarity).toBe(0)
})
```

## Test Naming

Use descriptive names that explain the behavior under test, not the implementation:

```typescript
// Good — describes observable behavior
test('returns empty array when no markets match query', () => {})
test('throws error when API key is missing', () => {})
test('falls back to substring search when Redis is unavailable', () => {})
test('rejects passwords shorter than 8 characters', () => {})

// Bad — describes implementation
test('calls setError when fetch fails', () => {})
test('uses the cache', () => {})
```

## Testing Patterns

### Unit Test (Jest/Vitest + React Testing Library)

```typescript
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Button } from './Button'

describe('Button Component', () => {
  it('renders with correct text', () => {
    // Arrange
    render(<Button>Click me</Button>)

    // Assert
    expect(screen.getByText('Click me')).toBeInTheDocument()
  })

  it('calls onClick when clicked', async () => {
    // Arrange
    const handleClick = jest.fn()
    render(<Button onClick={handleClick}>Click</Button>)

    // Act
    await userEvent.click(screen.getByRole('button'))

    // Assert
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it('is disabled when disabled prop is true', () => {
    render(<Button disabled>Click</Button>)
    expect(screen.getByRole('button')).toBeDisabled()
  })
})
```

Vitest is the default for new TypeScript projects — use `vi.fn()` / `vi.mock()` in place of `jest.fn()` / `jest.mock()`.

### API Integration Test

```typescript
import { NextRequest } from 'next/server'
import { GET } from './route'

describe('GET /api/markets', () => {
  it('returns markets successfully', async () => {
    // Arrange
    const request = new NextRequest('http://localhost/api/markets')

    // Act
    const response = await GET(request)
    const data = await response.json()

    // Assert
    expect(response.status).toBe(200)
    expect(data.success).toBe(true)
    expect(Array.isArray(data.data)).toBe(true)
  })

  it('validates query parameters', async () => {
    const request = new NextRequest('http://localhost/api/markets?limit=invalid')
    const response = await GET(request)
    expect(response.status).toBe(400)
  })

  it('handles database errors gracefully', async () => {
    // Mock the database to throw, verify 500 is returned
  })
})
```

### E2E Test (Playwright)

```typescript
import { test, expect } from '@playwright/test'

test('user can search and filter markets', async ({ page }) => {
  // Arrange: navigate to the page
  await page.goto('/markets')
  await expect(page.locator('h1')).toContainText('Markets')

  // Act: search
  await page.fill('input[placeholder="Search markets"]', 'election')

  // Assert: web-first assertions auto-wait — never page.waitForTimeout
  const results = page.locator('[data-testid="market-card"]')
  await expect(results.first()).toBeVisible()
  await expect(results).toHaveCount(5)
  await expect(results.first()).toContainText('election', { ignoreCase: true })
})
```

## Test File Organization

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   └── Button.test.tsx          # Unit tests
│   └── MarketCard/
│       ├── MarketCard.tsx
│       └── MarketCard.test.tsx
├── app/
│   └── api/
│       └── markets/
│           ├── route.ts
│           └── route.test.ts         # Integration tests
└── e2e/
    ├── markets.spec.ts               # E2E tests
    └── auth.spec.ts
```

## Mocking External Services

```typescript
// Database client (vi.mock for Vitest)
jest.mock('@/lib/db', () => ({
  db: {
    user: {
      findUnique: jest.fn(() => Promise.resolve({ id: 1, name: 'Test User' })),
    },
  },
}))

// External service client
jest.mock('@/lib/payments', () => ({
  createCharge: jest.fn(() => Promise.resolve({ id: 'ch_123', status: 'succeeded' })),
  checkHealth: jest.fn(() => Promise.resolve({ connected: true })),
}))
```

## Coverage Configuration

```json
{
  "jest": {
    "coverageThreshold": {
      "global": {
        "branches": 80,
        "functions": 80,
        "lines": 80,
        "statements": 80
      }
    }
  }
}
```

## Common Anti-Patterns

```typescript
// WRONG: Testing implementation details
expect(component.state.count).toBe(5)

// CORRECT: Test user-visible behavior
expect(screen.getByText('Count: 5')).toBeInTheDocument()

// WRONG: Brittle CSS selectors
await page.click('.css-class-xyz')

// CORRECT: Semantic selectors
await page.click('button:has-text("Submit")')
await page.click('[data-testid="submit-button"]')

// WRONG: Tests that depend on each other
test('creates user', () => { /* ... */ })
test('updates same user', () => { /* depends on previous test */ })

// CORRECT: Each test sets up its own data
test('updates user', () => {
  const user = createTestUser()  // independent setup
})
```

---

**Remember**: Tests are not optional. They are the safety net that enables confident refactoring, rapid development, and production reliability.
