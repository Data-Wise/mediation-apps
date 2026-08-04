# Design & Engineering Standards for mediation-apps Shiny Apps

Status: living reference, extracted from medci and medmc (2026-08-04). A
third app should be able to start from this document instead of
re-deriving these patterns from scratch. Update this file whenever a
pattern here changes in either app — it's a reference to what's actually
implemented, not aspirational.

## 1. Layout: the 3-zone card stack

Single-column, max-width, centered — not a `sidebarLayout`. Sequential
cards give the eye exactly one anchor at a time instead of putting inputs,
results, plot, and notes at the same visual weight simultaneously.

```
Zone 1 -- Inputs        (quiet card)
Zone 2 -- Result        (the one visually loud element)
Zone 3 -- Plot           (quiet card, supporting evidence)
Footer -- everything else, collapsed by default (accordion)
```

Reference implementation: `apps/medci/ui.R:115-202`,
`apps/medmc/ui.R` (equivalent structure).

Wrapper: `div(class = "mc-page", ...)` — `max-width: 720px; margin: 0
auto;` (both apps' `ui.R`, `.mc-page` rule).

**Rule:** anything that isn't the primary input → result → plot path goes
in the footer accordion (`class = "mc-footer-strip"`, `bslib::accordion(open
= FALSE, ...)`), not inline in the main flow. Examples already following
this: medci's "About this calculator" / SE-formula / citation panels
(`apps/medci/ui.R:178-201`); medmc's "Submitted values (sanity check)" /
"About this calculator" panels (`apps/medmc/ui.R`).

## 2. CSS design tokens

Confirmed identical between `apps/medci/ui.R` and `apps/medmc/ui.R` —
treat these as the shared palette for any new app, not a per-app choice:

| Token | Value | Used for |
|---|---|---|
| Accent | `#2e6f63` | Result card left rail, result heading text |
| Card border | `#e1d9c8` | All card/footer-strip borders |
| Card radius | `12px` (`10px` for the footer strip) | `.mc-card`, `.mc-result` |
| Card shadow | `0 1px 2px rgba(32,42,39,0.06), 0 6px 20px rgba(32,42,39,0.05)` | `.mc-card`, `.mc-result` |
| Result background | `#f0f6f4` | `.mc-result` |
| Body text | `#202a27` | `.mc-result-text` |
| Muted/label text | `#616e69` | `.mc-card-head`, `.mc-footer-strip .accordion-button` |
| Monospace stack | `ui-monospace, 'SF Mono', Menlo, monospace` | `.mc-result-text` |

Paired-input tint colors (medci-specific, reusable pattern for any app with
naturally paired coefficients): `#eaf3f1` / `#f6efe1` (`.mc-coef-a` /
`.mc-coef-b`, `apps/medci/ui.R:59-64`) — color-codes which inputs belong
together (e.g. â with its SE) so the pairing reads instantly without
reading labels.

**Rule:** define these once via `tags$style(type = "text/css", HTML("..."))`
at the top of `ui.R`, scoped by the shared `.mc-*` class prefix. Don't
introduce a new accent color or shadow value in a new app without a reason
— the whole point is that a user moving between apps in this ecosystem
sees one consistent visual language.

## 3. Reactive & debounce discipline

**Rule, non-negotiable:** any Shiny `output` that reads a *debounced*
reactive must get **every** value it needs from that reactive's return
value — never touch `input$...` directly inside the same output. Shiny
subscribes an output to every reactive/input it reads during evaluation,
not just the first one; a mixed dependency (debounced reactive + raw
input) means the output still fires on every keystroke, defeating the
debounce.

This has bitten this codebase twice:
- medci's `drawPlot()` (PR #27's first attempt) called the debounced
  `results()` for its validation side-effect, then read
  `mu.x`/`mu.y`/`se.x`/`se.y`/`rho`/`alpha` from `input$...` directly.
  Fixed by having `rawResults()` return a list carrying all six values,
  and `drawPlot()` reading exclusively from `results()$...`
  (`apps/medci/server.R:17-31` — see the comment documenting this).
