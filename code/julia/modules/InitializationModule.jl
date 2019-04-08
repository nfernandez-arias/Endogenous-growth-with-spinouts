#---------------------------------
# Name: InitializationModule.jl
#
# Module containing scripts for initializaiton
# in main.jl
#

__precompile__()

module InitializationModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule
using AuxiliaryModule

export setAlgorithmParameters, setModelParameters, setInitialGuess

function setAlgorithmParameters()

    f = open("./figures/algoPar.txt", "w")

    mgrid_numPoints = 1000
    mgrid_minimum = 0.0
    mgrid_maximum = .015
    mgrid_logSpacing = true
    mgrid_logSpacingMinimum = 1e-8

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum);

    write(f, "mGrid Parameters \n---------------\n")
    for n in fieldnames(mGridParameters)
        temp = getfield(mGrid,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    incumbentHJB_timeStep = 50;
    incumbentHJB_tolerance = 1e-7;
    incumbentHJB_maxIter = 30

    incumbentHJB = HJBellmanParameters(incumbentHJB_timeStep,incumbentHJB_tolerance,incumbentHJB_maxIter);

    write(f, "Incumbent HJB Parameters \n---------------\n")
    for n in fieldnames(HJBellmanParameters)
        temp = getfield(incumbentHJB,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    spinoutHJB_timeStep = 0.01;
    spinoutHJB_tolerance = 1e-3;
    spinoutHJB_maxIter = 1;

    spinoutHJB = HJBellmanParameters(spinoutHJB_timeStep,spinoutHJB_tolerance,spinoutHJB_maxIter);

    write(f, "Spinout HJB Parameters \n---------------\n")
    for n in fieldnames(HJBellmanParameters)
        temp = getfield(spinoutHJB,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    g_tolerance = 1e-7;
    g_maxIter = 500;
    g_updateRate = 0.3;
    g_updateRateExponent = 1;

    g = IterationParameters(g_tolerance,g_maxIter,g_updateRate,g_updateRateExponent);

    write(f, "g Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(g,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    L_RD_tolerance = 1e-7;
    L_RD_maxIter = 500;
    L_RD_updateRate = 0.3;
    L_RD_updateRateExponent = 1;

    L_RD = IterationParameters(L_RD_tolerance,L_RD_maxIter,L_RD_updateRate,L_RD_updateRateExponent);

    write(f, "L_RD Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(L_RD,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    w_tolerance = 1e-7;
    w_maxIter = 500;
    w_updateRate = 0.3;
    w_updateRateExponent = 1;

    w = IterationParameters(w_tolerance,w_maxIter,w_updateRate,w_updateRateExponent);

    write(f, "w Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(w,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    zSzE_tolerance = 1e-9;
    zSzE_maxIter = 150;
    zSzE_updateRate = 0.3;
    zSzE_updateRateExponent = 1;

    zSzE = IterationParameters(zSzE_tolerance,zSzE_maxIter,zSzE_updateRate,zSzE_updateRateExponent);

    write(f, "zSzE Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(zSzE,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    # Logging parameters

    g_L_RD_w_Log_verbose = 2;
    g_L_RD_w_Log_print_skip = 1;
    g_L_RD_w_Log = LogParameters(g_L_RD_w_Log_verbose,g_L_RD_w_Log_print_skip);

    write(f, "g,L_RD,w Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(g_L_RD_w_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    zSzE_Log_verbose = 2;
    zSzE_Log_print_skip = 1;
    zSzE_Log = LogParameters(zSzE_Log_verbose,zSzE_Log_print_skip);

    write(f, "zSzE Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(zSzE_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    incumbentHJB_Log_verbose = 2;
    incumbentHJB_Log_print_skip = 100;
    incumbentHJB_Log = LogParameters(incumbentHJB_Log_verbose,incumbentHJB_Log_print_skip);

    write(f, "incumbent HJB Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(incumbentHJB_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    close(f)

    return AlgorithmParameters(mGrid, incumbentHJB, spinoutHJB, g, L_RD, w, zSzE, g_L_RD_w_Log, zSzE_Log, incumbentHJB_Log);

end

function setModelParameters()

    # General
    ρ = 0.05
    β = 0.106
    L = 1

    # Innovation
    χI = 3.2523
    χS = 1.42543
    χE = 1.2029
    ψI = 0.5
    ψSE = 0.5
    λ = 1.0532733

    # Spinouts
    ν = 0.0102495
    ξ = 10

    modelPar = ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,ξ)

    f = open("./figures/modelPar.txt", "w")

    write(f, "Model Parameters \n---------------\n")
    for n in fieldnames(ModelParameters)
        temp = getfield(modelPar,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    close(f)

    return modelPar

end

function setInitialGuess(pa::AlgorithmParameters,pm::ModelParameters,mGrid)

    g = 0.01

    L_RD = 0.1;

    β = pm.β;
    #wbar = (β^β)*(1-β)^(2-2*β);
    wbar = AuxiliaryModule.Cβ(β)

    w = wbar * ones(size(mGrid));
    #w = 0.5 * wbar * ones(pa.mGrid.numPoints,1)

    #idxM = pa.mGrid.numPoints;

    zS = pm.ξ .* mGrid

    #zS = 0.1 * ones(pa.mGrid.numPoints,1)

    #zE = 0.1 * zS

    zE = 0.1*ones(size(zS))
    #zE = 0 * ones(pa.mGrid.numPoints,1);

    #return InitialGuess(L_RD,w,idxM,zS,zE)
    initGuess = Guess(g,L_RD,w,zS,zE)

    return initGuess

end


end