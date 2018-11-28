#---------------------------------
# Name: InitializationModule.jl
#
# Module containing scripts for initializaiton
# in main.jl
#

__precompile__()

module InitializationModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule
export setAlgorithmParameters, setModelParameters, setInitialGuess

function setAlgorithmParameters()

    mgrid_numPoints = 500;
    mgrid_minimum = 0.0;
    mgrid_maximum = 10;
    mgrid_logSpacing = true;
    mgrid_logSpacingMinimum = 1e-12;

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum);

    incumbentHJB_timeStep = 100;
    incumbentHJB_tolerance = 1e-10;
    incumbentHJB_maxIter = 1;

    incumbentHJB = HJBellmanParameters(incumbentHJB_timeStep,incumbentHJB_tolerance,incumbentHJB_maxIter);

    spinoutHJB_timeStep = 0.01;
    spinoutHJB_tolerance = 1e-3;
    spinoutHJB_maxIter = 1;

    spinoutHJB = HJBellmanParameters(spinoutHJB_timeStep,spinoutHJB_tolerance,spinoutHJB_maxIter);

    L_RD_tolerance = 1e-2;
    L_RD_maxIter = 1;
    L_RD_updateRate = 0.5;
    L_RD_updateRateExponent = 1;

    L_RD = IterationParameters(L_RD_tolerance,L_RD_maxIter,L_RD_updateRate,L_RD_updateRateExponent);

    w_tolerance = 1e-2;
    w_maxIter = 1;
    w_updateRate = 0.5;
    w_updateRateExponent = 1;

    w = IterationParameters(w_tolerance,w_maxIter,w_updateRate,w_updateRateExponent);

    zSzE_tolerance = 1e-4;
    zSzE_maxIter = 10;
    zSzE_updateRate = 0.1;
    zSzE_updateRateExponent = 1;

    zSzE = IterationParameters(zSzE_tolerance,zSzE_maxIter,zSzE_updateRate,zSzE_updateRateExponent);

    # Logging parameters

    L_RD_w_Log_verbose = 2;
    L_RD_w_Log_print_skip = 10;
    L_RD_w_Log = LogParameters(L_RD_w_Log_verbose,L_RD_w_Log_print_skip);

    zSzE_Log_verbose = 2;
    zSzE_Log_print_skip = 1;
    zSzE_Log = LogParameters(zSzE_Log_verbose,zSzE_Log_print_skip);

    incumbentHJB_Log_verbose = 2;
    incumbentHJB_Log_print_skip = 100;
    incumbentHJB_Log = LogParameters(incumbentHJB_Log_verbose,incumbentHJB_Log_print_skip);

    return AlgorithmParameters(mGrid, incumbentHJB, spinoutHJB, L_RD, w, zSzE, L_RD_w_Log, zSzE_Log, incumbentHJB_Log);

end

function setModelParameters()

    # General
    ρ = 0.03;
    β = 0.2;
    L = 1.0;

    # Innovation
    χI = 1.5;
    χS = 1;
    χE = 0.5;
    ψI = 0.5;
    ψSE = 0.5;
    λ = 1.2;

    # Spinouts
    ν = 0.3;
    ξ = 0.2;

    return ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,ξ);

end

function setInitialGuess(pa::AlgorithmParameters,pm::ModelParameters,mGrid)

    L_RD = 0.1;

    β = pm.β;
    wbar = (β^β)*(1-β)^(2-2*β);
    w = 0.1 * wbar * ones(size(mGrid));

    #idxM = pa.mGrid.numPoints;

    #zS = pm.ξ .* mGrid

    zS = 0.01 * ones(size(mGrid))
    zE = zS

    #zE = zeros(size(zS))

    #return InitialGuess(L_RD,w,idxM,zS,zE)
    return Guess(L_RD,w,zS,zE)

end



end
