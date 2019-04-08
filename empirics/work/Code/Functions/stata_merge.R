stata.merge <- function(x,y,name) {

  x$new1 <- 1
  y$new2 <- 2
  df <- merge(x,y, by = name, all = TRUE)
  df$merge <- rowSums(df[,c("new1", "new2")], na.rm=TRUE)
  df$new1 <- NULL
  df$new2<- NULL
  df  

}
