
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
    
    
    #Change the color of the entry error text.
    tags$style(type='text/css', '#SEaMessages {color: red;}'),
    tags$style(type='text/css', '#SEbMessages {color: red;}'), 
    tags$style(type='text/css', '#alphaMessages {color: red;}'), 
    tags$style(type='text/css', '#rhoMessages {color: red;}'), 
    
#     tags$style(type='text/css', '#plot {font-size: 3%}'),
    
  
    #numericInput allows the user to enter a value. An error occurs when an intial value is not specified...For the mathematical notation, HTML was used. textOutput displays the entry error messages when nessecary.
    numericInput("mu.x",HTML("a&#770:"),0),
    
    numericInput("mu.y",HTML("b&#770:"),0),
    
    numericInput("se.x",HTML("SE(a&#770):"),1),
    
    textOutput("SEaMessages"),
    
    numericInput("se.y",HTML("SE(b&#770):"),1),
    
    textOutput("SEbMessages"),
    
    numericInput("alpha",HTML("&#945:"),0.05),
       
    textOutput("alphaMessages"),
  
    numericInput("rho",HTML("&#961:"),0),
    
    textOutput("rhoMessages"),
    
    
    #The button to submit new input values and render all output.
    submitButton("Submit")
    
  ),
   
  
  #Setup the main (middle) space on the webpage for viewing the output.
  mainPanel(
    
    h4("Information"),  
    HTML("<p>This web application computes a confidence interval (CI) for the mediated effect and the product of two normal random variables using the RMediation package. RMediation is an R package that computes CIs for the mediated effect using a variety of methods including the distribution of the product of the coefficients method (PRODCLIN).<p>

  <p>Tofighi, D. & MacKinnon, D. P. (2011). RMediation: An R package for mediation analysis confidence intervals.<a href=http://www.ncbi.nlm.nih.gov/pmc/articles/PMC3233842/pdf/nihms325903.pdf>[PDF]</a> <i>Behavior Research Methods, 43,</i> 692-700.<p>
    
  <p>To compute the confidence interval for the mediated effect, a*b, using the distribution of the product of the coefficients method, input the following values into the boxs on the left: the coefficient estimate (a&#770), the coefficient estimate (b&#770), the standard error of a&#770 (SE(a&#770)), the standard error of b&#770 (SE(b&#770)), the significance level for the confidence interval (&#945), and the correlation between a&#770 and b&#770 (&#961).<p>
         
  <p>If you have any questions/concerns regarding the RMediation package, please email me at <a href='mailto:dtofighi@psych.gatech.edu'>dtofighi@psych.gatech.edu</a></p>"),
    
    
    #Add space between the information and output.
    HTML("<br><br>"),
    
    
    #h4 creates the heading with a specific size (h4), and tableOutput outputs the table specified in the server.R file (output$table) containing the values submitted by the user. 
    h4("Submitted Values"),
    tableOutput("invals"),
   
    
    #h4 creates the heading with a specific size (h4), and tableOutput outputs the table specified in the server.R file (output$view) containing the confidence interval.
    h4("Confidence Interval for the Mediated Effect"),
    tableOutput("view"),
    
    #h4 creates the heading with a specific size (h4), and plotOutput outputs the plot specified in the sever.R file (output$plot). The plot comes from the medci function in used in server.R.
    h4("Density Plot and Confidence Interval"),
    plotOutput("plot", width = "772px", height = "526px")
    
             
  ))    
)