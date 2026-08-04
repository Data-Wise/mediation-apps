# SPEC: A "front door" landing page for medci/medmc

Status: **Gate 0 resolved 2026-08-04 — `connect.posit.cloud/data-wise` already
lists both apps publicly, no login wall.** Added to `README.md`. Phases 1-3
(GitHub Pages build) are now optional polish, not required — pursue only if
the nicer branded launch-card visual is wanted for papers/teaching, not to
solve the core "long URL" problem, which Gate 0 already solves.

Folds in
[BRAINSTORM-shiny-apps-landing-page-2026-08-04.md](BRAINSTORM-shiny-apps-landing-page-2026-08-04.md)
(adversarially reviewed) into a concrete build spec.

## Context

medci and medmc are each deployed independently to Posit Connect Cloud,
each with its own long, cloud-issued URL. Neither the repo's `README.md`
nor either app links to the other's live URL today. This is an
ADHD-friendly-design problem one level up from the apps' own UI: remembering
an opaque long URL is exactly the working-memory tax the apps' interior
redesign (3-zone cards, debounced live feedback, this session's
matrix-swatch/alpha-preset work) has been stripping out of the apps
themselves.

Constraint (CLAUDE.md): Connect Cloud's GitHub-connect flow clones the raw
repo tree with no custom build step, and its publish flow requires
explicitly picking each app's `ui.R`/`app.R` as the primary file per app
(not an autodetection crawl of the whole tree). So a front door has to
either live outside Connect Cloud entirely, or be a third Connect Cloud app
— and adding files alongside `apps/` should not interfere with medci/medmc's
own publish config, though this is inferred from the Deploy section, not
yet smoke-tested.

## Decision

