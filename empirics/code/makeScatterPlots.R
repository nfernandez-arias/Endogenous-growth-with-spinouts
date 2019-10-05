
rm(list = ls())

data <- fread("data/compustat-spinouts_Stata.csv")


data[ , xrd_demeaned := xrd - mean(xrd), by = "gvkey"]
data[ , spinoutCount_demeaned := spinoutCount - mean(spinoutCount), by = "gvkey"]
data[ , spinoutCountUnweighted_demeaned := spinoutCountUnweighted - mean(spinoutCountUnweighted), by = "gvkey"]
data[ , spinoutsDFFV_demeaned := spinoutsDiscountedFFValue - mean(spinoutsDiscountedFFValue), by = "gvkey"]

data[ , xrd5_demeaned := xrd_5 - mean(xrd_5), by = "gvkey"]
data[ , spinoutCountUnweighted5_demeaned := spinoutCountUnweighted_5 - mean(spinoutCountUnweighted_5), by = "gvkey"]
data[ , spinoutsDFFV5_demeaned := spinoutsDiscountedFFValue_5 - mean(spinoutsDiscountedFFValue_5), by = "gvkey"]

data[ , xrd_firm_IndustryYearFE := xrd_demeaned - mean(xrd_demeaned), by = c("naics4","year")]
data[ , spinoutCount_firm_IndustryYearFE := spinoutCount_demeaned - mean(spinoutCount_demeaned), by = c("naics4","year")]
data[ , spinoutCountUnweighted_firm_IndustryYearFE := spinoutCountUnweighted_demeaned - mean(spinoutCountUnweighted_demeaned), by = c("naics4","year")]
data[ , spinoutsDFFV_firm_IndustryYearFE := spinoutsDFFV_demeaned - mean(spinoutsDFFV_demeaned), by = c("naics4","year")]

data[ , xrd5_firm_IndustryYearFE := xrd5_demeaned - mean(xrd5_demeaned), by = c("naics4","year")]
data[ , spinoutCountUnweighted5_firm_IndustryYearFE := spinoutCountUnweighted5_demeaned - mean(spinoutCountUnweighted5_demeaned), by = c("naics4","year")]
data[ , spinoutsDFFV5_firm_IndustryYearFE := spinoutsDFFV5_demeaned - mean(spinoutsDFFV5_demeaned), by = c("naics4","year")]

data[ , xrd_allFE := xrd_firm_IndustryYearFE - mean(xrd_firm_IndustryYearFE), by = c("State","year")]
data[ , spinoutCount_allFE := spinoutCount_firm_IndustryYearFE - mean(spinoutCount_firm_IndustryYearFE), by = c("State","year")]
data[ , spinoutCountUnweighted_allFE := spinoutCountUnweighted_firm_IndustryYearFE - mean(spinoutCountUnweighted_firm_IndustryYearFE), by = c("State","year")]
data[ , spinoutsDFFV_allFE := spinoutsDFFV_firm_IndustryYearFE - mean(spinoutsDFFV_firm_IndustryYearFE), by = c("State","year")]

data[ , xrd5_firm_allFE := xrd5_firm_IndustryYearFE - mean(xrd5_firm_IndustryYearFE), by = c("State","year")]
data[ , spinoutCountUnweighted5_allFE := spinoutCountUnweighted5_firm_IndustryYearFE - mean(spinoutCountUnweighted5_firm_IndustryYearFE), by = c("State","year")]
data[ , spinoutsDFFV5_allFE := spinoutsDFFV5_firm_IndustryYearFE== - mean(spinoutsDFFV5_firm_IndustryYearFE), by = c("State","year")]


# Construct scatter plot by state

library(ggplot2)



## Raw OLS

ggplot(data = data, aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout counts") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw.png", plot = last_plot())

ggplot(data = data, aes(x = xrd, y = spinoutCountUnweighted)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout founder counts") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-SpinoutsFounders-1yr-raw.png", plot = last_plot())


## Discounted FF Value  
ggplot(data = data, aes(x = xrd, y = spinoutsDiscountedFFValue)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts valuation") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Valuation (millions $)") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-SpinoutsDFFV-1yr-raw.png", plot = last_plot())


## Demeaned by firm

