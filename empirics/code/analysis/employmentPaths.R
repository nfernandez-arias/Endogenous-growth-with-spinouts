

data <- fread("data/VentureSource/startupsPaths.csv")

parentsSpinouts <- fread("data/parentsSpinoutsWSO.csv")

parentsSpinouts[ , EntityFromPublic := max(fromPublic), by = "EntityID"]
parentsSpinouts[ , EntityWso4 := max(wso4), by = "EntityID"]

spinoutsID <- unique(parentsSpinouts[ , .(EntityID,EntityFromPublic,EntityWso4)])

setkey(spinoutsID,EntityID)

setkey(data,EntityID)

data <- spinoutsID[data]

averageEmployeeCounts <- data[ , .(avg = mean( na.omit(lEmployeeCount)),
                                  q03 = quantile(na.omit(lEmployeeCount),0.03), 
                                  q10 = quantile(na.omit(lEmployeeCount),0.1), 
                                  q25 = quantile(na.omit(lEmployeeCount),0.25),
                                  q50 = median(na.omit(lEmployeeCount)),
                                  q75 = quantile(na.omit(lEmployeeCount),0.75),
                                  q90 = quantile(na.omit(lEmployeeCount),0.9),
                                  q97 = quantile(na.omit(lEmployeeCount),0.97)),
                               by = .(EntityFromPublic,EntityAge)]

averageEmployeeCounts[ EntityFromPublic == 1, group := "Spinouts"]
averageEmployeeCounts[EntityFromPublic == 0, group := "Non-spinouts"]

averageEmployeeCountsWSO4 <- data[ EntityFromPublic == 1, .(avg = mean( na.omit(lEmployeeCount)),
                                   q03 = quantile(na.omit(lEmployeeCount),0.03), 
                                   q10 = quantile(na.omit(lEmployeeCount),0.1), 
                                   q25 = quantile(na.omit(lEmployeeCount),0.25),
                                   q50 = median(na.omit(lEmployeeCount)),
                                   q75 = quantile(na.omit(lEmployeeCount),0.75),
                                   q90 = quantile(na.omit(lEmployeeCount),0.9),
                                   q97 = quantile(na.omit(lEmployeeCount),0.97)),
                               by = .(EntityWso4,EntityAge)]

averageEmployeeCountsWSO4[ EntityWso4 == 1, group := "WSO4"]
averageEmployeeCountsWSO4[ EntityWso4  == 0, group := "Non-WSO4"]


ggplot(averageEmployeeCounts[!is.na(EntityFromPublic) & EntityAge <= 15], aes(x = EntityAge, group = group, color = group)) + 
  geom_line(aes(y = q03, linetype = "q03")) +
  geom_line(aes(y = q10, linetype = "q10")) + 
  geom_line(aes(y = q25, linetype = "q25")) + 
  geom_line(aes(y = q50, linetype = "q50")) +
  geom_line(aes(y = q75, linetype = "q75")) +
  geom_line(aes(y = q90, linetype = "q90")) +
  geom_line(aes(y = q97, linetype = "q97")) +
  #theme(text = element_text(size=14)) +
  #theme(legend.position = "none") +
  ggtitle("Employment paths for spinouts and non-spinouts") +
  #ggtitle("Unadjusted") + 
  #xlim(1986,2009) + 
  ylab("Quantiles of log employment") +
  xlab("Firm age")

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


