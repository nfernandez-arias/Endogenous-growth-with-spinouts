
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


## Raw OLS

ggplot(data = data, aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  #scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=14)) + 
  #theme(legend.position = "none") +
  ggtitle("Higher R&D is associated with more employee spinout formation") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending")

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw.png", plot = last_plot())

# Raw OLS separated out by parent firm state

ggplot(data = data[State == "CA" | State == "IL" | State == "IN" | State == "MA" | State == "MI" | State == "NY" | State == "TX" | State == "WA"], aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  theme(text = element_text(size=12)) + 
  #theme(legend.position = "none") +
  ggtitle("Variation in the R&D - spinouts relationship across innovative states") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending") + 
  facet_wrap(~ State, ncol = 4) 

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw_byState.png")

ggplot(data = data, aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=12)) + 
  #theme(legend.position = "none") +
  ggtitle("NAICS codes 3 (incl. manufacturing) and 5 (incl. software publishers) contain most parents") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending") + 
  facet_wrap(~ naics1, ncol = 3) 

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw_byNAICS1.png")

ggplot(data = data[naics1 == "3" | naics1 == "5" ], aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=12)) + 
  #theme(legend.position = "none") +
  ggtitle("Relationship driven by NAICS 32, 33, 51 and 54") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending") + 
  facet_wrap(~ naics2, ncol = 3) 

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw_byNAICS2.png")

ggplot(data = data[naics2 == "32" | naics2 == "33" | naics2 == "51" | naics2 == "54"], aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=12)) + 
  #theme(legend.position = "none") +
  ggtitle("Relationship driven by 325, 334, 336, 511, 517, 519, and 541") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending") + 
  facet_wrap(~ naics3, ncol = 3) 

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw_byNAICS3.png")

ggplot(data = data[naics3 == "325" | naics3 == "334" | naics3 == "336" | naics3 == "511" | naics3 == "517" | naics3 == "519" | naics3 == "541"], aes(x = xrd, y = spinoutCount)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm", se = TRUE, size = 0.6) + 
  scale_color_manual(values = my_palette) + 
  theme(text = element_text(size=12)) + 
  #theme(legend.position = "none") +
  ggtitle("Relationship concentrated in four 3-digit NAICS industries") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("# of Spinouts") +
  xlab("Effective real R&D spending") + 
  facet_wrap(~ naics3, ncol = 3) 

ggsave("../figures/scatterPlot_RD-Spinouts-1yr-raw_byNAICS3_zoomIn.png")


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


ggplot(data = data[State == "CA" | State == "MA"], aes(x = xrd_d, y = spinoutsDiscountedFFValue_d, group = State, color = State)) + 
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



# Clean up

rm(data,stateYearLevelData)


