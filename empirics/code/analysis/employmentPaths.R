

data <- fread("data/VentureSource/startupsPaths.csv")

parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")

parentsSpinouts[ , EntityFromPublic := max(fromPublic), by = "EntityID"]
parentsSpinouts[ , NAICS1_4 := substr(NAICS1,1,4)]
parentsSpinouts[ , NAICS1_3 := substr(NAICS1,1,3)]
parentsSpinouts[ , NAICS1_2 := substr(NAICS1,1,2)]
parentsSpinouts[ , NAICS1_1 := substr(NAICS1,1,1)]

for (i in 1:4)
{
  wsoLowerCase <- paste("wso",i,sep = "")
  wsoString <- paste("WSO",i,sep = "")
  entitywsoString <- paste("Entity",wsoString, sep = "")
  
  parentsSpinouts[ , (entitywsoString) := max(get(wsoLowerCase)) , by = EntityID]
  
}

spinoutsID <- unique(parentsSpinouts[ , .(EntityID,EntityFromPublic,EntityWSO1,EntityWSO2,EntityWSO3,EntityWSO4,NAICS1_4,NAICS1_3,NAICS1_2,NAICS1_1)])

setkey(spinoutsID,EntityID)

setkey(data,EntityID)

data <- spinoutsID[data][ !is.na(EntityFromPublic)]

fwrite(data,"data/VentureSource/startupsPathsStata.csv")

#data <- data[year >= 1995 & year <= 2005]

#---------------------------------------------#
# Make plots of quantiles of startup success
# metric vs. startup age.
#---------------------------------------------#

