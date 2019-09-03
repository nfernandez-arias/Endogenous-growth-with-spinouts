



function spinoutMassDecomposition(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,incumbentSolution::IncumbentSolution,μ::Array{Float64},γ::Array{Float64},t::Array{Float64})

    # Unpack model parameters
    ν = modelPar.ν
    θ = modelPar.θ
    sFromE = modelPar.spinoutsFromEntrants
    sFromS = modelPar.spinoutsFromSpinouts


    # Unpack guesses
    g = guess.g
    L_RD = guess.L_RD
    w = guess.w
    wE = guess.wE
    wNC = guess.wNC
    idxM = guess.idxM
    driftNC = guess.driftNC

    # Unpack incumbentSolution
    V = incumbentSolution.V
    zI = incumbentSolution.zI
    noncompete = incumbentSolution.noncompete

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    zS = zSFunc(algoPar,modelPar,idxM)
    zE = zEFunc(modelPar,incumbentSolution,w,wE,zS)

    a = driftNC*ones(size(zI)) + (1-θ) * ν * (sFromE * zE + sFromS * zS + (1 .- noncompete) .* zI)

    mI = zeros(size(mGrid))
    mS = zeros(size(mGrid))
    mE = zeros(size(mGrid))

    mIFrac = zeros(size(mGrid))
    mSFrac = zeros(size(mGrid))
    mEFrac = zeros(size(mGrid))
    mI_NC_Frac = zeros(size(mGrid))
    mS_NC_Frac = zeros(size(mGrid))

    for i = 2:length(mGrid)

        mI[i] = ν * (1-θ) * sum( (1 .- noncompete[1:i-1]) .* zI[1:i-1] .* a[1:i-1].^(-1) .* Δm[1:i-1])
        mS[i] = sFromS * (1-θ) * ν * sum( zS[1:i-1] .* a[1:i-1].^(-1) .* Δm[1:i-1])
        mE[i] = sFromE * (1-θ) * ν * sum( zE[1:i-1] .* a[1:i-1].^(-1) .* Δm[1:i-1])

    end

    mI_NC = abarIncumbentsFunc(algoPar,modelPar,zI,μ,γ) * t
    mS_NC = abarFunc(algoPar,modelPar,zI,zS,zE,μ,γ) * t - mI_NC

    mIFrac[2:end] = mI[2:end] ./ mGrid[2:end]
    mSFrac[2:end] = mS[2:end] ./ mGrid[2:end]
    mEFrac[2:end] = mE[2:end] ./ mGrid[2:end]
    mI_NC_Frac[2:end] = mI_NC[2:end] ./ mGrid[2:end]
    mS_NC_Frac[2:end] = mS_NC[2:end] ./ mGrid[2:end]


    return mIFrac,mSFrac,mEFrac,mI_NC_Frac,mS_NC_Frac

end
