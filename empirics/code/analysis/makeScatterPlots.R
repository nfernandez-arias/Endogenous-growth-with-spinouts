
rm(list = ls())

data <- fread("data/compustat-spinouts_Stata.csv")

#data[ , xrd := log(xrd)]
#data[ , Spinouts_fut4 := log(Spinouts_fut4)]
#data[ Spinouts_fut4 == -Inf, Spinouts_fut4 := NA]
#data[ xrd == -Inf, xrd := NA]

data[ , spinoutCount := Reduce(`+`,shift(spinoutCount,1L:2L,type="lead")), by = "gvkey"]
data[ , spinoutCountUnweighted := Reduce(`+`,shift(spinoutCountUnweighted,1L:2L,type="lead")), by = "gvkey"]
data[ , spinoutsDiscountedFFValue := Reduce(`+`,shift(spinoutsDiscountedFFValue,1L:2L,type="lead")), by = "gvkey"]


data[ , xrd_d := xrd - mean(na.omit(xrd)), by = "gvkey"]
data[ , Spinouts_fut4_d := Spinouts_fut4 - mean(na.omit(Spinouts_fut4)), by = "gvkey"]
data[ , spinoutCount_d := spinoutCount - mean(na.omit(spinoutCount)), by = "gvkey"]
data[ , spinoutCountUnweighted_d := spinoutCountUnweighted - mean(na.omit(spinoutCountUnweighted)), by = "gvkey"]
data[ , spinoutsDiscountedFFValue_d := spinoutsDiscountedFFValue - mean(na.omit(spinoutsDiscountedFFValue)), by = "gvkey"]

data[ , xrd_d := xrd_d - mean(na.omit(xrd_d)), by = c("naics4","year")]
data[ , Spinouts_fut4_d := Spinouts_fut4_d - mean(na.omit(Spinouts_fut4)), by = c("naics4","year")]
data[ , spinoutCount_d := spinoutCount_d - mean(na.omit(spinoutCount_d)), by = c("naics4","year")]
data[ , spinoutCountUnweighted_d := spinoutCountUnweighted_d - mean(na.omit(spinoutCountUnweighted_d)), by = c("naics4","year")]
data[ , spinoutsDiscountedFFValue_d := spinoutsDiscountedFFValue_d - mean(na.omit(spinoutsDiscountedFFValue_d)), by = c("naics4","year")]

data[ , xrd_d := xrd_d - mean(na.omit(xrd_d)), by = c("State","year")]
data[ , Spinouts_fut4_d := Spinouts_fut4_d - mean(na.omit(Spinouts_fut4)), by = c("State","year")]
data[ , spinoutCount_d := spinoutCount_d - mean(na.omit(spinoutCount_d)), by = c("State","year")]
data[ , spinoutCountUnweighted_d := spinoutCountUnweighted_d - mean(na.omit(spinoutCountUnweighted_d)), by = c("State","year")]
data[ , spinoutsDiscountedFFValue_d := spinoutsDiscountedFFValue_d - mean(na.omit(spinoutsDiscountedFFValue_d)), by = c("State","year")]

data[ , xrd_d := xrd_d - mean(na.omit(xrd_d)), by = "firmAge"]
data[ , Spinouts_fut4_d := Spinouts_fut4_d - mean(na.omit(Spinouts_fut4)), by = "firmAge"]
data[ , spinoutCount_d := spinoutCount_d - mean(na.omit(spinoutCount_d)), by = "firmAge"]
data[ , spinoutCountUnweighted_d := spinoutCountUnweighted_d - mean(na.omit(spinoutCountUnweighted_d)), by = "firmAge"]
data[ , spinoutsDiscountedFFValue_d := spinoutsDiscountedFFValue_d - mean(na.omit(spinoutsDiscountedFFValue_d)), by = "firmAge"]

# Construct scatter plot by state

library(ggplot2)

library(RColorBrewer)

my_palette <- brewer.pal(name="Blues",n=8)[4:9]

## Raw OLS

ggplot(data = data, aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("Higher R&D is associated with more employee spinout formation") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending")

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw.png", plot = last_plot())

ggplot(data = data, aes(x = xrd, y = Spinouts_fut4)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("Higher R&D predicts future employee spinout formation") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("log # of Spinouts from t+1 to t+4") +
  xlab("Effective real R&D spending at t")

ggsave("../figures/scatterPlot_RD-SpinoutsFut4-raw.png", plot = last_plot())

ggplot(data = data, aes(x = xrd, y = spinoutCountUnweighted)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE , size = 0.6) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout founder counts") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending")

ggsave("../figures/scatterPlot_RD-SpinoutsFounders-1yr-raw.png", plot = last_plot())


## Discounted FF Value  
ggplot(data = data, aes(x = xrd, y = spinoutsDiscountedFFValue)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts valuation") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Valuation (millions $)") +
  xlab("Effective real R&D spending")

ggsave("../figures/scatterPlot_RD-SpinoutsDFFV-1yr-raw.png", plot = last_plot())

## All demeaning

ggplot(data = data, aes(x = xrd_d, y = spinoutCount_d)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout counts (demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending")
  

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-allFE.png", plot = last_plot())

ggplot(data = data, aes(x = xrd_d, y = Spinouts_fut4_d)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinout counts (fut4, demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending")

  ggsave("../figures/scatterPlot_RD-SpinoutsFut4-allFE.png", plot = last_plot())

ggplot(data = data, aes(x = xrd_d, y = spinoutCountUnweighted_d)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  theme(text = element_text(size=16)) + 
  #theme(legend.position = "none") +
  ggtitle("R&D spending and founder counts (demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Founders") +
  xlab("Effective R&D spending")
    
ggsave("../figures/scatterPlot_RD-SpinoutsFounders-1yr-allFE.png", plot = last_plot())

ggplot(data = data, aes(x = xrd_d, y = spinoutsDiscountedFFValue_d)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("R&D spending and spinouts DFFV (demeaned)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Valuation (millions 2012 $)") +
  xlab("Effective real R&D spending")

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





