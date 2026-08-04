
#Shiny Application for RMediation package using the medci function
#ui script file
#9/24/2013



library(shiny)
library(bslib)



#Defining the user interface:
fluidPage(

  theme = bs_theme(version = 5, bootswatch = "flatly"),

  withMathJax(),

  #Get rid of arrows on the side of input boxes.
  tags$style(type="text/css",
    "input[type=number]::-webkit-inner-spin-button,
     input[type=number]::-webkit-outer-spin-button {
    -webkit-appearance: none;
    margin: 0; }"
  ),

  titlePanel("RMediation"),

  sidebarLayout(

    #Create the sidebar for medci inputs
    sidebarPanel(

      #a and b are a paired coefficient/SE structure -- grouped side by
      #side (a-column, b-column) instead of one flat stack, so the pairing
      #reads visually instead of only through the label text.
      fluidRow(
        column(6,
          numericInput("mu.x", "\\(\\hat{a}\\):", 0),
          numericInput("se.x", "\\(SE_{\\hat{a}}\\):", 1)
        ),
        column(6,
          numericInput("mu.y", "\\(\\hat{b}\\):", 0),
          numericInput("se.y", "\\(SE_{\\hat{b}}\\):", 1)
        )
      ),

      #validate()/need() in server.R renders input errors as Shiny's
      #standard inline error style instead of custom red text.

      numericInput("alpha", "\\(\\alpha\\):", 0.05),

      numericInput("rho", "\\(\\rho\\):", 0),

      HTML("<br>"),

      #Collapsible so the sidebar leads with inputs, not prose -- opt in
      #to the explanation instead of always scrolling past it.
      bslib::accordion(
        open = FALSE,
        bslib::accordion_panel(
          "About this calculator",
          helpText(HTML("<p>This web application computes a confidence interval (CI) for the mediated effect and the product of two normal random variables.</p>

<p>To compute the confidence interval for the mediated effect, \\(\\hat{a} \\cdot \\hat{b}\\), using the distribution of the product of the coefficients method, input the following values into the boxes
                    above: the coefficient estimate (\\(\\hat{a}\\)), the coefficient estimate (\\(\\hat{b}\\)), the standard error of \\(\\hat{a}\\) (\\(SE_{\\hat{a}}\\)), the standard error of \\(\\hat{b}\\) (\\(SE_{\\hat{b}}\\)), the significance level for
                    the confidence interval (\\(\\alpha\\)), and the correlation between \\(\\hat{a}\\) and \\(\\hat{b}\\) (\\(\\rho\\)).</p>")),
          helpText(HTML("<p>If you have any questions/concerns regarding the RMediation package, please email me at <a href='mailto:dtofighi@gmail.com'>dtofighi@gmail.com</a>.</p>"))
        )
      )
    ),

    #Setup the main (middle) space on the webpage for viewing the output.
    mainPanel(

      h5("Results"),
      #Fenced, monospace, copy-to-clipboard block. The copy button reads
      #the rendered element's innerText (not the raw HTML source), so the
      #HTML entities server.R emits (e.g. &#770;) come through as their
      #actual rendered characters, not literal entity text.
      div(
        style = "position: relative;",
        actionButton("copyResults", "Copy", icon = icon("copy"),
                     class = "btn-sm btn-outline-secondary",
                     style = "position: absolute; top: 6px; right: 6px; z-index: 2;",
                     onclick = "navigator.clipboard.writeText(document.getElementById('interval').innerText); var b = document.getElementById('copyResults'); var t = b.innerHTML; b.innerHTML = 'Copied!'; setTimeout(function(){ b.innerHTML = t; }, 1200);"),
        #A plain styled div, not tags$pre -- <pre> preserves whitespace
        #literally, and Shiny's HTML generator inserts leading
        #indentation/newlines around nested tags, which showed up as a
        #visible indent on the first line under pre-wrap. A monospace div
        #keeps the fenced look without whitespace-literal semantics.
        div(
          style = "font-family: monospace; padding: 12px 90px 12px 12px; background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px;",
          htmlOutput("interval", inline = TRUE)
        )
      ),

      h5("Density Plot and Confidence Interval"),
      #Percentage width instead of a fixed 600px so the plot doesn't
      #overflow on narrow/mobile viewports; height stays fixed since
      #plotOutput needs an absolute height.
      plotOutput("plot", width = "100%", height = "425px"),

      div(
        style = "margin-top: 6px;",
        downloadButton("downloadPlot", "Download plot", class = "btn-sm btn-outline-secondary"),
        helpText("Tip: right-click the plot above to copy it directly to your clipboard.")
      ),

      HTML("<br>"),
      HTML("<b>NOTE:</b> When \\(\\rho=0\\) the standard error for the indirect effect is calculated using"),
      HTML("$$SE_{(\\hat{a}\\hat{b})}=\\sqrt{(a\\,SE(\\hat{b}))^2+(b\\,SE(\\hat{a}))^2+SE(\\hat{a})^2\\,SE(\\hat{b})^2}$$"),

      #Citation moved out of the primary input->output flow (was sitting
      #directly above Results) into a collapsible panel of its own.
      bslib::accordion(
        open = FALSE,
        bslib::accordion_panel(
          "Citation",
          HTML("<p>Tofighi, D. & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals.<a href=http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3233842/pdf/nihms325903.pdf>[PDF]</a> <i>Behavior Research Methods, 43,</i> 692-700.<p>")
        )
      )
    )
  )
)
