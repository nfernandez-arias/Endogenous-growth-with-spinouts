#-----------------------------------#
# 
# filename: foundersComparison.R
#
# This file tabulates statistics about founders of companies
# i.e. comparing number of founders from public vs. not from public
# or WSO4 vs nonWSO4 vs notFromPublic
# in each year, in each state-year, in industry-year, etc.
#
#-----------------------------------#


parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")

#-----------------------------------#
# Construct counts of founders in each year
#-----------------------------------#
    
setnames(parentsSpinouts,"joinYear","year")

for (founderType in c("all","technical","founder2","executive"))
{
  #-----------------#
  # Raw counts    
  #-----------------#
  
  temp <- parentsSpinouts[ , .(wso4 = sum(na.omit(wso4 * get(founderType))), 
                               nonwso4 = sum(na.omit(get(founderType) * (fromPublic - wso4))), 
                               nonSpinout = sum(na.omit(get(founderType) * (1 - fromPublic))), 
                               startups = sum(get(founderType))), 
                           by = year]
  
  #temp[ , checksum := wso4 + nonwso4 + nonSpinout]
  
  temp2 <- melt(temp, id.var = "year", measure.vars = c("wso4","nonwso4","nonSpinout","startups"))
  
  ggplot(data = temp2[ variable == "nonSpinout" | variable == "wso4" | variable == "nonwso4"], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Number of founders: ",founderType,sep = ""), " founders",sep = "")) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Number of founders") +
    xlab("Join Year")
  
  filePath = paste(paste("figures/plots/founderCountsByYear",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderCounts",founderType,sep = "_")
  
  assign(outputName,temp2)
  
  #-----------------#
  # Fractions - all
  #-----------------#
  
  temp[ , `:=` (wso4Frac = wso4 / startups, 
                nonwso4Frac = nonwso4 / startups, 
                nonSpinoutFrac = nonSpinout / startups)]
  
  temp_varlist <- c("wso4Frac","nonwso4Frac","nonSpinoutFrac")
  
  temp2 <- melt(temp, id.var = "year", measure.vars = temp_varlist)
  
  ggplot(data = temp2[ variable %in% temp_varlist], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Fraction of founders: ",founderType,sep = ""), " founders",sep = "")) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Fraction of founders") +
    xlab("Join Year")
  
  filePath = paste(paste("figures/plots/founderFractionsByYear",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderFractions",founderType,sep = "_")
  
  assign(outputName,temp2)
  
  #-----------------#
  # Fractions -- hasBio == 1
  #-----------------#
  
  temp <- parentsSpinouts[ hasBio == 1, .(wso4 = sum(na.omit(wso4 * get(founderType))), 
                                          nonwso4 = sum(na.omit(get(founderType) * (fromPublic - wso4))), 
                                          nonSpinout = sum(na.omit(get(founderType) * (1 - fromPublic))),
                                          startups = sum(get(founderType))), 
                           by = year]
  
  temp[ , `:=` (wso4Frac = wso4 / startups, 
                nonwso4Frac = nonwso4 / startups, 
                nonSpinoutFrac = nonSpinout / startups)]
  
  temp_varlist <- c("wso4Frac","nonwso4Frac","nonSpinoutFrac")
  
  temp2 <- melt(temp, id.var = "year", measure.vars = temp_varlist)
  
  ggplot(data = temp2[ variable %in% temp_varlist], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Fraction of founders: ",founderType,sep = ""), " founders",sep = "")) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Fraction of founders") +
    xlab("Join Year")
  
  filePath = paste(paste("figures/plots/founderFractionsByYearHasBio",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderFractionsHasBio",founderType,sep = "_")
  
  assign(outputName,temp2)
  
  #-----------------#
  # Fractions -- hasBio == 1 and joinYearImputed == 0
  #-----------------#
  
  temp <- parentsSpinouts[ hasBio == 1 & joinYearImputed == 0, .(wso4 = sum(na.omit(wso4 * get(founderType))), 
                                                                 nonwso4 = sum(na.omit(get(founderType) * (fromPublic - wso4))), 
                                                                 nonSpinout = sum(na.omit(get(founderType) * (1 - fromPublic))), 
                                                                 startups = sum(get(founderType))), 
                           by = year]
  
  temp[ , `:=` (wso4Frac = wso4 / startups, 
                nonwso4Frac = nonwso4 / startups, 
                nonSpinoutFrac = nonSpinout / startups)]
  
  temp_varlist <- c("wso4Frac","nonwso4Frac","nonSpinoutFrac")
  
  temp2 <- melt(temp, id.var = "year", measure.vars = temp_varlist)
  
  ggplot(data = temp2[ variable %in% temp_varlist], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Fraction of founders: ",founderType,sep = ""), " founders",sep = "")) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Fraction of founders") +
    xlab("Join Year")
  
  filePath = paste(paste("figures/plots/founderFractionsByYearHasBioNoJoinYearImputation",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderFractionsHasBioNoJoinYearImputation",founderType,sep = "_")
  
  assign(outputName,temp2)
  
  #----------------------------#
  # Counts - By state and year
  #----------------------------#
  
  temp <- parentsSpinouts[ , .(wso4 = sum(na.omit(wso4 * get(founderType))), 
                               nonwso4 = sum(na.omit(get(founderType) * (fromPublic - wso4))), 
                               nonSpinout = sum(na.omit(get(founderType) * (1 - fromPublic))), 
                               startups = sum(get(founderType))), 
                           by = .(EntityState,year)]
  
  #temp[ , checksum := wso4 + nonwso4 + nonSpinout]
  
  temp <- melt(temp, id.vars = c("EntityState","year"), measure.vars = c("wso4","nonwso4","nonSpinout","startups"))
  
  ggplot(data = temp[ EntityState %in% LargeStates & (variable == "nonSpinout" | variable == "wso4" | variable == "nonwso4")], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Number of founders: ",founderType,sep = ""), " founders",sep = "")  ) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Number of founders") +
    xlab("Join Year") + 
    facet_wrap(~ EntityState, ncol = 4) 
  
  filePath = paste(paste("figures/plots/founderCountsByStateYear",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderCountsState",founderType,sep = "_")
  
  assign(outputName,temp)
  
  #----------------------------#
  # PERCENTAGES by state and year
  #----------------------------#
  
  temp <- parentsSpinouts[ , .(wso4 = sum(na.omit(wso4 * get(founderType))), 
                               nonwso4 = sum(na.omit(get(founderType) * (fromPublic - wso4))), 
                               nonSpinout = sum(na.omit(get(founderType) * (1 - fromPublic))), 
                               startups = sum(get(founderType))), 
                           by = .(EntityState,year)]
  
  #temp[ , checksum := wso4 + nonwso4 + nonSpinout]
  
  temp[ , `:=` (wso4 = wso4 / startups, nonwso4 = nonwso4 / startups, nonSpinout = nonSpinout / startups)]
  
  temp <- melt(temp, id.vars = c("EntityState","year"), measure.vars = c("wso4","nonwso4","nonSpinout","startups"))
  
  ggplot(data = temp[ EntityState %in% LargeStates & (variable == "nonSpinout" | variable == "wso4" | variable == "nonwso4")], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Fraction of founders: ",founderType,sep = ""), " founders",sep = "")) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Fraction of founders") +
    xlab("Join Year") + 
    facet_wrap(~ EntityState, ncol = 4) 
  
  filePath = paste(paste("figures/plots/founderFractionsByStateYear",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderFractionsState",founderType,sep = "_")
  
  assign(outputName,temp)
  
  #----------------------------#
  # PERCENTAGES by state and year
  # only when hasBio == 1
  #----------------------------#
  
  temp <- parentsSpinouts[ hasBio == 1, .(wso4 = sum(na.omit(wso4 * get(founderType))), 
                                          nonwso4 = sum(na.omit(get(founderType) * (fromPublic - wso4))), 
                                          nonSpinout = sum(na.omit(get(founderType) * (1 - fromPublic))), 
                                          startups = sum(get(founderType))), 
                           by = .(EntityState,year)]
  
  #temp[ , checksum := wso4 + nonwso4 + nonSpinout]
  
  temp[ , `:=` (wso4 = wso4 / startups, nonwso4 = nonwso4 / startups, nonSpinout = nonSpinout / startups)]
  
  temp <- melt(temp, id.vars = c("EntityState","year"), measure.vars = c("wso4","nonwso4","nonSpinout","startups"))
  
  ggplot(data = temp[ EntityState %in% LargeStates & (variable == "nonSpinout" | variable == "wso4" | variable == "nonwso4")], aes(x = year, y = value, fill = variable)) + 
    geom_area(position = "stack") +
    #scale_fill_manual(values = my_palette) + 
    theme(text = element_text(size=16)) +
    #theme(legend.position = "none") +
    ggtitle(paste(paste("Fraction of founders: ",founderType,sep = ""), " founders",sep = "")) +
    #ggtitle("Unadjusted") + 
    xlim(1986,2011) + 
    ylab("Fraction of founders") +
    xlab("Join Year") + 
    facet_wrap(~ EntityState, ncol = 4) 
  
  filePath = paste(paste("figures/plots/founderFractionsByStateYearHasBio",founderType,sep = "_"),".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8)
  
  outputName <- paste("founderFractionsStateHasBio",founderType,sep = "_")
  
  assign(outputName,temp)
  
}

#-----------------------------------#
# Make a plot with all
#-----------------------------------#

#data_all <- rbind(founderFractions)  



#-----------------------------------#
# Make some tables
#-----------------------------------#

## Table 1 (a,b,c,d): 
# 
# Column1: year
# Column2: founderCounts - 
# Column3: startupCounts
# Column4: founderCounts - wso4 + nonwso4
# Column5: founderFractions - wso4 + nonwso4
# Column6: founderFractions - wso4
# Column7: founderFractionsHasBio - wso4 + nonwso4  
# Column8: founderFractionsHasBio - wso4

for (founderType in c("all","technical","founder2","executive"))
{
    founderCountsString <- paste("founderCounts",founderType,sep = "_")
    founderFracsString <- paste("founderFractions",founderType,sep = "_")
    founderFracsHasBioString <- paste("founderFractionsHasBio",founderType,sep = "_")
    
    founderCountsTemp <- dcast(get(founderCountsString),year ~ variable, value.var = "value")
    founderFracsTemp <- dcast(get(founderFracsString),year ~ variable, value.var = "value")
    founderFracsHasBioTemp <- dcast(get(founderFracsHasBioString),year ~ variable, value.var = "value")
    
    founderCountsTemp[ , `:=` (spinoutsCount = as.integer(wso4 + nonwso4), allCount = as.integer(startups))]
    founderFracsTemp[ , `:=` (spinoutsFrac = (wso4Frac + nonwso4Frac)*100, wso4Frac = wso4Frac * 100)]
    founderFracsHasBioTemp[ , `:=` (spinoutsFracHasBio = (wso4Frac + nonwso4Frac)*100, wso4FracHasBio = wso4Frac * 100)]
    
    founderCountsTemp <- founderCountsTemp[ , .(year,spinoutsCount,allCount)]
    founderFracsTemp <- founderFracsTemp[ , .(year,spinoutsFrac,wso4Frac)]
    founderFracsHasBioTemp <- founderFracsHasBioTemp[ , .(year,spinoutsFracHasBio,wso4FracHasBio)]
    
    setkey(founderCountsTemp,year)
    setkey(founderFracsTemp,year)
    setkey(founderFracsHasBioTemp,year)
    
    temp <- startupsCountByYear[foundingYear <= 2015]
    
    temp <- founderCountsTemp[temp]
    temp <- founderFracsTemp[temp]
    temp <- founderFracsHasBioTemp[temp]
    
    setcolorder(temp,c("year","allCount","startupsCount","spinoutsCount","spinoutsFrac","spinoutsFracHasBio","wso4Frac","wso4FracHasBio"))
    
    temp <- temp[ year >= 1986]
    
    tableNameString <- paste("table1",founderType,sep = "_")
    
    assign(tableNameString,temp)
    
    # Print latex table
    names(temp) <- c("Year","Number of founders","Number of start-ups","Number of founders from public companies",
                     "Fraction from public companies (%)","Fraction from public companies when bio. info available (%)",
                     "Fraction from public companies in same 4-digit NAICS (%)","Fraction from public companies in same 4-digit NAICS when bio. info available (%)")
    
    
    if (founderType == "all")
    {
      captionString <- paste("Summary of founders. Here, \"founder\" includes all individuals employed at startups in",
                        " the VentureSource database who joined the startup within ",founderThreshold," year(s) of its founding year.", sep = "")
    } else if (founderType == "technical")
    {
      captionString <- paste("Summary of founders. Here, \"founder\" includes all individuals employed at startups in"
                                         ,"the VentureSource database who (1) joined the startup within ",founderThreshold,
                                         " year(s) of its founding year; and (2) have the title of ",paste0(technicalTitles, collapse = ", "),".",sep = "")
    } else if (founderType == "founder2")
    {
      captionString <- paste("Summary of founders. Here, \"founder\" includes all individuals employed at startups in"
                             ,"the VentureSource database who (1) joined the startup within ",founderThreshold,
                             " year(s) of its founding year; and (2) have the title of ",paste0(founderTitles, collapse = ", "),".",sep = "")
    } else if (founderType == "executive")
    {
      captionString <- paste("Summary of founders. Here, \"founder\" includes all individuals employed at startups in"
                             ,"the VentureSource database who (1) joined the startup within ",founderThreshold,
                             " year(s) of its founding year; and (2) have the title of ",paste0(executiveTitles, collapse = ", "),".",sep = "")
    }
    
    
    tempXtable <- xtable(temp,align = c("c","p{1.75cm}","p{1.75cm}","p{1.75cm}","p{1.75cm}","p{1.75cm}","p{1.75cm}","p{1.75cm}","p{1.75cm}"), 
                         caption = captionString, 
                         label = paste0("table:GStable_",founderType),
                         digits = 1)
    filePath <- paste(paste("figures/tables/",tableNameString, sep = ""),".tex",sep = "")
    print(tempXtable,filePath, type = "latex", size = "\\scriptsize", include.rownames = FALSE, booktabs = TRUE, table.placement = "!htb")
    
}





