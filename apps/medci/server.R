
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
    
    #Set up variables to easily represent the mu and SE estimates
    se.xy <- sqrt(input$se.y^2*input$mu.x^2+input$se.x^2*input$mu.y^2+2*input$mu.x*input$mu.y*input$rho*input$se.x*input$se.y+input$se.x^2*input$se.y^2+input$se.x^2*input$se.y^2*input$rho^2);
    mu.xy <- input$mu.x*input$mu.y+input$rho*input$se.x*input$se.y
    
    #Create the statements to be combined for the APA sentence format output  
#     paste("For a&#770 = ", round(input$mu.x,digits=3), " (SE = ", round(input$se.x,digits=3), ")", " and b&#770 = ", round(input$mu.y,digits=3), " (SE = ", round(input$se.y,digits=3), "),", 
#                      " the indirect effect estimate is ", round(medValues[[2]][[2]],digits=3), " (SE = ", round(medValues[[2]][[3]],digits=3), "). The distribution of the product of coefficients method ",
#                      round((1-input$alpha)*100,digits=3),"% CI is ", "[", round(medValues[[2]][[1]],digits=3),", ",round(medValues[[2]][[1]],digits=3),"].",sep="")

    #New results statement because version 1.1.4 of RMediation output for the medci function does not produce the indirect effect estimate and SE anymore. So this now calls these estimates from a 
    #different location than before. They are being calculated above rather than being pulled from output.

    #Index by name, not position: medci(type="all") returns a list keyed
    #by method name ("Distribution of Product", "Monte Carlo", "Asymptotic
    #Normal"). The previous version used medValues[[2]], which is the
    #Monte Carlo method's CI, not Distribution of Product's -- the label
    #below and the numbers it displayed disagreed. Indexing by name also
    #survives a future reordering of medci()'s return list.
    dopCI <- medValues[["Distribution of Product"]][["95% CI"]]

    paste("For a&#770 = ", round(input$mu.x,digits=3), " (SE = ", round(input$se.x,digits=3), ")", " and b&#770 = ", round(input$mu.y,digits=3), " (SE = ", round(input$se.y,digits=3), "),",
          " the indirect effect estimate is ", round(mu.xy,digits=3), " (SE = ", round(se.xy,digits=3), "). The distribution of the product of coefficients method ",
          round((1-input$alpha)*100,digits=3),"% CI is ", "[", round(dopCI[[1]],digits=3),", ",round(dopCI[[2]],digits=3),"].",sep="")
    
    
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