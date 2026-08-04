
#Shiny Application for Monte Carlo / Asymptotic-Delta confidence
#intervals for an arbitrary user-defined formula.
#ui script file
#
#Migrated 2026-08-04 from the legacy amplab.shinyapps.io/MEDMC app
#(ui.R dated 2/10/2014). See server.R and
#SPEC-medmc-migration-2026-08-04.md for the full design record.



library(shiny)
library(bslib)



#Layout follows medci's already-shipped 3-zone stack (Inputs -> Result
#-> Plot, non-essential content in a collapsed footer strip) for visual
#consistency across the mediation-apps ecosystem. See medci/ui.R for the
#rationale comment on why this replaced a flat sidebarLayout.
fluidPage(

  theme = bs_theme(version = 5, bootswatch = "flatly"),

  withMathJax(),

  tags$style(type = "text/css", HTML("
    .mc-page { max-width: 720px; margin: 0 auto; }

    .mc-card {
      background: #ffffff;
      border: 1px solid #e1d9c8;
      border-radius: 12px;
      box-shadow: 0 1px 2px rgba(32,42,39,0.06), 0 6px 20px rgba(32,42,39,0.05);
      padding: 16px 18px;
      margin-bottom: 16px;
    }

    .mc-card-head {
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-weight: 700;
      color: #616e69;
      margin-bottom: 10px;
    }

    .mc-result {
      border-left: 4px solid #2e6f63;
      background: #f0f6f4;
      border-radius: 12px;
      border-top: 1px solid #e1d9c8;
      border-right: 1px solid #e1d9c8;
      border-bottom: 1px solid #e1d9c8;
      box-shadow: 0 1px 2px rgba(32,42,39,0.06), 0 6px 20px rgba(32,42,39,0.05);
      padding: 16px 18px;
      margin-bottom: 16px;
      position: relative;
    }
    .mc-result-head {
      font-size: 0.8rem;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      font-weight: 700;
      color: #2e6f63;
      margin-bottom: 8px;
    }
    .mc-result-text {
      font-family: ui-monospace, 'SF Mono', Menlo, monospace;
      font-size: 0.95rem;
      color: #202a27;
    }
    #copyResults { position: absolute; top: 14px; right: 16px; }

    .mc-footer-strip {
      border: 1px solid #e1d9c8;
      border-radius: 10px;
      background: #ffffff;
      padding: 4px 6px;
    }
    .mc-footer-strip .accordion-button {
      font-size: 0.85rem;
      color: #616e69;
      background: transparent;
      box-shadow: none;
    }

    .mc-swatch-grid {
      display: inline-block;
      border-radius: 6px;
      padding: 2px;
    }
    .mc-swatch-invalid {
      outline: 2px solid #b3261e;
      outline-offset: 2px;
    }
    /* Significance Level is typed directly (e.g. .05, .01) -- the
       increment/decrement spinner arrows invite clicking through tiny
       0.001-ish steps to a specific value, which isn't how this field is
       actually used. Hide them; typing still works normally. */
    #alpha::-webkit-outer-spin-button,
    #alpha::-webkit-inner-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }
    #alpha[type='number'] {
      -moz-appearance: textfield;
    }

    .mc-swatch-warning {
      color: #b3261e;
      font-size: 0.8rem;
      margin-top: 4px;
    }
  ")),

  div(
    class = "mc-page",

    titlePanel("Monte Carlo Confidence Intervals for Indirect Effects"),
    helpText("Computes Monte Carlo and Asymptotic-Delta confidence intervals for an arbitrary nonlinear function of coefficient estimates — e.g. sequential indirect effects or contrasts of indirect effects in mediation models."),

    navset_tab(
      id = "mainTabs",

      nav_panel(
        "Results",

        HTML("<br>"),
        HTML("If you would like to see examples of using the Monte Carlo method, <a id='linkToMCEX' href='#' onclick='Shiny.setInputValue(\"linkToMCEX\", Math.random()); return false;'>click here</a>."),

        #Zone 1: inputs.
        div(
          class = "mc-card",
          div(class = "mc-card-head", "1 · Inputs"),
          textInput("mu", "Coefficient Estimates:", "1,0.7,0.6,0.45"),
          helpText("Comma-separated, in the order they appear in the formula (e.g. b1,b2,b3,...)."),

          textInput("Sigma", "Variance-Covariance Matrix:", "0.05,0,0,0,0.05,0,0,0.03,0,0.03"),
          helpText("Lower-triangle values, comma-separated: top of the left column downward, then each column thereafter."),

          #Live sanity check: numeric table + color swatch grid, both sourced
          #from parseSigma() and updating on every keystroke (not debounced)
          #-- see server.R for why. Visible inline instead of buried in a
          #collapsed footer accordion, so the user can confirm the values
          #landed where intended before running the computation.
          fluidRow(
            column(6, tableOutput("covmat")),
            column(6,
              checkboxInput("showSwatch", "Show color grid", value = FALSE),
              uiOutput("covmatSwatch")
            )
          ),

          textInput("quant", "Formula:", "b1*b2*b3*b4"),
          helpText("References the coefficients as b1, b2, ... Allowed: + - * / ^ ( ) and log()."),

          numericInput("alpha", "Significance Level:", 0.05)
        ),

        #Zone 2: Result.
        div(
          class = "mc-result",
          actionButton("copyResults", "Copy", icon = icon("copy"),
                       class = "btn-sm btn-outline-secondary",
                       onclick = "navigator.clipboard.writeText(document.getElementById('interval').innerText); var b = document.getElementById('copyResults'); var t = b.innerHTML; b.innerHTML = 'Copied!'; setTimeout(function(){ b.innerHTML = t; }, 1200);"),
          div(class = "mc-result-head", "2 · Result"),
          div(class = "mc-result-text", textOutput("interval", inline = TRUE))
        ),

        #Zone 3: plot.
        div(
          class = "mc-card",
          div(class = "mc-card-head", "3 · Density plot"),
          plotOutput("plot", width = "100%", height = "425px"),
          div(
            style = "margin-top: 6px;",
            downloadButton("downloadPlot", "Download plot", class = "btn-sm btn-outline-secondary"),
            helpText("Tip: right-click the plot above to copy it directly to your clipboard.")
          )
        ),

        #Footer: submitted-values sanity tables, collapsed by default.
        div(
          class = "mc-footer-strip",
          bslib::accordion(
            open = FALSE,
            bslib::accordion_panel(
              "Submitted values (sanity check)",
              h6("Coefficient Estimates"),
              tableOutput("invals")
            ),
            bslib::accordion_panel(
              "About this calculator",
              helpText(HTML("<p>This web application computes Monte Carlo and Asymptotic-Delta confidence intervals for a nonlinear function of coefficient estimates and indirect effects.</p>
                    <p><b>Coefficient Estimates</b> — in the order they appear in the formula, separated by commas.</p>
                    <p><b>Variance-Covariance Matrix</b> — the lower triangle, separated by commas: top of the left column downward, then each column thereafter.</p>
                    <p><b>Formula</b> — references the coefficients as b1, b2, ... Allowed: <i>+</i>, <i>-</i>, <i>*</i>, <i>/</i>, <i>^</i>, and <i>log( )</i>.</p>"))
            )
          )
        )
      ),

      nav_panel(
        "Monte Carlo Examples",
        HTML("<br>"),
        HTML("To return to the results, click the Results tab above."),
        #MCexample.html is a complete standalone HTML document (its own
        #<html>/<head>/<body>, self-contained styles + base64 images),
        #not a fragment -- includeHTML() would nest invalid markup.
        #Embed it via iframe instead, served from www/ automatically.
        tags$iframe(src = "MCexample.html", width = "100%", height = "800px",
                    style = "border: 1px solid #e1d9c8; border-radius: 8px;"),
        HTML("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;The figure above shows an example of an SEM with a single micromediational chain. <i>X</i> is the antecedent variable, <i>M<sub>1</sub></i>, <i>M<sub>2</sub></i> and <i>M<sub>3</sub></i> are the
              mediators, <i>Y</i> is an outcome variable. <i>&epsilon;<sub>1</sub> ... &epsilon;<sub>4</sub></i> are residual terms and independent of one another. For this model,
              suppose that we are interested in testing hypotheses about specific and combined indirect effects.<br>"),
        img(src = "MCeqs.png", align = "left"),
        HTML("&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;These hypotheses test complex <i>nonlinear</i> functions of
              indirect and direct effects, so we use the Monte Carlo method to build <i>(1-&alpha;/2)%</i> CIs. Monte Carlo
              CIs are more accurate than Asymptotic-Delta CIs. When the Monte Carlo CI does <i>not</i> include zero, we reject the null hypothesis at the significance level, &alpha;.")
      )
    )
  )
)
