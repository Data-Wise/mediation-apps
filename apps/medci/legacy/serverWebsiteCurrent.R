
#Shiny Application for RMediation package using the medci function
#server script file
#9/24/2013



library(shiny)
library(RMediation)



#A call to shiny-server to take all of the following into account (The sever logic).
shinyServer(function(input, output) {
  
  
  #Create a reactive expression. This will be called everytime the users uses the submitButton to submit new input information. This expression will regenerate all of the arguments within it. This reactive expression will be used to take in the submitted values from the user and call them into the medci funtion to then send the output through a table for veiwing the confidence intervals.
  results <- reactive({
    
    #Create a variable to represent the medci function output from the user's input values.
    medValues <- medci(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho,input$alpha,type="all")
    
    #Create the statements to be combined for the APA sentence format output  
    paste("For a&#770 = ", round(input$mu.x,digits=3), " (SE = ", round(input$se.x,digits=3), ")", " and b&#770 = ", round(input$mu.y,digits=3), " (SE = ", round(input$se.y,digits=3), "),", 
                     " the indirect effect estimate is ", round(medValues[[2]][[2]],digits=3), " (SE = ", round(medValues[[2]][[3]],digits=3), "). The distribution of the product of coefficients method ",
                     round((1-input$alpha)*100,digits=3),"% CI is ", "[", round(medValues[[2]][[1]][1],digits=3),", ",round(medValues[[2]][[1]][2],digits=3),"].",sep="")

  })


  #The if statements supress the CI table output when a negative value is entered for Standard Error.
  output$interval <- renderText({
#     
#     if(input$se.x < 0){
#       return(NULL)
#     }
#     
#     if(input$se.y < 0){
#       return(NULL)
#     }
#     else{
    print(head(results()),quote=FALSE)
#     }
  })
  
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
    
    if(input$se.x <= 0){
      print("Error: Standard Error must be a positive value")
    }
    
  })
  
  #Create standard error b (se.y) entry error message.
  output$SEbMessages <- renderText({
    
    if(input$se.y <= 0){
      print("Error: Standard Error must  be a positive value")
    }
    
  })
  
  
  
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
medci(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho, input$alpha, plot=TRUE, plotCI=TRUE)
  }
    
  })
  
})