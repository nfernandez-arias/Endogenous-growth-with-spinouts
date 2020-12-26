

data <- fread("data/VentureSource/startupsPaths.csv")

parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")

parentsSpinouts[ , NAICS1_4 := substr(NAICS1,1,4)]
parentsSpinouts[ , NAICS1_3 := substr(NAICS1,1,3)]
parentsSpinouts[ , NAICS1_2 := substr(NAICS1,1,2)]
parentsSpinouts[ , NAICS1_1 := substr(NAICS1,1,1)]
  
tempvarlist <- c()
      
#---------------------------#
# For each definition of founder, 
# construct entity-level indicator which
# denotes whether there is at least oneTable \ref{table:GStable_founder2} shows that WSO founders account for roughly 10\% of all founders
# founder from public, or from WSOi for i = 1:4
#---------------------------@
              
for (founderType in c("all","founder2","technical","executive"))
{
  entityfounderString <- paste("Entity_",founderType,sep = "")
  entityfounderCountString <- paste("Entity_",founderType,"_count",sep = "")
  entityfounderFromPublicString <- paste(entityfounderString,"_fromPublic", sep = "")
  
  # Construct flag as from public if at least startupSpinoutFounderFraction of founders are from public
  
  parentsSpinouts[ , (entityfounderString) := max(get(founderType)), by = EntityID]
  
  parentsSpinouts[ , (entityfounderCountString) := sum(na.omit(get(founderType))), by = EntityID]
  
  parentsSpinouts[ , (entityfounderFromPublicString) := sum(fromPublic * get(founderType)) / sum(get(founderType)), 
                   by = EntityID]
  
  #parentsSpinouts[ get(entityfounderFromPublicString) >= startupSpinoutFounderFraction & get(entityfounderString) == 1,
   #                (entityfounderFromPublicString) := 1]
  
  #parentsSpinouts[ get(entityfounderFromPublicString) < startupSpinoutFounderFraction & get(entityfounderString) == 1,
    #               (entityfounderFromPublicString) := 0]
  
  parentsSpinouts[ get(entityfounderString) == 0, (entityfounderFromPublicString) := NA]
  
  #parentsSpinouts[ , (entityfounderFromPublicString) := max(get(entityfounderString) * fromPublic), by = EntityID]
      
  for (i in 1:4)
  {
    wsoLowerCase <- paste("wso",i,sep = "")
    wsoString <- paste("WSO",i,sep = "")
    entitywsoString <- paste("Entity_",founderType,"_",wsoString, sep = "")
  
    # Construct flag as WSOi if at least startupSpinoutFounderFraction of founders of founderType as WSOi
    parentsSpinouts[ , (entitywsoString) := sum(get(wsoLowerCase) * fromPublic * get(founderType)) /sum(get(founderType)), 
                     by = EntityID]
    #parentsSpinouts[ get(entitywsoString) >= startupSpinoutFounderFraction & get(entitywsoString) != Inf, 
    #                 (entitywsoString) := 1]
    #parentsSpinouts[ get(entitywsoString) < startupSpinoutFounderFraction & get(entitywsoString) != Inf, 
    #                 (entitywsoString) := 0]
    parentsSpinouts[ get(entityfounderString) == 0, (entitywsoString) := NA ]
    
    #parentsSpinouts[ , (entitywsoString) := max(get(wsoLowerCase) * get(founderType)) , by = EntityID]
    
    tempvarlist <- c(tempvarlist,entitywsoString)
    
  }
  
  tempvarlist <- c(tempvarlist,entityfounderString,entityfounderCountString,entityfounderFromPublicString) 
  
}

#---------------------------#
# Merge with data on entity paths
#---------------------------#

spinoutsID <- unique(parentsSpinouts[ , c("EntityID","NAICS1_1","NAICS1_2","NAICS1_3","NAICS1_4",tempvarlist), with = FALSE])

setkey(spinoutsID,EntityID)

setkey(data,EntityID)

data <- spinoutsID[data]
    
# Export for regression analysis
fwrite(data,"data/VentureSource/startupsPathsStata_11-11.csv")
#write.dta(data,"data/VentureSource/startupPathsStata.dta")


