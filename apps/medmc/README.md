# medmc

"Monte Carlo Confidence Intervals for Indirect Effects" — Shiny
frontend for Monte Carlo / Asymptotic-Delta confidence intervals of an
arbitrary user-defined nonlinear function of coefficient estimates
(e.g. sequential indirect effects, contrasts of indirect effects).

Migrated from `amplab.shinyapps.io/MEDMC` (`server.R` dated 2/10/2014).

Live on Posit Connect Cloud (connect.posit.cloud), verified working as
of 2026-08-04.

## Status

Not a straight port. The original called
`RMediation::ci(M, S, QU, A, type="all")`, where `QU` was an arbitrary
user-typed formula evaluated via Monte Carlo + asymptotic-delta methods
on a raw mean vector and covariance matrix. Current RMediation's `ci()`
is an S7 generic on typed distribution objects (`ProductNormal`,
`ProductNormal2`, `ProductNormal3`) with no equivalent for an arbitrary
formula — confirmed via `tools::Rd_db("RMediation")` and by reading the
RMediation 1.1.3 source directly (the version contemporary with this
app, pulled from the CRAN archive).

**Reimplemented the MC/delta computation directly in this app**, not
routed through `RMediation::ci()`. Same statistical methods, verified
against the actual 1.1.3 source:

- Monte Carlo point estimate = mean of simulated draws
  (`MASS::mvrnorm`, `n = 1e5` — a deliberate reduction from the
  original's `n = 1e6` default, a performance tradeoff for Connect
  Cloud's shared compute)
- Asymptotic-Delta point estimate = plug-in value at the mean vector,
  SE via symbolic differentiation (`stats::deriv`, matching the
  original's method exactly — not a numeric approximation)
- These are genuinely different numbers, matching the original's
  behavior (its two methods' point estimates were never the same value)

See `SPEC-medmc-migration-2026-08-04.md` (repo root) for the full
design record, including the adversarial review that caught the
point-estimate assumption before implementation.

## Matrix sanity-check

Next to the Variance-Covariance Matrix input: a numeric table
(`output$covmat`) showing only the lower triangle + diagonal the user
actually typed -- the mirrored upper-triangle cells `vechReverse()`
fills in for matrix algebra are blanked in the display copy, not shown
as redundant zeros. An optional color-coded grid (`output$covmatSwatch`,
`renderUI` CSS grid, not a plot -- redraws cheaply on every keystroke)
is available via a "Show color grid" checkbox (default off; it
duplicated the table without adding much). Both are sourced from
`parseSigma()`. The grid flags a non-positive-semi-definite matrix
visually (via `eigen()`, magnitude-scaled tolerance) before it would
otherwise only surface once `MASS::mvrnorm()` fails inside the debounced
`results()`, and is capped at 6 coefficients -- larger matrices fall
back to the table alone. See
`/Users/dt/.claude/plans/abstract-weaving-boot.md` for the design record
(adversarially reviewed before implementation).

## Significance Level input

A `selectizeInput` with common presets (`.0001`, `.005`, `.01`, `.05`,
`.1`) plus free typing (`create = TRUE`) for any other value. Validated
server-side against the open interval (0, 1) exclusive. Replaced the
original `numericInput` because its spin-arrow widget didn't match how
the field is actually used (typed directly, not incremented). Restructuring
this also surfaced and fixed a latent bug: `output$interval` was reading
`input$alpha` directly in addition to the debounced `results()` -- the
same mixed-dependency class documented in medci's `drawPlot()` history
(PR #27). `alpha` is now parsed once inside `rawResults()` and carried
through its return list.

## Security

The formula field is user-typed R code, evaluated via `eval()`. Guarded
by `validateFormula()` in `server.R`: a fully-anchored charset allowlist
restricted to exactly the letters `b`, `l`, `o`, `g` (enough for `b1`,
`b2`, ..., `log()` and nothing else — no other base-R function name is
spellable from that letter set), digits, and `+ - * / ^ ( )`, plus a
200-character length cap (blocks R's parser from crashing on deeply
nested parentheses, a vector the charset check alone doesn't cover).

## No `renv`

Same reasoning as `medci` — Connect Cloud doesn't support renv for
environment setup; `manifest.json` alone drives package provisioning.
See the repo's `CLAUDE.md` Structure section.

`legacy/` holds the other files from the original shinyapps.io bundle
(`global.R`, `test.R`, `MSEM.png`, `plots.png`, `enter.js`, and the
`.Rmd`/`.html`/`.md` sources for the worked-example content) for
provenance only.

## Follow-up

- `shinytest2` e2e coverage — everything so far verified via
  `parse()`/`source()` and `shiny::testServer()`, matching medci's
  documented gap.
- The Monte Carlo Examples tab's inline "click here" link uses
  `updateTabsetPanel()` (bslib-native) instead of the original's raw
  jQuery `.nav-tabs` manipulation, which doesn't work under bslib's tab
  markup.