- medmc's `output$interval` read `input$alpha` directly alongside the
  debounced `results()` while formula/mu/Sigma flowed correctly through
  the return list — caught while restructuring the Significance Level
  input to a `selectizeInput`. Fixed the same way: `alpha` parsed once in
  `rawResults()`, carried in its return list
  (`apps/medmc/server.R` — see the comment on the `list(...)` return and
  on `output$interval`).

**Pattern to follow in any new app:**
```r
rawResults <- reactive({
  # ... validation, computation ...
  list(
    # every value any downstream output needs, including things that
    # *look* like they could just be read from input$ again
    expr_text = input$quant,
    alpha = alpha_val,
    mc = list(...), delta = list(...)
  )
})
results <- debounce(rawResults, 500)

output$interval <- renderText({
  r <- results()
  # read ONLY from r$..., never input$... here
})
```

**Non-debounced outputs are fine and don't need this discipline** — e.g.
medmc's `parseSigma()`-derived live matrix sanity-check table/swatch are
deliberately *not* debounced (they update on every keystroke, same as the
raw parse functions they're built on) precisely because they're not mixed
with a debounced reactive. The rule only applies when an output's
dependency graph includes both a debounced reactive and a raw input.

500ms is the established debounce interval for expensive recomputation
(Monte Carlo draws, symbolic differentiation) triggered by live reactivity
with no submit button.

## 4. Input validation conventions

- Use `validate(need(condition, "message"))`, not custom `if`/red-text
  `textOutput`s. Renders Shiny's standard inline-error style, keeps
  validation logic co-located with the reactive it guards.
- **Tolerances on computed conditions (e.g. PSD checks, near-zero
  denominators) must be scaled to the value's own magnitude, not a bare
  absolute cutoff.** User-typed numeric inputs are unbounded — an absolute
  tolerance is wrong at both extremes (false negatives on large-magnitude
  near-singular cases, false positives from float noise on tiny values).
  Reference: medmc's `covmatPSD()`,
  `tol <- 1e-8 * max(abs(ev)); min(ev) > -tol` (`apps/medmc/server.R`).
- **Open-interval bounds should say so precisely.** medmc's Significance
  Level validates `alpha_val > 0 && alpha_val < 1` with the message
  "...between 0 and 1 (exclusive)" — don't leave the boundary behavior
  implicit in the message text.
- **User-typed formulas evaluated via `eval()` need a structural allowlist,
  not a blocklist.** medmc's `validateFormula()` pattern: fully-anchored
  regex (`^[...]+$`) against the *entire* trimmed string (never an
  unanchored search-match), charset restricted to exactly the characters
  needed for the allowed grammar, plus a length cap to bound parser
  recursion depth (`apps/medmc/server.R` — see `validateFormula()`'s
  extensive comment for why this specific charset is a structural
  guarantee, not a heuristic). Reuse this pattern verbatim for any new app
  that evaluates user-typed expressions.

## 5. Live-visual sanity checks (optional, opt-in by default)

If an app takes structured input a user could easily transpose or
mis-enter (e.g. a matrix, a formula), consider a live, non-debounced visual
alongside the raw text input — but:

- Gate it behind a checkbox, default **off**, if it doesn't clearly earn
  its default-visible screen space. medmc's matrix color-grid swatch
  started default-on, then was made opt-in after "does not add much"
  feedback (`apps/medmc/server.R`, `req(input$showSwatch)`).
- Prefer `renderUI()` with a CSS grid over `renderPlot()`/`image()` for
  small live visuals redrawing on every keystroke — a graphics-device
  round trip per keystroke is a real lag/flicker risk on shared compute
  (Connect Cloud), a CSS grid redraws cheaply.
- Cap the visual's size for large inputs (medmc's swatch falls back to a
  text note beyond 6 coefficients) rather than letting it degrade
  silently into an illegible wall of cells.
- Blank (not zero-fill) any display cells that are structurally derived
  rather than user-entered (e.g. medmc's mirrored upper-triangle matrix
  cells, `apps/medmc/server.R`, `display[upper.tri(Sigma)] <- NA` +
  `na = ""` in `renderTable`) — showing a derived value back as if the
  user typed it is misleading. But a **genuine** zero the user did type
  should stay visible (formatted to cut trailing-zero noise if needed,
  not blanked) — blanking it would make it indistinguishable from a
  structurally-derived cell.

