# medci

Shiny frontend for `RMediation::medci()` — confidence intervals for the
product of two coefficients (distribution-of-product, Monte Carlo,
asymptotic normal methods).

Migrated from `amplab.shinyapps.io/MEDCI` (app id 60898, live since
2019-07-29, originally created 2015-09-21).

## Verification

Original `ui.R`/`server.R` (dated 2013-09-24) tested against current CRAN
`RMediation` 1.6.1 inside this app's pinned `renv` environment — sources
clean, `medci(type="all")` returns the same three-method structure the UI
expects. No code changes were needed; the original app was compatible
as-is.

`legacy/` holds the other files from the original shinyapps.io bundle
(`olds.R`, `oldu.R`, `changeserver.R`, `changeui.R`,
`serverWebsiteCurrent.R`, `uiWebsiteCurrent.R`, `medci info.docx`) for
provenance only — Shiny's classic `ui.R`/`server.R` mode does not
auto-source them, so they have no effect on the running app.

## Follow-up

- `shinytest2` e2e coverage (per mediation-apps CLAUDE.md test-tier
  convention) — this migration was verified by direct function-call
  testing, not a full UI interaction test yet.
- Deploy to Connect Cloud via the repo's path-filtered CI workflow.
