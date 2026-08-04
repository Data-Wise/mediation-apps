
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
  #
  #Returns a list (not just the text) that includes the raw input values
  #alongside the computed text -- output$plot reads mu.x/mu.y/se.x/se.y/
  #rho/alpha from THIS list, not from input$... directly. That's load-
  #bearing: Shiny subscribes an output to every reactive value it reads
  #during evaluation, not just the first one, so if drawPlot() touched
  #input$... directly it would depend on both the debounced `results()`
  #AND the raw undebounced inputs -- reintroducing the exact per-keystroke
  #flash the debounce below was written to eliminate. (Caught in review:
  #the first debounce fix, PR #27, had exactly this bug -- drawPlot()
  #called results() but then read input$... itself.)
  #
  #Debounced (500ms) below via `results <- debounce(rawResults, 500)`: with
  #live reactivity and no submit button, every keystroke re-triggers this
  #-- typing "0.1" digit-by-digit, or briefly clearing a field, hit a
  #transient invalid/incomplete state that flashed an error before
  #settling on the correct value. Debouncing waits until input pauses
  #instead of recomputing on every keystroke -- same "type and see it
  #happen" feel, without the flash. (Considered reintroducing
  #submitButton instead -- rejected: that was removed in PR #17
  #specifically for the immediate-feedback ADHD-friendly design goal, and
  #debounce fixes the flash without giving that up.)
  rawResults <- reactive({

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

    mu.x <- input$mu.x; mu.y <- input$mu.y
    se.x <- input$se.x; se.y <- input$se.y
    rho <- input$rho; alpha <- input$alpha

    #type="dop" (Distribution of Product) is the default and the ONLY
    #method this app displays -- type="all" (the previous call) also
    #computed a 100,000-draw Monte Carlo estimate and an Asymptotic
    #Normal estimate every time this reactive fires, neither ever used.
    #type="dop" returns a flat list ($`95% CI`, $Estimate, $SE) rather
    #than nested under a method name, since there's only one method.
    medValues <- medci(mu.x, mu.y, se.x, se.y, rho, alpha, type = "dop")

    #Set up variables to easily represent the mu and SE estimates
    se.xy <- sqrt(se.y^2*mu.x^2+se.x^2*mu.y^2+2*mu.x*mu.y*rho*se.x*se.y+se.x^2*se.y^2+se.x^2*se.y^2*rho^2)
    mu.xy <- mu.x*mu.y+rho*se.x*se.y

    dopCI <- medValues[["95% CI"]]

    text <- paste("For a&#770 = ", round(mu.x,digits=3), " (SE = ", round(se.x,digits=3), ")", " and b&#770 = ", round(mu.y,digits=3), " (SE = ", round(se.y,digits=3), "),",
          " the indirect effect estimate is ", round(mu.xy,digits=3), " (SE = ", round(se.xy,digits=3), "). The distribution of the product of coefficients method ",
          round((1-alpha)*100,digits=3),"% CI is ", "[", round(dopCI[[1]],digits=3),", ",round(dopCI[[2]],digits=3),"].",sep="")

    list(text = text, mu.x = mu.x, mu.y = mu.y, se.x = se.x, se.y = se.y, rho = rho, alpha = alpha)
  })

  results <- debounce(rawResults, 500)


  output$interval <- renderText({
    print(head(results()$text),quote=FALSE)
  })


  #Draws the density/CI plot to whatever graphics device is currently
  #open -- shared by the on-screen renderPlot() and the PNG downloadHandler
  #below so both stay in sync with a single implementation. Reads its
  #parameters from results() (debounced), never from input$... directly
  #-- see the comment on rawResults above for why that distinction
  #matters.
  drawPlot <- function() {
    r <- results()
    medci(r$mu.x, r$mu.y, r$se.x, r$se.y, r$rho, r$alpha, plot=TRUE, plotCI=TRUE)
  }

  #Specify that we want the plot produced by medci to be shown in the user interface.
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
