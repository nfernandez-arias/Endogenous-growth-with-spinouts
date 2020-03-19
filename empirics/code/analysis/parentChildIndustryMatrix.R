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

temp <- fread("data/parentsSpinoutsWSO.csv")

for (ndigits in c(1,2,3,4))
{
  for (founderType in c("all","technical","founder2","executive"))
  {
    
    dataStorageString <- paste0("data_",founderType)
    
    #parentsSpinoutsLinks <- unique(temp[get(founderType) == 1],by = c("gvkey","EntityID"))[ , .(gvkey,EntityID,naics,NAICS1)][ naics != "" & NAICS1 != ""]
    #parentsSpinoutsLinks <- temp[get(founderType) == 1, .N, by = c("gvkey","EntityID")][ , .(gvkey,EntityID,naics,NAICS1)][ naics != "" & NAICS1 != ""]
    
    parentsSpinoutsLinks <- temp[ naics != "" & NAICS1 != ""]
    
    setnames(parentsSpinoutsLinks,"naics","ParentNAICS")
    setnames(parentsSpinoutsLinks,"NAICS1","ChildNAICS")
    
    # Drop observations with fewer than n digits
    
    parentsSpinoutsLinks <- parentsSpinoutsLinks[ nchar(ChildNAICS) >= ndigits & nchar(ParentNAICS) >= ndigits ]
    
    # Take n-digit substr
    parentsSpinoutsLinks[ , `:=` (ParentNAICS = substr(ParentNAICS,1,ndigits), ChildNAICS = substr(ChildNAICS,1,ndigits))]
    
    ## Compute fraction of spinouts from each parent firm state going to each child firm state 
    # Count spinouts from each parent - child state pair
    naicsPairsCounts <- parentsSpinoutsLinks[ , .N, by = .(ParentNAICS,ChildNAICS)]
    
    
    ParentNAICSCodes <- unique(naicsPairsCounts, by = "ParentNAICS")$ParentNAICS
    ChildNAICSCodes <- unique(naicsPairsCounts, by = "ChildNAICS")$ChildNAICS
    
    parentOnly <- setdiff(union(ParentNAICSCodes,ChildNAICSCodes),ChildNAICSCodes)
    childOnly <- setdiff(union(ParentNAICSCodes,ChildNAICSCodes),ParentNAICSCodes)
    
    for (code in parentOnly) {
      
      naicsPairsCounts <- rbindlist(list(naicsPairsCounts,list(substr(ParentNAICSCodes[1],1,ndigits),code,0)), use.names = FALSE, fill = FALSE)
      
    }
    
    for (code in childOnly) {
      
      naicsPairsCounts <- rbindlist(list(naicsPairsCounts,list(code,substr(ChildNAICSCodes[1],1,ndigits),0)), use.names = FALSE, fill = FALSE)
      
    }
    
    ## Now complete by code
    
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
    pal <- colorRampPalette( brewer.pal(name="Blues",n=9))(100)
    
    pdf(paste0("figures/plots/industry_noscale_heatmap_naics",ndigits,"_",founderType,".pdf"))
    heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, col = pal, scale = "none", cexRow = 1.2 - 0.2 * ndigits, cexCol = 1.2 - 0.2 * ndigits)
    dev.off()
    
    pdf(paste0("figures/plots/industry_column_heatmap_naics",ndigits,"_",founderType,".pdf"))
    heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, col = pal, scale = "column", cexRow = 1.2 - 0.2 * ndigits, cexCol = 1.2 - 0.2 * ndigits)
    dev.off()
    
    pdf(paste0("figures/plots/industry_row_heatmap_naics",ndigits,"_",founderType,".pdf"))
    heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, col = pal, scale = "row", cexRow = 1.2 - 0.2 * ndigits, cexCol = 1.2 - 0.2 * ndigits)
    dev.off()
    
    assign(dataStorageString,dataCounts)
  }
  
  
}



    








