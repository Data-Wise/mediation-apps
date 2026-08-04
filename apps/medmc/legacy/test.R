q <- "a*b"
q <- paste("~",q,sep="")
q1 <- as.formula(q)
class(q1)


numextractall <- function(string){
  unlist(regmatches(string,gregexpr("[[:digit:]]+\\.*[[:digit:]]*",string)), use.names=FALSE)
} 

M <- as.vector(numextractall(input$mu))
S <- as.vector(numextractall(input$Sigma))
Q <- as.formula(numextractall(input$quant))
