



function spinoutMassDecomposition(algoPar::AlgorithmParameters,modelPar::ModelParameters,guess::Guess,incumbentSolution::IncumbentSolution)

    # Unpack model parameters
    ν = modelPar.ν
    sFromE = modelPar.spinoutsFromEntrants
    sFromS = modelPar.spinoutsFromSpinouts


    # Unpack guesses
    g = guess.g
    L_RD = guess.L_RD
    w = guess.w
    idxM = guess.idxM

    # Unpack incumbentSolution
    V = incumbentSolution.V
    zI = incumbentSolution.zI
    noncompete = incumbentSolution.noncompete

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    mI = zeros(size(mGrid))
    mS = zeros(size(mGrid))
    mE = zeros(size(mGrid))

    mI_frac = zeros(size(mGrid))
    mS_frac = zeros(size(mGrid))
    mE_frac = zeros(size(mGrid))

    for i = 2:length(mGrid))

        mI[i] = ν * sum( zI[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])
        mS[i] = sFromS * ν * sum( zS[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])
        mE[i] = sFromE * ν * sum( zE[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])

    end

    mI_frac[2:end] = mI[2:end] ./ mGrid[2:end]
    mS_frac[2:end] = mS[2:end] ./ mGrid[2:end]
    mE_frac[2:end] = mE[2:end] ./ mGrid[2:end]

    return mIFrac,mSFrac,mEFrac

end
