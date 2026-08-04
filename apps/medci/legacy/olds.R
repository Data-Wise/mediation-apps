#Shiny Application for RMediation package using the ci function
#server script file
#2/10/2014


library(shiny)
library(RMediation)



#A call to shiny-server to take all of the following into account (The sever logic).
shinyServer(function(input, output) {
  
  
  #Create a reactive expression. This will be called everytime the users uses the submitButton to    submit new input information. This expression will regenerate all of the arguments within it. This expression will be used to bring in the values submitted by the user to output them into a table.
  inputValues <- reactive({
    
    #A variable to represent the vector of inputted/submitted values
    CIvals <- c(input$mu,input$Sigma,input$quant,input$alpha)
    
    #Create a data frame to represent the submitted values in a table
    data.frame(
      "Coeffient Estimates"           = input$mu,
      "Variance-Covariance Matrix"    = input$Sigma,
      "Formula"   = input$quant,
      "Significance Level"            = input$alpha,
      stringsAsFactors=TRUE, check.names=FALSE) 
    
  })
  
  
  #Specify that we want the data frame to be shown in the user interface, and that we want it to be rendered with every new submission. The digits option allows to specify the number of digits shown after the decimal.
  output$invals <- renderTable({
    head(inputValues())
  },digits=4, include.rownames=FALSE)
  
 
  #Create a reactive expression. This will be called everytime the users uses the submitButton to submit new input information. This expression will regenerate all of the arguments within it. This reactive expression will be used to take in the submitted values from the user and call them into the medci funtion to then send the output through a table for veiwing the confidence intervals.
  
  #To display the results for the Monte Carlo method.
  CIValues <- reactive({
    
  changevals <- c(input$mu,input$Sigma,input$quant,input$alpha)
  
  #Change the textInput strings to numeric for mu and Sigma, and to change the input quant to a formula.
  numextractall <- function(string){
    unlist(regmatches(string,gregexpr("[[:digit:]]+\\.*[[:digit:]]*",string)), use.names=FALSE)
  } 
  
  M <- as.numeric(numextractall(input$mu))
  S <- as.numeric(numextractall(input$Sigma))
  pqu <- paste("~",input$quant,sep="")
  QU <- as.formula(pqu)
  A <- input$alpha
    
    #Create a variable to represent the ci function output from the user's input values.
    newvals <- ci(M,S,QU,A,type="all")
  
  
    #Compse a data frame to organize the output values from ci. For example, "Interval" will be the column header of the table for the values/strings that you choose to put in the column below it using c() to create a vector of the information. 
  
  #Have to create a data frame of the unlisted output in order to call each piece of output seperately into another data.frame that is shown to users.
  redo <- data.frame(unlist(newvals))

  #This is created to leave some boxes in the data frame blank. The empty string needs to be numeric so the digits=4 option will work on the other values in the column.
  SP <- as.numeric(" ")
  
  data.frame(
    Interval = c("Lower Limit","Upper Limit"),
    Value = c(redo[1,1],redo[2,1]),
    Estimate = c(redo[3,1],SP),
    SE = c(redo[4,1],SP),
    Error = c(redo[5,1],SP)
    
    )
    
  
  })
  
    output$interval <- renderTable({
      head(CIValues())
      },digits=4, include.rownames=FALSE)
  
  #Redo the same process as above for a second table to display the asymptotic results.  
  CIValues2 <- reactive({
    
    changevals2 <- c(input$mu,input$Sigma,input$quant,input$alpha)
    
    #Change the textInput strings to numeric for mu and Sigma, and to change the input quant to a formula.
    numextractall <- function(string){
      unlist(regmatches(string,gregexpr("[[:digit:]]+\\.*[[:digit:]]*",string)), use.names=FALSE)
    } 
    
    M <- as.numeric(numextractall(input$mu))
    S <- as.numeric(numextractall(input$Sigma))
    pqu <- paste("~",input$quant,sep="")
    QU <- as.formula(pqu)
    A <- input$alpha
    
    #Create a variable to represent the ci function output from the user's input values.
    newvals2 <- ci(M,S,QU,A,type="all")
    
    
    #Compse a data frame to organize the output values from ci. For example, "Interval" will be the column header of the table for the values/strings that you choose to put in the column below it using c() to create a vector of the information. 
    
    #Have to create a data frame of the unlisted output in order to call each piece of output seperately into another data.frame that is shown to users.
    redo2 <- data.frame(unlist(newvals2))
    
    #This is created to leave some boxes in the data frame blank. The empty string needs to be numeric so the digits=4 option will work on the other values in the column.
    SP <- as.numeric(" ")
    
    data.frame(
      Interval = c("Lower Limit","Upper Limit"),
      Value = c(redo2[6,1],redo2[7,1]),
      Estimate = c(redo2[8,1],SP),
      SE = c(redo2[9,1],SP) 
    )
  })
  
  output$interval2 <- renderTable({
    head(CIValues2())
    },digits=4, include.rownames=FALSE)
  
  
#   #Specify that we want the plot produced by ci to be shown in the user interface, and that we want it to be rendered for every new submission. We have to call the ci function agian in order to get this plot.
#   output$plot <- renderPlot({
#     
#     
#     #Change the textInput strings to numeric for mu and Sigma, and to change the input quant to a formula.
#     numextractall <- function(string){
#       unlist(regmatches(string,gregexpr("[[:digit:]]+\\.*[[:digit:]]*",string)), use.names=FALSE)
#     } 
#     
#     M <- as.numeric(numextractall(input$mu))
#     S <- as.numeric(numextractall(input$Sigma))
#     pqu <- paste("~",input$quant,sep="")
#     QU <- as.formula(pqu)
#     A <- input$alpha
#  
#     
#      CIplot <- ci(M,S,QU,A,type="all", plot=TRUE, plotCI=TRUE,cex=0.5)
# #     png(filename='MonteCarlo.png',width=600, height=600,units='px',pointsize=8)
# #   mtext("Monte Carlo", line=-2, side=1, adj=0, cex=0.8, col='purple')
# #    
#     plotPNG(func,filename = tempfile(fileext = ".png"), 
#             width = 600, height = 425, res = 72, pointsize = 8)
# func <- ci(M,S,QU,A,type="all", plot=TRUE, plotCI=TRUE)
#  })

output$myImage <- renderImage({
  
  
  numextractall <- function(string){
    unlist(regmatches(string,gregexpr("[[:digit:]]+\\.*[[:digit:]]*",string)), use.names=FALSE)
  } 
  
  M <- as.numeric(numextractall(input$mu))
  S <- as.numeric(numextractall(input$Sigma))
  pqu <- paste("~",input$quant,sep="")
  QU <- as.formula(pqu)
  A <- input$alpha
  # A temp file to save the output.
  # This file will be removed later by renderImage
  outfile <- tempfile(fileext='.png')
  
  # Generate the PNG
  png(outfile, width=600, height=425, pointsize = 10)
  CIplot <- ci(M,S,QU,A,type="all", plot=TRUE, plotCI=TRUE)
  dev.off()
  
  # Return a list containing the filename
  list(src = outfile,
       contentType = 'image/png',
       width = 600,
       height = 425,
       alt = "This is alternate text")
}, deleteFile = TRUE)
  

})