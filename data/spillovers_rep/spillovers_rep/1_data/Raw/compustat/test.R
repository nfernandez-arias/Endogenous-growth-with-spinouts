setwd("C:/Google_Drive_Princeton/PhD - Big boy/Research/Endogenous growth with worker flows and noncompetes/data/spillovers_rep/spillovers_rep/1_data/Raw/compustat")
library(readstata13)

data <- read.dta13("compustat_annual.dta")

save.dta13(data,"compustat_annual_13.dta")