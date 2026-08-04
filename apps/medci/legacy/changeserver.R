
#Shiny Application for RMediation package using the medci function
#server script file
#9/24/2013



library(shiny)
library(RMediation)



#A call to shiny-server to take all of the following into account (The sever logic).
shinyServer(function(input, output) {
  
  
  #Create a reactive expression. This will be called everytime the users uses the submitButton to    submit new input information. This expression will regenerate all of the arguments within it. This expression will be used to bring in the values submitted by the user to output them into a table.
  inputValues <- reactive({
    
    #A variable to represent the vector of inputted/submitted values
    vals <- c(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho, input$alpha)
 
    #Create a data frame to represent the submitted values in a table
     data.frame(
      "Estimate of a"      = input$mu.x,
      "Estimate of b"      = input$mu.y,
      "SE of a"            = input$se.x,
      "SE of b"            = input$se.y,
      "Significance Level" = input$alpha,
      "Correlation"        = input$rho,
      stringsAsFactors=FALSE, check.names=FALSE) 
    
     })
    
  
  #Specify that we want the data frame to be shown in the user interface, and that we want it to be rendered with every new submission. The digits option allows to specify the number of digits shown after the decimal.
  output$invals <- renderTable({
    head(inputValues())
  },digits=4, include.rownames=FALSE)
  
  
  #Create alpha entry error messages.
  output$alphaMessages <- renderText({
    
    if(input$alpha <.0001){
      print("Error: Alpha must be between .0001 and .9999")
    }
    else if(input$alpha >.9999){
      print("Error: Alpha must be between .0001 and .9999")
    }
    
  })
  
  #Create rho entry error messages.
  output$rhoMessages <- renderText({
    
    if(input$rho < -0.999){
      print("Error: Correlation must be between -.999 and .999")
    }
    else if(input$rho > .999){ 
      print("Error: Correlation must be between -.999 and .999")
    }
    
  })
  
  #Create standard error a (se.x) entry error message.
  output$SEaMessages <- renderText({
    
    if(input$se.x < 0){
      print("Error: Standard Error must be a positive value")
    }
    
  })
  
  #Create standard error b (se.y) entry error message.
  output$SEbMessages <- renderText({
    
    if(input$se.y < 0){
      print("Error: Standard Error must  be a positive value")
    }
    
  })

  
  #Create a reactive expression. This will be called everytime the users uses the submitButton to submit new input information. This expression will regenerate all of the arguments within it. This reactive expression will be used to take in the submitted values from the user and call them into the medci funtion to then send the output through a table for veiwing the confidence intervals.
  medciValues <- reactive({
    
    #Create a variable to represent the medci function output from the user's input values.
    medValues <- medci(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho, input$alpha)
    
  
  
  #Compse a data frame to organize the output values from medci. For example, "Interval" will be the column header of the table for the values/strings that you choose to put in the column below it using c() to create a vector of the information. 
  data.frame(
    Interval = c("Lower Limit",
             "Upper Limit"),
    Value    = c(medValues[[1]],
              medValues[[2]]),
    Percent  = c(names(medValues[1]),
                 names(medValues[2]))
  
    )

  })
  
  #Specify that we want the data frame to be shown in the user interface, and that we want it to be rendered with every new submission.The digits option allows to specify the number of digits shown after the decimal.
  #The if statements supress the CI table output when a negative value is entered for Standard Error.
  output$view <- renderTable({
    
    if(input$se.x < 0){
      return(NULL)
    }
    
    if(input$se.y < 0){
      return(NULL)
    }
    else{
    head(medciValues())
    }
  },digits=3,include.rownames=FALSE)
  
  
  #Specify that we want the plot produced by medci to be shown in the user interface, and that we want it to be rendered for every new submission. We have to call the medci function agian in order to get this plot.
  #The if statements supress the plot output when a negative value is entered for Standard Error.
  output$plot <- renderPlot({
   
    if(input$se.x < 0){
      return(NULL)
    }
    
    if(input$se.y < 0){
      return(NULL)
    }
    else{
  medplot <- medci(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho, input$alpha, plot=TRUE, plotCI=TRUE)
  
    }
    
  })
  
})