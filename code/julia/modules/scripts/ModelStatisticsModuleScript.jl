



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

    zS = zSFunc(algoPar,modelPar,idxM)
    zE = zEFunc(modelPar,incumbentSolution,w,zS)

    a = sFromE * zE + sFromS * zS + zI

    mI = zeros(size(mGrid))
    mS = zeros(size(mGrid))
    mE = zeros(size(mGrid))

    mIFrac = zeros(size(mGrid))
    mSFrac = zeros(size(mGrid))
    mEFrac = zeros(size(mGrid))

    for i = 2:length(mGrid)

        mI[i] = ν * sum( zI[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])
        mS[i] = sFromS * ν * sum( zS[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])
        mE[i] = sFromE * ν * sum( zE[1:i-1] .* ((ν*a[1:i-1]).^(-1)) .* Δm[1:i-1])

    end

    mIFrac[2:end] = mI[2:end] ./ mGrid[2:end]
    mSFrac[2:end] = mS[2:end] ./ mGrid[2:end]
    mEFrac[2:end] = mE[2:end] ./ mGrid[2:end]

    return mIFrac,mSFrac,mEFrac

end