#---------------------------#
# Construct m-distribution
#---------------------------#

# In each industry-year, count the number of startups still in operation and that have not been acquired
# Could also count those that are still in product development, but might have modify something earlier 
# in the data pipeline

# Only include observations with industry information
data_temp <- data[ nchar(NAICS1_4) == 4 &  year >= 1986 & year <= 2008]

# Ensure that observations with zero employees contribute nothing to employee count
data_temp[ lEmployeeCount == -Inf, lEmployeeCount := NA]
industryYearCounts <- data_temp[ , .(count = .N, employees = sum(na.omit(exp(lEmployeeCount))), valuation = sum(na.omit(exp(lPostValUSD)))), by = .(NAICS1_4,year)]


# Make bar plot of employee counts, and startup counts, for each industry
p1 <- ggplot(industryYearCounts, aes(x = as.character(NAICS1_4), y = employees)) + 
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

p2 <- ggplot(industryYearCounts, aes(x = as.character(NAICS1_4), y = count)) + 
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

p3 <- ggplot(industryYearCounts, aes(x = as.character(NAICS1_4), y = valuation)) + 
  geom_bar(stat = "identity") + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))

p <- grid.arrange(p1,p2,p3)

compustat <- fread("data/compustat-spinouts_Stata.csv")[ , .(gvkey, year, emp, naics4, naics1)]

compustatIndustryYearCounts <- compustat[ , .(countCompustat = .N, employeesCompustat = sum(na.omit(emp)), naics1 = naics1), by = .(naics4,year)]


# Merge
setkey(compustatIndustryYearCounts,naics4,year)
setkey(industryYearCounts,NAICS1_4,year)


industryYearCounts <- compustatIndustryYearCounts[industryYearCounts]

industryYearCounts[ , countFrac := count / countCompustat]
industryYearCounts[ , employeesFrac := employees / employeesCompustat]

industryYearCounts[ employeesFrac == Inf, employeesFrac := NA]
industryYearCounts[ countFrac == Inf, countFrac := NA]

ggplot(industryYearCounts[year == 1993 & (naics1 == 3 | naics1 == 5)], aes(x = employeesFrac)) + 
  #geom_histogram(bins = 100) + 
  geom_density() + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1))
  #facet_wrap(~year, nrow = 4)

industryYearCounts[ , employeesFracNormalized := (employeesFrac - mean(na.omit(employeesFrac))) / sd(na.omit(employeesFrac)), by = naics4 ]
industryYearCounts[ , countFracNormalized := (countFrac - mean(na.omit(countFrac))) / sd(na.omit(countFrac)), by = naics4 ]
industryYearCounts[ countFracNormalized == Inf, countFracNormalized := NA]
industryYearCounts[ employeesFracNormalized == Inf, employeesFracNormalized := NA]
industryYearCounts[ employeesFrac == Inf, employeesFrac := NA]
  
ggplot(industryYearCounts[ year >= 1986 & year <= 2008 & (naics1 == 3 | naics1 == 5)], aes(x = year, y = countFracNormalized)) + 
  geom_line() + 
  theme(axis.text.x = element_text(angle = 90, hjust = 1)) + 
  facet_wrap(~naics4, nrow = 4)

industryYearCounts.lm = lm(formula = countFrac ~ as.factor(year) + as.factor(naics4), na.action = na.exclude, data = industryYearCounts[ year >= 1986 & year <= 2008 & (naics1 == 3 | naics1 == 5)])

industryYearCounts.res = resid(industryYearCounts.lm)


#---------------------------#
# Make plots!
#---------------------------#

data_store <- data

entityMinAge <- 0

