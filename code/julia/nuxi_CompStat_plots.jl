# CompStat_Auxiliary
#####

#using Revise
#using Compat
using InitializationModule
using AlgorithmParametersModule
using ModelSolver
using HJBModule
using GuessModule
using AuxiliaryModule
#using Plots; gr()
using DataFrames
using Gadfly
using JLD2


algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
guess = setInitialGuess(algoPar,modelPar,mGrid)

νMin = 0.005
νMax = 0.1
νStep = 0.005

χSMin = 1.42 - 0.125
χSMax = χSMin + 0.5
χSStep = 0.125

νGrid = νMin:νStep:νMax#--------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)


χSGrid = χSMin:χSStep:χSMax


@load "./output/resultsBackup.jld2" resultsMatrix


gArray = zeros(size(resultsMatrix))
L_RDArray = zeros(size(resultsMatrix))

RDArray_total = zeros(size(resultsMatrix))

RDArray_incumbent = zeros(size(resultsMatrix))
RDArray_entrants = zeros(size(resultsMatrix))
RDArray_spinouts = zeros(size(resultsMatrix))

RDShareArray_incumbent = zeros(size(resultsMatrix))
RDShareArray_entrants = zeros(size(resultsMatrix))
RDShareArray_spinouts = zeros(size(resultsMatrix))

growthArray_incumbent = zeros(size(resultsMatrix))
growthArray_entrants = zeros(size(resultsMatrix))
growthArray_spinouts = zeros(size(resultsMatrix))

growthShareArray_incumbent = zeros(size(resultsMatrix))
growthShareArray_entrants = zeros(size(resultsMatrix))
growthShareArray_spinouts = zeros(size(resultsMatrix))

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
guess = setInitialGuess(algoPar,modelPar,mGrid)

νMin = 0.005
νMax = 0.1
νStep = 0.005

χSMin = 1.42 - 0.125
χSMax = χSMin + 0.5
χSStep = 0.125

νGrid = νMin:νStep:νMax#--------------------------------#

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)


χSGrid = χSMin:χSStep:χSMax


@load "./output/resultsBackup.jld2" resultsMatrix


#include("nuxi_chiS_unpackScript.jl")

i = 1;
j = 1;

for i = 1:length(χSGrid)
    for j = 1:length(νGrid)

        # Run unpack script - lots of hardcoded shit, could be
        # better, but don't have time to fix now. This is cleaner.

        #include("nuxi_chiS_unpackScript.jl")
        g = resultsMatrix[i,j].finalGuess.g
        L_RD = resultsMatrix[i,j].finalGuess.L_RD

        w = resultsMatrix[i,j].finalGuess.w
        zS = resultsMatrix[i,j].finalGuess.zS
        zE = resultsMatrix[i,j].finalGuess.zE
        V = resultsMatrix[i,j].incumbent.V
        zI = resultsMatrix[i,j].incumbent.zI
        W = resultsMatrix[i,j].spinoutValue

        γ = resultsMatrix[i,j].auxiliary.γ
        t = resultsMatrix[i,j].auxiliary.t

        τI = AuxiliaryModule.τI(modelPar,zI)
        τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
        τE = AuxiliaryModule.τE(modelPar,zS,zE)
        τS = zeros(size(τE))
        τS[:] = τSE[:] - τE[:]

        τ = τI + τSE

        z = zS + zE + zI
        a = z

        finalGoodsLabor = AuxiliaryModule.LF(L_RD,modelPar)

        mGrid,Δm = mGridBuild(algoPar.mGrid)

        #Compute derivative of a for calculating stationary distribution

        aPrime = zeros(size(a))

        for i = 1:length(aPrime)-1

            aPrime[i] = (a[i+1] - a[i]) / Δm[i]

        end

        aPrime[end] = aPrime[end-1]

        ##################
        ## Unpack parameters
        #################

        χS = χSGrid[i]
        ν = νGrid[j]

        ϕSE(z) = z .^(-modelPar.ψSE)
        ϕI(z) = z .^(-modelPar.ψI)

        λ = modelPar.λ
        ρ = modelPar.ρ
        ξ = modelPar.ξ
        ψI = modelPar.ψI
        χI = modelPar.χI
        β = modelPar.β

        ## Finally compute final stuff

        wbar = AuxiliaryModule.Cβ(β)
        Π = AuxiliaryModule.profit(resultsMatrix[i,j].finalGuess.L_RD,modelPar)

        integrand =  (ν .* aPrime .+ τ) ./ (ν .* a)
        summand = integrand .* Δm
        integral = cumsum(summand[:])
        μ = exp.(-integral)
        μ = μ / sum(μ .* Δm)

        ## Record for plotting

        gArray[i,j] = g
        L_RDArray[i,j] = L_RD


        RDContribution_incumbent = sum(zI .* γ .* μ .* Δm)
        RDContribution_entrants = sum(zE .* γ .* μ .* Δm)
        RDContribution_spinouts = sum(zS .* γ .* μ .* Δm)

        RDArray_incumbent[i,j] = RDContribution_incumbent
        RDArray_entrants[i,j] = RDContribution_entrants
        RDArray_spinouts[i,j] = RDContribution_spinouts

        totalRD = sum(a .* γ .* μ .* Δm)

        RDShare_incumbent = RDContribution_incumbent / totalRD
        RDShare_entrants = RDContribution_entrants / totalRD
        RDShare_spinouts = RDContribution_spinouts / totalRD

        RDShareArray_incumbent[i,j] = RDShare_incumbent
        RDShareArray_entrants[i,j] = RDShare_entrants
        RDShareArray_spinouts[i,j] = RDShare_spinouts

        growthContribution_incumbent = (modelPar.λ - 1) * sum(τI .* γ .* μ .* Δm)
        growthContribution_entrants = (modelPar.λ - 1) * sum(τE .* γ .* μ .* Δm)
        growthContribution_spinouts = (modelPar.λ - 1) * sum(τS .* γ .* μ .* Δm)

        growthArray_incumbent[i,j] = growthContribution_incumbent
        growthArray_entrants[i,j] = growthContribution_entrants
        growthArray_spinouts[i,j] = growthContribution_spinouts

        totalGrowth = growthContribution_incumbent + growthContribution_entrants + growthContribution_spinouts

        growthShare_incumbent = growthContribution_incumbent / totalGrowth
        growthShare_entrants = growthContribution_entrants / totalGrowth
        growthShare_spinouts = growthContribution_spinouts / totalGrowth

        growthShareArray_incumbent[i,j] = growthShare_incumbent
        growthShareArray_entrants[i,j] = growthShare_entrants
        growthShareArray_spinouts[i,j] = growthShare_spinouts


    end
