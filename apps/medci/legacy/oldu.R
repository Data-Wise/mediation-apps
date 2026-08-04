#Shiny Application for RMediation package using the ci function
#ui script file
#2/10/2014



library(shiny)

#Defining the user interface:
shinyUI(pageWithSidebar(
  
  #Title for the application:
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
               
    
    textInput("mu","Coefficient Estimates:","1,0.7,0.6,0.45"),
    
    textInput("Sigma","Variance-Covariance Matrix:","0.05,0,0,0,0.05,0,0,0.03,0,0.03"),
    
    textInput("quant","Formula for Indirect Effect:","b1*b2*b3*b4"),
    
    numericInput("alpha","Significance Level:",0.05),
    
    #The button to submit new input values and render all output.
    submitButton("Submit")
    
  ),
  
  #Setup the main (middle) space on the webpage for viewing the output.
  mainPanel(
    
    h4("Information"),  
    HTML("<p>This web application computes a confidence interval for a nonlinear function of coefficient estimates with an asymptotic multivariate normal distribution using the Monte Carlo method and the asymptotic normal theory method with multivariate delta standard errors (Sobel, 1982). A confidence interval for each method is calculated, and a density plot is produced which includes the sampling distribution and confidence interval with error bars for both methods. </p> 

<p>To compute the confidence interval, use the boxes to the left to submit the following values: </p>
<p><b>Coefficient Estimates</b> - Input the coefficient estimates seperated by commas. Be sure to enter these estimates in the order they appear in the formula; they will automatically be assigned the names <i>b1, b2,..., bn</i>.</p> 

<p><b>Variance-Covariance Matrix</b> - Input the values of the lower trainge cariance-covariance matrix seperated by commas. Start with the top of the left column continuing downward followed by each column thereafter in the same fashion.</p> 

<p><b>Formula for Indirect Effect</b> - Input the formula in relation to the coefficient estimates entered (e.g. <i>b1*b2*b3</i>). The formula can include *, /, ^, and log.</p> 

<p><b>Significance Level</b> - Enter the significancce level for the confidence interval.</p>

<p>Tofighi, D. & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals.<a href=http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3233842/pdf/nihms325903.pdf>[PDF]</a> <i>Behavior Research Methods, 43,</i> 692-700.</p>

<p>If you have any questions/concerns regarding the RMediation package, please email me at <a href='mailto:dtofighi@psych.gatech.edu'>dtofighi@psych.gatech.edu</a></p>"),
    
    
    #Add space between the information and output.
    HTML("<br><br>"),
    #h4 creates the heading with a specific size (h4), and tableOutput outputs the table specified in the server.R file containing the confidence interval.
    h4("Submitted Values"),
    tableOutput("invals"),
    
    h4("Monte Carlo Confidence Interval"),
    tableOutput("interval"),
    
    h4("Asymptotic Normal Confidence Interval"),
    tableOutput("interval2"),
    
    #h4 creates the heading with a specific size (h4), and plotOutput outputs the plot specified in the sever.R file. The plot comes from the medci function in used in server.R.
    h4("Density Plot and Confidence Interval"),
#    plotOutput("plot", width = "600px", height = "425px"),
    imageOutput("myImage")
#     plotPNG(plot,filename = CIplot(fileext = ".png"), 
#             width = 600, height = 425, res = 72, pointsize = 8)
    
    
  )
  
))