
#Shiny Application for RMediation-style Monte Carlo / Asymptotic-Delta
#confidence intervals for an arbitrary user-defined formula.
#server script file
#
#Migrated 2026-08-04 from the legacy amplab.shinyapps.io/MEDMC app
#(server.R dated 2/10/2014). NOT a straight port: the original called
#RMediation::ci(M, S, QU, A, type="all"), but current RMediation's ci()
#is an S7 generic on typed distribution objects with no equivalent for
#an arbitrary user-typed formula over a raw mean vector + covariance
#matrix. Reimplemented directly here instead -- see
#SPEC-medmc-migration-2026-08-04.md for the full design record,
#including how the statistical methods below were verified against the
#actual RMediation 1.1.3 source (contemporary with this app).



library(shiny)
library(MASS)



#Turns a lower-triangle vector (column-major: top of left column
#downward, then next column, matching the original app's documented
#input format) into a full symmetric matrix. Written locally instead of
#using lavaan::vech.reverse() -- lavaan is a large SEM package pulled in
#only for this one utility; this is a ~10-line replacement.
vechReverse <- function(v) {
  n <- (sqrt(1 + 8 * length(v)) - 1) / 2
  m <- matrix(0, n, n)
  m[lower.tri(m, diag = TRUE)] <- v
  m[upper.tri(m)] <- t(m)[upper.tri(m)]
  m
}

#Formula-string validator. Two layers:
#
#1. Length cap (200 chars) -- R's recursive-descent parser can hit
#   "C stack usage too close to limit" on deeply nested parens; every
#   character in the allowed charset below (digits, letters, parens) is
#   available to such an attack, so the charset check alone doesn't stop
#   it. A short length cap bounds nesting depth as a side effect.
#2. Anchored charset allowlist, letters restricted to exactly {b, l, o,
#   g} -- enough to write "b1", "b12", "log(...)" and nothing else. This
#   is not just "looks like an allowlist": no other base-R function name
#   is spellable using only the letters b/l/o/g (system, eval, get,
#   unlink, environment, etc. all need letters outside this set), so
#   restricting to this charset is a structural guarantee against
#   calling anything but log(), not just a heuristic. The check is
#   `grepl("^(...)$", trimws(x))` against the ENTIRE trimmed string --
#   never an unanchored search-style match, which is the classic way an
#   allowlist like this gets bypassed (a valid prefix riding along with
#   a disallowed suffix).
validateFormula <- function(formula_str, n_coef) {
  trimmed <- trimws(formula_str)

  if (nchar(trimmed) == 0 || nchar(trimmed) > 200) {
    return("Formula must be between 1 and 200 characters.")
  }

  if (!grepl("^[-blog0-9.+*/^() ]+$", trimmed)) {
    return("Formula may only contain b1, b2, ... coefficient names, numbers, + - * / ^ ( ), and log().")
  }

  expr <- tryCatch(parse(text = trimmed)[[1]], error = function(e) NULL)
  if (is.null(expr)) {
    return("Formula isn't valid R syntax -- check parentheses and operators.")
  }

  vars <- all.vars(expr)
  bad_vars <- vars[!grepl("^b[0-9]+$", vars) | as.integer(sub("^b", "", vars)) > n_coef | as.integer(sub("^b", "", vars)) < 1]
  if (length(bad_vars) > 0) {
    return(sprintf("Formula references %s, but only b1..b%d are available for the %d coefficient(s) entered.",
                    paste(bad_vars, collapse = ", "), n_coef, n_coef))
  }

  list(expr = expr, vars = vars)
}



