
##
#
# THis script computes the entry rate basded on the patent data
#
#
#

rm(list = ls())


patents <- fread("data/nber uspto/pat76_06_assg.csv")


# Compute founding date
patents <- patents[order(pdpass,appyear)]
patents[ , foundingYear := appyear[1], by = pdpass]

# Flag patents as coming from a new firm if appyear is within 1 year of founding date
patents[ appyear - foundingYear <= 3, newFirm := 1]

##
# Fraction of patents from new firms by year
#
# Both citation and count ratios

yearRatios <- patents[ , .(countRatio = nrow(.SD[newFirm == 1]) / .N, citationRatio = sum(na.omit(allcites[newFirm == 1])) / sum(na.omit(allcites))), by = appyear]
yearRatiosLong <- melt(yearRatios,id.vars = "appyear", measure.vars = c("countRatio","citationRatio"))
setnames(yearRatiosLong,"variable","type")
setnames(yearRatiosLong,"value","ratio")

library(ggplot2)

ggplot(data = yearRatiosLong, aes(x = appyear, y = ratio, group = type, color = type)) + 
  geom_line() +
  theme(text = element_text(size=16)) +
  #theme(legend.position = "none") +
  ggtitle("Fraction of patents from new firms") +
  #ggtitl   e("Unadjusted") + 
  xlim(1986,2005) +
  ylim(0,0.3) +
  ylab("Fraction") +
  xlab("Year")

ggsave("../figures/patents_from_new_firms.png", plot = last_plot()) 








