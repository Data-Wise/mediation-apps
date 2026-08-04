
#Shiny Application for RMediation package using the medci function
#server script file
#9/24/2013



library(shiny)
library(RMediation)



#A call to shiny-server to take all of the following into account (The sever logic).
shinyServer(function(input, output) {


  #Create a reactive expression. This recomputes automatically whenever any
  #input changes (no submit button -- see ui.R). validate()/need() render
  #Shiny's standard inline-error style near the output that depends on them,
  #replacing the old four separate ...Messages textOutputs + red CSS.
  results <- reactive({

    validate(
      need(input$alpha > .0001 && input$alpha < .9999,
           "Error: Alpha must be between .0001 and .9999"),
      need(input$rho > -0.999 && input$rho < .999,
           "Error: Correlation must be between -.999 and .999"),
      need(input$se.x > 0,
           "Error: Standard Error must be a positive value"),
      need(input$se.y > 0,
           "Error: Standard Error must be a positive value")
    )

    #Create a variable to represent the medci function output from the user's input values.
    medValues <- medci(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho,input$alpha,type="all")

    #Set up variables to easily represent the mu and SE estimates
    se.xy <- sqrt(input$se.y^2*input$mu.x^2+input$se.x^2*input$mu.y^2+2*input$mu.x*input$mu.y*input$rho*input$se.x*input$se.y+input$se.x^2*input$se.y^2+input$se.x^2*input$se.y^2*input$rho^2);
    mu.xy <- input$mu.x*input$mu.y+input$rho*input$se.x*input$se.y

    #Index by name, not position: medci(type="all") returns a list keyed
    #by method name ("Distribution of Product", "Monte Carlo", "Asymptotic
    #Normal"). Indexing by name survives a future reordering of medci()'s
    #return list.
    dopCI <- medValues[["Distribution of Product"]][["95% CI"]]

    paste("For a&#770 = ", round(input$mu.x,digits=3), " (SE = ", round(input$se.x,digits=3), ")", " and b&#770 = ", round(input$mu.y,digits=3), " (SE = ", round(input$se.y,digits=3), "),",
          " the indirect effect estimate is ", round(mu.xy,digits=3), " (SE = ", round(se.xy,digits=3), "). The distribution of the product of coefficients method ",
          round((1-input$alpha)*100,digits=3),"% CI is ", "[", round(dopCI[[1]],digits=3),", ",round(dopCI[[2]],digits=3),"].",sep="")


  })


  output$interval <- renderText({
    print(head(results()),quote=FALSE)
  })


  #Draws the density/CI plot to whatever graphics device is currently
  #open -- shared by the on-screen renderPlot() and the PNG downloadHandler
  #below so both stay in sync with a single implementation.
  drawPlot <- function() {
    results()
    medci(input$mu.x,input$mu.y,input$se.x,input$se.y,input$rho, input$alpha, plot=TRUE, plotCI=TRUE)
  }

  #Specify that we want the plot produced by medci to be shown in the user interface.
  #Reactive validation (alpha/rho/SE bounds) already runs via results(); we
  #depend on it here so the plot clears together with the results text
  #instead of throwing its own separate error.
  output$plot <- renderPlot({
    drawPlot()
  })

  #Explicit "save figure" control (right-click-to-save also works on the
  #rendered image, but not every user knows that).
  output$downloadPlot <- downloadHandler(
    filename = function() {
      sprintf("medci-plot-%s.png", format(Sys.time(), "%Y%m%d-%H%M%S"))
    },
    content = function(file) {
      png(file, width = 600, height = 425)
      drawPlot()
      dev.off()
    }
  )

})
