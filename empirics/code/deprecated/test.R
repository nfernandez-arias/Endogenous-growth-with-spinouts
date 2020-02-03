# File name: Jeffers 2018 on state-level R\&D spending

library(data.table)
library(readstata13)

rm(list = ls())

data1 <- data.table(read.dta13('../raw/nsf/rd_state_sic.dta'))

