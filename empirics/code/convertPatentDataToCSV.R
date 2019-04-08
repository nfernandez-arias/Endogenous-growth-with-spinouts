library(data.table)
library(readstata13)

setwd("~/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/empirics/code")


# Assignees
data <- read.dta13("../raw/nber uspto/assignee.dta")
fwrite(data,file = "../data/nber uspto/assignee.csv")
rm(data)

# Dynass
data <- read.dta13("../raw/nber uspto/dynass.dta")
fwrite(data,file = "../data/nber uspto/dynass.csv")
rm(data)

# Patents
data <- read.dta13("../raw/nber uspto/pat76_06_assg.dta")
fwrite(data,file = "../data/nber uspto/pat76_06_assg.csv")
rm(data)

# Citations
data <- read.dta13("../raw/nber uspto/cite76_06.dta")
fwrite(data,file = "../data/nber uspto/cite76_06.csv")
rm(data)

# Pdpcohdr
data <- read.dta13("../raw/nber uspto/pdpcohdr.dta")
fwrite(data,file = "../data/nber uspto/pdpcohdr.csv")
rm(data)

# orig_gen_76_06
data <- read.dta13("../raw/nber uspto/orig_gen_76_06.dta")
fwrite(data,file = "../data/nber uspto/orig_gen_76_06.csv")
rm(data)

# patassg.dta
data <- read.dta13("../raw/nber uspto/patassg.dta")
fwrite(data,file = "../data/nber uspto/patassg.csv")
rm(data)



