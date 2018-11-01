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
include("ModelParameters.jl")
include("InitialGuess.jl")

# Functions for solving model
#include("solveModel.jl")

#--------------------------------#
# Set algorithm parameters       #
#--------------------------------#

pa = setAlgorithmParameters()
pm = setModelParameters()
ig = setInitialGuess(pa,pm)