ggplot(data = data, aes(x = xrd_demeaned, y = spinoutCount_demeaned)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts (firm demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts (deviation)") +
  xlab("R&D spending (millions $) (deviation)")

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-firmFE.png", plot = last_plot())

ggplot(data = data, aes(x = xrd_demeaned, y = spinoutsDFFV_demeaned)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts valuation (firm demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Valuation (millions $)") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-SpinoutsDFFV-1yr-firmFE.png", plot = last_plot())

## All demeaning

ggplot(data = data, aes(x = xrd_allFE, y = spinoutCount_allFE)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout counts (firm, naics4-year, state-year demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts (deviation)") +
  xlab("R&D spending (millions $) (deviation)")

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-allFE.png", plot = last_plot())

ggplot(data = data, aes(x = xrd_allFE, y = spinoutCountUnweighted_allFE)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout founder counts (firm, naics4-year, state-year demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts (deviation)") +
  xlab("R&D spending (millions $) (deviation)")

ggsave("../figures/scatterPlot_RD-SpinoutsFounders-1yr-allFE.png", plot = last_plot())

ggplot(data = data, aes(x = xrd_allFE, y = spinoutsDFFV_allFE)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) +
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts valuation (firm, naics4-year, state-year demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Valuation (millions $)") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-SpinoutsDFFV-1yr-allFE.png", plot = last_plot())


ggplot(data = data[State == "CA" | State == "MA"], aes(x = xrd_allFE, y = spinoutsDFFV_allFE, group = State, color = State)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm", se = TRUE) + 
  theme(text = element_text(size=20)) +
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts valuation (CA and MA, firm, naics4-year, state-year demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Valuation (millions $)") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-SpinoutsDFFV-1yr-allFE_CAandMA.png", plot = last_plot())





ggplot(data = data, aes(x = xrd_5, y = spinoutCountUnweighted_5)) + 
  geom_point(size = 0.3) +
  geom_smooth(method = "lm") +    
  #theme(legend.position = "none") +
  ggtitle("Relationship between R&D spending and spinouts (firm-year observations, 1-year window)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")

ggsave("../figures/scatterPlot_RD-Spinouts-5yr-raw.png", plot = last_plot())


## Firm fixed effects


ggplot(data = data, aes(x = xrd_demeaned, y = spinoutCountUnweighted_demeaned)) + 
  geom_point() +
  geom_smooth(method = "lm") + 
  #theme(legend.position = "none") +
  ggtitle("Relationship between R&D spending and spinouts by state (1-year window, firm fixed effect)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")


ggplot(data = data[State == "CA" | State == "NY" | State == "MI" | State == "NJ" | State == "IL" | State == "MA" | State == "WA"], aes(x = xrd5_demeaned, y = spinoutCountUnweighted5_demeaned, color = State)) + 
  geom_point() +
  geom_smooth(method = "lm") + 
  #theme(legend.position = "none") +
  ggtitle("Relationship between R&D spending and spinouts (5-year window, firm fixed effect)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")



# Firm and 4 digit industry-year fixed effects

ggplot(data = data[State == "CA" | State == "NY" | State == "MI" | State == "NJ" | State == "IL" | State == "MA" | State == "WA"], aes(x = xrd_firm_IndustryYearFE, y = spinoutCountUnweighted_firm_IndustryYearFE, color = State)) + 
  geom_point() +
  geom_smooth(method = "lm") + 
  #theme(legend.position = "none") +
  ggtitle("Relationship between R&D spending and spinouts (1-year window, firm and naics4-year demeaning)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")


data[State == "CA", Calif := "CA"]
data[is.na(Calif), Calif := "Other"]

ggplot(data = data, aes(x = xrd_firm_IndustryYearFE, y = spinoutCountUnweighted_firm_IndustryYearFE, color = Calif)) + 
  geom_point() +
  geom_smooth(method = "lm") +  
  #theme(legend.position = "none") +
  ggtitle("Relationship between R&D spending and spinouts (1-year window, firm and naics4-year demeaning)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")



## State-year level data

data[,  xrdStateYear := sum(xrd) , by = c("State","year")]
data[, spinoutsStateYear := sum(spinoutCountUnweighted) , by = c("State","year")]

stateYearLevelData <- unique(data, by = c("State","year"))[ , .(State,year,xrdStateYear,spinoutsStateYear)]



ggplot(data = stateYearLevelData, aes(x = xrdStateYear, y = spinoutsStateYear)) + 
  geom_point() +
  geom_smooth(method = "lm") +  
  #theme(legend.position = "none") +
  ggtitle("Relationship between R&D spending and spinouts (1-year window, state-year level regression)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("R&D spending (millions $)")