## 6. Security

Any `eval()` on user-typed text requires the allowlist pattern in §4
(structural charset guarantee + anchored full-string match + length cap).
Document *why* the specific charset is safe (which base-R function names
are/aren't spellable from it) — don't just assert it.

## 7. Testing conventions

- `parse("ui.R")` / `parse("server.R")` after any edit — catches syntax
  errors before deploy, matches what Connect Cloud's GitHub-connect flow
  will actually execute (no separate build/lint step in the pipeline).
- `shiny::testServer()` for behavioral regression coverage: extract the
  server function (`shinyServer <- function(f) f; server <-
  source("server.R", local = TRUE)$value`), drive with
  `session$setInputs()` + `session$elapse(ms)` to simulate debounce
  timing, assert on `output$...`. Cover: the happy path, each `validate()`
  boundary condition, and — whenever an output depends on both a debounced
  reactive and raw inputs — an explicit check that changing the raw input
  alone does *not* cause the debounced output to resettle early (guards
  against reintroducing the §3 bug).
- No `shinytest2` end-to-end coverage yet in either app — a known gap, not
  a standard to violate; note it in a new app's README's Follow-up section
  rather than silently skipping it.

## 8. Manifest / deploy

- `manifest.json` regenerated via `rsconnect::writeManifest(".")` after
  every code change, committed alongside the change (not hand-edited).
- No `renv` — Connect Cloud's GitHub-connect flow clones the raw repo tree
  with no `renv::restore()` step; `manifest.json` alone drives package
  provisioning. See root `CLAUDE.md` Structure section for the full
  rationale.
- Connect Cloud publish requires explicitly picking each app's
  `ui.R`/`app.R` as the primary file per app at connect-time — it is not
  an autodetection crawl of the whole repo tree.

## 9. Container pages (docs/ site)

Every app gets a container page at `docs/<app>/index.html`, linked from
the `docs/index.html` menu — plain HTML/CSS, no build step, matching the
apps' own inline-`<style>` convention. Reference implementation:
`docs/medci/index.html`, `docs/medmc/index.html` (2026-08-04).

**Template (same section order for every app):**

1. Nav row — back to `docs/index.html`, forward to the sibling app.
2. Header card — app name + one-line description, left-rail accent border
   in the app's identity color.
3. Formula card — the method's notation, rendered via MathJax (CDN script
   tag with a pinned `integrity` hash — see below), reusing copy already
   written in the app's own "About this calculator" panel. Don't
   re-author descriptions; copy them.
4. Worked-example card — one filled-in numeric example with a real
   computed result, not a placeholder number. Verify the number against
   the actual method (e.g. `RMediation::medci()` directly, or an actual
   Monte Carlo simulation matching the app's default inputs) before
   committing it — a fabricated-looking-plausible CI is a real risk here
   (caught and fixed twice in this repo's history, both apps).
5. Screenshot `<figure>` — a real capture of the live app (see
   `reference_browser_screenshot_to_file_capture` memory for the capture
   technique), not a mockup.
6. Citation `<details>` (collapsed by default) — every app gets this
   section for template symmetry even without a published citation yet;
   show "Citation forthcoming" rather than omitting the section.
7. Explicit Launch button — the *only* place the Connect Cloud URL
   appears. No auto-redirect (`<meta http-equiv="refresh">`) — the whole
   point of a container page over a redirect stub is giving the visitor
   context before they commit to leaving the site.

**Identity color:** each app's container page may use its own accent
color, distinct from its siblings, even when the apps share a color in
their own live Shiny UI (medci and medmc both use `#2e6f63` teal
in-app; medmc's container page uses `#5b4b8a` instead). This is a
deliberate, container-page-only divergence for visual distinctness
between apps on the menu page — not a drift to reconcile.

**MathJax loading:** pin a `integrity="sha384-..."` hash on the CDN
`<script>` tag (compute via `curl <url> | openssl dgst -sha384 -binary |
openssl base64 -A`) — a bare CDN `<script src>` with no SRI is a supply-
chain risk a security-review pass will flag.
