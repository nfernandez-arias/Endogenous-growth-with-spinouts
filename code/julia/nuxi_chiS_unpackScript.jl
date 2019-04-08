# Filename: nuxi_chiS_unpackScript.jl
#
# Contains script for unpacking stuff from results

## Unpack results
# and compute some equilibrium variables

function nuxi_chiS_unpack(i,j,resultsMatrix)

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

end
