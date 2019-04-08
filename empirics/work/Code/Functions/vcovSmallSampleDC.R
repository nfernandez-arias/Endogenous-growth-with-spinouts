vcovSmallSampleDC <- function(x,dat,type = c("HC0","sss","HC1","HC2","HC3","HC4")) {
  
  Vci <- vcovCR(x, cluster = dat$state, type = "CR2")
  Vct <- vcovCR(x, cluster = dat$year, type = "CR2")
  Vw <- vcovG(x, type = type, l = 0, inner = "white")
  
  res <- Vci + Vct - Vw
  attr(res, which = "cluster") <- "group-time"
  
  return(res)
  
}