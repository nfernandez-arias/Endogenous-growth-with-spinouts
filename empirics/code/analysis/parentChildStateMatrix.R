#------------------------------------------------#
#
# File name: parentChildStateMatrix.R
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

temp <- fread("data/parentsSpinouts.csv")
stateAbbrevs <- fread("bloom/spillovers_rep/1_data/Raw/stmap.csv")[ , .(abbr,fips)]
setkey(stateAbbrevs,abbr)


parentsSpinoutsLinks <- unique(temp,by = c("gvkey","EntityID"))

parentsSpinoutsLinks <- parentsSpinoutsLinks[ , .(conml,gvkey,state,EntityID,EntityName,foundingYear,globCount)]

setnames(parentsSpinoutsLinks,"state","ParentState")

EntityInfo <- unique(fread("raw/VentureSource/01Deals.csv")[ , .(EntityID,BriefDescription,FullDesc,WebURL,Competition,State)], by = "EntityID")

setnames(EntityInfo,"State","ChildState")

setkey(EntityInfo,EntityID)
setkey(parentsSpinoutsLinks,EntityID)

parentsSpinoutsLinks <- EntityInfo[parentsSpinoutsLinks][!is.na(ParentState) & !is.na(ChildState) & ParentState != "" & ChildState != ""]

## Now merge with state number identifiers, so that I can "complete" the matrix later
## and have a visualization where every state is on each side (easier visualization)

setkey(parentsSpinoutsLinks,ParentState)
parentsSpinoutsLinks <- stateAbbrevs[parentsSpinoutsLinks]
setnames(parentsSpinoutsLinks,"fips","ParentFips")
parentsSpinoutsLinks[ , abbr := NULL]

setkey(parentsSpinoutsLinks,ChildState)
parentsSpinoutsLinks <- stateAbbrevs[parentsSpinoutsLinks]
setnames(parentsSpinoutsLinks,"fips","ChildFips")
parentsSpinoutsLinks[ , abbr := NULL]


## Compute fraction of spinouts from each parent firm state going to each child firm state 
# Count spinouts from each parent - child state pair
statePairsCounts <- parentsSpinoutsLinks[ , .N, by = .(ParentFips,ChildFips)]

## Now complete by fips

complete <- tidyr::complete

statePairsCounts <- data.table(complete(statePairsCounts,ParentFips = 1:78,ChildFips = 1:78))

statePairsCounts <- statePairsCounts[order(ParentFips,ChildFips)]

statePairsCounts[ is.na(N), N := 0]


## Merge back in state names
setkey(stateAbbrevs,fips)

setkey(statePairsCounts,ParentFips)
statePairsCounts <- stateAbbrevs[statePairsCounts]
setnames(statePairsCounts,"abbr","ParentState")
setnames(statePairsCounts,"fips", "ParentFips")

setkey(statePairsCounts,ChildFips)
statePairsCounts <- stateAbbrevs[statePairsCounts]
setnames(statePairsCounts,"abbr","ChildState")
setnames(statePairsCounts,"fips", "ChildFips")
## Construct fractions 

statePairsCounts <- statePairsCounts[ ParentState != "" & ChildState != "" & !is.na(ParentState) & !is.na(ChildState)]

statePairsCounts[ , parentTotal := sum(na.omit(N)), by = "ParentFips"]
statePairsFractions <- statePairsCounts[ , .(parentChildFraction = N / parentTotal), by = .(ParentFips,ParentState,ChildFips,ChildState)]

statePairsFractions <- statePairsFractions[order(ParentFips,ChildFips)]

statePairsCounts[ , parentTotal := NULL]

## Now change to wide format for easy plotting of heatmaps
########

statePairsCounts <- statePairsCounts[order(ParentState,ChildState)]

statePairsCounts[ is.nan(N) , N := NA]

statePairsCounts <- dcast(statePairsCounts, ParentState ~ ChildState, value.var = "N")

statePairsFractions[ is.nan(parentChildFraction), parentChildFraction := 0]

statePairsFractions <- dcast(statePairsFractions, ParentState ~ ChildState, value.var = "parentChildFraction")



#### Finally CONSTRUCT HEATMAPS
################################

rnames <- statePairsCounts[ ,1]
dataCounts <- as.matrix(statePairsCounts[ , 2:ncol(statePairsCounts)])
rownames(dataCounts) <- t(rnames)

library(RColorBrewer)
pal <- colorRampPalette( brewer.pal(name="RdYlGn",n=9))(100)

pdf("code/plots/state_column_heatmap.pdf")
heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, scale = "column", col = pal, balanceColor = FALSE)
dev.off()

pdf("code/plots/state_row_heatmap.pdf")
heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, scale = "row", col = pal)
dev.off()













