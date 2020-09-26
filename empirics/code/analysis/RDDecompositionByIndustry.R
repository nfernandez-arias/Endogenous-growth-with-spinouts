
data <- fread("data/compustat-spinouts_Stata.csv")

RDbyIndustryYear = data[ , .(xrd.l3 = sum(na.omit(xrd.l3))), by = .(naics2,year)] 

RDbyYear = data[ , .(xrd.l3 = sum(na.omit(xrd.l3))), by = year]

data[ , naics2_selected := naics2]
data[ naics1 != 3 & naics1 != 5, naics2_selected := 0]

data[ , naics3_selected := naics3]
data[ naics2 != 33 & naics2 != 32 & naics2 != 51, naics3_selected := 0]

RDbyIndustry = data[ , .(xrd.l3 = sum(na.omit(xrd.l3))), by = .(naics2_selected)]
RDbyIndustry[ , naics1 := substr(naics2_selected,1,1)]

RDbyIndustryNAICS3 = data[ , .(xrd.l3 = sum(na.omit(xrd.l3))), by = .(naics3_selected)]
RDbyIndustryNAICS3[ , naics2 := substr(naics3_selected,1,1)]

RDbyIndustry[ , xrd.l3.share := 100 * xrd.l3 / sum(xrd.l3)]
RDbyIndustryNAICS3[ , xrd.l3.share := 100 * xrd.l3 / sum(xrd.l3)]

setkey(RDbyIndustry,xrd.l3.share)

RDbyIndustry[ , xrd.l3.share.cum := cumsum(xrd.l3.share)]


test <- ecdf(RDbyIndustry$xrd.l3)
plot(test)

ggplot(RDbyIndustry, aes(x = naics3_selected, y = xrd.l3.share.cum)) + 
  geom_line()

mycolors = c(colorRampPalette(brewer.pal(name="Dark2", n = 8))(9), brewer.pal(name="Paired", n = 6))



ggplot(RDbyIndustry[naics1 != 1 & naics1 != 9 & naics1 != 7], aes(x = "", y = xrd.l3, fill = as.factor(naics2_selected))) + 
  geom_bar(stat = "identity", width = 1) + 
  coord_polar("y", start = 0) + 
  scale_color_manual(values = mycolors)

ggplot(RDbyIndustryYear, aes(x = year, y = xrd.l3)) + 
  geom_line() + 
  facet_wrap(~naics1)


ggplot(RDbyYear, aes(x = year, y = xrd.l3)) + 
  geom_line()

