using GuessModule

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
guess = setInitialGuess(algoPar,modelPar,mGrid)

nuMin = 0.01
nuMax = 0.2
nuStep = 0.01

nuGrid = nuMin:nuStep:nuMax

resultsMatrix = zeros(length(nuGrid),2)

#resultsMatrix = AbstractVector{Guess}

#guess = Guess(initGuess.g,initGuess.L_RD,initGuess.w,initGuess.zS,initGuess.zE)

for i = 1:length(nuGrid)

    modelPar.ν = nuGrid[i]
    results,zSfactor,zEfactor,spinoutFlow,γ,t = solveModel(algoPar,modelPar,guess)
    g = results.finalGuess.g
    L_RD = results.finalGuess.L_RD

    #resultsMatrix[i] := results.finalGuess

    resultsMatrix[i,1] = g
    resultsMatrix[i,2] = L_RD

    guess.g = results.finalGuess.g
    guess.L_RD = results.finalGuess.L_RD
    guess.w = results.finalGuess.w
    guess.zS = results.finalGuess.zS
    guess.zE = results.finalGuess.zE

end

#--------------------------#
# Plot results             #
#--------------------------#

df = DataFrame(x = nuGrid, y = resultsMatrix[:,1], label = "g")
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Growth rate vs ν"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Rate"), Guide.xlabel("ν"), Theme(background_color=colorant"white"))


df = DataFrame(x = nuGrid, y = resultsMatrix[:,2], label = "L_RD")
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("L_RD vs ν"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Amount of labor"), Guide.xlabel("ν"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/nuPlot.png", 10inch, 10inch), p)
