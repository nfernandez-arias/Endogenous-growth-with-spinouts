
data <- fread("data/compustat-spinouts_Stata.csv")[ year >= 1986 & year <= 2006]


for (var in c("xrd.l3","xrd.at.l3",
              "founders.founder2.f3","founders.founder2.at.f3",
              "founders.founder2.wso4.f3","founders.founder2.wso4.at.f3",
              "founders.founder2.wso1.f3","founders.founder2.wso1.at.f3",
              "founders.founder2.wso2.f3","founders.founder2.wso2.at.f3",
              "founders.founder2.wso3.f3","founders.founder2.wso3.at.f3"))
{
  # remove outliers
  #data <- data[ abs(get(var) - mean(get(var), na.rm = TRUE)) / sd(get(var), na.rm = TRUE) <= 7 ]
  varString <- paste0(var,".d")
  data[ , (varString) := get(var) - mean(get(var) , na.rm = TRUE), by = "gvkey" ]
  
  varString2 <- paste0(var,".d2")
  data[ , (varString2) := get(varString) - mean(get(varString) , na.rm = TRUE), by = .(naics4,year) ]
  
  varString3 <- paste0(var,".d3")
  data[ , (varString3) := get(varString2) - mean(get(varString2) , na.rm = TRUE), by = .(State,year) ]
  
  varString4 <- paste0(var,".d4")
  data[ , (varString4) := get(varString3) - mean(get(varString3) , na.rm = TRUE), by = .(firmAge) ]
  
  varStringIntersection <- paste0(var,".dIntersection")
  data[ , (varStringIntersection) := get(varString) - mean(get(varString), na.rm = TRUE), by = .(naics4,State,firmAge,year) ]
        
}



## Raw OLS

ggplot(data = data[State %in% c("CA","NY","TX","MA","IL")], aes(x = xrd.l3.dIntersection, y = founders.founder2.wso4.f3.dIntersection, color = as.factor(State), fill = as.factor(State))) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = FALSE) +
  #geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = FALSE, aes(linetype = "Whole sample")) + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", aes(linetype = "# founders > 0") + 
  #scale_color_manual(values = my_palette) +
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee spinout formation", 
       subtitle = "Levels") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

#ggsave("figures/scatterPlot_RD-Founders.pdf", plot = last_plot(), width = 9, height = 6, units = "in")


ggplot(data = data[], aes(x = xrd.l3, y = founders.founder2.f3)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey") + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee spinout formation", 
       subtitle = "Levels") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

ggsave("figures/scatterPlot_RD-Founders.png", plot = last_plot(), width = 9, height = 6, units = "in")

ggplot(data = data[], aes(x = xrd.l3.dIntersection, y = founders.founder2.f3.dIntersection)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey") + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee spinout formation", 
       subtitle = "Deviation from Firm and State-industry-age-year mean") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

ggsave("figures/scatterPlot_RD-Founders_dIntersection.png", plot = last_plot(), width = 9, height = 6, units = "in")


ggplot(data = data, aes(x = xrd.l3.dIntersection, y = founders.founder2.wso4.f3.dIntersection)) + 
  #geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey") + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  stat_summary_bin(fun = 'mean', bins = 10, shape = 1) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Corporate R&D predicts employee spinouts") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("R&D spending") + 
  theme(text=element_text(family="Latin Modern Roman"))

ggsave("figures/scatterPlot_RD-FoundersWSO4_dIntersection.png", plot = last_plot(), width = 6, height = 4, units = "in")

ggplot(data = data, aes(x = xrd.l3.d4, y = founders.founder2.wso4.f3.d4)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey") + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) +
  stat_summary_bin(fun = 'mean', bins = 10, shape = 1) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee WSO4 formation", 
       subtitle = "Levels") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

ggsave("figures/scatterPlot_RD-FoundersWSO4_d4.pdf", plot = last_plot(), width = 9, height = 6, units = "in")



ggplot(data = data[], aes(x = xrd.l3.dIntersection, y = founders.founder2.f3.dIntersection)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "Whole sample")) + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee spinout formation", 
       subtitle = "Deviation from Firm and State-industry-age-year mean") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

ggsave("figures/scatterPlot_RD-Founders_dIntersection.pdf", plot = last_plot(), width = 9, height = 6, units = "in")

ggplot(data = data[], aes(x = xrd.l3.d4, y = founders.founder2.f3.d4)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "Whole sample")) + 
  #geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee spinout formation", 
       subtitle = "Deviation from Firm and State-industry-age-year mean") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

ggsave("figures/scatterPlot_RD-Founders_d4.pdf", plot = last_plot(), width = 9, height = 6, units = "in")


ggplot(data = data[], aes(x = xrd.l3.d4, y = founders.founder2.f3.d4)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "Whole sample")) + 
  geom_smooth(method = "lm_robust", data = data[founders.founder2.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D is associated with more employee spinout formation", 
       subtitle = "Deviation from Firm and State-industry-age-year mean") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders") +
  xlab("Real effective R&D spending")

ggsave("figures/scatterPlot_RD-Founders_dIntersection.pdf", plot = last_plot(), width = 9, height = 6, units = "in")





ggplot(data = data[], aes(x = xrd.at.l3, y = founders.founder2.at.f3)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "Whole sample")) + 
  geom_smooth(method = "lm_robust", data = data[founders.founder2.at.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D / assets is associated with more employee founders / assets", 
       subtitle = "Levels") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders / assets") +
  xlab("Real effective R&D spending / assets")

ggsave("figures/scatterPlot_RDAssets-FoundersAssets.pdf", plot = last_plot(), width = 9, height = 6, units = "in")

ggplot(data = data[], aes(x = xrd.at.l3.dIntersection, y = founders.founder2.at.f3.dIntersection)) + 
  geom_point(size = 0.1) +
  geom_smooth(method = "lm_robust", formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "Whole sample")) + 
  geom_smooth(method = "lm_robust", data = data[founders.founder2.at.f3 > 0], formula = y ~ poly(x,1), se = TRUE, color = "black", fill = "grey", aes(linetype = "# founders > 0")) + 
  #scale_color_manual(values = my_palette) + 
  theme(legend.position = "bottom") +
  scale_linetype_discrete(name = "") + 
  #theme(legend.position = "none") +
  labs(title = "Higher R&D / assets is inconsistently associated with more employee founders / assets", 
       subtitle = "Deviations (firm, age, naics4-year, state-year)") +
  #ggtitle("Unadjusted") + 
  #ylim(0,1500) + 
  ylab("Founders / assets") +
  xlab("Real effective R&D spending / assets")
      
ggsave("figures/scatterPlot_RDAssets-FoundersAssets_d4.pdf", plot = last_plot(), width = 9, height = 6, units = "in")
  
  



#-----------------------------------------#
# DEPRECATED 
#-----------------------------------------#


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


