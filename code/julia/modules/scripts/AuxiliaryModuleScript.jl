#---------------------------------
# Name: AuxiliaryModule.jl
#
# Module containing auxiliary
# functions for solving model
#
# E.g., profit as funciton of L_RD guess

#include("./AlgorithmParametersModule.jl")
#include("./ModelParametersModule.jl")
#include("./GuessModule.jl")

#

#export Cβ,LF,profit,wbarFunc,initialGuessIncumbentHJB,zSFunc,zEFunc,τSEFunc,τEFunc,τIFunc

function Cβ(β::Float64)

    return (β/(1-β) * (1-β)^((1-β)/β))^β

end

function LF(L_RD::Float64, modelPar::ModelParameters)

    β,L = modelPar.β, modelPar.L;
    Cβconst = Cβ(β)
    #return β * (L - L_RD) / (β + (1-β)^2);

    return (L-L_RD) / (1 + (1-β)/Cβconst)

end

function LF(L_RD::Array{Float64}, modelPar::ModelParameters)

    β,L = modelPar.β, modelPar.L;
    Cβconst = Cβ(β)
    #return β * (L - L_RD) / (β + (1-β)^2);

    return (ones(size(L_RD)) * L -L_RD) / (1 + (1-β)/Cβconst)

end



function profit(L_RD::Float64, modelPar::ModelParameters)

    β = modelPar.β;
    #return β * (1-β)^((2-β)/β) * β^(-1) * LF(L_RD,modelPar);

    return β * LF(L_RD, modelPar)

end

function wbarFunc(β::Float64)

    #return (β^β)*(1-β)^(2-2*β);
    return Cβ(β)

end

function zSFunc(algoPar::AlgorithmParameters,modelPar::ModelParameters,idxM::Int64)

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    zS = ones(size(mGrid))
    zS[1:idxM] = modelPar.ξ * mGrid[1:idxM]

    #println("$(typeof(idxM))")

    #println("idxM = $idxM")

    if idxM == length(mGrid)
        return zS
    else
        zS[idxM+1:end] = ones(size(zS[idxM+1:end])) * zS[idxM]
        return zS
    end

end

function zEFunc(modelPar::ModelParameters,V0::Float64,zI::Array{Float64},w::Array{Float64},wE::Array{Float64}, zS::Array{Float64})

    #wE = (modelPar.spinoutsFromEntrants * w + (1 - modelPar.spinoutsFromEntrants) * wbarFunc(modelPar.β) * ones(size(w)))

    if modelPar.spinoutsSamePool == true

        zE = max.( (wE ./ (modelPar.χE * (modelPar.λ * (1-modelPar.κ) .* V0))).^(-1/modelPar.ψI) .- zS .- zI,0)

    else

        zE = max.( (wE ./ (modelPar.χE * (modelPar.λ * (1-modelPar.κ) .* V0))).^(-1/modelPar.ψSE) .- zS,0)

    end

    return zE

end

function zEFunc(modelPar::ModelParameters,incumbentHJBSolution::IncumbentSolution,w::Array{Float64},wE::Array{Float64},zS::Array{Float64})

    V = incumbentHJBSolution.V
    zI = incumbentHJBSolution.zI

    V0 = V[1]

    return zEFunc(modelPar,V0,zI,w,wE,zS)

end

function abarFunc(algoPar::AlgorithmParameters,modelPar::ModelParameters,zI::Array{Float64},zS::Array{Float64},zE::Array{Float64},μ::Array{Float64},γ::Array{Float64})

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    θ = modelPar.θ
    ν = modelPar.ν
    sFromS = modelPar.spinoutsFromSpinouts
    sFromE = modelPar.spinoutsFromEntrants

    abar = θ * ν * sum( (zI + sFromS * zS) .* γ .* μ .* Δm )

    return abar

end

function abarIncumbentsFunc(algoPar::AlgorithmParameters,modelPar::ModelParameters,zI::Array{Float64},μ::Array{Float64},γ::Array{Float64})

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    θ = modelPar.θ
    ν = modelPar.ν
    sFromS = modelPar.spinoutsFromSpinouts
    sFromE = modelPar.spinoutsFromEntrants

    abar = θ * ν * sum( zI .* γ .* μ .* Δm )

    return abar

end

function aFunc(modelPar::ModelParameters,zI::Array{Float64},zS::Array{Float64},zE::Array{Float64},abar::Float64)

    θ = modelPar.θ
    ν = modelPar.ν
    sFromE = modelPar.spinoutsFromEntrants
    sFromS = modelPar.spinoutsFromSpinouts

    a = abar * ones(size(zI)) + (1-θ) * ν * (zI + sFromS * zS + sFromE * zE)

    return a

end

function WcalFunc(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,W::Array{Float64},μ::Array{Float64},γ::Array{Float64},CNC::Bool)

    if CNC == true

        modelPar.CNC = true

        return WcalFunc(algoPar,modelPar,guess,W,μ,γ)

    else

        modelPar.CNC = false

        return WcalFunc(algoPar,modelPar,guess,W,μ,γ)

    end

end

function WcalFunc(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,W::Array{Float64},μ::Array{Float64},γ::Array{Float64})

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    θ = modelPar.θ
    ν = modelPar.ν
    sFromS = modelPar.spinoutsFromSpinouts
    sFromE = modelPar.spinoutsFromEntrants

    Wcal = sum(W .* γ .* μ .* Δm)

    return Wcal

end

function τSEFunc(modelPar::ModelParameters,zI::Array{Float64},zS::Array{Float64},zE::Array{Float64})

    χS = modelPar.χS
    χE = modelPar.χE

    ψSE = modelPar.ψSE
    ψI = modelPar.ψI

    ϕSE(z) = z .^(-ψSE)
    ϕI(z) = z .^(-ψI)

    if modelPar.spinoutsSamePool == true

        return (χS * zS + χE * zE) .* ϕI(zS + zI + zE)

    else

        return (χS * zS + χE * zE) .* ϕSE(zS + zE)

    end

end

function τEFunc(modelPar::ModelParameters,zI::Array{Float64},zS::Array{Float64},zE::Array{Float64})

    χE = modelPar.χE

    ψSE = modelPar.ψSE
    ψI = modelPar.ψI

    ϕSE(z) = z .^(-ψSE)
    ϕI(z) = z .^(-ψI)

    if modelPar.spinoutsSamePool == true

        return χE * zE .* ϕI(zI + zS + zE)

    else

        return χE * zE .* ϕSE(zS + zE)

    end

end

function τIFunc(modelPar::ModelParameters,zI::Array{Float64})

    χI = modelPar.χI

    ψI = modelPar.ψI

    ϕI(z) = z .^(-ψI)

    return χI * zI .* ϕI(zI)

end

function τIFunc(modelPar::ModelParameters,zI::Array{Float64},zS::Array{Float64},zE::Array{Float64})

    χI = modelPar.χI

    ψI = modelPar.ψI

    ϕI(z) = z .^(-ψI)

    if modelPar.spinoutsSamePool == true

        return χI * zI .* ϕI(zI + zS + zE)

    else

        return χI * zI .* ϕI(zI)

    end

end

function initialGuessIncumbentHJB(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess)

    # Calculate initial guess for incumbent value function

    return (profit(guess.L_RD, modelPar) / modelPar.ρ) * ones(algoPar.mGrid.numPoints,1);

end
