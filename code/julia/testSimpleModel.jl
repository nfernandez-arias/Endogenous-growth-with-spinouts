using Revise
using EndogenousGrowthWithSpinouts
using LaTeXStrings


cd("/home/nico/nfernand@princeton.edu/PhD - Thesis/Research/Endogenous-growth-with-spinouts/code/julia")

modelPar = initializeSimpleModel()
makePlots(modelPar,"highKe")
