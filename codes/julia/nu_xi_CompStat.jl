
using GuessModule

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
guess = setInitialGuess(algoPar,modelPar,mGrid)

νMin = 0.01
νMax = 0.2
νStep = 0.01

ξMin = 2
ξMax = 10
ξStep = 2

νGrid = νMin:νStep:νMax

ξGrid = ξMin:ξStep:ξMax

#resultsMatrix = zeros(length(νGrid),length(ξGrid),5)
#resultsMatrix = fill(Guess(guess.g,guess.L_RD,guess.w,guess.zS,guess.zE),(length(νGrid),length(ξGrid)))
resultsMatrix = Array{Guess,2}(undef,length(ξGrid),length(νGrid))

#guess = Guess(initGuess.g,initGuess.L_RD,initGuess.w,initGuess.zS,initGuess.zE)

i_idx = 1
j_idx = 1

for i = 1:length(ξGrid)

    i_idx = i

    for j = 1:length(νGrid)

        j_idx = j

        modelPar.ξ = ξGrid[i]
        modelPar.ν = νGrid[j]

        results,zSfactor,zEfactor,spinoutFlow,γ,t = solveModel(algoPar,modelPar,guess)

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

for i = 1:length(ξGrid)
    for j = 1:length(νGrid)

        gArray[i,j] = resultsMatrix[i,j].g
        L_RDArray[i,j] = resultsMatrix[i,j].L_RD

    end
end


#df = DataFrame(x = νGrid, y = resultsMatrix[:,1], label = "g")
df1 = DataFrame(x = νGrid, y = gArray[1,:], label = "ξ = $(ξGrid[1])")
df2 = DataFrame(x = νGrid, y = gArray[2,:], label = "ξ = $(ξGrid[2])")
df3 = DataFrame(x = νGrid, y = gArray[3,:], label = "ξ = $(ξGrid[3])")
df4 = DataFrame(x = νGrid, y = gArray[4,:], label = "ξ = $(ξGrid[4])")
df5 = DataFrame(x = νGrid, y = gArray[5,:], label = "ξ = $(ξGrid[5])")
df = vcat(df1,df2,df3,df4,df5)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Growth rate vs ν"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Rate"), Guide.xlabel("ν"), Theme(background_color=colorant"white"))


df1 = DataFrame(x = νGrid, y = L_RDArray[1,:], label = "ξ = $(ξGrid[1])")
df2 = DataFrame(x = νGrid, y = L_RDArray[2,:], label = "ξ = $(ξGrid[2])")
df3 = DataFrame(x = νGrid, y = L_RDArray[3,:], label = "ξ = $(ξGrid[3])")
df4 = DataFrame(x = νGrid, y = L_RDArray[4,:], label = "ξ = $(ξGrid[4])")
df5 = DataFrame(x = νGrid, y = L_RDArray[5,:], label = "ξ = $(ξGrid[5])")
df = vcat(df1,df2,df3,df4,df5)
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("L_RD vs ν"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Amount of labor"), Guide.xlabel("ν"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)
draw(PNG("/home/nico/nfernand@princeton.edu/PhD - Big boy/Research/Endogenous-growth-with-spinouts/codes/julia/figures/nu_xi_plot.png", 10inch, 10inch), p)
