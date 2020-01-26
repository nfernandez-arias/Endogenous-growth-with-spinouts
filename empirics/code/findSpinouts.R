#------------------------------------------------#
#
# File name: findSpinouts.R
#
# Author: Nicolas Fernandez-Arias 
#
# Purpose:
#
# This is the main script for identifying spinouts
# of Compustat firms by name matching to employee bios deals <- fread(
# in Venture Source.  
#------------------------------------------------#

# Parse employee biographies
source("code/VentureSource/parseBiographies.R")

# Link entities to entityname and founding date
source("code/VentureSource/linkEntitiesToEntityNamesAndFoundingDates.R")

# Determine which is the previous firm the employee worked at
source("code/VentureSource/findLastEmployer.R")

# Clean results from AltDG
source("code/AltDG/cleanAltDGResults.R")

# Link bios to Compustat
source("code/linkBiosToCompustat2.R")

# Classify entrepreneurs into various classes
source("code/VentureSource/classifyFounders.R")




