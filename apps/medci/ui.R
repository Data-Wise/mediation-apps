
#Shiny Application for RMediation package using the medci function
#ui script file
#9/24/2013



library(shiny)
library(bslib)



#Defining the user interface:
#
#Layout: a single-column 3-zone stack (inputs -> one dominant result ->
#supporting plot), replacing the earlier sidebarLayout. Rationale (see
#the published layout mockup this implements): a flat sidebar+mainPanel
#split puts inputs, results, plot, and notes all at the same visual
#weight with no anchor for the eye. Chunking into sequential cards with
#exactly one visually "loud" element (the result) reduces how many
#things compete for attention at once.
fluidPage(

  theme = bs_theme(version = 5, bootswatch = "flatly"),

  withMathJax(),

  tags$style(type = "text/css", HTML("
    /* Get rid of arrows on the side of input boxes. */
    input[type=number]::-webkit-inner-spin-button,
    input[type=number]::-webkit-outer-spin-button {
      -webkit-appearance: none;
      margin: 0;
    }

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

    /* Coefficient a/b get distinct tints -- the pairing (a-hat with its
       SE, b-hat with its SE) reads instantly by color, not just by
       reading each label. */
    .mc-coef { border-radius: 8px; padding: 10px 12px 4px; }
    .mc-coef-a { background: #eaf3f1; }
    .mc-coef-b { background: #f6efe1; }
    .mc-coef-label {
      font-size: 0.72rem; font-weight: 700; color: #616e69; margin-bottom: 4px;
    }

    /* The Result card is the one visually loud element on the page --
       colored left rail + shadow, everything else stays quiet. */
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

    /* Fenced/monospace/copyable result text -- a plain div, not
       tags$pre. <pre> preserves whitespace literally, and Shiny's HTML
       generator inserts leading indentation/newlines around nested
       tags, which showed up as a visible indent under pre-wrap. */
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
  ")),

  div(
    class = "mc-page",

    titlePanel("RMediation"),

    #Zone 1: inputs, grouped into tinted a/b columns.
    div(
      class = "mc-card",
      div(class = "mc-card-head", "1 · Inputs"),
      fluidRow(
        column(6,
          div(
            class = "mc-coef mc-coef-a",
            div(class = "mc-coef-label", "Coefficient a"),
            numericInput("mu.x", "\\(\\hat{a}\\):", 0),
            numericInput("se.x", "\\(SE_{\\hat{a}}\\):", 1)
          )
        ),
        column(6,
          div(
            class = "mc-coef mc-coef-b",
            div(class = "mc-coef-label", "Coefficient b"),
            numericInput("mu.y", "\\(\\hat{b}\\):", 0),
            numericInput("se.y", "\\(SE_{\\hat{b}}\\):", 1)
          )
        )
      ),
      #validate()/need() in server.R renders input errors as Shiny's
      #standard inline error style instead of custom red text.
      fluidRow(
        column(6, numericInput("alpha", "\\(\\alpha\\):", 0.05)),
        column(6, numericInput("rho", "\\(\\rho\\):", 0))
      )
    ),

    #Zone 2: Result -- the one dominant element on the page.
    div(
      class = "mc-result",
      actionButton("copyResults", "Copy", icon = icon("copy"),
                   class = "btn-sm btn-outline-secondary",
                   onclick = "navigator.clipboard.writeText(document.getElementById('interval').innerText); var b = document.getElementById('copyResults'); var t = b.innerHTML; b.innerHTML = 'Copied!'; setTimeout(function(){ b.innerHTML = t; }, 1200);"),
      div(class = "mc-result-head", "2 · Result"),
      div(class = "mc-result-text", htmlOutput("interval", inline = TRUE))
    ),

    #Zone 3: plot -- supporting evidence, visually quieter than the result.
    div(
      class = "mc-card",
      div(class = "mc-card-head", "3 · Density plot"),
      #Percentage width instead of a fixed 600px so the plot doesn't
      #overflow on narrow/mobile viewports; height stays fixed since
      #plotOutput needs an absolute height.
      plotOutput("plot", width = "100%", height = "425px"),
      div(
        style = "margin-top: 6px;",
        downloadButton("downloadPlot", "Download plot", class = "btn-sm btn-outline-secondary"),
        helpText("Tip: right-click the plot above to copy it directly to your clipboard.")
      )
    ),

    #Everything non-essential (about text, the ratio=0 SE formula note,
    #citation) collapses into one quiet strip at the bottom, off the
    #primary input -> result -> plot path.
    div(
      class = "mc-footer-strip",
      bslib::accordion(
        open = FALSE,
        bslib::accordion_panel(
          "About this calculator",
          helpText(HTML("<p>This web application computes a confidence interval (CI) for the mediated effect and the product of two normal random variables.</p>

<p>To compute the confidence interval for the mediated effect, \\(\\hat{a} \\cdot \\hat{b}\\), using the distribution of the product of the coefficients method, input the following values into the boxes
                    above: the coefficient estimate (\\(\\hat{a}\\)), the coefficient estimate (\\(\\hat{b}\\)), the standard error of \\(\\hat{a}\\) (\\(SE_{\\hat{a}}\\)), the standard error of \\(\\hat{b}\\) (\\(SE_{\\hat{b}}\\)), the significance level for
                    the confidence interval (\\(\\alpha\\)), and the correlation between \\(\\hat{a}\\) and \\(\\hat{b}\\) (\\(\\rho\\)).</p>")),
          helpText(HTML("<p>If you have any questions/concerns regarding the RMediation package, please email me at <a href='mailto:dtofighi@gmail.com'>dtofighi@gmail.com</a>.</p>"))
        ),
        bslib::accordion_panel(
          "SE formula (\\(\\rho = 0\\))",
          HTML("<p>When \\(\\rho=0\\) the standard error for the indirect effect is calculated using</p>"),
          HTML("$$SE_{(\\hat{a}\\hat{b})}=\\sqrt{(a\\,SE(\\hat{b}))^2+(b\\,SE(\\hat{a}))^2+SE(\\hat{a})^2\\,SE(\\hat{b})^2}$$")
        ),
        bslib::accordion_panel(
          "Citation",
          HTML("<p>Tofighi, D. & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals.<a href=http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3233842/pdf/nihms325903.pdf>[PDF]</a> <i>Behavior Research Methods, 43,</i> 692-700.<p>")
        )
      )
    )
  )
)
