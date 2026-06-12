---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when the user asks to build web components, pages, artifacts, posters, or applications (examples include websites, landing pages, dashboards, React components, HTML/CSS layouts, or when styling/beautifying any web UI). Generates creative, polished code and UI design that avoids generic AI aesthetics. Keywords: UI実装, 画面実装, ランディングページ, ダッシュボード, フロントエンド, コンポーネント, LPを作る
license: Complete terms in LICENSE.txt
---

**Precedence**: ux-ui-design's anti-pattern table, type/spacing scales, and conventions OVERRIDE anything below. This skill supplies creative direction WITHIN those constraints.

This skill guides creation of distinctive, production-grade frontend interfaces that avoid generic "AI slop" aesthetics. Implement real working code with exceptional attention to aesthetic details and creative choices.

The user provides frontend requirements: a component, page, application, or interface to build. They may include context about the purpose, audience, or technical constraints.

## Design Thinking

Before coding, understand the context and commit to a BOLD aesthetic direction:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Pick an extreme: brutally minimal, maximalist chaos, retro-futuristic, organic/natural, luxury/refined, playful/toy-like, editorial/magazine, brutalist/raw, art deco/geometric, soft/pastel, industrial/utilitarian, etc. There are so many flavors to choose from. Use these for inspiration but design one that is true to the aesthetic direction.
- **Constraints**: Technical requirements (framework, performance, accessibility).
- **Differentiation**: What makes this UNFORGETTABLE? What's the one thing someone will remember?

**CRITICAL**: Choose a clear conceptual direction and execute it with precision. Bold maximalism and refined minimalism both work - the key is intentionality, not intensity.

Then implement working code (HTML/CSS/JS, React, Vue, etc.) that is:
- Production-grade and functional
- Visually striking and memorable
- Cohesive with a clear aesthetic point-of-view
- Meticulously refined in every detail

## Frontend Aesthetics Guidelines

Focus on:
- **Typography**: Apply these measurable rules, not adjectives:
  - **Two-slot pairing rule**: choose exactly one display typeface and one body typeface from *different* categories (e.g. slab/serif display + grotesque body; humanist sans display + monospace body; transitional serif display + geometric sans body). Never pair two typefaces from the same category.
  - **Banned as primary display font** (the default AI look — never use these as the hero/heading face): Inter, Roboto, system-ui, DM Sans, Space Grotesk, Arial. These are acceptable for body copy where neutrality is intentional.
  - **Heading letter-spacing**: apply −1% to −3% (`letter-spacing: -0.01em` to `-0.03em`) for display sizes ≥32px. Tight tracking at large sizes signals typographic intention; loose or default tracking at those sizes reads as an afterthought.
  - Pair a distinctive display font with a refined body font — unexpected, characterful display face with a workhorse body that doesn't compete.
- **Color & Theme**: Commit to a cohesive aesthetic. Use CSS variables for consistency. Dominant colors with sharp accents outperform timid, evenly-distributed palettes.
- **Motion**: Motion must clarify state or orientation — never decorate. Prioritize CSS-only solutions for HTML. Use Motion library for React when available. Focus on high-impact moments: one well-orchestrated page load with staggered reveals (animation-delay) creates more delight than scattered micro-interactions. Hover and scroll effects must be predictable and purposeful; honor `prefers-reduced-motion`.
- **Spatial Composition**: Create visual interest through scale contrast, weight, and density WITHIN the grid. Generous negative space OR controlled density — every element still aligns to the layout grid and the 4/8px spacing system.
- **Backgrounds & Visual Details**: Backgrounds are canvases — let content create the visual interest. No mesh-gradient blobs, noise textures, or grain overlays (rejected by ux-ui-design's anti-pattern table). Atmosphere comes from a purposeful palette, restrained geometric patterns, and shadows that convey real elevation — never decoration that competes with content.

NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character.

Interpret creatively and make choices that feel genuinely designed for the context. Give each PRODUCT a distinctive identity, then keep it consistent: within a product, reuse the same typefaces, palette, theme, and component conventions across every screen. Do not default to common AI choices (Space Grotesk, for example) — but never sacrifice product-level consistency for per-generation novelty.

**IMPORTANT**: Match implementation complexity to the aesthetic vision. Maximalist designs need elaborate code with extensive animations and effects. Minimalist or refined designs need restraint, precision, and careful attention to spacing, typography, and subtle details. Elegance comes from executing the vision well.

Remember: Claude is capable of extraordinary creative work. Don't hold back, show what can truly be created when thinking outside the box and committing fully to a distinctive vision.

## Completion Gate

After generating any user-facing screen, page, or section, invoke the **design-reviewer** agent for independent evaluation. Pass only the changed files — not your self-assessment. Do not present the output as complete until design-reviewer returns PASS.
