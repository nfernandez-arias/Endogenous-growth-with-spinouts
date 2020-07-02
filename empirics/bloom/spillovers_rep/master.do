*******************************************************************************
* THIS FILE GENERATES ALL OF TABLES AND DATASETS USED IN
*		"Have R&D spillovers changed over time?" by Brian Lucking, Nicholas Bloom and John Van Reenen
*
* TO REPLICATE THE PAPER FROM START TO FINISH,UNCOMMENT OUT LINES 33-42, AND RUN THIS PROGRAM (NOTE: THIS TAKES A LONG TIME)
* TO REPLICATE JUST THE TABLES, RUN THIS DO-FILE AS-IS (WITH LINES 33-42 COMMENTED OUT)
clear all
clear matrix
cap log close
set more off
set matsize 11000
cap ssc install avar
cap ssc install xtivreg2
cap ssc install newey2
cap ssc install reghdfe
cap ssc install ivreg2
cap ssc install ranktest
global dir "/Users/brianlucking/Dropbox/spillovers_rep"							// change this to your working directory
global raw_data "$dir/1_data/Raw"
global data 	"$dir/1_data/Intermediate"
global programs "$dir/2_programs"
global tables   "$dir/3_tables"
cd "$programs"
* SET SAMPLING PARAMETERS *
global primary_share 0.75	// share of segment sales allocated to primary industry
global compustat_start 1980	// compustat financials data, we use 1980-2015 and then throw out first 5 years of data as a burn-in period
global compustat_end 2015
global segments_start 1985	// time frame of data used to construct SIC
global segments_end 2015
global patent_start 1970	// time frame of data used to construct TEC, 2006 is the last available year
global patent_end 2006
/* DATA TRANSFORMATION
do deflators.do			// reads NBER industry price deflators
do patents_count.do		// constructs intermediate patent citations/count data
do compustat.do 		// constructs intermediate segments and accounting data
do sample.do			// create subsets of raw data using the sampling parameters defined above
do patents.do			// creates SIC/TEC measures -> takes a long time to run (~10 hours)
do spillovers.do		// merges together intermediate files and generates key variables
do spillovers_sBSV.do
* ANALYSIStablestablestables
do rsample.do			// regression sample (makes sure same # obs. in each table)
do rollspill.do*/		// this creates a time-varying spillovers measure based on previous 5 years of data
do tables_rollsic_tex.do // creates the tables
do tables_time.do
