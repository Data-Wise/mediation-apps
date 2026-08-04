# SPEC: MEDMC migration to mediation-apps

**Status:** revised after adversarial review — for review before implementation
**Date:** 2026-08-04 (v2 — v1 requested changes: see "Review history" below)

## Review history

v1 was adversarially reviewed (2026-08-04) — verdict REQUEST CHANGES, 2
critical + 6 important findings. v2 (this version) resolves all of them:

- **Point-estimate mismatch (critical):** resolved by reading the actual
  RMediation 1.1.3 source (contemporary with the 2014 app, pulled from
  the CRAN archive) — `confintMC.R`/`confintAsymp.R` confirm the MC and
  Asymptotic-Delta methods report **two different point estimates**
  (mean-of-draws vs. plug-in). See "Statistical design" below.
- **Missing `MCeqs.png` (critical):** added to file layout.
- **Unanchored formula validator, nested-paren DoS, non-finite results,
  Sigma dimension/PSD validation, live-reactivity perf, jQuery tab-jump
  script:** all addressed below, each in the section it affects.

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

Ground truth for this section: RMediation 1.1.3 source (`ci.R`,
`confintMC.R`, `confintAsymp.R`), pulled from the CRAN archive — the
version contemporary with the 2014 MEDMC app, not a guess from the
current S7 API.

### Covariance matrix reconstruction

Original code uses `lavaan::vech.reverse()` to turn the lower-triangle
input into a full symmetric matrix. **Recommendation: write a small
local helper instead of attaching `lavaan`.** `lavaan` is a large SEM
package pulled in only for this one utility; a ~10-line
lower-triangle-to-symmetric-matrix function avoids the dependency
entirely. (`lavaan` is already transitively installed via RMediation,
so this isn't about availability — it's about not attaching a heavy
package for one utility function in a lean single-file app.)

**Dimension validation (matches original's own check exactly, in
`ci.R`):** before reconstructing, validate
`length(M) == (sqrt(1 + 8 * length(S)) - 1) / 2`, i.e. `length(S)` must
equal `n(n+1)/2` for `n = length(M)`. Reject with a `validate()`/`need()`
message, not a matrix-construction crash, when it doesn't hold.

**Alpha bound:** the original's `numericInput("alpha", ...)` has no
bound at all. Add `validate(need(alpha > .0001 && alpha < .9999, ...))`
matching medci's existing convention for the same input.

**Positive-semi-definiteness:** `MASS::mvrnorm()` errors ungracefully on
a non-PSD `Sigma` (an easily-reachable user typo — e.g. a variance
smaller than its covariance implies). Wrap the MC draw step so this
surfaces as a `validate()` message ("the covariance matrix you entered
is not valid — check the diagonal (variance) values are large enough
relative to the off-diagonal covariances"), not an unhandled error.

### Monte Carlo CI

The original's MC point estimate is the **mean of the simulated
draws**, not a plug-in value — confirmed directly from `confintMC.R`:
`quantMean <- mean(quant.vec)`. n.mc default in the original is `1e6`;
this spec deliberately uses `1e5` instead as a documented performance
tradeoff for a web app running inside Connect Cloud's shared compute
(the accuracy difference between 1e5 and 1e6 MC draws is a `MC Error`
of `SE/sqrt(n)` — an order of magnitude smaller denominator, still
negligible in practice for a 3-significant-digit display).

```r
draws <- MASS::mvrnorm(n = 1e5, mu = M, Sigma = Sigma)
colnames(draws) <- paste0("b", seq_along(M))
values <- eval(quant_expr, envir = as.data.frame(draws))

#Guard: a formula that's smooth almost everywhere (e.g. 1/log(b1)) can
#still blow up at particular draws (log(1)=0). Drop non-finite draws
#before summarizing rather than letting NA/Inf propagate into SE/CI --
#but if ALL draws are non-finite, that's a validate() error, not a
#silently-empty result.
values <- values[is.finite(values)]
validate(need(length(values) > 0,
              "This formula is undefined for the values you entered (e.g. log of a non-positive number) -- try different coefficient estimates."))

point_est_mc <- mean(values)
se_mc <- sd(values)
ci_mc <- quantile(values, c(alpha / 2, 1 - alpha / 2))
```

### Asymptotic-Delta CI

The original's delta-method point estimate IS the plug-in value at
`M` (`confintAsymp.R`: `quantMean <- eval(quant, muList)`) — genuinely
different from the MC method's mean-of-draws. Both get displayed
separately in the results text, exactly as the original did (its output
string interpolates `newvals[[1]][[2]]` for MC and `newvals[[2]][[2]]`
for Asymptotic-Delta as two distinct numbers).

The original computes the gradient via R's base `deriv()` (symbolic
differentiation), not numeric differentiation — and since the allowed
formula grammar (`+ - * / ^ log()`) is exactly what `stats::deriv()`
supports natively, this spec uses the same approach: exact symbolic
derivatives, zero new dependency (base R), more accurate than a numeric
approximation and more faithful to the original.

