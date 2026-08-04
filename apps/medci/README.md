# medci

Shiny frontend for `RMediation::medci()` — confidence intervals for the
product of two coefficients (distribution-of-product, Monte Carlo,
asymptotic normal methods).

Migrated from `amplab.shinyapps.io/MEDCI` (app id 60898, live since
2019-07-29, originally created 2015-09-21).

## Status

Live on Posit Connect Cloud (connect.posit.cloud), verified working as of
2026-08-04. No `renv` — Connect Cloud's native GitHub-connect publish
flow clones the raw repo tree and provisions packages purely from
`manifest.json`; see the repo's `CLAUDE.md` Structure section for why
`renv` was removed entirely rather than just `.rscignore`'d.

Original `ui.R`/`server.R` (dated 2013-09-24) initially verified
compatible as-is against current CRAN `RMediation` 1.6.1. Since then:

- Fixed a mislabeled-CI bug (`server.R` indexed the Monte Carlo result by
  position while labeling it "distribution of the product" — now indexed
  by name).
- Modernized the UI in two rounds: `fluidPage`/`bslib` theme, live
  reactivity (dropped `submitButton`), MathJax notation, `validate()`
  error handling, responsive plot sizing, paired a/b input columns,
  citation/about moved into collapsible panels.

`legacy/` holds the other files from the original shinyapps.io bundle
(`olds.R`, `oldu.R`, `changeserver.R`, `changeui.R`,
`serverWebsiteCurrent.R`, `uiWebsiteCurrent.R`, `medci info.docx`) for
provenance only — Shiny's classic `ui.R`/`server.R` mode does not
auto-source them, so they have no effect on the running app.

## Follow-up

- `shinytest2` e2e coverage (per mediation-apps CLAUDE.md test-tier
  convention) — everything so far has been verified via
  `parse()`/`source()` and `shiny::testServer()`, not a full snapshot/UI
  interaction test suite.
- Parked: interactive `plotly` density plot and bookmarkable input state
  (items #9-10 from the UI enhancement review) — both cross the golem
  escalation trigger, out of scope for the current single-file app.
- Parked: dark-mode toggle (`bslib::input_dark_mode()`). Not a drop-in —
  the 3-zone layout's custom CSS (`.mc-card`, `.mc-result`, `.mc-coef-a`/
  `-b`) uses hardcoded hex colors, not theme-aware tokens, so those blocks
  would stay light-colored while Bootstrap's own components flipped.
  Needs a CSS-custom-properties rework first.
