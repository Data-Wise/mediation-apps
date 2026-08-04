# SPEC: MEDMC migration to mediation-apps

**Status:** draft — for review before implementation
**Date:** 2026-08-04

## Problem

MEDMC (legacy `amplab.shinyapps.io/MEDMC`) is the second app slated for
migration into this repo, following the same pattern as `medci`
(`apps/medmc/`, native GitHub-connect deploy, no renv, manifest.json
committed). Unlike medci, a straight port is blocked: the app's core
call is `ci(M, S, QU, A, type="all")` — a raw mean vector, a covariance
matrix, an **arbitrary user-typed formula**, and an alpha level. Current
RMediation's `ci()` is an S7 generic dispatched on typed distribution
objects (`ProductNormal`, `ProductNormal2`, `ProductNormal3`), each
hardcoded to a fixed product structure (2 or 3 variables). There is no
current RMediation function that reproduces "arbitrary formula, Monte
Carlo + asymptotic-delta CI from a raw mean vector and covariance
matrix" — that generality doesn't exist in the modern typed API
(confirmed via `tools::Rd_db("RMediation")` — no matching topic).

Decision (already made): **reimplement the MC/delta computation
directly in the app**, not routed through `RMediation::ci()`. Same
statistical methods the original app used; RMediation stays a citation
and conceptual reference, not a runtime dependency for this
computation.

## What the original app does (from `medmc-bundle/ui.R` + `server.R`)

- **Inputs:**
  - `mu` — comma-separated coefficient estimates, e.g. `"1,0.7,0.6,0.45"`
  - `Sigma` — comma-separated **lower triangle** of the covariance
    matrix (column-major, top-to-bottom then next column), e.g.
    `"0.05,0,0,0,0.05,0,0,0.03,0,0.03"` for a 4×4 matrix
  - `quant` — a formula string referencing the coefficients as `b1`,
    `b2`, ... in the order given in `mu`, e.g. `"b1*b2*b3*b4"`.
    Documented as supporting `+ - * / ^` and `log()`.
  - `alpha` — significance level
- **Outputs:**
  - Submitted-values tables (coefficient vector, reconstructed
    covariance matrix) — a sanity check the user can visually confirm
    against what they typed
  - Results text: point estimate + CI from **both** the Monte Carlo
    method and the Asymptotic-Delta method
  - A density plot (Monte Carlo draws) with CI marked
  - A static "Monte Carlo Examples" tab (`MCexample.html`, pre-rendered
    from `MCexample.Rmd`) — an illustrative worked example, no
    computation, ports unchanged

## Statistical design

### Covariance matrix reconstruction

Original code uses `lavaan::vech.reverse()` to turn the lower-triangle
input into a full symmetric matrix. **Recommendation: write a small
local helper instead of attaching `lavaan`.** `lavaan` is a large SEM
package pulled in only for this one utility; a ~10-line
lower-triangle-to-symmetric-matrix function avoids the dependency
entirely. (`lavaan` is already transitively installed via RMediation,
so this isn't about availability — it's about not attaching a heavy
package for one utility function in a lean single-file app.)

### Monte Carlo CI

```r
draws <- MASS::mvrnorm(n = 1e5, mu = M, Sigma = Sigma)
colnames(draws) <- paste0("b", seq_along(M))
values <- eval(quant_expr, envir = as.data.frame(draws))
point_est <- eval(quant_expr, envir = as.list(setNames(M, colnames(draws))))
se <- sd(values)
ci <- quantile(values, c(alpha / 2, 1 - alpha / 2))
```

### Asymptotic-Delta CI

```r
grad_fn <- function(b) eval(quant_expr, envir = as.list(setNames(b, paste0("b", seq_along(b)))))
g <- numDeriv::grad(grad_fn, M)
se <- sqrt(t(g) %*% Sigma %*% g)
ci <- point_est + c(-1, 1) * qnorm(1 - alpha / 2) * se
```

`numDeriv` is already a transitive dependency (present in medci's
manifest), so no new package beyond `MASS` (also already present).

### Security: formula input is user-typed R code

**This needs a validator before `eval(parse(text = ...))`, not just
because it's good practice — the original app had the same
`eval`-on-user-string shape, and porting it without a guard would ship
a new instance of the same class of risk into a repo we're actively
building.** Restrict the formula to only:

- identifiers matching `^b[0-9]+$` (must also be `<= length(M)`)
- numeric literals
- operators `+ - * / ^ ( )`
- the single function `log()`

Reject (with a clear validation message, not a crash) anything else —
no other function calls, no assignment, no `;`, no backticks. Implement
as a regex/token allowlist checked before `parse()`/`eval()` ever runs,
not as a blocklist. This is a `validate()`/`need()` in `server.R`, same
idiom already used in `medci` for input bounds — not a new pattern.

## UI

Same layout family as medci's already-shipped 3-zone stack, adapted for
this app's extra input (the formula field) and the submitted-values
sanity tables:

1. **Inputs card** — coefficient estimates, covariance matrix (as
   entered), formula, alpha. No a/b column-tinting here since the
   number of coefficients is variable (unlike medci's fixed a/b pair).
2. **Result card** — both CIs (MC and Asymptotic-Delta), same
   fenced/copyable treatment as medci.
3. **Plot card** — density plot + download button, same pattern as
   medci.
4. Footer strip — submitted-values tables (collapsed by default, opt-in
   sanity check) + the Monte Carlo Examples content, ported from
   `MCexample.html` unchanged.

`fluidPage`/`bslib` theme, live reactivity (no `submitButton`),
`withMathJax()` instead of the CDN-loaded MathJax script the original
used — matching medci's already-established modernization, not a new
decision.

## File layout

```
apps/medmc/
├── ui.R
├── server.R
├── manifest.json       # generated via rsconnect::writeManifest(), no renv (matches medci)
├── www/
│   └── MCexample.html  # ported unchanged from medmc-bundle
├── legacy/              # original bundle files, provenance only (matches medci's legacy/)
└── README.md
```

No `.Rprofile`/`renv/` — same reasoning as medci (Connect Cloud doesn't
support renv; see `CLAUDE.md` Structure section).

## Verification plan

- `shiny::testServer()` against known values: reproduce the original
  app's example (`mu = "1,0.7,0.6,0.45"`, the 4×4 covariance matrix,
  `quant = "b1*b2*b3*b4"`) and sanity-check the MC/delta CIs are close
  to each other and centered near the plug-in point estimate.
- Explicit formula-validator tests: confirm `"b1*b2"`, `"log(b1)*b2"`
  pass; confirm `"system('ls')"`, `"b1; b2"`, `"unknownfn(b1)"` are
  rejected with a validation message, not evaluated.
- `ui.R` evaluates cleanly via `source()`, same check used for medci.

## Explicitly out of scope

- Any change to how `medci` or the mediationverse packages work.
- Porting the "beta version" disclaimer/feedback-email banner as
  functional UI — it's stale prose from 2014, can be dropped or
  reworded, not preserved literally.
