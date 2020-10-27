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

temp <- fread("data/parentsSpinoutsWSO.csv")[ joinYear >= 1987 & joinYear <= 2009]

for (ndigits in c(1,2,3,4))
{
  for (founderType in c("all","technical","founder2","executive"))
  {
    
    dataStorageString <- paste0("data_",founderType)
    
    #parentsSpinoutsLinks <- unique(temp[get(founderType) == 1],by = c("gvkey","EntityID"))[ , .(gvkey,EntityID,naics,NAICS1)][ naics != "" & NAICS1 != ""]
    #parentsSpinoutsLinks <- temp[get(founderType) == 1, .N, by = c("gvkey","EntityID")][ , .(gvkey,EntityID,naics,NAICS1)][ naics != "" & NAICS1 != ""]
    
    
    parentsSpinoutsLinks <- temp[ naics != "" & NAICS1 != "" & fromPublic == 1 & get(founderType) == 1]
    
    if (ndigits %in% c(3,4)) {
      parentsSpinoutsLinks <- parentsSpinoutsLinks[ substr(naics,1,2) %in% c("32","33","51") & substr(NAICS1,1,2) %in% c("32","33","51")]
    }
    
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
    
    naicsPairsCounts_wide <- dcast(naicsPairsCounts, ParentNAICS ~ ChildNAICS, value.var = "N")
    
    #### Finally CONSTRUCT HEATMAPS
    ################################
    
    rnames <- naicsPairsCounts_wide[ ,1]
    dataCounts <- as.matrix(naicsPairsCounts_wide[ , 2:ncol(naicsPairsCounts_wide)])
    rownames(dataCounts) <- t(rnames)
    
    library(RColorBrewer)
    pal <- colorRampPalette( brewer.pal(name="Blues",n=9))(600)
    
    pdf(paste0("figures/plots/industry_noscale_heatmap_naics",ndigits,"_",founderType,".pdf"))
    heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, col = pal, scale = "none", cexRow = 1.2 - 0.2 * ndigits, cexCol = 1.2 - 0.2 * ndigits)
    dev.off()
    
    pdf(paste0("figures/plots/industry_column_heatmap_naics",ndigits,"_",founderType,".pdf"))
    heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, col = pal, scale = "column", cexRow = 1.2 - 0.2 * ndigits, cexCol = 1.2 - 0.2 * ndigits)
    dev.off()
    
    pdf(paste0("figures/plots/industry_row_heatmap_naics",ndigits,"_",founderType,".pdf"))
    heatmap3(dataCounts, na.rm = TRUE, Rowv = NA, symm = TRUE, col = pal, scale = "row", cexRow = 1.2 - 0.2 * ndigits, cexCol = 1.2 - 0.2 * ndigits)
    dev.off()
    
    
    naicsPairsCounts[ , N_row := (N - mean(na.omit(N))) / sd(na.omit(N)), by = ParentNAICS]
    naicsPairsCounts[ , N_column := (N - mean(na.omit(N))) / sd(na.omit(N)), by = ChildNAICS]
    
    naicsPairsCounts2 <- naicsPairsCounts
    naicsPairsCounts2[ , `:=` (ParentNAICS = as.factor(ParentNAICS), ChildNAICS = as.factor(ChildNAICS))]
    
    font_import("Computer Modern Roman")
    
    #industriesTable <- data.table(cbind(Code = c("31-33","51","52","54"), Industry = c("Manufacturing","Information","Finance & Insurance", "Professional, Scientific, Technical Services")))
    
    #hj <- matrix( c(1.5,0), ncol = 2, nrow = nrow(industriesTable), byrow = TRUE)
    #x <- matrix( c(1,0), ncol = 2, nrow = nrow(industriesTable), byrow = TRUE)
    
    #tt1 <- ttheme_default(core = list(fg_params = list(hjust = as.vector(hj),
                                                      # x = as.vector(x))),
                      #    colhead = list(fg_params = list(hjust = 1, x = 0.95)))

    ggplot(naicsPairsCounts2, aes(x = ChildNAICS, y =  ParentNAICS, fill = N_row)) + 
      geom_tile() + 
      scale_x_discrete(position = "top") +
      scale_y_discrete(limits = rev(levels(as.factor(naicsPairsCounts2$ParentNAICS)))) + 
      coord_fixed() + 
      labs(fill = "Count (z-score)") + 
      scale_fill_gradientn( colors = brewer.pal(name="Blues",n=9)) +
      #annotation_custom(tableGrob(industriesTable, rows = NULL, theme = tt1), xmin = 39, xmax = Inf, ymin = -15) +
      xlab("Spinout industry") +
      ylab("Parent industry") + 
      theme(text=element_text(family="Latin Modern Roman"), 
            axis.text = element_text(size = 11),
            axis.title = element_text(size = 16))
    
    ggsave(paste0("figures/plots/industry_row_heatmap_naics",ndigits,"_",founderType,"_ggplot2.png"), plot = last_plot(), width = 8, height = 5.333333, units = "in")
    
    naicsPairsCounts2[ , ParentNAICS := as.character(ParentNAICS)]
    naicsPairsCounts2[ , ChildNAICS := as.character(ChildNAICS)]
    
    naicsPairsCounts3 <- naicsPairsCounts2[ParentNAICS != "49" & ParentNAICS != "99"]
    naicsPairsCounts3 <- naicsPairsCounts3[ChildNAICS != "49" & ChildNAICS != "99"]
    

    
    ggplot(naicsPairsCounts3[], aes(x = ChildNAICS, y =  ParentNAICS, fill = N_column)) + 
      geom_tile() + 
      scale_x_discrete(position = "top") +
      scale_y_discrete(limits = rev(levels(as.factor(naicsPairsCounts3$ParentNAICS)))) + 
      coord_fixed() + 
      labs(fill = "Count (z-score)") + 
      scale_fill_gradientn( colors = brewer.pal(name="Blues",n=9)) +
      #annotation_custom(tableGrob(industriesTable, rows = NULL, theme = tt1), xmin = 39, xmax = Inf, ymin = -15) +
      xlab("Spinout industry") +
      ylab("Parent industry") + 
      theme(text=element_text(family="Latin Modern Roman"), 
            axis.text = element_text(size = 11),
            axis.title = element_text(size = 16))
    
    ggsave(paste0("figures/plots/industry_column_heatmap_naics",ndigits,"_",founderType,"_ggplot2.png"), plot = last_plot(), width = 8, height = 5.333333, units = "in")
    
    
    assign(dataStorageString,dataCounts)
    
    
  }
  
  
}



    