#A call to shiny-server to take all of the following into account (The sever logic).
shinyServer(function(input, output, session) {

  #Parses mu into a named numeric vector (b1, b2, ...).
  parseMu <- reactive({
    m <- suppressWarnings(as.numeric(strsplit(input$mu, ",")[[1]]))
    validate(need(length(m) > 0 && !anyNA(m),
                  "Coefficient Estimates: enter comma-separated numbers, e.g. 1,0.7,0.6,0.45"))
    setNames(m, paste0("b", seq_along(m)))
  })

  #Parses Sigma (lower-triangle input) and validates its length against
  #mu's implied dimension -- the same check the original app's ci()
  #performed (RMediation 1.1.3 ci.R): length(Sigma) must equal
  #n(n+1)/2 for n = length(mu).
  parseSigma <- reactive({
    M <- parseMu()
    s <- suppressWarnings(as.numeric(strsplit(input$Sigma, ",")[[1]]))
    validate(need(length(s) > 0 && !anyNA(s),
                  "Variance-Covariance Matrix: enter comma-separated numbers."))
    n <- length(M)
    expected_len <- n * (n + 1) / 2
    validate(need(length(s) == expected_len,
                   sprintf("Variance-Covariance Matrix: %d coefficient(s) need %d lower-triangle values, but %d were entered.",
                           n, expected_len, length(s))))
    Sigma <- vechReverse(s)
    dimnames(Sigma) <- list(names(M), names(M))
    Sigma
  })

  #Submitted-values sanity table (footer strip, collapsed by default).
  output$invals <- renderTable({
    data.frame(Coefficient = names(parseMu()), Estimate = as.numeric(parseMu()))
  }, digits = 4, rownames = FALSE)

  #Only the lower triangle + diagonal are ever entered by the user
  #(vechReverse() mirrors them into the upper triangle purely so the matrix
  #is usable in mvrnorm()/matrix algebra downstream) -- showing the mirrored
  #upper-triangle values back to the user is redundant and reads as
  #"extra zeros" they never typed. Blank them in the display copy only;
  #parseSigma()'s return value (used for the actual computation) is
  #untouched.
  #
  #Genuine zero covariances (a real value the user typed, not a blanked
  #cell) are shown as a bare "0" instead of "0.0000" -- cuts visual noise
  #from the common all-zero off-diagonal case without making a real zero
  #indistinguishable from the blanked (never-entered) upper-triangle
  #cells, which stay "" via na = "".
  output$covmat <- renderTable({
    Sigma <- parseSigma()
    display <- as.data.frame(Sigma)
    display[upper.tri(Sigma)] <- NA
    fmt <- as.data.frame(lapply(display, function(col) {
      ifelse(is.na(col), NA_character_,
             ifelse(col == 0, "0", formatC(col, digits = 4, format = "f")))
    }))
    rownames(fmt) <- rownames(display)
    fmt
  }, rownames = TRUE, na = "")

  #Live PSD check for the matrix sanity-check swatch below -- additive only,
  #does not touch parseSigma()'s own validate() calls or rawResults()'s
  #downstream error text. Tolerance is scaled to the matrix's own magnitude
  #(not a bare absolute cutoff) since Sigma's entries are user-typed and
  #unbounded -- an absolute tolerance would be wrong at both extremes (false
  #negatives on large-magnitude near-singular matrices, false positives from
  #float noise on tiny entries).
  covmatPSD <- reactive({
    Sigma <- parseSigma()
    ev <- eigen(Sigma, symmetric = TRUE, only.values = TRUE)$values
    tol <- 1e-8 * max(abs(ev))
    min(ev) > -tol
  })

  #Live matrix sanity-check swatch, next to the Sigma input in Zone 1 (not
  #the footer). A CSS grid via renderUI(), not an image()-based renderPlot()
  #-- this output is deliberately NOT debounced (recomputes on every
  #keystroke, same as parseSigma()/output$covmat above), and a renderPlot()
  #graphics-device round trip on every keystroke would be a real lag/flicker
  #risk on Connect Cloud's shared compute (see the n.mc comment above for the
  #same constraint). Built only on parseSigma() -- never on rawResults() or
  #the debounced results() -- so this can't reintroduce the class of bug
  #documented in medci's drawPlot() comment (a plot reading input$... AND a
  #debounced reactive at once).
  #
  #Color-only (no numeric overlay): the numbers are already in the adjacent
  #table at digits=4 precision -- text at swatch-cell size would be
  #illegible. Capped at n<=6 coefficients; beyond that a 49+-cell grid
  #wouldn't stay legible next to the table, so it falls back to a note.
  output$covmatSwatch <- renderUI({
    #Opt-in (checkbox default off) -- the color grid duplicates information
    #already in the numeric table above and wasn't worth showing by default;
    #still available for anyone who does want the visual scan.
    req(input$showSwatch)

    Sigma <- parseSigma()
    n <- nrow(Sigma)

    if (n > 6) {
      return(helpText("Matrix too large to show as a color grid (more than 6 coefficients) -- see the table."))
    }

    psd_ok <- covmatPSD()
    maxAbs <- max(abs(Sigma))
    pos_ramp <- grDevices::colorRamp(c("#ffffff", "#2e6f63"))
    neg_ramp <- grDevices::colorRamp(c("#ffffff", "#f6efe1"))

    rows <- lapply(seq_len(n), function(i) {
      cells <- lapply(seq_len(n), function(j) {
        v <- Sigma[i, j]
        intensity <- if (maxAbs > 0) abs(v) / maxAbs else 0
        ramp <- if (v >= 0) pos_ramp else neg_ramp
        bg <- grDevices::rgb(ramp(intensity), maxColorValue = 255)
        tags$div(
          title = round(v, 4),
          style = sprintf(
            "width: 26px; height: 26px; background-color: %s; border: 1px solid #e1d9c8;",
            bg
          )
        )
      })
      tags$div(style = "display: flex;", cells)
    })

    tagList(
      div(
        class = if (psd_ok) "mc-swatch-grid" else "mc-swatch-grid mc-swatch-invalid",
        rows
      ),
      if (!psd_ok) {
        div(class = "mc-swatch-warning", icon("triangle-exclamation"), " Not positive-semi-definite")
      }
    )
  })

  #Core computation: Monte Carlo + Asymptotic-Delta CIs for the user's
  #formula. validate()/need() throughout render Shiny's standard
  #inline-error style instead of a crash.
  rawResults <- reactive({
    M <- parseMu()
    Sigma <- parseSigma()
    n <- length(M)

    #alpha comes from a selectizeInput (presets + free typing), so it
    #arrives as character -- parse before use. Bounds are the open
    #interval (0, 1) exclusive, matching what the presets themselves span.
    alpha_val <- suppressWarnings(as.numeric(input$alpha))
    validate(need(!is.na(alpha_val) && alpha_val > 0 && alpha_val < 1,
                  "Significance Level must be a number between 0 and 1 (exclusive)."))

    parsed <- validateFormula(input$quant, n)
    validate(need(is.list(parsed), if (is.list(parsed)) "" else parsed))
    expr <- parsed$expr
    bnames <- names(M)

    #--- Monte Carlo method ---
    #n.mc = 1e5, not the original's default of 1e6 -- a deliberate
    #performance tradeoff for Connect Cloud's shared compute; the
    #accuracy difference (MC Error = SE/sqrt(n)) is negligible at
    #3-significant-digit display. See SPEC "Monte Carlo CI".
    draws <- tryCatch(
      MASS::mvrnorm(n = 1e5, mu = M, Sigma = Sigma),
      error = function(e) NULL
    )
    validate(need(!is.null(draws),
                  "The covariance matrix you entered isn't valid -- check the diagonal (variance) values are large enough relative to the off-diagonal covariances."))
    colnames(draws) <- bnames
    #eval() on user input: safe here specifically because `expr` came
    #from validateFormula() above, which structurally guarantees (not
    #just filters) the parsed expression can only reference b1..bn,
    #numeric literals, +-*/^(), and log() -- see validateFormula()'s
    #comment for why no other base-R function name is spellable in that
    #charset. Do not call eval() on any other user-derived string in
    #this file without the same guarantee.
    values <- eval(expr, envir = as.data.frame(draws))

    #A formula smooth almost everywhere (e.g. 1/log(b1)) can still blow
    #up at particular draws (log(1)=0). Drop non-finite draws rather
    #than letting NA/Inf propagate into SE/CI.
    values <- values[is.finite(values)]
    validate(need(length(values) > 0,
                  "This formula is undefined for the values you entered (e.g. log of a non-positive number) -- try different coefficient estimates."))

    point_est_mc <- mean(values)
    se_mc <- sd(values)
    ci_mc <- stats::quantile(values, c(alpha_val / 2, 1 - alpha_val / 2))

    #--- Asymptotic-Delta method ---
    #Symbolic differentiation via stats::deriv() -- not numeric
    #differentiation -- matching the original exactly (RMediation
    #1.1.3 confintAsymp.R used base deriv() too), and exact rather than
    #approximate since the allowed grammar (+ - * / ^ log()) is
    #precisely what deriv() supports natively.
    quant_formula <- stats::as.formula(paste0("~", input$quant))
    fx <- tryCatch(
      stats::deriv(quant_formula, bnames, function.arg = TRUE),
      error = function(e) NULL
    )
    validate(need(!is.null(fx),
                  "The asymptotic-delta method needs a differentiable formula -- check the formula uses only + - * / ^ and log()."))
    grad_result <- do.call(fx, as.list(M))
    grad <- as.vector(attr(grad_result, "gradient"))

    se_delta <- as.numeric(sqrt(t(grad) %*% Sigma %*% grad))
    validate(need(is.finite(se_delta) && se_delta > 0,
                  "The asymptotic-delta method isn't well-defined at these values -- try different coefficient estimates."))

    point_est_delta <- eval(expr, envir = as.list(M))
    q <- stats::qnorm(1 - alpha_val / 2)
    ci_delta <- point_est_delta + c(-1, 1) * q * se_delta

    #alpha_val is carried in the return list (not read from input$alpha
    #again downstream) for the same reason expr_text is: output$interval
    #depends on results() (debounced) -- if it also read input$alpha
    #directly it would pick up a second, undebounced dependency and
    #reintroduce the class of bug documented in medci's drawPlot() history
    #(PR #27) and noted in the Part 1 swatch comments above.
    list(
      expr_text = input$quant,
      alpha = alpha_val,
      mc = list(estimate = point_est_mc, se = se_mc, ci = ci_mc, draws = values),
      delta = list(estimate = point_est_delta, se = se_delta, ci = ci_delta)
    )
  })

  #Debounced (500ms), matching medci's PR #27 fix for the same class of
  #bug -- live reactivity with no submit button re-triggers on every
  #keystroke, and here that means recomputing 1e5 MC draws + a symbolic
  #gradient on every partial/invalid intermediate formula state while
  #typing. Debounce waits until input pauses instead.
  results <- debounce(rawResults, 500)

  output$interval <- renderText({
    r <- results()
    paste0(
      "For ", r$expr_text, ", the point estimate and ", round((1 - r$alpha) * 100, digits = 3),
      "% Monte Carlo CI are ", round(r$mc$estimate, digits = 3), " (SE = ", round(r$mc$se, digits = 3),
      ") and [", round(r$mc$ci[[1]], digits = 3), ", ", round(r$mc$ci[[2]], digits = 3), "], respectively. ",
      "The point estimate and ", round((1 - r$alpha) * 100, digits = 3), "% Asymptotic-Delta CI are ",
      round(r$delta$estimate, digits = 3), " (SE = ", round(r$delta$se, digits = 3), ") and [",
      round(r$delta$ci[[1]], digits = 3), ", ", round(r$delta$ci[[2]], digits = 3), "], respectively."
    )
  })

  #Shared plot-drawing function -- density of the MC draws with both
  #methods' CIs marked, used by both the on-screen renderPlot() and the
  #PNG downloadHandler so they can't drift apart (same pattern as
  #medci's drawPlot()).
  drawPlot <- function() {
    r <- results()
    d <- density(r$mc$draws)

    plot(d, main = "", xlab = r$expr_text, ylab = "Density", lwd = 2, col = "#2e6f63")

    #Overlay the asymptotic-normal density for comparison.
    curve(stats::dnorm(x, r$delta$estimate, r$delta$se), add = TRUE, col = "blue", lty = 2, lwd = 2)

    #Density curve, CI bar, and point all teal (the app's accent color,
    #matching the Result card's #2e6f63) so the "Monte Carlo" legend
    #entry matches what's actually drawn -- previously the curve stayed
    #black while only the CI bar changed color, so the legend swatch
    #didn't match the curve it was labeling. Blue/dashed for
    #Asymptotic-Delta stays as the second, visually distinct series.
    usr <- par("usr")
    yci_mc <- usr[3] + 0.05 * diff(usr[3:4])
    yci_delta <- usr[3] + 0.10 * diff(usr[3:4])
    arrows(r$mc$ci[[1]], yci_mc, r$mc$ci[[2]], yci_mc, length = 0, angle = 90, code = 3, lwd = 3, col = "#2e6f63")
    points(r$mc$estimate, yci_mc, pch = 19, cex = 1.4, col = "#2e6f63")
    arrows(r$delta$ci[[1]], yci_delta, r$delta$ci[[2]], yci_delta, length = 0, angle = 90, code = 3, lwd = 3, col = "blue", lty = 2)
    points(r$delta$estimate, yci_delta, pch = 19, cex = 1.4, col = "blue")

    legend("topright", c("Monte Carlo", "Asymptotic-Delta"), col = c("#2e6f63", "blue"), lty = c(1, 2), lwd = 3, bty = "n", cex = 0.8)
  }

  output$plot <- renderPlot({
    drawPlot()
  })

  output$downloadPlot <- downloadHandler(
    filename = function() {
      sprintf("medmc-plot-%s.png", format(Sys.time(), "%Y%m%d-%H%M%S"))
    },
    content = function(file) {
      png(file, width = 600, height = 425)
      drawPlot()
      dev.off()
    }
  )

  #Jump from the inline "click here" link (Results tab) to the Monte
  #Carlo Examples tab -- bslib-native (updateTabsetPanel), replacing the
  #original's raw jQuery .nav-tabs/.tab-pane manipulation, which doesn't
  #work under bslib's tab markup.
  observeEvent(input$linkToMCEX, {
    updateTabsetPanel(session, "mainTabs", selected = "Monte Carlo Examples")
  })

})