**Gate 0 (do first, before any implementation):** check whether Posit
Connect Cloud's account dashboard already lists both apps under one
shareable URL (e.g. `connect.posit.cloud/<account>`). If yes, that may
already satisfy "one URL to remember" for zero new work, and everything
below becomes optional polish rather than a requirement. This spec assumes
Gate 0 comes back negative or insufficient (e.g. requires login, isn't
meant to be public-facing, or isn't visually adequate) — confirm this
before starting Phase 1.

**If Gate 0 is negative: build a static GitHub Pages landing page**,
served from a `docs/` folder on `main`, at `data-wise.github.io/mediation-apps/`
(or `.../mediation-apps` — Pages URL trailing-slash behavior to be
confirmed during implementation, not assumed). Two large ADHD-friendly
launch cards (icon, one-line description, big button) link out to each
app's real Connect Cloud URL. Reuses card CSS tokens confirmed identical
between medci/medmc's `ui.R` files: `#2e6f63` accent
(`border-left: 4px solid #2e6f63` / `color: #2e6f63`), `border-radius:
12px`, and the exact same `box-shadow: 0 1px 2px rgba(32,42,39,0.06), 0 6px
20px rgba(32,42,39,0.05)`.

Chosen over the alternatives in the brainstorm because: no new
infrastructure beyond a repo setting toggle; free for a public repo served
via the `docs/`-folder method specifically (not an Actions-based deploy,
which would consume metered minutes); no third-party dependency or
link-rot risk (unlike a URL shortener); and doesn't cross the golem
escalation trigger a full app consolidation would.

## Scope

### In scope (this spec)

1. `docs/index.html` — the landing page itself, two launch cards.
2. Repo Settings → Pages enabled, source = `docs/` folder on `main`.
3. `README.md` "Live apps" section added, linking to the new Pages URL
   as the primary front door (plus the two direct Connect Cloud URLs as a
   fallback/reference).
4. Badge-ify those README links (shields.io-style "▶ Launch medci" /
   "▶ Launch medmc").
5. Cross-links between medci's and medmc's own "About" accordion panels,
   pointing at each other's live URL.
6. Per-app redirect shortcuts: `docs/medci/index.html` and
   `docs/medmc/index.html`, each a meta-refresh to the real Connect Cloud
   URL, giving `data-wise.github.io/mediation-apps/medci/` (confirm exact
   trailing-slash shape during implementation) as a direct deep-link.

### Explicitly out of scope (this spec)

- **Custom domain** (either on GitHub Pages or on Connect Cloud directly)
  — long-term item from the brainstorm; GitHub-Pages-side is well-documented
  and could follow later without disrupting this spec's URL, but isn't
  needed for the core ask. Connect-Cloud-side is unconfirmed whether the
  free tier even supports it — don't pursue until verified.
- **A third "hub" Shiny app on Connect Cloud** — considered, rejected:
  adds a third URL to remember (partially undercuts the goal) and its own
  `manifest.json`/deploy cycle for what is otherwise static content.
- **Consolidating medci + medmc into one multi-tab app** — genuinely
  solves "one URL," but is a real architectural change crossing the golem
  escalation trigger (CLAUDE.md). Separate spec if ever pursued.
- **URL shortener (bit.ly-style)** — a legitimate quick stopgap if the
  landing page is delayed, but not part of this build; adds an external
  dependency and link-rot risk that GitHub Pages avoids for free.
- **QR code generation** — trivial follow-up once the final front-door URL
  exists; not blocking, do after Phase 1 lands.

## Implementation plan

**Phase 0 — Verify (no code changes):**
- Check Connect Cloud account dashboard (Gate 0, above).
- Confirm `mediation-apps` repo visibility/plan — if private, confirm
  GitHub Pages is available (GitHub Free-for-organizations or higher).
- Decide the Pages source mechanism explicitly (`docs/` folder on `main`,
  per Decision above) rather than defaulting to whatever the Settings UI
  suggests.

**Phase 1 — Landing page:**
- `docs/index.html`: two launch cards reusing the confirmed-shared CSS
  tokens (see Decision). Static HTML/CSS, no build step, no JS framework
  needed for two links.
- Enable Pages in repo Settings, source = `docs/` on `main`.
- Smoke test: re-publish one existing app (e.g. medci) on Connect Cloud
  after `docs/` exists in the tree, to confirm adding the folder doesn't
  interfere with Connect Cloud's own primary-file selection (this is the
  one caveat from the brainstorm that's a real risk to the *existing* live
  apps, not just a nice-to-have — verify before merging).

**Phase 2 — Per-app deep links:**
- `docs/medci/index.html`, `docs/medmc/index.html` — meta-refresh
  redirects to each app's real Connect Cloud URL.
- Confirm actual served URL shape (trailing slash vs. `/index.html`) once
  Pages is live, and document the working form in `README.md`.

**Phase 3 — Doc + in-app updates:**
- `README.md`: add "Live apps" section, badge-style links, Pages URL as
  primary.
- `apps/medci/ui.R` / `apps/medmc/ui.R`: add a cross-link to the other
  app's URL in each "About" accordion panel.

## Verification

- Manual: visit the Pages URL, confirm both launch cards render and link
  to the correct live Connect Cloud URLs.
- Manual: visit each per-app redirect path, confirm it lands on the
  correct app.
- Manual: confirm the Phase 1 smoke test (re-publish of an existing app)
  still resolves to the same `ui.R`/`app.R` primary file Connect Cloud
  already had configured — no accidental re-selection prompt or broken
  deploy.
- No `shiny::testServer()` coverage applicable — this is static content
  and doesn't touch server-side reactive logic in either app; the only
  code-adjacent change (About-panel cross-links) is a static UI string,
  verified via `parse()` on the touched `ui.R` files.

## Open questions (carried from the brainstorm, unresolved)

- Does Gate 0 (Connect Cloud account dashboard) actually exist and is it
  shareable? Blocks whether Phase 1+ is needed at all.
- Exact GitHub Pages URL trailing-slash behavior for the per-app redirect
  paths (Phase 2) — confirm once Pages is live, don't guess in advance.
