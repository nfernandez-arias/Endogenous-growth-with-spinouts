# File name: yearStateXRD-NSF_convertToCSV.R
#
# Description: Converts NSF data to csv (see Docs/README.txt)
#

rm(list = ls())

data <- data.table(read.dta13('Data/rd-by-state.dta'))

data <- data %>% rename(xrd_NSF = RD, GDP_NSF = GDP)
data <- data %>% select(state,year,xrd_NSF,GDP_NSF)
fwrite(data,"Data/rd-by-state.csv")