end


#df = DataFrame(x = νGrid, y = resultsMatrix[:,1], label = "g")

#df = DataFrame(x = Float64[],y = Float64[],label = String[])

x = νGrid * modelPar.ξ
data = gArray'
labels = ["\\chi_s= $val" for val in χSGrid]
p1 = plot(x,data,title = "g", xlabel = "nu \\xi", ylabel = "g", label = labels, legend = false)


data = L_RDArray'
p2 = plot(x,data,title = "\\ L_{RD}", xlabel = "nu \\xi", ylabel = "\\ L_{RD}",label = labels)

p = plot(p1,p2,layout = (2,1))

png("./figures/presentation/nuxi_chiS_g_plot_GR.png")


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

RDArrray_total = RDArray_incumbent + RDArray_entrants + RDArray_spinouts

df1 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_total[1,:], label = "χS = $(χSGrid[1])")
df2 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_total[2,:], label = "χS = $(χSGrid[2])")
df3 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_total[3,:], label = "χS = $(χSGrid[3])")
df4 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_total[4,:], label = "χS = $(χSGrid[4])")
df5 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_total[5,:], label = "χS = $(χSGrid[5])")
df = vcat(df1,df2,df3,df4,df5)
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("L_RD vs νξ"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Amount of labor"), Guide.xlabel("νξ"), Theme(background_color=colorant"white"))


p = vstack(p1,p2)
draw(PNG("./figures/nuxi_chiS_g_plot.png", 10inch, 10inch), p)
draw(PNG("./figures/presentation/nuxi_chiS_g_plot_2.png", 10inch, 7inch), p)

df1 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_incumbent[2,:], label = "Incumbents")
df2 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_entrants[2,:], label = "Entrants")
df3 = DataFrame(x = νGrid * modelPar.ξ, y = RDArray_spinouts[2,:], label = "Spinouts")
df = vcat(df1,df2,df3)
p1 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("RD decomposition"), Guide.ColorKey(title = "Legend"), Guide.ylabel("RD labor"), Guide.xlabel("νξ"), Theme(background_color=colorant"white"))

df1 = DataFrame(x = νGrid * modelPar.ξ, y = growthArray_incumbent[2,:], label = "Incumbent")
df2 = DataFrame(x = νGrid * modelPar.ξ, y = growthArray_entrants[2,:], label = "Entrants")
df3 = DataFrame(x = νGrid * modelPar.ξ, y = growthArray_spinouts[2,:], label = "Spinouts")
df = vcat(df1,df2,df3)
p2 = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Growth decomposition"), Guide.ColorKey(title = "Legend"), Guide.ylabel("g"), Guide.xlabel("νξ"), Theme(background_color=colorant"white"))

p = vstack(p1,p2)
draw(PNG("./figures/presentation/nuxi_RDandGrowth_plot.png", 10inch, 7inch), p)



## Plot social welfare

β = modelPar.β
ρ = modelPar.ρ

ρArray = ρ * ones(size(gArray))
OutputCoefficient = (((1-β) * AuxiliaryModule.Cβ(β)^(-1))^(1-β))/(1-β)
LFArray = AuxiliaryModule.LF(L_RDArray,modelPar)
WelfareArray = OutputCoefficient .* LFArray ./ (ρArray .- gArray)

df1 = DataFrame(x = νGrid * modelPar.ξ, y = WelfareArray[1,:], label = "χS = $(χSGrid[1])")
df2 = DataFrame(x = νGrid * modelPar.ξ, y = WelfareArray[2,:], label = "χS = $(χSGrid[2])")
df3 = DataFrame(x = νGrid * modelPar.ξ, y = WelfareArray[3,:], label = "χS = $(χSGrid[3])")
df4 = DataFrame(x = νGrid * modelPar.ξ, y = WelfareArray[4,:], label = "χS = $(χSGrid[4])")
df5 = DataFrame(x = νGrid * modelPar.ξ, y = WelfareArray[5,:], label = "χS = $(χSGrid[5])")
df = vcat(df1,df2,df3,df4,df5)
p = plot(df, x = "x", y = "y", color = "label", Geom.line, Guide.title("Social welfare vs νξ"), Guide.ColorKey(title = "Legend"), Guide.ylabel("Welfare"), Guide.xlabel("νξ"), Theme(background_color=colorant"white"))

draw(PNG("./figures/presentation/nuxi_chiS_welfare_plot.png", 10inch, 7inch),p)
