# SPEC-container-pages-2026-08-04.md

Spec-driven-development companion to
[BRAINSTORM-container-pages-2026-08-04.md](BRAINSTORM-container-pages-2026-08-04.md).
Builds on the already-shipped landing page (`SPEC-shiny-apps-landing-page-2026-08-04.md`,
PRs #43-45, live at `data-wise.github.io/mediation-apps`).

## 1. Objective

Replace the two instant-redirect stub pages (`docs/medci/index.html`,
`docs/medmc/index.html`) with real content pages, so a first-time visitor
gets context (what the app does, the formula, a worked example) before
committing to launch, instead of bouncing straight to Connect Cloud.

Target users: researchers citing the method, students/instructors,
returning users who just want to launch fast. All three are served by the
same page — content up top, an unmissable Launch button, no forced wait.

## 2. Commands

No build step — plain HTML/CSS, no framework, no package manager, same as
the existing `docs/` tree.

| Action | Command |
|---|---|
| Preview locally | `python3 -m http.server 8971` inside `docs/`, open `localhost:8971` |
| Deploy | Push to `main` — GitHub Pages (source = `docs/` on `main`) rebuilds automatically |
| Regenerate app manifests (unrelated, unaffected) | `Rscript -e 'rsconnect::writeManifest(".")'` inside `apps/<app>/` |

## 3. Project structure

```
docs/
├── index.html              # unchanged: 2-card menu, now links to container pages
├── medci/
│   └── index.html          # REPLACED: redirect stub -> content page
└── medmc/
    └── index.html          # REPLACED: redirect stub -> content page
```

Both container pages share one template (header, formula, worked example,
screenshot placeholder, citation `<details>`, Launch button, cross-link) —
see BRAINSTORM "Container page anatomy" for the full section list. No new
directories, no build tooling, no JS framework.

## 4. Code style

- Inline `<style>` per page, matching the existing `docs/index.html`
  convention (no shared stylesheet file yet — two pages don't justify one).
- Reuse copy verbatim from each app's own `ui.R` "About this calculator"
  panel and `README.md` — do not re-author descriptions.
- MathJax for formula rendering (`withMathJax()` is already a dependency
  pattern inside the apps themselves; container pages load it the same way
  the apps' `ui.R` files do — `mathjax.org`/CDN script tag).
- Color tokens: medci keeps `#2e6f63` (teal, shared with the live app);
  medmc's container page uses `#5b4b8a` (plum/indigo) as its own identity
  accent — this divergence is container-page-only, the live medmc Shiny UI
  stays teal per `DESIGN-STANDARDS.md`.
- Citation `<details>` block present on both pages for template symmetry;
  medmc's shows "Citation forthcoming" (no citation published yet).

## 5. Testing strategy

| Tier | Coverage |
|---|---|
| e2e | Local `http.server` preview: formula renders via MathJax, Launch button navigates to the correct Connect Cloud content URL (same URLs already verified in the redirect-stub implementation), cross-link navigates to the sibling container page |
| dogfood | Click through `index.html` -> medci container -> Launch, and `index.html` -> medmc container -> Launch; confirm no auto-redirect fires and the citation `<details>` expands/collapses on both pages |
| unit | N/A — static HTML/CSS, no parser/script |
| integration | N/A — no cross-command data flow |
| dependency | N/A — no new external dependency (MathJax CDN already used elsewhere in the ecosystem) |

## 6. Boundaries

**Always do:**
- Keep both container pages structurally identical (same template, same
  section order) — per-app differences are content/color only, not layout.
- Preserve the exact Connect Cloud content URLs already verified in the
  current redirect stubs (`019fcd3d-...` for medci, `019fcd7b-...` for
  medmc) — copy them out of the existing `docs/medci/index.html` /
  `docs/medmc/index.html` `<meta refresh>`/`canonical` tags before
  overwriting those files, do not retype or re-derive from memory.
- Update `README.md`'s "Live apps" section: both the prose ("branded launch
  cards for both apps") and the implied behavior need a check — it
  currently doesn't claim "instant redirect" outright, but should be
  re-read once the container pages exist in case anything there now reads
  as describing the old redirect-only flow.

**Ask first about:**
- Any change to the live Shiny apps' own `ui.R`/`server.R` (out of scope —
  this spec only touches `docs/`).
- Adding a shared stylesheet file or build tooling, if the two-page
  duplication becomes a real maintenance problem later.
- Publishing an actual medmc citation (replacing "forthcoming") once one
  exists.

**Never do:**
- Auto-redirect on page load — the whole point of this feature is
  replacing that behavior with an explicit Launch action.
- Add screenshots in this pass (deferred fast-follow per BRAINSTORM
  "Non-goals").
- Introduce a static site generator for two pages.

## Suggested next step

Implement on a feature branch (`feature/container-pages`) — spec is
decided, no open items remain.
