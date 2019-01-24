using InitializationModule
using AlgorithmParametersModule
using ModelSolver
using GuessModule

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
guess = setInitialGuess(algoPar,modelPar,mGrid)

νMin = 0.02
νMax = 0.2
νStep = 0.02

χSMin = 1.5
χSMax = 3.5
χSStep = 0.5

νGrid = νMin:νStep:νMax#--------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)


χSGrid = χSMin:χSStep:χSMax

#resultsMatrix = zeros(length(νGrid),length(ξGrid),5)
#resultsMatrix = fill(Guess(guess.g,guess.L_RD,guess.w,guess.zS,guess.zE),(length(νGrid),length(ξGrid)))
resultsMatrix = Array{Guess,2}(undef,length(χSGrid),length(νGrid))

#guess = Guess(initGuess.g,initGuess.L_RD,initGuess.w,initGuess.zS,initGuess.zE)

i_idx = 1
j_idx = 1

for i = 1:length(χSGrid)

    i_idx = i

    for j = 1:length(νGrid)

        j_idx = j

        modelPar.χS = χSGrid[i]
        modelPar.ν = νGrid[j]

        results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,guess)

        guess.g = results.finalGuess.g
        guess.L_RD = results.finalGuess.L_RD
        guess.w = results.finalGuess.w
        guess.zS = results.finalGuess.zS
        guess.zE = results.finalGuess.zE

        resultsMatrix[i,j] = Guess(results.finalGuess.g,results.finalGuess.L_RD,results.finalGuess.w,results.finalGuess.zS,results.finalGuess.zE)

    end

end

#--------------------------#
# Plot results             #
#--------------------------#

gArray = zeros(size(resultsMatrix))
L_RDArray = zeros(size(resultsMatrix))

for i = 1:length(χSGrid)
    for j = 1:length(νGrid)

        gArray[i,j] = resultsMatrix[i,j].g
        L_RDArray[i,j] = resultsMatrix[i,j].L_RD

    end
end


#df = DataFrame(x = νGrid, y = resultsMatrix[:,1], label = "g")

df = DataFrame(x = Float64[],y = Float64[],label = String[])

df1 = DataFrame(x = νGrid * modelPar.ξ, y = gArray[1,:], label = "χS = $(χSGrid[1])")
df2 = DataFrame(x = νGrid * modelPar.ξ, y = gArray[2,:], label = "χS = $(χSGrid[2])")
df3 = DataFrame(x = νGrid * modelPar.ξ, y = gArray[3,:], label = "χS = $(χSGrid[3])")
df4 = DataFrame(x = νGrid * modelPar.ξ, y = gArray[4,:], label = "χS = $(χSGrid[4])")
df5 = DataFrame(x = νGrid * modelPar.ξ, y = gArray[5,:], label = "χS = $(χSGrid[5])")
df = vcat(df1,df2,df3,df4,df5)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Growth rate vs νξ"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Rate"), Guide.xlabel("νξ"), Theme(background_color=colorant"white"))


df1 = DataFrame(x = νGrid * modelPar.ξ, y = L_RDArray[1,:], label = "χS = $(χSGrid[1])")
df2 = DataFrame(x = νGrid * modelPar.ξ, y = L_RDArray[2,:], label = "χS = $(χSGrid[2])")
df3 = DataFrame(x = νGrid * modelPar.ξ, y = L_RDArray[3,:], label = "χS = $(χSGrid[3])")
df4 = DataFrame(x = νGrid * modelPar.ξ, y = L_RDArray[4,:], label = "χS = $(χSGrid[4])")
df5 = DataFrame(x = νGrid * modelPar.ξ, y = L_RDArray[5,:], label = "χS = $(χSGrid[5])")
df = vcat(df1,df2,df3,df4,df5)
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("L_RD vs νξ"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Amount of labor"), Guide.xlabel("νξ"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)
draw(PNG("./figures/nuxi_chiS_plot.png", 10inch, 10inch), p)
