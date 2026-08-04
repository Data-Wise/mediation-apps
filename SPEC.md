# SPEC.md

Spec-driven-development companion to
[SPEC-shiny-apps-landing-page-2026-08-04.md](SPEC-shiny-apps-landing-page-2026-08-04.md)
(the detailed build spec — this file is the 6-area summary format).

**Status (2026-08-04, updated): done and shipped**, beyond what this
spec originally scoped. What started as "optional polish" (Gate 0 below
already solved the core problem) became the primary public front door:
GitHub Pages went from a 2-card menu + instant redirects (this spec's
original scope, PRs #43-45) to full per-app container pages with a
formula, worked example, citation, real screenshots, and an explicit
Launch button replacing the redirect (PRs #46-50 — see
[SPEC-container-pages-2026-08-04.md](SPEC-container-pages-2026-08-04.md)
for that follow-on spec). Live at
[data-wise.github.io/mediation-apps](https://data-wise.github.io/mediation-apps/).

## 1. Objective

Give medci and medmc a single memorable "front door" URL, so users don't
have to remember either app's long Posit Connect Cloud address. Target
users: researchers/students using the mediation-apps ecosystem, plus the
maintainer sharing links in papers/teaching materials.

**Gate 0 resolved 2026-08-04:** `connect.posit.cloud/data-wise` already
lists both apps publicly, no login required. Added to `README.md`. The
GitHub Pages build below was pursued anyway as the nicer, more
substantial front door — see Status note above.

## 2. Commands

No build step — this is static HTML/CSS, no framework, no package manager.

| Action | Command |
|---|---|
| Preview locally | Open `docs/index.html` directly in a browser |
| Enable hosting | Repo Settings → Pages → source = `docs/` folder on `main` |
| Regenerate app manifests (unrelated apps, unaffected by this work) | `Rscript -e 'rsconnect::writeManifest(".")'` inside `apps/<app>/` |

## 3. Project structure

```
docs/
├── index.html            # landing page: 2 launch cards (medci, medmc)
├── medci/index.html      # container page: formula, worked example, screenshot,
│                          # citation, explicit Launch button (was a redirect stub
│                          # as originally scoped here -- see SPEC-container-pages)
├── medci/img/screenshot.png
├── medmc/index.html      # same template, medmc's own #5b4b8a accent
└── medmc/img/screenshot.png
```

Existing `apps/medci/ui.R`, `apps/medmc/ui.R` get one addition each: a
cross-link to the other app's URL in their "About" accordion panel. No
other files in `apps/` change.

## 4. Code style

- Plain HTML + inline/embedded CSS. No JS framework — two links don't need
  one.
- Reuse the CSS tokens already shared and confirmed identical between
  `apps/medci/ui.R` and `apps/medmc/ui.R` (see `DESIGN-STANDARDS.md` §2):
  `#2e6f63` accent, `border-radius: 12px`, `box-shadow: 0 1px 2px
  rgba(32,42,39,0.06), 0 6px 20px rgba(32,42,39,0.05)`. The landing page
  should look like it belongs to the same product as the apps it links to,
  not a generic directory listing.
- ADHD-friendly layout: two large launch cards (icon, one-line description,
  big button), no scrolling required, no wall of prose.

## 5. Testing strategy

No `shiny::testServer()` coverage applicable — static content, no
server-side reactive logic touched.

- Manual: visit the Pages URL, confirm both cards render and link to the
  correct live Connect Cloud URLs.
- Manual: visit each per-app redirect path, confirm it lands on the
  correct app.
- Manual smoke test (real risk, not optional): re-publish one existing app
  (e.g. medci) on Connect Cloud after `docs/` exists in the tree, confirm
  it still resolves to the same `ui.R` primary file — no accidental
  re-selection prompt or broken deploy. **Never run explicitly as a
  standalone step** (needs the maintainer's own Connect Cloud login), but
  implicitly validated: both apps' Connect Cloud content kept
  auto-republishing correctly through every `docs/`-touching merge to
  `main` in this spec's history (PRs #45, #47, #49), confirmed via direct
  screenshot verification of both apps as recently as 2026-08-04.
- `parse("ui.R")` on `apps/medci/ui.R` / `apps/medmc/ui.R` after the
  About-panel cross-link edit (static string change only).

## 6. Boundaries

**Always do without asking:**
- Static file edits under `docs/`.
- `parse()`-checking any `ui.R` touched.

**Ask first:**
- Enabling GitHub Pages in repo Settings (a repo configuration change,
  not a code change).
- Editing `apps/medci/ui.R` or `apps/medmc/ui.R` (live, deployed app code)
  — even for the small About-panel cross-link, confirm before merging
  given the smoke-test risk noted above.
- Any change to repo visibility/plan (relevant if GitHub Pages
  availability turns out to depend on it).

**Never do:**
- Touch medci/medmc's statistical/server-side logic as part of this work
  — out of scope, unrelated to the front-door problem.
- Introduce a build step, JS framework, or third-party hosting dependency
  for what two static launch cards don't need.
- Assume the Pages URL shape (trailing slash, `.io/repo` pattern) without
  confirming once Pages is actually live — stated as fact in the detailed
  SPEC's Phase 2, not to be shortcut here either.