```r
fx <- stats::deriv(quant_formula, paste0("b", seq_along(M)), func = TRUE)
grad <- as.vector(attr(do.call(fx, as.list(setNames(M, paste0("b", seq_along(M))))), "gradient"))

se_delta <- sqrt(t(grad) %*% Sigma %*% grad)
validate(need(is.finite(se_delta) && se_delta > 0,
              "The asymptotic-delta method isn't well-defined at these values -- try different coefficient estimates."))

point_est_delta <- eval(quant_expr, envir = as.list(setNames(M, paste0("b", seq_along(M)))))
ci_delta <- point_est_delta + c(-1, 1) * qnorm(1 - alpha / 2) * se_delta
```

### Live reactivity: debounce, don't drop it

medci's own PR #27 (2026-08-04) hit exactly this problem: live
reactivity without a submit button re-triggers the reactive on every
keystroke, and a MEDMC formula field being typed character-by-character
passes through many invalid intermediate states. Unlike medci, MEDMC's
computation is also genuinely expensive (1e5 MC draws + a symbolic
gradient on every trigger) — recomputing that on every keystroke is a
real perf issue, not just a flash-of-error UX issue. **Wrap the
combined reactive in `shiny::debounce(rawResults, 500)`** from the
start, matching medci's now-proven fix, rather than shipping without it
and hitting the same bug again.

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
no other function calls, no assignment, no `;`, no backticks.

**Two implementation requirements the validator must meet, not just
"an allowlist regex":**

1. **Fully anchored.** The check must be `grepl("^(...)$", trimws(formula))`
   against the *entire* trimmed string — never an unanchored
   `grepl(pattern, x)`/search-style match. An unanchored check is the
   classic way an allowlist like this gets bypassed: a legitimate
   allowed prefix can make the match succeed while a disallowed suffix
   (e.g. `"b1*b2; system('ls')"`) rides along unrejected.
2. **Length/nesting cap.** R's parser is recursive-descent and can hit
   "C stack usage too close to limit" — crashing or hanging the R
   process — on deeply nested parenthesized expressions. Every
   character involved in such an attack (`(`, `)`, digits, `b`) is
   already in the allowlist charset, so the charset check alone does
   not block it. Cap the formula string at a small length (e.g. **200
   characters**) and reject before `parse()` ever sees it — this single
   cap also incidentally bounds nesting depth, since you can't nest
   deeper than you have characters for.

This is a `validate()`/`need()` in `server.R`, same idiom already used
in `medci` for input bounds — not a new pattern.

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
   `MCexample.html`.

`fluidPage`/`bslib` theme, live-but-debounced reactivity (see above; no
`submitButton`), `withMathJax()` instead of the CDN-loaded MathJax
script the original used — matching medci's already-established
modernization, not a new decision.

