#------------------------------------------------#
#
# File name: matchPatentsToCompustat.R
#
# Author: Nicolas Fernandez-Arias 
#
# Purpose:
#
# 
#------------------------------------------------#

# First reshape dynass into a long format with 
# pdpass-gkvey-year observations for each relevant year
source("code/nber uspto/dynassReshape.R")

# Next construct a dataset matching patents to gkvey years, using appyear
source("code/nber uspto/matchPatentsGvkeys.R")

# Next compute patent counts
source("code/nber uspto/constructPatentCounts.R")

#patents_ipc <- fread("data/nber uspto/pat76_06_ipc.csv")[order(patent,pdpass)]
#patentsAssignees <- fread("data/nber uspto/patassg.csv")[order(patnum,pdpass)]
#originality <- fread("data/nber uspto/orig_gen_76_06.csv")[order(patent)]



