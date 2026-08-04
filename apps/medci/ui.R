
#Shiny Application for RMediation package using the medci function
#ui script file
#9/24/2013



library(shiny)



#Defining the user interface:
shinyUI(pageWithSidebar(

  
  #Title that is shown in the header of the application:
  headerPanel("RMediation"),
  
  #Create the sidebar for medci inputs
  sidebarPanel(
    
    #Set the maximum width for the sidebarPanel and the mainPanel. span4 is the sidebar, and span8 is the mainpanel. 
    tags$head(
      tags$style(type="text/css", "label.radio { display: inline-block; }", ".radio input[type=\"radio\"] { float: none; }"),
      tags$style(type='text/css', ".span4 { max-width: 270px; }"),
      tags$style(type='text/css', ".span8 { max-width: 800px; }")
    ),
    
    
    #Suppress error messages from R processes. (So that we can create our own popup errors)
    tags$style(type="text/css",
               ".shiny-output-error { visibility: hidden; }",
               ".shiny-output-error:before { visibility: hidden; }"
    ),
    
    #Get rid of arrows on the side of input boxes.
    tags$style(type="text/css",
      "input[type=number]::-webkit-inner-spin-button, 
       input[type=number]::-webkit-outer-spin-button { 
      -webkit-appearance: none; 
      margin: 0; }" 
    ),
    
    #Change the color of the entry error text.
    tags$style(type='text/css', '#SEaMessages {color: red;}'),
    tags$style(type='text/css', '#SEbMessages {color: red;}'), 
    tags$style(type='text/css', '#alphaMessages {color: red;}'), 
    tags$style(type='text/css', '#rhoMessages {color: red;}'), 

    #Create the box for the example equation in the helpText.
    tags$style(type='text/css', ".boxed {border: 1.5px solid black;}"),
    
    #Allow the use of MathJax within the ui.R file
    tags$head( tags$script(src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML-full", type = 'text/javascript'),
               tags$script( "MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});", type='text/x-mathjax-config')
    ),
    
    
    #Below used to allow MAthJax, then it suddenly stopped working. The above statement was then substituted.
#     tags$head(
#             
#       tags$script(src = 'https://c328740.ssl.cf1.rackcdn.com/mathjax/2.0-latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML', type = 'text/javascript')
#             
#     ),
    
    
    #numericInput allows the user to enter a value. An error occurs when an intial value is not specified...For the mathematical notation, HTML was used. textOutput displays the entry error messages when nessecary.
    numericInput("mu.x",HTML("<i>a&#x0302</i>:"),0),
    
    numericInput("mu.y",HTML("<i>b&#x0302</i>:"),0),
    
    numericInput("se.x",HTML("<i>SE<sub>a&#x0302</sub></i>:"),1),

    textOutput("SEaMessages"),
    
    numericInput("se.y",HTML("<i>SE<sub>b&#x0302</sub></i>:"),1),
    
    textOutput("SEbMessages"),
    
    numericInput("alpha",HTML("<i>&alpha;</i>:"),0.05),
       
    textOutput("alphaMessages"),
  
    numericInput("rho",HTML("<i>&rho;</i>:"),0),
    
    textOutput("rhoMessages"),
    
    
    #The button to submit new input values and render all output.
    submitButton("Submit"),
    
    HTML("<br>"),
    
    helpText(HTML("<p><b>Information:</b> This web application computes a confidence interval (CI) for the mediated effect and the product of two normal random variables.</p>

<p>To compute the confidence interval for the mediated effect, <i>a &middot; b</i>, using the distribution of the product of the coefficients method, input the following values into the boxes 
                  above: the coefficient estimate (<i>a&#x0302</i>), the coefficient estimate (<i>b&#x0302</i>), the standard error of <i>a&#x0302 (SE<sub>a&#x0302</sub>)</i>, the standard error of <i>b&#x0302 (SE<sub>b&#x0302</sub>)</i>, the significance level for 
                  the confidence interval (<i>&alpha;</i>), and the correlation between <i>a&#x0302</i> and <i>b&#x0302</i> (<i>&rho;</i>).</p>")),


# tags$div(class = "boxed", HTML("<b>Example:</b> $$\\frac{\\hat{a}}{3}$$")),
helpText(HTML("<p>If you have any questions/concerns regarding the RMediation package, please email me at <a href='mailto:dtofighi@psych.gatech.edu'>dtofighi@psych.gatech.edu</a>.</p>")
)),
    
#   ),
   
  
  #Setup the main (middle) space on the webpage for viewing the output.
  mainPanel(
    
    
    HTML("<b>Citation</b>"),
    HTML("<p>Tofighi, D. & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals.<a href=http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3233842/pdf/nihms325903.pdf>[PDF]</a> <i>Behavior Research Methods, 43,</i> 692-700.<p>"),

 
    #Add space between the information and output.
    HTML("<br>"),
   
    
    #h4 creates the heading with a specific size (h4), and tableOutput outputs the table specified in the server.R file (output$view) containing the confidence interval.
    h5("Results"),
    htmlOutput("interval"),
#     htmlOutput("equation"),
# 
#     
    #h4 creates the heading with a specific size (h4), and plotOutput outputs the plot specified in the sever.R file (output$plot). The plot comes from the medci function in used in server.R.
    h5("Density Plot and Confidence Interval"),
    plotOutput("plot", width = "600px", height = "425px"),
    
    HTML("<br>"),
    HTML("<b>NOTE:</b> When <i>&rho;=0</i> the standard error for the indirect effect is calculated using"), 
#          <it>SE<sub>(a&#x0302 b&#x0302)</sub>=
#          $SE_{(\\hat{a}\\hat{b})}=\\sqrt{(a\\,SE(\\hat{b}))^2+(b\\,SE(\\hat{a}))^2+SE(\\hat{a})^2\\,SE(\\hat{b})^2}$."),
img(src='SE.png', align = "left")
             


  ))    
)