for (founderType in c("all","founder2","executive","technical"))
{
  
  # Consider the universe of startups that have at least one "founder"  
  # under the four definitions of founder
  entityfounderString <- paste("Entity_",founderType,sep = "")
  data <- data_store[ get(entityfounderString) == 1]
  
  entityfounderFromPublicString <- paste(entityfounderString,"_fromPublic", sep = "")
  
  #---------------------------------------------#
  # Make plots of startup success
  # metric vs. startup age.
  #---------------------------------------------#
  
  for (var in c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount",
                "lrevenue","lrevenuedivEmployeeCount","goingOutOfBusiness","successfullyExiting"))
  {
    
    # First calculate unconditional -- nothing vs age
    varNum <- paste0(founderType,"_",var,"_unconditional")
    assign(varNum,data[ EntityAge >= entityMinAge , mean(na.omit(as.double(get(var)))), by = get(entityfounderFromPublicString)])
    
    
    varTable <- paste("data_",var,sep = "")
    outerTemp_State <- data[ , .(avg = mean( na.omit(as.double(get(var)))),
                                 q05 = quantile(na.omit(as.double(get(var))),0.05), 
                                 #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                                 q25 = quantile(na.omit(as.double(get(var))),0.25),
                                 q50 = median(na.omit(as.double(get(var)))),
                                 q75 = quantile(na.omit(as.double(get(var))),0.75),
                                 #q90 = quantile(na.omit(as.double(get(var))),0.9),
                                 q95 = quantile(na.omit(as.double(get(var))),0.95)),
                             by = c("State",entityfounderFromPublicString,"EntityAge")]
    
    outerTemp_State[ get(entityfounderFromPublicString) == 1, group := "Left"]
    outerTemp_State[ get(entityfounderFromPublicString) == 0, group := "Right"]
    outerTemp_State[ , (entityfounderFromPublicString) := NULL]
    outerTemp_State[ , subplot := "Spinouts vs Non-Spinouts"]
    
    outerTemp <- data[ , .(avg = mean( na.omit(as.double(get(var)))),
                           q05 = quantile(na.omit(as.double(get(var))),0.05), 
                           #q10 = quantile(na.omit(as.double(get(var))),0.1), 
                           q25 = quantile(na.omit(as.double(get(var))),0.25),
                           q50 = median(na.omit(as.double(get(var)))),
                           q75 = quantile(na.omit(as.double(get(var))),0.75),
                           #q90 = quantile(na.omit(as.double(get(var))),0.9),
                           q95 = quantile(na.omit(as.double(get(var))),0.95)),
                       by = c(entityfounderFromPublicString,"EntityAge")]
    
    outerTemp[ get(entityfounderFromPublicString) == 1, group := "Left"]
    outerTemp[ get(entityfounderFromPublicString) == 0, group := "Right"]
    outerTemp[ , (entityfounderFromPublicString) := NULL]
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
                    by = c(naicsString,entityfounderFromPublicString,"EntityAge")]
      
      temp[ get(entityfounderFromPublicString) == 1, group := "Left"]
      temp[ get(entityfounderFromPublicString) == 0, group := "Right"]
      temp[ , (entityfounderFromPublicString) := NULL]
      temp[ , subplot := "Spinouts vs Non-Spinouts"]
      
      assign(dtString_inner,temp)
      
    }
    
    for (i in 1:4)
    {
      wsoString <- paste("WSO",i,sep = "")
      nonwsoString <- paste("Non-",wsoString,sep = "")
      
      entitywsoString <- paste("Entity_",founderType,"_",wsoString, sep = "")
      
      temp_State <- data[ get(entityfounderFromPublicString) == 1, .(avg = mean( na.omit(as.double(get(var)))),
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
      
      temp <- data[ get(entityfounderFromPublicString) == 1, .(avg = mean( na.omit(as.double(get(var)))),
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
        
        temp <- data[ get(entityfounderFromPublicString) == 1, .(avg = mean( na.omit(as.double(get(var)))),
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
    
    if (var %in% c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount","lrevenue","lrevenuedivEmployeeCount"))
    {
      ggplot(outerTemp[EntityAge <= 15 & EntityAge >= entityMinAge], aes(x = EntityAge, linetype = group)) + 
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
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(.~subplot, ncol = 2)
      
      filePath = paste("figures/plots/startupLifeCycle_",founderType,"_",var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      ggplot(outerTemp[EntityAge <= 15 & EntityAge >= entityMinAge], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg, color = "avg")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Mean ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(.~subplot, ncol = 2)
      
      filePath = paste("figures/plots/startupLifeCycle_",founderType,"_avg_",var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      outerTemp_1 <- outerTemp[(EntityAge <= 15 & EntityAge >= entityMinAge) & (subplot == "Spinouts vs Non-Spinouts" | subplot == "WSO4 vs Non-WSO4")]
      outerTemp_1[ subplot == "Spinouts vs Non-Spinouts" & group == "Left", group := "Spinouts"]
      outerTemp_1[ subplot == "Spinouts vs Non-Spinouts" & group == "Right", group := "Other startups"]
      outerTemp_1[ subplot == "Spinouts vs Non-Spinouts" , subplot := "SvNoS"]
      outerTemp_1[ subplot == "WSO4 vs Non-WSO4" & group == "Left", group := "WSO4 Spinouts"]
      outerTemp_1[ subplot == "WSO4 vs Non-WSO4" & group == "Right", group := "Non-WSO4 Spinouts"]
      outerTemp_1[ subplot == "WSO4 vs Non-WSO4", subplot := "WSO4vNoWSO4"]
      
      labels <- c("Spinouts vs Non-Spinouts", "WSO4 vs Non-WSO4")
      names(labels) <- c("SvNoS","WSO4vNoWSO4")
      
      outerTemp_1 <- split(outerTemp_1, f = outerTemp_1$subplot)
      
      p1 <- ggplot(outerTemp_1$SvNoS, aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg)) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +  
        ggtitle(paste0("Mean ", var, " by startup age")) +
        theme(legend.position = "bottom") +
        guides(linetype = guide_legend(title = "Legend")) +  
        #theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Mean ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap( ~subplot, ncol = 2, labeller = labeller(subplot = labels)) 
        
      p2 <- p1 %+% outerTemp_1$WSO4vNoWSO4
      
      p3 <- grid.arrange(p1,p2, nrow = 1)
      
      filePath = paste("figures/plots/startupLifeCycle_",founderType,"_avg_SvNoS_WSO4vNoWSO4_",var,".pdf",sep = "")
      
      ggsave(filePath, plot = p3, device = "pdf", width = 10, height = 4, units = "in")
      
      ggplot(outerTemp_State[EntityAge <= 15 & EntityAge >= entityMinAge & State %in% LargestStates], aes(x = EntityAge, linetype = group)) + 
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
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(State~subplot, ncol = 5)
      
      filePath = paste("figures/plots/startupLifeCycle_", founderType, "_State_", var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      ggplot(outerTemp_State[EntityAge <= 15 & EntityAge >= entityMinAge & State %in% LargestStates], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg, color = "avg")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Mean ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(State~subplot, ncol = 5)
      
      filePath = paste("figures/plots/startupLifeCycle_", founderType, "_avg", "_State_", var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      for (j in 1:3) 
      {
        naicsString <- paste("NAICS1",j,sep = "_")
        dtString_inner <- paste("outerTemp",naicsString, sep = "_")
        naicsListString <- paste("LargestIndustries",j,sep = "_")
        
        ggplot(get(dtString_inner)[EntityAge <= 15 & EntityAge >= entityMinAge & get(naicsString) %in% get(naicsListString)], aes(x = EntityAge, linetype = group)) + 
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
          theme(plot.title = element_text(hjust = 0.5)) +
          #ggtitle("Unadjusted") + 
          #xlim(1986,2009) + 
          ylab(paste("Quantiles of ",var,sep = "")) +
          xlab("Age") + 
          facet_wrap(get(naicsString)~subplot, ncol = 5)
        
        filePath = paste("figures/plots/startupLifeCycle_", founderType, "_", naicsString, "_", var, ".pdf",sep = "")
        
        ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
        
        ggplot(get(dtString_inner)[EntityAge <= 15 & EntityAge >= entityMinAge & get(naicsString) %in% get(naicsListString)], aes(x = EntityAge, linetype = group)) + 
          geom_line(aes(y = avg, color = "avg")) +
          #theme(text = element_text(size=14)) +
          #theme(legend.position = "none") +
          ggtitle(paste(var, " by startup age", sep = "")) +
          theme(plot.title = element_text(hjust = 0.5)) +
          #ggtitle("Unadjusted") + 
          #xlim(1986,2009) + 
          ylab(paste("Mean ",var,sep = "")) +
          xlab("Age") + 
          facet_wrap(get(naicsString)~subplot, ncol = 5)
        
        filePath = paste("figures/plots/startupLifeCycle_", founderType, "_avg_", naicsString, "_", var, ".pdf",sep = "")
        
        ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      }
    } else
    {
      ggplot(outerTemp[EntityAge <= 15 & EntityAge >= entityMinAge], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg, color = "avg")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(.~subplot, ncol = 2)
      
      filePath = paste("figures/plots/startupLifeCycle_",founderType,"_",var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      # Just S v no S and WSO4 vs no WSO4
      
      outerTemp_1 <- outerTemp[(EntityAge <= 15 & EntityAge >= entityMinAge) & (subplot == "Spinouts vs Non-Spinouts" | subplot == "WSO4 vs Non-WSO4")]
      outerTemp_1[ subplot == "Spinouts vs Non-Spinouts" & group == "Left", group := "Spinouts"]
      outerTemp_1[ subplot == "Spinouts vs Non-Spinouts" & group == "Right", group := "Other startups"]
      outerTemp_1[ subplot == "Spinouts vs Non-Spinouts" , subplot := "SvNoS"]
      outerTemp_1[ subplot == "WSO4 vs Non-WSO4" & group == "Left", group := "WSO4 Spinouts"]
      outerTemp_1[ subplot == "WSO4 vs Non-WSO4" & group == "Right", group := "Non-WSO4 Spinouts"]
      outerTemp_1[ subplot == "WSO4 vs Non-WSO4", subplot := "WSO4vNoWSO4"]
      
      labels <- c("Spinouts vs Non-Spinouts", "WSO4 vs Non-WSO4")
      names(labels) <- c("SvNoS","WSO4vNoWSO4")
      
      outerTemp_1 <- split(outerTemp_1, f = outerTemp_1$subplot)
      
      p1 <- ggplot(outerTemp_1$SvNoS, aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg)) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +  
        #ggtitle(paste0("Hazard rate of ", var, " by startup age")) +
        theme(legend.position = "bottom") +
        guides(linetype = guide_legend(title = "Legend")) +  
        #theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Hazard rate of ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap( ~subplot, ncol = 2, labeller = labeller(subplot = labels)) 
      
      p2 <- p1 %+% outerTemp_1$WSO4vNoWSO4
      
      p3 <- grid.arrange(p1,p2, nrow = 1)
      
      filePath = paste("figures/plots/startupLifeCycle_",founderType,"_avg_SvNoS_WSO4vNoWSO4_",var,".pdf",sep = "")
      
      ggsave(filePath, plot = p3, device = "pdf", width = 10, height = 4, units = "in")
      
        # State
      
      ggplot(outerTemp[EntityAge <= 15 & EntityAge >= entityMinAge], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg, color = "avg")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(.~subplot, ncol = 2)
      
      filePath = paste("figures/plots/startupLifeCycle_",founderType,"_",var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      
      ggplot(outerTemp_State[EntityAge <= 15 & EntityAge >= entityMinAge & State %in% LargestStates], aes(x = EntityAge, linetype = group)) + 
        geom_line(aes(y = avg, color = "avg")) +
        #theme(text = element_text(size=14)) +
        #theme(legend.position = "none") +
        ggtitle(paste(var, " by startup age", sep = "")) +
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Quantiles of ",var,sep = "")) +
        xlab("Age") + 
        facet_wrap(State~subplot, ncol = 5)
      
      filePath = paste("figures/plots/startupLifeCycle_", founderType, "_State_", var,".pdf",sep = "")
      
      ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      
      for (j in 1:3) 
      {
        naicsString <- paste("NAICS1",j,sep = "_")
        dtString_inner <- paste("outerTemp",naicsString, sep = "_")
        naicsListString <- paste("LargestIndustries",j,sep = "_")
        
        ggplot(get(dtString_inner)[EntityAge <= 15 & EntityAge >= entityMinAge & get(naicsString) %in% get(naicsListString)], aes(x = EntityAge, linetype = group)) + 
          geom_line(aes(y = avg, color = "avg")) +
          #theme(text = element_text(size=14)) +
          #theme(legend.position = "none") +
          ggtitle(paste(var, " by startup age", sep = "")) +
          theme(plot.title = element_text(hjust = 0.5)) +
          #ggtitle("Unadjusted") + 
          #xlim(1986,2009) + 
          ylab(paste("Quantiles of ",var,sep = "")) +
          xlab("Age") + 
          facet_wrap(get(naicsString)~subplot, ncol = 5)
        
        filePath = paste("figures/plots/startupLifeCycle_", founderType, "_", naicsString, "_", var, ".pdf",sep = "")
        
        ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
      }
    }
  }
  
  #---------------------------#
  # Plotting vs year, rather than vs firm age
  #---------------------------#
  
  data_overTime <- data[ EntityAge >= 1 & year >= 1993 & year <= 2015]
  #dataOverTime <- data[EntityAge >= 3 & EntityAge <= 20]
  
  for (var in c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount",
                "lrevenue","lrevenuedivEmployeeCount","goingOutOfBusiness","successfullyExiting"))
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
                                by = c(entityfounderFromPublicString,"year")]
    
    #outerTemp <- melt(outerTemp, id.vars = c("EntityFromPublic","EntityAge"), measure.vars = c("q03","q10","q25","q50","q75","q90","q97","avg"))
    
    outerTemp[ get(entityfounderFromPublicString) == 1, group := "Left"]
    outerTemp[ get(entityfounderFromPublicString) == 0, group := "Right"]
    outerTemp[ , (entityfounderFromPublicString) := NULL]
    outerTemp[ , subplot := "Spinouts vs Non-Spinouts"]
    
    for (i in 1:4)
    {
      wsoString <- paste("WSO",i,sep = "")
      nonwsoString <- paste("Non-",wsoString,sep = "")
      entitywsoString <- paste("Entity_",founderType,"_",wsoString, sep = "")
      
      temp <- data_overTime[ get(entityfounderFromPublicString)== 1, .(avg = mean( na.omit(as.double(get(var)))),
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
    
    if (var %in% c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount","lrevenue","lrevenuedivEmployeeCount"))
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
        theme(plot.title = element_text(hjust = 0.5)) +
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
        theme(plot.title = element_text(hjust = 0.5)) +
        #ggtitle("Unadjusted") + 
        #xlim(1986,2009) + 
        ylab(paste("Mean of ",var,sep = "")) +
        xlab("Year") + 
        facet_wrap(.~subplot, ncol = 2)
    }
    
    filePath = paste("figures/plots/startupOverTime_", founderType, "_", var,".pdf",sep = "")
    
    ggsave(filePath, plot = last_plot(), device = "pdf", width = 12, height = 8, units = "in")
    
  }
  
}

#-----------------------------#
# Construct table of raw comparisons
#-----------------------------#

for (var in c("lEmployeeCount","lPostValUSD","lPostValUSDdivEmployeeCount",
              "lrevenue","lrevenuedivEmployeeCount","goingOutOfBusiness","successfullyExiting"))
{
  
  outputTableString <- paste0("table_raw_comparison_",var)
  
  outer <- data.table()
  
  for (founderType in c("all","founder2","executive","technical"))
  {
    inputTableString <- paste0(founderType,"_",var,"_unconditional")
    
    temp <- get(inputTableString)$V1
    
    outer <- rbind(outer,t(c(founderType,as.double(temp))))
    
  }
  
  names(outer) <- c("Definition of founder","Spinouts","Other")
  
  outer[ , Other := as.double(Other)]
  outer[ , Spinouts := as.double(Spinouts)]
  
  assign(outputTableString,outer)
    
  captionString <- paste0("Average ",var," by cateogry of startup and by definition of founder. Startups are classified as spinouts if",
                          " at least a fraction ", startupSpinoutFounderFraction ," their founders are from a ",
                          "public firm in Compustat.")
  
  outerXtable <- xtable(outer,align = c("r","p{1.5cm}","c","c"), 
                         caption = captionString, 
                         label = paste0("table:raw_comparison_",var),
                         digits = 2)
  
  filePath <- paste0("figures/tables/",outputTableString,".tex")
  print(outerXtable,filePath, type = "latex", size = "\\small", include.rownames = FALSE, floating = TRUE, booktabs = TRUE, table.placement = "!htb")
  
      
}



      

