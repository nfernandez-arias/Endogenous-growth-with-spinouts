data <- fread("data/compustat-spinouts_Stata.csv")[ , .(gvkey,year,State,naics1,naics2,naics3,naics4,xrd,xrd.l3,founders.founder2.f3, founders.founder2.wso4.f3)]

# Raw fit

data[ , xrd.l3 := xrd.l3 / 1000]
data[ , founders.Prediction := xrd.l3 * 0.7]
data[ , founders.wso4.Prediction := xrd.l3 * 0.4]

data[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
data[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]


ggplot(data[naics1 == 3 | naics1 == 5], aes(x = xrd.l3, y = founders.founder2.f3, color = as.factor(naics1), group = as.factor(naics1))) + 
  geom_point() +
  #geom_text(aes(label = naics1)) + 
  #geom_line(aes(y = founders.Prediction, color = as.factor(naics1))) + 
  geom_smooth(method = "lm", se = FALSE, aes(color = as.factor(naics1))) + 
  #geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending", color = as.factor(naics1))) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at firm-year level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("R&D spending") + 
  ylab("Founders")

ggplot(data[naics1 ==3 | naics1 == 5], aes(x = founders.founder2.f3, y = founders.Prediction, group = as.factor(naics1))) + 
  geom_point(aes(color = as.factor(naics1))) +
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted", color = as.factor(naics1))) + 
  #geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at firm-year level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("Actual founders") + 
  ylab("Predicted founders")

# By company

dataByCompany <-  data[ naics1 == 3 | naics1 == 5, .(naics1 = max(naics1), xrd = sum(xrd), xrd.l3 = sum(xrd.l3), 
                                                     founders.founder2.f3 = sum(na.omit(founders.founder2.f3)), founders.founder2.wso4.f3 = sum(na.omit(founders.founder2.wso4.f3))), 
                        by = .(gvkey)]

dataByCompany[ , founders.Prediction := xrd.l3 * 0.7]
dataByCompany[ , founders.wso4.Prediction := xrd.l3 * 0.4]

dataByCompany[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
dataByCompany[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]

ggplot(dataByCompany, aes(x = founders.founder2.f3, y = founders.Prediction)) + 
  geom_point(aes(size = xrd.l3)) +
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at firm level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("Actual founders") + 
  ylab("Predicted founders")
#theme(legend.position = "bottom")

ggplot(dataByCompany, aes(x = xrd.l3, y = founders.founder2.f3, group = as.factor(naics1))) + 
  geom_point(aes(size = xrd.l3)) +
  geom_text(aes(label = naics1)) + 
  geom_line(aes(y = founders.Prediction)) + 
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted", color = as.factor(naics1))) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending", color = as.factor(naics1))) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at firm level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("R&D spending") + 
  ylab("Founders")


# By industry

dataByIndustry <- data[ naics1 == 3 | naics1 == 5, .(xrd = sum(xrd), xrd.l3 = sum(xrd.l3), 
                            founders.founder2.f3 = sum(na.omit(founders.founder2.f3)), founders.founder2.wso4.f3 = sum(na.omit(founders.founder2.wso4.f3))), 
                        by = .(naics4)]

dataByIndustry[ , founders.Prediction := xrd.l3 * 0.7]
dataByIndustry[ , founders.wso4.Prediction := xrd.l3 * 0.4]

dataByIndustry[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
dataByIndustry[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]

ggplot(dataByIndustry, aes(x = founders.founder2.f3, y = founders.Prediction)) + 
  geom_point(aes(size = xrd.l3)) +
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at 4-digit NAICS level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("Actual founders") + 
  ylab("Predicted founders")
  #theme(legend.position = "bottom")

ggplot(dataByIndustry, aes(x = xrd.l3, y = founders.founder2.wso4.f3)) + 
  geom_point(aes(size = xrd.l3)) +
  geom_line(aes(y = founders.wso4.Prediction)) + 
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at 4-digit NAICS level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("R&D spending") + 
  ylab("Founders")

ggplot(dataByIndustry, aes(x = founders.founder2.wso4.f3, y = founders.wso4.Prediction)) + 
  geom_point(aes(size = xrd.l3)) +
  geom_text(aes(label = naics4)) + 
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at 4-digit NAICS level",
       subtitle = "WSO4 spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") +
  xlab("Actual founders") + 
  ylab("Predicted founders")
