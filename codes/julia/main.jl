#--------------------------------#
# Name: main.jl                  #
#                                #
# Main function for testing      #
# my suite for solving           #
# endogenous growth model        #
# with spinouts.                 #
#--------------------------------#

# Set working directory

#pwd()

#--------------------------------#
#   Loading auxiliary functions  #
#--------------------------------#

# Include libraries for types and default constructor functions used
# for exploration

include("AlgorithmParameters.jl")
include("setAlgorithmParameters.jl")
include("ModelParameters.jl")
include("InitialGuess.jl")
include("solveModel.jl")

# Functions for solving model
#include("solveModel.jl")

#--------------------------------#
# Set algorithm parameters       #
#--------------------------------#

pa = setAlgorithmParameters()
pm = setModelParameters()
ig = setInitialGuess(pa,pm)

#--------------------------------#
# Solve model with the above parameters
#--------------------------------#

model = solveModel(pa,pm,ig)
