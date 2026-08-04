
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

      #numericInput allows the user to enter a value. Inputs recompute the
      #results reactively as they change -- no submit button needed.
      numericInput("mu.x", "\\(\\hat{a}\\):", 0),

      numericInput("mu.y", "\\(\\hat{b}\\):", 0),

      numericInput("se.x", "\\(SE_{\\hat{a}}\\):", 1),

      #validate()/need() in server.R renders these as Shiny's standard
      #inline error style instead of custom red text.

      numericInput("se.y", "\\(SE_{\\hat{b}}\\):", 1),

      numericInput("alpha", "\\(\\alpha\\):", 0.05),

      numericInput("rho", "\\(\\rho\\):", 0),

      HTML("<br>"),

      helpText(HTML("<p><b>Information:</b> This web application computes a confidence interval (CI) for the mediated effect and the product of two normal random variables.</p>

<p>To compute the confidence interval for the mediated effect, \\(\\hat{a} \\cdot \\hat{b}\\), using the distribution of the product of the coefficients method, input the following values into the boxes
                  above: the coefficient estimate (\\(\\hat{a}\\)), the coefficient estimate (\\(\\hat{b}\\)), the standard error of \\(\\hat{a}\\) (\\(SE_{\\hat{a}}\\)), the standard error of \\(\\hat{b}\\) (\\(SE_{\\hat{b}}\\)), the significance level for
                  the confidence interval (\\(\\alpha\\)), and the correlation between \\(\\hat{a}\\) and \\(\\hat{b}\\) (\\(\\rho\\)).</p>")),

      helpText(HTML("<p>If you have any questions/concerns regarding the RMediation package, please email me at <a href='mailto:dtofighi@gmail.com'>dtofighi@gmail.com</a>.</p>")
      )
    ),

    #Setup the main (middle) space on the webpage for viewing the output.
    mainPanel(

      HTML("<b>Citation</b>"),
      HTML("<p>Tofighi, D. & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals.<a href=http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3233842/pdf/nihms325903.pdf>[PDF]</a> <i>Behavior Research Methods, 43,</i> 692-700.<p>"),

      HTML("<br>"),

      h5("Results"),
      htmlOutput("interval"),

      h5("Density Plot and Confidence Interval"),
      plotOutput("plot", width = "600px", height = "425px"),

      HTML("<br>"),
      HTML("<b>NOTE:</b> When \\(\\rho=0\\) the standard error for the indirect effect is calculated using"),
      HTML("$$SE_{(\\hat{a}\\hat{b})}=\\sqrt{(a\\,SE(\\hat{b}))^2+(b\\,SE(\\hat{a}))^2+SE(\\hat{a})^2\\,SE(\\hat{b})^2}$$")
    )
  )
)