#theme(legend.position = "bottom")



# By state 

dataByState <- data[ naics1 == 3 | naics1 == 5, .(xrd = sum(xrd), xrd.l3 = sum(xrd.l3), 
                                                     founders.founder2.f3 = sum(na.omit(founders.founder2.f3)), founders.founder2.wso4.f3 = sum(na.omit(founders.founder2.wso4.f3))), 
                        by = State]

dataByState[ , founders.Prediction := xrd.l3 * 0.7]
dataByState[ , founders.wso4.Prediction := xrd.l3 * 0.4]

dataByState[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
dataByState[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]

ggplot(dataByState, aes(x = founders.founder2.f3, y = founders.Prediction)) + 
  geom_point(aes(size = xrd.l3)) + 
  #geom_text(aes(label = State)) +
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", aes(weight = xrd.l3, linetype = "Weighted by R&D spending"), se = FALSE) +
  #geom_abline(slope = 1) + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending")



  
# By industry-year 

dataByIndustryYear <- data[ , .(naics1 = max(naics1), xrd = sum(xrd), xrd.l3 = sum(xrd.l3), 
                                founders.founder2.f3 = sum(na.omit(founders.founder2.f3)), founders.founder2.wso4.f3 = sum(na.omit(founders.founder2.wso4.f3))), 
                            by = .(naics4,year)]

dataByIndustryYear[ , founders.Prediction := xrd.l3 * 0.7]
dataByIndustryYear[ , founders.wso4.Prediction := xrd.l3 * 0.4]

dataByIndustryYear[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
dataByIndustryYear[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]

ggplot(dataByIndustryYear[ (naics3 == 322 | naics3 == 324 | naics3 == 325 | naics3 == 333 | naics3 == 334 | naics3 == 336 | naics3 == 511 | naics3 == 517 | naics3 == 519 | naics3 == 541) & year <= 2006], aes(x = year, y = xrd.l3)) + 
  geom_line(aes(linetype = "xrd.l3")) + 
  scale_linetype_discrete(name = "", labels = "R&D") + 
  labs(title = "Real effective R&D spending by year", 
       subtitle = "Billions 2014 USD deflated by cumulative productivity growth since 2014, averaged over t,t-1,t-2") + 
  theme(legend.position = "bottom") + 
  xlab("Year") + 
  ylab("Total expenditure") + 
  facet_wrap( vars(naics4))


dataByIndustryYear2 <- dataByIndustryYear[naics4 == 3241 | naics4 == 3252 | naics4 == 3254 | naics4 == 3333 | naics4 == 3341 | naics4 == 3342 | naics4 == 3344 | naics4 == 3345 | naics4 == 3361 | naics4 == 3364 | naics4 == 5112 | naics4 == 5171 | naics4 == 5191 | naics4 == 5415 | naics4 == 5417]

ggplot( dataByIndustryYear2[ year <= 2006], aes(x = year, y = xrd.l3)) + 
  geom_line(aes(linetype = "xrd.l3")) + 
  scale_linetype_discrete(name = "", labels = "R&D") + 
  labs(title = "Real effective R&D spending by year", 
       subtitle = "Billions 2014 USD deflated by cumulative productivity growth since 2014, averaged over t,t-1,t-2") + 
  theme(legend.position = "bottom") + 
  xlab("Year") + 
  ylab("Total expenditure") + 
  facet_wrap( vars(naics4))

ggplot(dataByIndustryYear2[ year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.Prediction, linetype = "founders.Prediction")) + 
  geom_line(aes(y = founders.founder2.f3, linetype = "founders.founder2.f3")) + 
  scale_linetype_discrete(name = "", labels = c("Founders","Predicted")) +
  theme(legend.position = "bottom") + 
  labs(title = "R&D generation production of spinouts, by 4-digit NAICS industry",
       subtitle = "Founder counts averaged over t+1,t+2,t+3") + 
  xlab("Year") + 
  ylab("Founders") + 
  facet_wrap(vars(naics4))

ggplot(dataByIndustryYear2[ year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.wso4.Prediction, linetype = "founders.wso4.Prediction")) + 
  geom_line(aes(y = founders.founder2.wso4.f3, linetype = "founders.founder2.wso4.f3")) + 
  scale_linetype_discrete(name = "", labels = c("Founders","Predicted")) +
  theme(legend.position = "bottom") + 
  labs(title = "R&D generation production of WSO4 spinouts, by 4-digit NAICS industry",
       subtitle = "Founder counts averaged over t+1,t+2,t+3") + 
  xlab("Year") + 
  ylab("Founders") + 
  facet_wrap(vars(naics4))


ggplot(dataByIndustryYear2[ year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.Prediction, linetype = "founders.Prediction")) + 
  geom_line(aes(y = founders.founder2.f3, linetype = "founders.founder2.f3")) + 
  scale_linetype_discrete(name = "", labels = c("Founders","Predicted")) +
  theme(legend.position = "bottom") + 
  labs(title = "R&D generation production of spinouts",
       subtitle = "Founder counts averaged over t+1,t+2,t+3") + 
  xlab("Year") + 
  ylab("Founders") + 
  facet_wrap(vars(naics4))

ggplot(dataByIndustryYear2, aes(x = xrd.l3, y = founders.founder2.f3)) + 
  geom_point(aes(size = xrd.l3)) +
  geom_text(aes(label = naics1)) + 
  geom_line(aes(y = founders.Prediction)) + 
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at Industry-year level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("R&D spending") + 
  ylab("Founders")

ggplot(dataByIndustryYear2, aes(x = founders.founder2.f3, y = founders.Prediction)) + 
  geom_point(aes(size = xrd.l3)) + 
  geom_text(aes(label = naics1)) +
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", aes(weight = xrd.l3, linetype = "Weighted by R&D spending"), se = FALSE) +
  #geom_abline(slope = 1) + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending")


# By state-year

dataByStateYear <- data[ , .(xrd = sum(xrd), xrd.l3 = sum(xrd.l3), 
                                founders.founder2.f3 = sum(na.omit(founders.founder2.f3)), founders.founder2.wso4.f3 = sum(na.omit(founders.founder2.wso4.f3))), 
                            by = .(State,year)]


dataByStateYear[ , founders.Prediction := xrd.l3 * 0.7]
dataByStateYear[ , founders.wso4.Prediction := xrd.l3 * 0.4]

dataByStateYear[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
dataByStateYear[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]

ggplot( dataByStateYear[ year <= 2006], aes(x = year, y = xrd.l3)) + 
  geom_line(aes(linetype = "xrd.l3")) + 
  scale_linetype_discrete(name = "", labels = "R&D") + 
  labs(title = "Real effective R&D spending by year", 
       subtitle = "Billions 2014 USD deflated by cumulative productivity growth since 2014, averaged over t,t-1,t-2") + 
  theme(legend.position = "bottom") + 
  xlab("Year") + 
  ylab("Total expenditure") + 
  facet_wrap( vars(State))

ggplot(dataByStateYear[ year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.Prediction, linetype = "founders.Prediction")) + 
  geom_line(aes(y = founders.founder2.f3, linetype = "founders.founder2.f3")) + 
  scale_linetype_discrete(name = "", labels = c("Founders","Predicted")) +
  theme(legend.position = "bottom") + 
  labs(title = "R&D generation production of spinouts, by 4-digit NAICS industry",
       subtitle = "Founder counts averaged over t+1,t+2,t+3") + 
  xlab("Year") + 
  ylab("Founders") + 
  facet_wrap(vars(State))

ggplot(dataByStateYear, aes(x = xrd.l3, y = founders.founder2.f3)) + 
  geom_point(aes(size = xrd.l3)) +
  #geom_text(aes(label = State)) + 
  geom_line(aes(y = founders.Prediction)) + 
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", se = FALSE, aes(weight = xrd.l3, linetype = "Weighted by R&D spending")) +
  #geom_abline(slope = 1) +
  labs(title = "Fit of prediction to data at State-year level",
       subtitle = "All spinouts") + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending") + 
  xlab("R&D spending") + 
  ylab("Founders")

ggplot(dataByStateYear, aes(x = founders.founder2.f3, y = founders.Prediction)) + 
  geom_point(aes(size = xrd.l3)) + 
  #geom_text(aes(label = State)) +
  geom_smooth(method = "lm", se = FALSE, aes(linetype = "Unweighted")) + 
  geom_smooth(method = "lm", aes(weight = xrd.l3, linetype = "Weighted by R&D spending"), se = FALSE) +
  #geom_abline(slope = 1) + 
  scale_linetype_discrete(name = "Regression line") + 
  scale_size_continuous(name = "R&D spending")

# By year

dataByYear <- data[ , .(xrd = sum(xrd), xrd.l3 = sum(xrd.l3), 
                        founders.founder2.f3 = sum(na.omit(founders.founder2.f3)), founders.founder2.wso4.f3 = sum(na.omit(founders.founder2.wso4.f3))), by = year]

dataByYear[ , founders.Prediction := xrd.l3 * 0.7]
dataByYear[ , founders.wso4.Prediction := xrd.l3 * 0.4]

dataByYear[ , founders.Explained :=  founders.Prediction / founders.founder2.f3]
dataByYear[ , founders.wso4.Explained := founders.wso4.Prediction / founders.founder2.wso4.f3]

ggplot(dataByYear[ year <= 2006], aes(x = year, y = xrd.l3)) + 
  geom_line(aes(linetype = "xrd.l3")) + 
  scale_linetype_discrete(name = "", labels = "R&D") + 
  labs(title = "Real effective R&D spending by year", 
       subtitle = "Billions 2014 USD deflated by cumulative productivity growth since 2014, averaged over t,t-1,t-2") + 
  theme(legend.position = "bottom") + 
  xlab("Year") + 
  ylab("Total expenditure")

p1 <- ggplot(dataByYear[ year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.Prediction, linetype = "founders.Prediction")) + 
  geom_line(aes(y = founders.founder2.f3, linetype = "founders.founder2.f3")) + 
  scale_linetype_discrete(name = "", labels = c("Founders","Predicted")) +
  theme(legend.position = "bottom") + 
  labs(title = "R&D generation production of spinouts",
       subtitle = "Founder counts averaged over t+1,t+2,t+3") + 
  xlab("Year") + 
  ylab("Founders")


p2 <- ggplot(dataByYear[ year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.wso4.Prediction, linetype = "founders.wso4.Prediction")) + 
  geom_line(aes(y = founders.founder2.wso4.f3, linetype = "founders.founder2.wso4.f3")) + 
  scale_linetype_discrete(name = "", labels = c("Founders","Predicted")) +
  theme(legend.position = "bottom") + 
  labs(title = "R&D generation of WSO spinouts",
       subtitle = "Founder counts averaged over t+1,t+2,t+3") + 
  xlab("Year") + 
  ylab("Founders")

p3 <- ggplot(dataByYear[year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.Explained * 100, linetype = "founders.Explained")) + 
  scale_linetype_discrete(name = "", labels = c("Percentage of founders explained")) +
  theme(legend.position = "bottom") + 
  labs(title = "Percentage of founders explained",
       subtitle = "Regression prediction divided by actual") + 
  xlab("Year") + 
  ylab("%")


p4 <- ggplot(dataByYear[year <= 2006], aes(x = year)) + 
  geom_line(aes(y = founders.wso4.Explained * 100, linetype = "founders.wso4.Explained")) + 
  scale_linetype_discrete(name = "", labels = c("Percentage of WSO4 founders explained")) +
  theme(legend.position = "bottom") + 
  labs(title = "Percentage of WSO4 founders explained",
       subtitle = "Regression prediction divided by actual") + 
  xlab("Year") + 
  ylab("%")


p <- grid.arrange(p1,p2,p3,p4)

      ggsave("figures/founder2_founders_f3_Accounting.pdf", plot = p, width = 12, height = 8, units = "in")
    