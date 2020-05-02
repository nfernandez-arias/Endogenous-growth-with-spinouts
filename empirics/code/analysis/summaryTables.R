


#----------------------------------------#
# Venture Source summary
#----------------------------------------#

# Startups summary



#startupsData <- fread("data/VentureSource/startupsData.csv")
#startupsData <- startupsData[ foundingYear >= VSminFoundingYear & foundingYear <= VSmaxFoundingYear]

data <- fread("data/parentsSpinoutsWSO.csv")

startupsData <- unique(data, by = "EntityID")[ foundingYear >= VSminFoundingYear & foundingYear <= VSmaxFoundingYear]



###### state counts 

# startups

stateCounts <- startupsData[ , .N, by = EntityState][order(-N)]
stAbbrev <- fread("raw/stmap.csv")
setkey(stAbbrev,abbr)
setkey(stateCounts,EntityState)
stateCounts <- stAbbrev[stateCounts][ , .(state,N)][order(-N)]
setnames(stateCounts,"state","State")
setnames(stateCounts,"N","Startups")

# Individuals

stateCounts_Individuals <- data[ , .N, by = EntityState][order(-N)]
setkey(stateCounts_Individuals,EntityState)
stateCounts_Individuals <- stAbbrev[stateCounts_Individuals][ , .(state,N)][order(-N)]
setnames(stateCounts_Individuals,"state","State")
setnames(stateCounts_Individuals,"N","Individuals")

# merge
setkey(stateCounts,State)
setkey(stateCounts_Individuals,State)

stateCounts <- stateCounts_Individuals[stateCounts][order(-Startups)]
setcolorder(stateCounts,c("State","Startups","Individuals"))
  
##### Industry counts

# startups 

industryCounts <- startupsData[ , .N, by = IndustryCode][order(-N)]
setnames(industryCounts,"IndustryCode","Industry")
setnames(industryCounts,"N","Startups")

# Individuals

industryCounts_Individuals <- data[ , .N, by = IndustryCode][order(-N)]
setnames(industryCounts_Individuals,"IndustryCode","Industry")
setnames(industryCounts_Individuals,"N","Individuals")

# merge

setkey(industryCounts,Industry)
setkey(industryCounts_Individuals,Industry)

industryCounts <- industryCounts_Individuals[industryCounts][order(-Startups)]
setcolorder(industryCounts,c("Industry","Startups","Individuals"))

######## Year counts

# startups

yearCounts <- startupsData[ , .N, by = foundingYear][order(foundingYear)]
setnames(yearCounts,"foundingYear","Year")
setnames(yearCounts, "N","Startups")

# Individuals

yearCounts_Individuals <- data[ , .N, by = joinYear][order(joinYear)]
setnames(yearCounts_Individuals,"joinYear","Year")
setnames(yearCounts_Individuals,"N","Individuals")

# merge   

setkey(yearCounts,Year)
setkey(yearCounts_Individuals,Year)

yearCounts <- yearCounts_Individuals[yearCounts][order(Year)]
setcolorder(yearCounts,c("Year","Startups","Individuals"))


## All together

startupCountsXtable <- xtable(cbind(industryCounts[1:23],stateCounts[1:23],yearCounts), align = c("r","p{4.5cm}","l","l","r","l","l","r","l","l"), 
                              caption = "Statistics on startups covered by VS sample. Industry information uses VS industrial classification. Startups are counted by founding year, individuals by year they joined the firm.",
                              label = "table:VS_summaryTable") 
print(startupCountsXtable, "figures/tables/summaryTables/VS_startupCountsAll.tex", type = "latex", size = "\\scriptsize", floating = TRUE, include.rownames = FALSE, booktabs = TRUE, table.placement = "!htb")




data <- data[all == 1]

### Title counts 

boardTitles <- grep("board|Board", unique(data$Title), value = T)

data[ , Title2 := Title]
data[ Title %in% boardTitles, Title2 := "Board member (outsider)"]

data[ Title2 == "Board member (outsider)", isOutsider := 1]

data[ all == 1, sum(na.omit(isOutsider)) / .N]



title2Counts <- data[all == 1 & Title2 != ""][ , .N, by = Title2][order(-N)]

title2Counts[ , Percentage := 100 * N / sum(N)]

setnames(title2Counts,"Title2","Title")
setnames(title2Counts,"N","Individuals")

title2CountsXtable <- xtable(title2Counts[1:20], digits = 1, align = c("r","r","l","l"),
                             caption = "Top 20 most frequent titles among founders in VS data.",
                             label = "table:VS_titlesSummaryTable")

print(title2CountsXtable, "figures/tables/summaryTables/titleCounts.tex", 
      type = "latex", size = "\\footnotesize", floating = TRUE, include.rownames = FALSE, booktabs = TRUE, table.placement = "!htb")
  

data[ Title2 == "Board member (outsider)", boardMember := 1]
data[ is.na(boardMember) , boardMember := 0]

fracBoardOutsiders <- data[ , sum(boardMember) / .N, by = EntityID]

fracBoardOutsidersTotal <- data[ , sum(boardMember) / .N]
      
hist(fracBoardOutsiders$V1, breaks = 100)

# Financing rounds summary

#deals <- fread("raw/VentureSource/01Deals.csv")[year (ymd(StartDate)) >= VSminFoundingYear & year(ymd(StartDate)) <= VSmaxFoundingYear]




#----------------------------------------#
# Employment Bios summary
#----------------------------------------#

                    
employerCounts <- data[!is.na(EmployerCase) & EmployerCase != ""]
employerCounts <- employerCounts[ , .N, by = EmployerCase]  
employerCounts <- employerCounts[order(-N)]
setnames(employerCounts,"N","Count")
setnames(employerCounts,"EmployerCase","Employer")


positionCounts <- data[!is.na(Position) & Position != ""]
positionCounts <- positionCounts[ , .N, by = Position]
positionCounts <- positionCounts[order(-N)]
positionCounts[ , Percentage := 100 * N / sum(N)]
setnames(positionCounts,"N","Count")

employerPositionCounts <- cbind(employerCounts[1:20],positionCounts[1:20])

employerPositionCountsXtable <- xtable(employerPositionCounts, digits = 1, align = c("r","r","l","r","l","l"),
                                       caption = "Top 20 previous employers and previous positions for founders in VS data.",
                                       label = "table:VS_previousEmployersSummaryTable")

print(employerPositionCountsXtable, "figures/tables/summaryTables/VS_previousEmployersPositionsCounts.tex", type = "latex", size = "\\footnotesize", floating = TRUE, include.rownames = FALSE, booktabs = TRUE, table.placement = "!htb")
      
