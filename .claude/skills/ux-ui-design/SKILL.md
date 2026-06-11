---
name: ux-ui-design
description: UX and UI design guidance covering the 5 planes of UX (Garrett), cognitive psychology laws (Hick/Fitts/Miller/Gestalt), typography scale, 4/8px spacing, accessible color contrast, layout grid discipline, anti-pattern detection for generic AI-generated UI, and a senior designer's review checklist. Load when working on UI design, screen design, design systems, UX, Figma work, or landing pages. Japanese triggers: UI設計, 画面設計, ダッシュボード, デザインシステム, ランディングページ, ワイヤーフレーム.
origin: Local
---

<!-- Vendored from ECC 2.0.0-rc.1 skills/design-system + skills/frontend-design-direction (merged + extended) -->

# UX / UI Design

The bar: output a senior UX/UI designer would sign off on — not a component-library default.

## Mandatory Gate — New Screens and Features

**If this is a NEW screen or feature (not a refinement of existing UI), complete requirements-design FIRST. Gate check: a `## Requirements Brief: …` block must be present in this conversation (or referenced as a file) before Phase 0 begins. If absent, STOP and run requirements-design — never start plane work without it.**

Refinements and restyling of existing UI may proceed directly to Phase 0. When in doubt, treat it as new.

## When to Activate

- Designing or reviewing any web page, app screen, dashboard, or component
- Making typography, color, spacing, or layout decisions
- Evaluating a UI for visual hierarchy, usability, or polish
- Producing or auditing a design system
- Creating landing pages, onboarding flows, or Figma artifacts
- Fixing UI that "looks generic" or "feels AI-generated"

---

## Phase 0 — Direction Before Pixels

