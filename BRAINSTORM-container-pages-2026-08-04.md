# BRAINSTORM: Container Pages for medci / medmc — 2026-08-04

## Context

The GitHub Pages site (`data-wise.github.io/mediation-apps`, PR #44/#45,
live) is currently a two-card index (`docs/index.html`) plus two stub pages
(`docs/medci/index.html`, `docs/medmc/index.html`) that instant-redirect via
`<meta http-equiv="refresh" content="0; ...">` to Connect Cloud. It solves
the "long URL" problem but has no content of its own — every visit either
bounces immediately or dead-ends on the two-card menu.

## Decisions (from expert questions)

| Question | Answer |
|---|---|
| Primary audience | Researchers citing the method, students/instructors, returning users (all three — page must serve first-time-context and instant-launch equally) |
| Container page content | Formula + worked example, screenshot/preview, citation block — full rich content, not just a bigger button |
| App hierarchy | Equals, side by side — no primary/secondary framing |
| ADHD principle | Progressive disclosure + visual distinctness + reduced redirect anxiety |
| Screenshots | Skip for v1 — fast-follow once page structure exists |
| Redirect behavior | **No auto-redirect.** Content page with an explicit Launch button — directly answers "redirect anxiety" |

## Proposal

Replace the two meta-refresh stub pages with real content pages. Keep
`docs/index.html` as the entry menu (still two equal cards) but make each
card link to a **container page**, not directly to Connect Cloud.

### Site structure

```
docs/
├── index.html              # menu (existing, unchanged in spirit)
├── medci/
│   └── index.html          # NEW: container page (was redirect stub)
└── medmc/
    └── index.html          # NEW: container page (was redirect stub)
```

### Container page anatomy (both apps, same template)

1. **Header** — app name + one-line description (reuse copy already in
   `README.md`/`ui.R` About panels — don't re-author).
2. **Formula block** — the notation already in each app's "About this
   calculator" accordion (`medci/ui.R:184-188`, `medmc/ui.R:191-195`),
   rendered with MathJax (already a dependency pattern in both apps' `ui.R`,
   so visitors get the same rendering they'd see in-app).
3. **Worked example** — one filled-in numeric example per app (medci: the
   existing default inputs â=0, b̂=0, SE=1,1, α=0.05; medmc: the existing
   default `1,0.7,0.6,0.45` / formula `b1*b2*b3*b4`), shown as a static
   result, not a live calculator — the container page renders, it doesn't
   compute.
4. **Citation block** — medci already has one (Tofighi & MacKinnon, 2011,
   `ui.R:199`); medmc doesn't have a published citation yet — flag this as
   an open item rather than inventing one.
5. **Screenshot slot** — reserved `<figure>` with alt text, image omitted
   in v1 per the "skip for now" decision; filled in as a fast-follow so the
   layout doesn't need to change later.
6. **Launch button** — explicit, prominent, single action — replaces the
   auto-redirect. This is the ONLY place the Connect Cloud URL appears.
7. **Cross-link** — "Need the other app instead?" back to `docs/index.html`
   or directly to the sibling container page (mirrors the in-app
   About-panel cross-links already shipped in PR #44).

### Visual distinctness

**Decided:** medmc gets its own accent color, distinct from medci's teal
(`#2e6f63`). Proposed: `#5b4b8a` (muted plum/indigo) — reads as clearly
distinct from teal at a glance, still muted enough to sit next to the
apps' shared warm-neutral palette (`#e1d9c8` borders, `#f6efe1` cream),
and carries no pre-existing semantic clash (not red/amber, which would
misread as a warning state).

This is a **container-page-only** change — it does not touch the live
Shiny apps' own CSS (`medmc/ui.R`'s `.mc-result`/`.mc-result-head`/CI-plot
colors stay teal, matching `DESIGN-STANDARDS.md`'s existing shared-token
convention for in-app UI). The distinct color is scoped to the marketing
layer (`docs/medmc/index.html`) as the page's identity accent, e.g. its
left-rail border and Launch button — a deliberate divergence from
in-app branding, not an inconsistency to fix later.

### Progressive disclosure

Formula + example open by default (this is the whole point of visiting);
citation block collapses into a `<details>`/accordion, matching the
in-app pattern (`bslib::accordion`) so the visual language carries over
from container page → app.

## Non-goals (v1)

- No live computation on the container page (that's what launching the app
  is for).
- No screenshots (fast-follow).
- No new build tooling — plain HTML/CSS, same as the current `docs/` tree,
  no static site generator introduced for two pages.

## Open items

All resolved:

- **medmc citation** — no published citation yet; the citation `<details>`
  block on medmc's container page shows "Citation forthcoming" instead of
  being omitted, so the section stays structurally identical to medci's
  (same template, no per-app layout branching) and is a one-line swap once
  a citation exists.
- **medmc accent color** — `#5b4b8a` (muted plum/indigo), distinct from
  medci's teal — see "Visual distinctness" above.

## Test plan

| Tier | Coverage |
|---|---|
| e2e | Load each container page locally (`python3 -m http.server` in `docs/`), verify formula renders via MathJax, Launch button navigates to the correct Connect Cloud content URL, cross-link navigates to the sibling page |
| dogfood | Click through index → medci container → Launch, and index → medmc container → Launch, confirm no auto-redirect fires |
| unit | N/A — static HTML/CSS, no parser/script introduced |
| integration | N/A — no cross-command data flow |
| dependency | N/A — no new external dependency |

## Documentation

- [x] README.md — update "Live apps" section: container pages change what
  the GitHub Pages link leads to (menu → content → explicit launch, not
  menu → instant redirect); update the description accordingly.
- [ ] DESIGN-STANDARDS.md — N/A, this doc covers the Shiny apps' own
  UI conventions, not the static `docs/` site; a container-page convention
  could be added here as a fast-follow but isn't required for v1.
- [ ] CHANGELOG — N/A, repo has no CHANGELOG.md currently (verify before
  release).

## Suggested next step

`/craft:plan:feature BRAINSTORM-container-pages-2026-08-04.md` or direct
implementation on a feature branch (`feature/container-pages`) once the two
open items above are resolved.
