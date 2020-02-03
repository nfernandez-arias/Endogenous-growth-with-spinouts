#------------------------------------------------#
#
# File name: parentChildIndustryMatrix.R
# 
# Author: Nicolas Fernandez-Arias
#
# Purpose:    
#
# This script uses the parent-spinout data to construct
# a matrix breaking down where spinouts come from (parent firm state)
# and where they go (child state). 
#------------------------------------------------#


rm(list = ls())

library(gplots)

temp <- fread("data/parentsSpinoutsWSO.csv")

parentsSpinoutsLinks <- unique(temp,by = c("gvkey","EntityID"))[ , .(gvkey,EntityID,naics,NAICS1)][ naics != "" & NAICS1 != ""]

setnames(parentsSpinoutsLinks,"naics","ParentNAICS")
setnames(parentsSpinoutsLinks,"NAICS1","ChildNAICS")

## Replace with 4-digit NAICS codes

ndigits <- 2

# Drop observations with fewer than 4 digits

parentsSpinoutsLinks <- parentsSpinoutsLinks[ nchar(ChildNAICS) >= ndigits & nchar(ParentNAICS) >= ndigits ]

# Take 4-digit substr
parentsSpinoutsLinks[ , `:=` (ParentNAICS = substr(ParentNAICS,1,ndigits), ChildNAICS = substr(ChildNAICS,1,ndigits))]

## Compute fraction of spinouts from each parent firm state going to each child firm state 
# Count spinouts from each parent - child state pair
naicsPairsCounts <- parentsSpinoutsLinks[ , .N, by = .(ParentNAICS,ChildNAICS)]


ParentNAICSCodes <- unique(naicsPairsCounts, by = "ParentNAICS")$ParentNAICS
ChildNAICSCodes <- unique(naicsPairsCounts, by = "ChildNAICS")$ChildNAICS

parentOnly <- setdiff(union(ParentNAICSCodes,ChildNAICSCodes),ChildNAICSCodes)
childOnly <- setdiff(union(ParentNAICSCodes,ChildNAICSCodes),ParentNAICSCodes)

for (code in ParentNAICSCodes) {
  
  naicsPairsCounts <- rbindlist(list(naicsPairsCounts,list(substr(5112,1,ndigits),code,0)), use.names = FALSE, fill = FALSE)
  
}

for (code in ChildNAICSCodes) {
  
  naicsPairsCounts <- rbindlist(list(naicsPairsCounts,list(code,substr(5412,1,ndigits),0)), use.names = FALSE, fill = FALSE)
  
}

## Now complete by code

complete <- tidyr::complete

naicsPairsCounts <- data.table(complete(naicsPairsCounts,ParentNAICS, ChildNAICS))

naicsPairsCounts <- naicsPairsCounts[order(ParentNAICS,ChildNAICS)]

naicsPairsCounts[ is.na(N), N := 0]

naicsPairsCounts <- unique(naicsPairsCounts, by = c("ParentNAICS","ChildNAICS"))

naicsPairsCounts <- dcast(naicsPairsCounts, ParentNAICS ~ ChildNAICS, value.var = "N")

#### Finally CONSTRUCT HEATMAPS
################################

rnames <- naicsPairsCounts[ ,1]
dataCounts <- as.matrix(naicsPairsCounts[ , 2:ncol(naicsPairsCounts)])
rownames(dataCounts) <- t(rnames)

library(RColorBrewer)
pal <- colorRampPalette( brewer.pal(name="RdYlGn",n=9))(100)

pdf("code/plots/industry_column_heatmap.pdf")
heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, scale = "column", col = pal, cexRow = 0.4, cexCol = 0.4)
dev.off()

pdf("code/plots/industry_row_heatmap.pdf")
heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, scale = "row", col = pal, cexRow = 0.4, cexCol = 0.4)
dev.off()















