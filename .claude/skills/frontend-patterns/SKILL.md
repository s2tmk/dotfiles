---
name: frontend-patterns
description: Frontend patterns for CSS layout, responsive design, accessibility (ARIA/keyboard/focus), animation with Framer Motion, form validation, a11y keyboard navigation, and cross-framework UI composition — excluding React hooks/state/Suspense (see react-patterns). Load for CSS, layout, animation, or a11y work.
origin: ECC
---

<!-- Vendored from ECC 2.0.0-rc.1 skills/frontend-patterns (trimmed: hooks/state/Suspense/RSC removed — see react-patterns) -->

# Frontend Development Patterns

Cross-framework UI patterns: CSS, layout, accessibility, animation, and form handling.

## When to Activate

- Styling, layout, or responsive design decisions
- Accessibility: keyboard navigation, ARIA, focus management
- Animation with Framer Motion or CSS transitions
- Form validation and error display patterns
- Composing UI components without framework-specific logic
- Performance: code splitting, virtualization, lazy loading

## Component Composition Patterns

### Compound Components

Share internal state across related sub-components via Context:

```tsx
interface TabsContextValue {
  activeTab: string
  setActiveTab: (tab: string) => void
}

const TabsContext = createContext<TabsContextValue | undefined>(undefined)

export function Tabs({ children, defaultTab }: {
  children: React.ReactNode
  defaultTab: string
}) {
  const [activeTab, setActiveTab] = useState(defaultTab)
  return (
    <TabsContext.Provider value={{ activeTab, setActiveTab }}>
      {children}
    </TabsContext.Provider>
  )
}

export function Tab({ id, children }: { id: string; children: React.ReactNode }) {
  const context = useContext(TabsContext)
  if (!context) throw new Error('Tab must be used within Tabs')
  return (
    <button
      className={context.activeTab === id ? 'active' : ''}
      onClick={() => context.setActiveTab(id)}
    >
      {children}
    </button>
  )
}
```

### Card Composition

```tsx
export function Card({ children, variant = 'default' }: CardProps) {
  return <div className={`card card-${variant}`}>{children}</div>
}

export function CardHeader({ children }: { children: React.ReactNode }) {
  return <div className="card-header">{children}</div>
}

export function CardBody({ children }: { children: React.ReactNode }) {
  return <div className="card-body">{children}</div>
}

// Usage
<Card>
  <CardHeader>Title</CardHeader>
  <CardBody>Content</CardBody>
</Card>
```

## CSS & Layout

### Spacing System

Use a 4px/8px base grid exclusively. Avoid arbitrary values.

```css
:root {
  --space-1: 4px;
  --space-2: 8px;
  --space-3: 12px;
  --space-4: 16px;
  --space-6: 24px;
  --space-8: 32px;
  --space-12: 48px;
  --space-16: 64px;
}
```

With Tailwind the scale maps to `p-1` (4px) through `p-16` (64px) — never use arbitrary `p-[13px]`.

### Responsive Layout

```css
/* Mobile-first, min-width breakpoints */
.grid {
  display: grid;
  grid-template-columns: 1fr;
  gap: var(--space-4);
}

@media (min-width: 768px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
}

@media (min-width: 1280px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
```

### Typography Scale

**Authoritative type scale lives in ux-ui-design; the Tailwind classes below map to that scale.**

Do not define an independent scale here. Use the 1.25 ("Major Third") ratio scale from `ux-ui-design/SKILL.md` and map it to Tailwind utility classes:

| Token (ux-ui-design) | Value | Tailwind class |
|---|---|---|
| `--text-xs`   | 0.64rem  (~10px) | `text-[0.64rem]` or custom token |
| `--text-sm`   | 0.8rem   (~13px) | `text-[0.8rem]`  or custom token |
| `--text-base` | 1rem     (16px)  | `text-base` |
| `--text-lg`   | 1.25rem  (20px)  | `text-xl` |
| `--text-xl`   | 1.563rem (25px)  | `text-2xl` (≈ 24px, use custom token for exactness) |
| `--text-2xl`  | 1.953rem (31px)  | `text-3xl` (≈ 30px, use custom token for exactness) |
| `--text-3xl`  | 2.441rem (39px)  | `text-4xl` (≈ 36px, use custom token for exactness) |
| `--text-4xl`  | 3.052rem (49px)  | `text-5xl` (≈ 48px, use custom token for exactness) |

For pixel-exact fidelity, extend Tailwind's `fontSize` config with the CSS custom properties from `ux-ui-design`. Never use arbitrary sizes like `text-[13px]` or `text-[17px]` that fall outside the scale.

Line heights: headings use `leading-tight` (1.2), body copy uses `leading-relaxed` (1.75).

### Color & Contrast

```css
/* Maintain WCAG AA contrast (4.5:1 for text, 3:1 for large/UI) */
/* Use CSS custom properties so dark mode is a single override */
:root {
  --color-text-primary:   hsl(222 84% 5%);
  --color-text-secondary: hsl(222 20% 40%);
  --color-surface:        hsl(0 0% 100%);
  --color-border:         hsl(222 13% 90%);
  --color-accent:         hsl(217 91% 60%);
}

@media (prefers-color-scheme: dark) {
  :root {
    --color-text-primary:   hsl(210 20% 95%);
    --color-text-secondary: hsl(210 10% 65%);
    --color-surface:        hsl(222 47% 9%);
    --color-border:         hsl(222 20% 20%);
  }
}
```

### Alignment & Grid Discipline

- Align elements to an 8px grid. Use `gap` instead of margins between grid children.
- Never mix `margin` and `gap` on the same axis in a flex/grid container.
- For fixed toolbars, cards, and counters: use `min-width` and `min-height` so content changes don't cause layout shift.

## Performance