**Monte Carlo Examples tab is NOT a pure "ported unchanged" copy.** The
original's inline link (`<a id='linkToMCEX'>`) jumps to that tab via a
jQuery snippet that directly manipulates Bootstrap-2-era
`.nav-tabs`/`.tab-pane` classes — this will not work under `bslib`'s tab
markup. Replace it with `bslib`'s own navigation: use
`bslib::nav_panel()`/`bslib::navset_tab()` for the tab structure and
`shiny::updateTabsetPanel()` (or `bslib::nav_select()`) for the
link-jump behavior, driven by an `actionLink` + `observeEvent` instead
of raw jQuery. `MCexample.html`'s *content* (the worked-example prose
and embedded figure) ports unchanged; only the tab-switching mechanism
needs a `bslib`-native replacement.

## File layout

```
apps/medmc/
├── ui.R
├── server.R
├── manifest.json       # generated via rsconnect::writeManifest(), no renv (matches medci)
├── www/
│   ├── MCexample.html  # worked-example content, ported unchanged
│   └── MCeqs.png       # referenced by ui.R's Monte Carlo Examples tab -- missing from v1 of this spec
├── legacy/              # original bundle files, provenance only (matches medci's legacy/)
└── README.md
```

No `.Rprofile`/`renv/` — same reasoning as medci (Connect Cloud doesn't
support renv; see `CLAUDE.md` Structure section).

## Verification plan

- `shiny::testServer()` against known values: reproduce the original
  app's own documented example (`mu = c(b1=1,b2=.7,b3=.6,b4=.45)`,
  `Sigma = c(.05,0,0,0,.05,0,0,.03,0,.03)`, `quant = ~b1*b2*b3*b4` — this
  is `ci()`'s own `@examples` block in RMediation 1.1.3, not an
  invented case) via `session$elapse()` past the debounce window.
  Sanity-check the MC and Asymptotic-Delta CIs are close to each other
  but confirm they are **not required to share a point estimate**
  (mean-of-draws vs. plug-in — see Statistical design).
- Explicit formula-validator tests:
  - Accept: `"b1*b2"`, `"log(b1)*b2"`
  - Reject (malicious/invalid): `"system('ls')"`, `"b1; b2"`,
    `"unknownfn(b1)"`
  - Reject (anchoring bypass attempt): `"b1*b2; system('ls')"` — a
    string with a valid allowed prefix and a disallowed suffix; must be
    rejected by the anchored check, not partially matched
  - Reject (DoS attempt): a formula string of 500+ nested parens —
    must be rejected by the length cap before `parse()` runs, not left
    to the parser
- Explicit input-validation tests:
  - `Sigma` length mismatched with `mu` length (e.g. 4 coefficients but
    a 3-coefficient covariance vector) — friendly `validate()` message,
    not a matrix-construction crash
  - Non-PSD `Sigma` (e.g. a covariance larger than the geometric mean of
    its variances allows) — friendly `validate()` message, not an
    `mvrnorm()` crash
  - A formula that's undefined at some MC draws but not all (e.g.
    `"1/log(b1)"` with `b1` centered near 1) — confirm non-finite draws
    are dropped and the CI still computes from the finite remainder
- `ui.R` evaluates cleanly via `source()`, same check used for medci.
- Render-gate: confirm both `MCexample.html` and `MCeqs.png` actually
  load in the built app (per the repo's `render-gate` skill convention),
  not just that `ui.R` sources without error.

## Explicitly out of scope

- Any change to how `medci` or the mediationverse packages work.
- Porting the "beta version" disclaimer/feedback-email banner as
  functional UI — it's stale prose from 2014, can be dropped or
  reworded, not preserved literally.
- Matching the original's plot-only coefficient parsing bug: the
  original's plot renderer used a digit-only regex (`numextractall`)
  that silently stripped minus signs, so negative coefficients
  historically rendered incorrectly in the plot even though the results
  *text* (parsed via `strsplit` on commas) handled them correctly. This
  spec's unified parsing (one parse path for both the results text and
  the plot) is a deliberate fix, not an accidental behavior change from
  the original.
