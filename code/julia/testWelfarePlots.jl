
welfareGrid = zeros(length(700:10:900),2)

numPointsMin = 700
numPointsMax = 900
numPointsInterval = 10
numPointsGrid = numPointsMin:numPointsInterval:numPointsMax


for (i,tempNumPoints) in enumerate(numPointsGrid)

    #print("i equals $i\n")
    #print("tempNumPoints equals $tempNumPoints\n")
    #print("\n\n\n")
    # New guess
    algoPar.mGrid.numPoints = tempNumPoints
    modelPar = setModelParameters()
    mGrid,Δm = mGridBuild(algoPar.mGrid)
    initGuess = setInitialGuess(algoPar,modelPar,mGrid)
    @timev w_diag,V_diag,W_diag,μ_diag,g_diag,L_RD_diag,results,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess)

    V = results.incumbent.V
    idxM = results.finalGuess.idxM
    w = results.finalGuess.w
    zS = EndogenousGrowthWithSpinouts.zSFunc(algoPar,modelPar,idxM)
    zE = EndogenousGrowthWithSpinouts.zEFunc(modelPar,results.incumbent,w,zS)


    L_RD = results.finalGuess.L_RD
    #γ = results.finalGuess.γ
    w = results.finalGuess.w
    idxM = results.finalGuess.idxM
    V = results.incumbent.V
    zI = results.incumbent.zI
    zIfromFOC = zeros(size(zI))
    noncompete = results.incumbent.noncompete
    W = results.spinoutValue


    zS_density = zeros(size(zS))
    zS_density[2:end] = (zS ./ mGrid)[2:end]
    zS_density[1] = modelPar.ξ

    τI = EndogenousGrowthWithSpinouts.τIFunc(modelPar,zI,zS,zE)
    τSE = EndogenousGrowthWithSpinouts.τSEFunc(modelPar,zI,zS,zE)
    τE = EndogenousGrowthWithSpinouts.τEFunc(modelPar,zI,zS,zE)
    τS = zeros(size(τE))
    τS[:] = τSE[:] - τE[:]

    sFromS = modelPar.spinoutsFromSpinouts
    sFromE = modelPar.spinoutsFromEntrants

    L_F = EndogenousGrowthWithSpinouts.LF(L_RD,modelPar)

    τ = τI + τSE

    z = zS + zE + zI
    a = sFromE * zE .+ sFromS * zS .+ zI .* (1 .- noncompete)

    finalGoodsLabor = EndogenousGrowthWithSpinouts.LF(L_RD,modelPar)

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    aPrime = zeros(size(a))

    for i = 1:length(aPrime)-1

        aPrime[i] = (a[i+1] - a[i]) / Δm[i]

    end

    aPrime[end] = aPrime[end-1]

    ϕSE(z) = z .^(-modelPar.ψSE)
    ϕI(z) = z .^(-modelPar.ψI)
    χS = modelPar.χS
    λ = modelPar.λ
    ρ = modelPar.ρ
    ν = modelPar.ν
    ξ = modelPar.ξ
    ζ = modelPar.ζ
    ψI = modelPar.ψI
    χI = modelPar.χI
    β = modelPar.β
    #wbar = (β^β)*(1-β)^(2-2*β);

    wbar = EndogenousGrowthWithSpinouts.wbarFunc(β)
    Π = EndogenousGrowthWithSpinouts.profit(results.finalGuess.L_RD,modelPar)
    idxCNC = findfirst( (noncompete .> 0)[:] )


    # Welfare
    flowOutput = (((1-β) * wbar^(-1) )^(1-β))/(1-β) * L_F

    if noncompete[1] == 1
        spinoutEntryCost = 0
    else
        spinoutEntryCost = ζ * sum(τS .* γ .* μ .* Δm) * λ * V[1]
    end

    #welfare = (flowOutput - spinoutEntryCost) / (ρ - g)
    #welfare2 = flowOutput / (ρ - g)


    # Save welfare stats
    #welfareGrid[i,1] = welfare
    #welfareGrid[i,2] = welfare2

end

plot(700:10:900,welfareGrid,label = ["Welfare 1" "Welfare 2"], title = "Welfare with diff number of grid points", xlabel = "Number of grid points in mGrid", ylabel = "Units of social welfare")