Before any visual work, answer these five questions (Jesse James Garrett's 5 planes, bottom-up):

| Plane | Question |
|---|---|
| **Strategy** | What problem is this interface solving, and for whom? State the job-to-be-done and propose 1-2 latent needs for user confirmation (per requirements-design). |
| **Scope** | Which features/content are in scope? What is explicitly out? |
| **Structure** | How is the information organized? What are the navigation flows? |
| **Skeleton** | Where do interface elements live? What are the layout and interaction patterns? |
| **Surface** | What is the visual language? Color, type, motion, and tone. |

Do not move to a lower plane without answering the ones above. "Make it look good" is not a strategy answer.

Choose a specific direction across these attributes before coding:
1. **Purpose**: what job does the interface do?
2. **Audience**: who uses this daily, and what do they need to scan first?
3. **Tone**: utilitarian / editorial / playful / industrial / refined / technical / maximal / minimal / dense / calm
4. **Memorable detail**: one design idea that makes the result feel intentional
5. **Constraints**: framework, existing tokens, a11y, performance, responsiveness

---

## Cognitive Psychology Essentials

Apply these laws consciously, not as decoration:

### Hick's Law — Reduce Choices at Decision Points
Time to decide grows logarithmically with the number of options. In practice:
- Primary navigation: ≤7 items
- Action buttons visible at once: ≤3 primary actions
- Onboarding: one decision per step

### Fitts's Law — Make Targets Easy to Hit
Interaction time = distance to target ÷ target size. In practice:
- Minimum touch target: 44×44px (iOS HIG), 48×48dp (Material)
- Primary CTA should be the largest interactive element on the screen
- Keep related actions close together (don't split confirm/cancel to opposite corners)

### Miller's Law — Chunk Information
Working memory holds 7 ± 2 items. In practice:
- Chunk long forms into labeled sections (3-5 fields per group)
- Use progressive disclosure: show only what is needed at the current step
- Table columns: ≤7 before a detail view becomes clearer

### Gestalt Grouping
The brain perceives grouped elements as related:
- **Proximity**: items near each other are read as a group — use spacing to signal grouping
- **Similarity**: identical color, shape, or icon signals equivalence
- **Continuity**: align items in a line to imply sequence
- **Enclosure**: borders and backgrounds create implied containers without DOM overhead

### Progressive Disclosure
Surface complexity only when the user has demonstrated intent:
- "Advanced settings" collapse by default
- Contextual actions appear on hover/focus, not always-visible
- Wizard patterns for multi-step configuration

---

## Figma Integration

Use Figma at appropriate fidelity for the stakes of the work:

- **Design-system work** (tokens, component libraries): use `figma:figma-generate-library` to build or extend a library from code.
- **Building screens in Figma**: load `figma:figma-use` first (mandatory), then call `figma:figma-generate-design` to translate a layout or page into Figma.
- **Implementing FROM a Figma URL**: call `get_design_context` with the file/node URL to extract the design spec before writing code. Never guess at a design from a screenshot alone.
- **Wireframe → Figma → code round-trips** are preferred for high-stakes UI (landing pages, onboarding flows, primary product screens). Wireframe in text first, push to Figma for visual validation, then implement.

---

## Typography Scale & Vertical Rhythm

Use a modular scale. Don't invent arbitrary sizes.

**This scale is the single source of truth; frontend-patterns' Tailwind sizes are a mapping of this scale.**

```css
:root {
  /* Type scale (1.25 ratio — "Major Third") */
  --text-xs:    0.64rem;   /* 10px  — captions, legal */
  --text-sm:    0.8rem;    /* 13px  — secondary labels */
  --text-base:  1rem;      /* 16px  — body copy */
  --text-lg:    1.25rem;   /* 20px  — large body, intro */
  --text-xl:    1.563rem;  /* 25px  — section heading */
  --text-2xl:   1.953rem;  /* 31px  — page heading */
  --text-3xl:   2.441rem;  /* 39px  — hero heading */
  --text-4xl:   3.052rem;  /* 49px  — display */

  /* Line heights */
  --leading-tight:   1.2;   /* headings */
  --leading-snug:    1.375; /* subheadings */
  --leading-normal:  1.5;   /* body */
  --leading-relaxed: 1.75;  /* long-form reading */

  /* Letter spacing */
  --tracking-tight: -0.02em;  /* large headings */
  --tracking-normal: 0;
  --tracking-wide:   0.05em;  /* all-caps labels, badges */
}
```

Vertical rhythm: body copy line-height × base font-size = baseline grid unit. Stack heading margins in multiples of that unit.

---

## Spacing System — 4/8px Grid

Every space in the layout must be a multiple of 4px.

```css
:root {
  --space-0:  0;
  --space-1:  4px;   /* tight: label gap, icon margin */
  --space-2:  8px;   /* compact: inner padding of small components */
  --space-3:  12px;
  --space-4:  16px;  /* default: component inner padding */
  --space-5:  20px;
  --space-6:  24px;  /* section sub-gap */
  --space-8:  32px;  /* section gap */
  --space-10: 40px;
  --space-12: 48px;  /* page section spacing */
  --space-16: 64px;
  --space-20: 80px;
  --space-24: 96px;  /* hero / above-fold padding */
}
```

Never use arbitrary values like `margin: 13px` or `padding: 7px`.

---

## Color — Tone & Manner with Accessible Contrast

### Palette Construction

Avoid single-hue palettes. A multi-dimensional palette:
- **Primary hue**: brand, primary actions
- **Neutral**: text, surfaces, borders (typically desaturated gray or warm gray)
- **Accent**: supporting hue, used sparingly
- **Semantic**: success (green), warning (amber), error (red), info (blue)

```css
/* Example token structure */
:root {
  --color-brand-500: hsl(217 91% 60%);   /* primary action */
  --color-brand-700: hsl(217 91% 42%);   /* hover state */

  --color-neutral-0:   hsl(0 0% 100%);
  --color-neutral-50:  hsl(220 14% 96%);
  --color-neutral-200: hsl(220 13% 91%);
  --color-neutral-500: hsl(220 9% 46%);
  --color-neutral-900: hsl(222 47% 9%);

  --color-success: hsl(142 71% 45%);
  --color-warning: hsl(37 92% 50%);
  --color-error:   hsl(0 72% 51%);
}
```

### Accessible Contrast

Minimum WCAG AA:
- Normal text (<18px, not bold): **4.5:1**
- Large text (≥18px or ≥14px bold): **3:1**
- UI components and graphical objects: **3:1**

WCAG AAA for body copy is 7:1 — target this for primary content in reading-intensive UIs.

Tools: [whocanuse.com](https://whocanuse.com), [Colour Contrast Analyser](https://www.tpgi.com/color-contrast-checker/)

---

## Layout Alignment & Grid Discipline

### Grid

```css
.page-grid {
  display: grid;
  grid-template-columns: repeat(12, 1fr);
  gap: var(--space-6);
  max-width: 1280px;
  margin-inline: auto;
  padding-inline: var(--space-6);
}
```

12-column grid: content at 8-10 columns with 1-2 column gutters creates natural breathing room.

### Alignment Rules

- Align to a shared axis — left-edge alignment is more readable than centered-stack for dense UIs
- Icon + label: vertically center on the cap-height of the label, not the full line-height
- Fixed toolbars, sidebars, and cards: use `min-width` and `min-height` to prevent layout shift when content changes
- When in doubt, align to the nearest grid line rather than the visually centered position

---

## Anti-Pattern: Generic AI-Generated UI

The following patterns indicate template-level output that a senior designer would reject:

| Anti-pattern | Why it fails | Fix |
|---|---|---|
| Purple-to-blue gradient everywhere | Signals "I used default Tailwind gradients" | Use a purposeful gradient only where it carries meaning; default to flat or subtle tone |
| Uniform border-radius + box-shadow on every card | No hierarchy — everything is equal weight | Vary elevation; use shadow only to convey z-order, not decoration |
| Oversized hero with centered vague headline | Hides the actual product | First viewport shows the real app, tool, or workflow |
| "Glass morphism" cards with no purpose | Decorative without semantic value | Use surface treatments only when they communicate containment or depth |
| Decorative blobs / mesh gradients in background | Draws attention away from content | Reserve backgrounds for canvases; let content create visual interest |
| Uniform icon-plus-label cards in a 3-column grid | Copy-paste from a landing page template | Design the actual data shape; information density should match the use case |
| All-sans font with no personality | Uncurated generic output | Choose a typeface with character appropriate to the domain |
| Features described inside the UI | Treats users as prospects, not users | Controls speak for themselves; remove instructional copy from production UI |
| Dark UI with purple accents | Default "AI product" aesthetic | Dark UIs need strong contrast ratios and a purposeful reason; don't default to dark because it "looks tech" |

---

## Review Checklist

Before marking UI work complete:

### Hierarchy
- [ ] The first viewport immediately communicates the product, workflow, or object
- [ ] Visual hierarchy supports scanning and repeated use (size, weight, color signal importance)
- [ ] There is a single dominant element per view — not three competing primaries

### Typography
- [ ] All type sizes come from the modular scale
- [ ] Line lengths are 45–75 characters for body copy
- [ ] Typography fits containers and does not overflow on mobile

### Spacing & Layout
- [ ] All spacing values are multiples of 4px
- [ ] Layout aligns to a grid; no free-floating elements
- [ ] Stable dimensions for grids, toolbars, controls — no layout shift on hover/focus

### Color
- [ ] Text contrast meets WCAG AA (4.5:1 normal, 3:1 large)
- [ ] UI components meet 3:1 against adjacent colors
- [ ] Dark mode (if implemented) is complete, not half-done

### Accessibility
- [ ] Interactive elements: minimum 44×44px touch target
- [ ] Keyboard navigable — tab order is logical
- [ ] Focus indicators are visible
- [ ] `aria-label` on icon-only buttons

### Motion
- [ ] Motion clarifies state or orientation — not decorative
- [ ] `prefers-reduced-motion` honored
- [ ] Transitions: 100–200ms for micro, 250–350ms for page-level

### Assets
- [ ] Real or generated data used (not Lorem Ipsum for a data-driven UI)
- [ ] Images carry subject matter, not filler stock

### Overall
- [ ] Result matches the existing frontend conventions unless there is a clear reason to depart
- [ ] No new dependency added for a pure visual flourish
- [ ] A senior UX/UI designer would sign off