### Code Splitting & Lazy Loading

```tsx
import { lazy, Suspense } from 'react'

const HeavyChart = lazy(() => import('./HeavyChart'))

export function Dashboard() {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  )
}
```

### Virtualization for Long Lists

```tsx
import { useVirtualizer } from '@tanstack/react-virtual'

export function VirtualList({ items }: { items: Item[] }) {
  const parentRef = useRef<HTMLDivElement>(null)

  const virtualizer = useVirtualizer({
    count: items.length,
    getScrollElement: () => parentRef.current,
    estimateSize: () => 80,
    overscan: 5,
  })

  return (
    <div ref={parentRef} style={{ height: '600px', overflow: 'auto' }}>
      <div style={{ height: `${virtualizer.getTotalSize()}px`, position: 'relative' }}>
        {virtualizer.getVirtualItems().map(row => (
          <div
            key={row.index}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              width: '100%',
              height: `${row.size}px`,
              transform: `translateY(${row.start}px)`,
            }}
          >
            <ItemCard item={items[row.index]} />
          </div>
        ))}
      </div>
    </div>
  )
}
```

Virtualize when list exceeds ~50 items with non-trivial rows.

## Accessibility Patterns

### Keyboard Navigation

```tsx
export function Dropdown({ options, onSelect }: DropdownProps) {
  const [isOpen, setIsOpen] = useState(false)
  const [activeIndex, setActiveIndex] = useState(0)

  const handleKeyDown = (e: React.KeyboardEvent) => {
    switch (e.key) {
      case 'ArrowDown':
        e.preventDefault()
        setActiveIndex(i => Math.min(i + 1, options.length - 1))
        break
      case 'ArrowUp':
        e.preventDefault()
        setActiveIndex(i => Math.max(i - 1, 0))
        break
      case 'Enter':
        e.preventDefault()
        onSelect(options[activeIndex])
        setIsOpen(false)
        break
      case 'Escape':
        setIsOpen(false)
        break
    }
  }

  return (
    <div
      role="combobox"
      aria-expanded={isOpen}
      aria-haspopup="listbox"
      onKeyDown={handleKeyDown}
    >
      {/* Dropdown content */}
    </div>
  )
}
```

### Focus Management

```tsx
export function Modal({ isOpen, onClose, children }: ModalProps) {
  const modalRef = useRef<HTMLDivElement>(null)
  const previousFocusRef = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (isOpen) {
      previousFocusRef.current = document.activeElement as HTMLElement
      modalRef.current?.focus()
    } else {
      previousFocusRef.current?.focus()
    }
  }, [isOpen])

  return isOpen ? (
    <div
      ref={modalRef}
      role="dialog"
      aria-modal="true"
      tabIndex={-1}
      onKeyDown={e => e.key === 'Escape' && onClose()}
    >
      {children}
    </div>
  ) : null
}
```

### ARIA Essentials

- Every `<img>` needs `alt` (empty string for decorative)
- Every `<input>` needs `<label htmlFor>` or `aria-label`
- Icon-only buttons need `aria-label`
- Live regions for dynamic content: `aria-live="polite"` (errors, status) or `"assertive"` (alerts)
- Semantic HTML first: `<button>`, `<nav>`, `<main>`, `<section>`, `<article>` before adding `role`

## Animation Patterns (Framer Motion)

```tsx
import { motion, AnimatePresence } from 'framer-motion'

// List enter/exit
export function AnimatedList({ items }: { items: Item[] }) {
  return (
    <AnimatePresence>
      {items.map(item => (
        <motion.div
          key={item.id}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.2 }}
        >
          <ItemCard item={item} />
        </motion.div>
      ))}
    </AnimatePresence>
  )
}

// Modal overlay + content
export function AnimatedModal({ isOpen, onClose, children }: ModalProps) {
  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            className="modal-overlay"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
          />
          <motion.div
            className="modal-content"
            initial={{ opacity: 0, scale: 0.95, y: 16 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 16 }}
            transition={{ duration: 0.15 }}
          >
            {children}
          </motion.div>
        </>
      )}
    </AnimatePresence>
  )
}
```

Animation principles:
- Motion should clarify state, not decorate it
- Duration: 100–200ms for micro-interactions, 250–350ms for page-level transitions
- Respect `prefers-reduced-motion`: wrap non-essential animations

```tsx
const prefersReduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
const transition = prefersReduced ? { duration: 0 } : { duration: 0.2 }
```

## Form Handling

### Controlled Form with Validation

```tsx
export function CreateItemForm() {
  const [name, setName] = useState('')
  const [error, setError] = useState<string | null>(null)

  const validate = (): boolean => {
    if (!name.trim()) { setError('Name is required'); return false }
    if (name.length > 200) { setError('Name must be under 200 characters'); return false }
    setError(null)
    return true
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!validate()) return
    await createItem({ name })
  }

  return (
    <form onSubmit={handleSubmit} noValidate>
      <label htmlFor="item-name">Name</label>
      <input
        id="item-name"
        value={name}
        onChange={e => setName(e.target.value)}
        aria-describedby={error ? 'name-error' : undefined}
        aria-invalid={error ? 'true' : undefined}
      />
      {error && <span id="name-error" role="alert">{error}</span>}
      <button type="submit">Create</button>
    </form>
  )
}
```

For multi-step forms, dynamic field arrays, or cross-field validation: use React Hook Form or TanStack Form.

## Anti-Patterns

- `margin: auto` on flex children when gap would do
- Hardcoded pixel values outside the spacing system
- Forgetting `aria-live` on dynamically updated regions
- Setting `outline: none` on focused elements without a visible alternative
- Animation on every scroll event without `will-change` or GPU compositing
- `useEffect` + `fetch` for application data (use TanStack Query or SWR instead)