for (var in c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount",
              "lrevenue","lrevenuedivEmployeeCount","goingOutOfBusiness"))
{
  varTable <- paste("data_",var,sep = "")
  outerTemp_State <- data[ , .(avg = mean( na.omit(as.double(get(var)))),
                                     q05 = quantile(na.omit(as.double(get(var))),0.05), 
                                     #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                                     q25 = quantile(na.omit(as.double(get(var))),0.25),
                                     q50 = median(na.omit(as.double(get(var)))),
                                     q75 = quantile(na.omit(as.double(get(var))),0.75),
                                     #q90 = quantile(na.omit(as.double(get(var))),0.9),
                                     q95 = quantile(na.omit(as.double(get(var))),0.95)),
                                    by = .(State,EntityFromPublic,EntityAge)]
  
  outerTemp_State[ EntityFromPublic == 1, group := "Left"]
  outerTemp_State[EntityFromPublic == 0, group := "Right"]
  outerTemp_State[ , EntityFromPublic := NULL]
  outerTemp_State[ , subplot := "Spinouts vs Non-Spinouts"]
  
  outerTemp <- data[ , .(avg = mean( na.omit(as.double(get(var)))),
                         q05 = quantile(na.omit(as.double(get(var))),0.05), 
                         #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                         q25 = quantile(na.omit(as.double(get(var))),0.25),
                         q50 = median(na.omit(as.double(get(var)))),
                         q75 = quantile(na.omit(as.double(get(var))),0.75),
                         #q90 = quantile(na.omit(as.double(get(var))),0.9),
                         q95 = quantile(na.omit(as.double(get(var))),0.95)),
                     by = .(EntityFromPublic,EntityAge)]
  
  outerTemp[ EntityFromPublic == 1, group := "Left"]
  outerTemp[ EntityFromPublic == 0, group := "Right"]
  outerTemp[ , EntityFromPublic := NULL]
  outerTemp[ , subplot := "Spinouts vs Non-Spinouts"]
  
  for (j in 1:3)
  {
    naicsString <- paste("NAICS1",j,sep = "_")
    dtString_inner <- paste("outerTemp",naicsString, sep = "_")
    
    temp <- data[ , .(avg = mean( na.omit(as.double(get(var)))),
                      q05 = quantile(na.omit(as.double(get(var))),0.05), 
                      #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                      q25 = quantile(na.omit(as.double(get(var))),0.25),
                      q50 = median(na.omit(as.double(get(var)))),
                      q75 = quantile(na.omit(as.double(get(var))),0.75),
                      #q90 = quantile(na.omit(as.double(get(var))),0.9),
                      q95 = quantile(na.omit(as.double(get(var))),0.95)),
                  by = c(naicsString,"EntityFromPublic","EntityAge")]
    
    temp[ EntityFromPublic == 1, group := "Left"]
    temp[ EntityFromPublic == 0, group := "Right"]
    temp[ , EntityFromPublic := NULL]
    temp[ , subplot := "Spinouts vs Non-Spinouts"]
    
    assign(dtString_inner,temp)
    
  }
  
  for (i in 1:4)
  {
    wsoString <- paste("WSO",i,sep = "")
    nonwsoString <- paste("Non-",wsoString,sep = "")
    entitywsoString <- paste("Entity",wsoString, sep = "")
    
    temp_State <- data[ EntityFromPublic == 1, .(avg = mean( na.omit(as.double(get(var)))),
                                           q05 = quantile(na.omit(as.double(get(var))),0.05), 
                                           #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                                           q25 = quantile(na.omit(as.double(get(var))),0.25),
                                           q50 = median(na.omit(as.double(get(var)))),
                                           q75 = quantile(na.omit(as.double(get(var))),0.75),
                                           #q90 = quantile(na.omit(as.double(get(var))),0.9),
                                           q95 = quantile(na.omit(as.double(get(var))),0.95)),
                  by = c("State",entitywsoString,"EntityAge")]
    
    subplotString <- paste(wsoString," vs ",nonwsoString, sep = "")
    
    temp_State[ get(entitywsoString) == 1, group := "Left"]
    temp_State[ get(entitywsoString) == 0, group := "Right"]
    temp_State[ , subplot := subplotString]
    temp_State[ , (entitywsoString) := NULL]
    
    temp <- data[ EntityFromPublic == 1, .(avg = mean( na.omit(as.double(get(var)))),
                                                 q05 = quantile(na.omit(as.double(get(var))),0.05), 
                                                 #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                                                 q25 = quantile(na.omit(as.double(get(var))),0.25),
                                                 q50 = median(na.omit(as.double(get(var)))),
                                                 q75 = quantile(na.omit(as.double(get(var))),0.75),
                                                 #q90 = quantile(na.omit(as.double(get(var))),0.9),
                                                 q95 = quantile(na.omit(as.double(get(var))),0.95)),
                        by = c(entitywsoString,"EntityAge")]
    
    temp[ get(entitywsoString) == 1, group := "Left"]
    temp[ get(entitywsoString) == 0, group := "Right"]
    temp[ , subplot := subplotString]
    temp[ , (entitywsoString) := NULL]
    
    outerTemp <- rbind(outerTemp,temp)
    
    outerTemp_State <- rbind(outerTemp_State,temp_State)
    
    for (j in 1:3)
    {
      naicsString <- paste("NAICS1",j,sep = "_")
      dtString_inner <- paste("outerTemp",naicsString, sep = "_")
      
      temp <- data[ EntityFromPublic == 1, .(avg = mean( na.omit(as.double(get(var)))),
                        q05 = quantile(na.omit(as.double(get(var))),0.05), 
                        #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                        q25 = quantile(na.omit(as.double(get(var))),0.25),
                        q50 = median(na.omit(as.double(get(var)))),
                        q75 = quantile(na.omit(as.double(get(var))),0.75),
                        #q90 = quantile(na.omit(as.double(get(var))),0.9),
                        q95 = quantile(na.omit(as.double(get(var))),0.95)),
                    by = c(naicsString,entitywsoString,"EntityAge")]
      
      temp[ get(entitywsoString) == 1, group := "Left"]
      temp[ get(entitywsoString) == 0, group := "Right"]
      temp[ , subplot := subplotString]
      temp[ , (entitywsoString) := NULL]
      
      assign(dtString_inner,rbind(get(dtString_inner),temp))
      
    }
    
  }
  
  assign(varTable,temp)
  
  if (var %in% c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount","lrevenue"))
  {
    ggplot(outerTemp[EntityAge <= 15 & EntityAge >= 3], aes(x = EntityAge, linetype = group)) + 
      geom_line(aes(y = q05, color = "q05")) +
      #geom_line(aes(y = q10, color = "q10")) + 
      geom_line(aes(y = q25, color = "q25")) + 
      geom_line(aes(y = q50, color = "q50")) +
      geom_line(aes(y = q75, color = "q75")) +
      #geom_line(aes(y = q90, color = "q90")) +
      geom_line(aes(y = q95, color = "q95")) +
      #theme(text = element_text(size=14)) +
      #theme(legend.position = "none") +
      ggtitle(paste(var, " by startup age", sep = "")) +
      #ggtitle("Unadjusted") + 
      #xlim(1986,2009) + 
      ylab(paste("Quantiles of ",var,sep = "")) +
      xlab("Years") + 
      facet_wrap(.~subplot, ncol = 2)
    
    filePath = paste("../figures/startupLifeCycle_",var,".pdf",sep = "")
    
    ggsave(filePath, plot = last_plot(), device = "pdf")
    
    ggplot(outerTemp_State[EntityAge <= 15 & EntityAge >= 3 & State %in% LargestStates], aes(x = EntityAge, linetype = group)) + 
      geom_line(aes(y = q05, color = "q05")) +
      #geom_line(aes(y = q10, color = "q10")) + 
      geom_line(aes(y = q25, color = "q25")) + 
      geom_line(aes(y = q50, color = "q50")) +
      geom_line(aes(y = q75, color = "q75")) +
      #geom_line(aes(y = q90, color = "q90")) +
      geom_line(aes(y = q95, color = "q95")) +
      #theme(text = element_text(size=14)) +
      #theme(legend.position = "none") +
      ggtitle(paste(var, " by startup age", sep = "")) +
      #ggtitle("Unadjusted") + 
      #xlim(1986,2009) + 
      ylab(paste("Quantiles of ",var,sep = "")) +
      xlab("Years") + 
      facet_wrap(State~subplot, ncol = 5)
    
    filePath = paste("../figures/startupLifeCycle_State_",var,".pdf",sep = "")
    
    ggsave(filePath, plot = last_plot(), device = "pdf")
    
    for (j in 1:3) 
    {
      naicsString <- paste("NAICS1",j,sep = "_")
      dtString_inner <- paste("outerTemp",naicsString, sep = "_")
      naicsListString <- paste("LargestIndustries",j,sep = "_")
      
      ggplot(get(dtString_inner)[EntityAge <= 15 & EntityAge >= 3 & get(naicsString) %in% get(naicsListString)], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = q05, color = "q05")) +
        #geom_line(aes(y = q10, color = "q10")) + 
        geom_line(aes(y = q25, color = "q25")) + 
        geom_line(aes(y = q50, color = "q50")) +
        geom_line(aes(y = q75, color = "q75")) +
        #geom_line(aes(y = q90, color = "q90")) +
        geom_line(aes(y = q95, color = "q95")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Years") + 
        facet_wrap(get(naicsString)~subplot, ncol = 5)
      
      filePath = paste("../figures/startupLifeCycle_", naicsString, "_", var, ".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf")
    }
  } else
  {
    ggplot(outerTemp[EntityAge <= 15 & EntityAge >= 3], aes(x = EntityAge, linetype = group)) + 
      geom_line(aes(y = avg, color = "avg")) +
      #theme(text = element_text(size=14)) +
      #theme(legend.position = "none") +
      ggtitle(paste(var, " by startup age", sep = "")) +
      #ggtitle("Unadjusted") + 
      #xlim(1986,2009) + 
      ylab(paste("Quantiles of ",var,sep = "")) +
      xlab("Years") + 
      facet_wrap(.~subplot, ncol = 2)
    
    filePath = paste("../figures/startupLifeCycle_",var,".pdf",sep = "")
    
    ggsave(filePath, plot = last_plot(), device = "pdf")
    
    ggplot(outerTemp_State[EntityAge <= 15 & EntityAge >= 3 & State %in% LargestStates], aes(x = EntityAge, linetype = group)) + 
      geom_line(aes(y = avg, color = "avg")) +
      #theme(text = element_text(size=14)) +
      #theme(legend.position = "none") +
      ggtitle(paste(var, " by startup age", sep = "")) +
      #ggtitle("Unadjusted") + 
      #xlim(1986,2009) + 
      ylab(paste("Quantiles of ",var,sep = "")) +
      xlab("Years") + 
      facet_wrap(State~subplot, ncol = 5)
    
    filePath = paste("../figures/startupLifeCycle_State_",var,".pdf",sep = "")
    
    ggsave(filePath, plot = last_plot(), device = "pdf")
    
    for (j in 1:3) 
    {
      naicsString <- paste("NAICS1",j,sep = "_")
      dtString_inner <- paste("outerTemp",naicsString, sep = "_")
      naicsListString <- paste("LargestIndustries",j,sep = "_")
      
      ggplot(get(dtString_inner)[EntityAge <= 15 & EntityAge >= 3 & get(naicsString) %in% get(naicsListString)], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg, color = "avg")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Years") + 
        facet_wrap(get(naicsString)~subplot, ncol = 5)
      
      filePath = paste("../figures/startupLifeCycle_", naicsString, "_", var, ".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf")
    }
  }
}


#---------------------------#
# Plotting vs year, rather than vs firm age
#---------------------------#

data_overTime <- data[ EntityAge >= 1 & year >= 1993 & year <= 2015]
#dataOverTime <- data[EntityAge >= 3 & EntityAge <= 20]

for (var in c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount",
              "lrevenue","lrevenuedivEmployeeCount","goingOutOfBusiness"))
{
  varTable <- paste("data_overTime_",var,sep = "")
  outerTemp <- data_overTime[ , .(avg = mean( na.omit(as.double(get(var)))),
                         q05 = quantile(na.omit(as.double(get(var))),0.05), 
                         #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                         q25 = quantile(na.omit(as.double(get(var))),0.25),
                         q50 = median(na.omit(as.double(get(var)))),
                         q75 = quantile(na.omit(as.double(get(var))),0.75),
                         #q90 = quantile(na.omit(as.double(get(var))),0.9),
                         q95 = quantile(na.omit(as.double(get(var))),0.95)),
                     by = .(EntityFromPublic,year)]
  
  #outerTemp <- melt(outerTemp, id.vars = c("EntityFromPublic","EntityAge"), measure.vars = c("q03","q10","q25","q50","q75","q90","q97","avg"))
  
  outerTemp[ EntityFromPublic == 1, group := "Left"]
  outerTemp[EntityFromPublic == 0, group := "Right"]
  outerTemp[ , EntityFromPublic := NULL]
  outerTemp[ , subplot := "Spinouts vs Non-Spinouts"]
  
  for (i in 1:4)
  {
    wsoString <- paste("WSO",i,sep = "")
    nonwsoString <- paste("Non-",wsoString,sep = "")
    entitywsoString <- paste("Entity",wsoString, sep = "")
    
    temp <- data_overTime[ EntityFromPublic == 1, .(avg = mean( na.omit(as.double(get(var)))),
                                           q05 = quantile(na.omit(as.double(get(var))),0.05), 
                                           #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                                           q25 = quantile(na.omit(as.double(get(var))),0.25),
                                           q50 = median(na.omit(as.double(get(var)))),
                                           q75 = quantile(na.omit(as.double(get(var))),0.75),
                                           #q90 = quantile(na.omit(as.double(get(var))),0.9),
                                           q95 = quantile(na.omit(as.double(get(var))),0.95)),
                  by = c(entitywsoString,"year")]
    
    subplotString <- paste(wsoString," vs ",nonwsoString, sep = "")
    
    temp[ get(entitywsoString) == 1, group := "Left"]
    temp[ get(entitywsoString) == 0, group := "Right"]
    temp[ , subplot := subplotString]
    
    temp[ , (entitywsoString) := NULL]
    
    outerTemp <- rbind(outerTemp,temp)
    
  }
  
  assign(varTable,temp)
  
  if (var %in% c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount","lrevenue"))
  {
    ggplot(outerTemp[year >= 1986], aes(x = year, linetype = group)) + 
      geom_line(aes(y = q05, color = "q05")) +
      #geom_line(aes(y = q10, color = "q10")) + 
      geom_line(aes(y = q25, color = "q25")) + 
      geom_line(aes(y = q50, color = "q50")) +
      geom_line(aes(y = q75, color = "q75")) +
      #geom_line(aes(y = q90, color = "q90")) +
      geom_line(aes(y = q95, color = "q95")) +
      #theme(text = element_text(size=14)) +
      #theme(legend.position = "none") +
      ggtitle(paste(var, " by year", sep = "")) +
      #ggtitle("Unadjusted") + 
      #xlim(1986,2009) + 
      ylab(paste("Quantiles of ",var,sep = "")) +
      xlab("Year") + 
      facet_wrap(.~subplot, ncol = 2)
    
  } else
  {
    ggplot(outerTemp[year >= 1986], aes(x = year, linetype = group)) + 
      geom_line(aes(y = avg, color = "avg")) +
      #theme(text = element_text(size=14)) +
      #theme(legend.position = "none") +
      ggtitle(paste(var, " by year", sep = "")) +
      #ggtitle("Unadjusted") + 
      #xlim(1986,2009) + 
      ylab(paste("Mean of ",var,sep = "")) +
      xlab("Year") + 
      facet_wrap(.~subplot, ncol = 2)
  }
  
  filePath = paste("../figures/startupOverTime_",var,".pdf",sep = "")
  
  ggsave(filePath, plot = last_plot(), device = "pdf")

}






## First make scatter plot

#ggplot(data[ !is.na(lEmployeeCount)],aes(x = EntityAge, y = lEmployeeCount)) + 
#  geom_point(size = 0.1)




ggplot(averageEmployeeCountsWSO4[!is.na(EntityWso4) & EntityAge <= 15], aes(x = EntityAge, group = group, color = group)) + 
  geom_line(aes(y = q03, linetype = "q03")) +
  geom_line(aes(y = q10, linetype = "q10")) + 
  geom_line(aes(y = q25, linetype = "q25")) + 
  geom_line(aes(y = q50, linetype = "q50")) +
  geom_line(aes(y = q75, linetype = "q75")) +
  geom_line(aes(y = q90, linetype = "q90")) +
  geom_line(aes(y = q97, linetype = "q97")) +
  #theme(text = element_text(size=14)) +
  #theme(legend.position = "none") +
  ggtitle("Employment paths for WSO4 and non-WSO4 (excl. non-spinouts)") +
  #ggtitle("Unadjusted") + 
  #xlim(1986,2009) + 
  ylab("Quantiles of log employment") +
  xlab("Firm age")


