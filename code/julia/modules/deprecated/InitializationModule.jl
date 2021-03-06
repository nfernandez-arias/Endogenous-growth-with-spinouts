#---------------------------------
# Name: InitializationModule.jl
#
# Module containing scripts for initializaiton
# in main.jl
#

__precompile__()

module InitializationModule

#include("./AlgorithmParametersModule.jl")
#include("./ModelParametersModule.jl")
#include("./GuessModule.jl")
#include("./AuxiliaryModule.jl")

using AlgorithmParametersModule, ModelParametersModule, GuessModule, AuxiliaryModule

export setAlgorithmParameters, setModelParameters, setInitialGuess

function setAlgorithmParameters()

    outerLoopMax = 2

    f = open("./figures/algoPar.txt", "w")

    mgrid_numPoints = 500
    mgrid_minimum = 0.0
    mgrid_maximum = .02
    mgrid_logSpacing = true
    mgrid_logSpacingMinimum = 1e-10 * mgrid_maximum

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum)

    write(f, "mGrid Parameters \n---------------\n")
    for n in fieldnames(mGridParameters)
        temp = getfield(mGrid,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    incumbentHJB_timeStep = 50
    incumbentHJB_tolerance = 1e-8
    incumbentHJB_maxIter = 200

    incumbentHJB = HJBellmanParameters(incumbentHJB_timeStep,incumbentHJB_tolerance,incumbentHJB_maxIter)

    write(f, "Incumbent HJB Parameters \n---------------\n")
    for n in fieldnames(HJBellmanParameters)
        temp = getfield(incumbentHJB,n)
        write(f,"$n: $temp \n")false
    end
    write(f, "\n\n")

    spinoutHJB_timeStep = 0.01
    spinoutHJB_tolerance = 1e-3
    spinoutHJB_maxIter = 150

    spinoutHJB = HJBellmanParameters(spinoutHJB_timeStep,spinoutHJB_tolerance,spinoutHJB_maxIter)

    write(f, "Spinout HJB Parameters \n---------------\n")
    for n in fieldnames(HJBellmanParameters)
        temp = getfield(spinoutHJB,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    g_tolerance = 1e-7
    g_maxIter = outerLoopMax
    g_updateRate = 0.3
    g_updateRateExponent = 1

    g = IterationParameters(g_tolerance,g_maxIter,g_updateRate,g_updateRateExponent)

    write(f, "g Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(g,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    L_RD_tolerance = 1e-7
    L_RD_maxIter = outerLoopMax
    L_RD_updateRate = 0.3
    L_RD_updateRateExponent = 1

    L_RD = IterationParameters(L_RD_tolerance,L_RD_maxIter,L_RD_updateRate,L_RD_updateRateExponent)

    write(f, "L_RD Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(L_RD,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    w_tolerance = 1e-7
    w_maxIter = outerLoopMax
    w_updateRate = 0.1
    w_updateRateExponent = 1

    w = IterationParameters(w_tolerance,w_maxIter,w_updateRate,w_updateRateExponent)

    write(f, "w Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(w,n)true
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    idxM_tolerance = 1e-7
    idxM_maxIter = 50
    idxM_updateRate = 0.8
    idxM_updateRateExponent = 1

    idxM = IterationParameters(idxM_tolerance,idxM_maxIter,idxM_updateRate,idxM_updateRateExponent)

    write(f, "idxM Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(idxM,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    # Logging parameters

    g_L_RD_w_Log_verbose = 2
    g_L_RD_w_Log_print_skip = 1
    g_L_RD_w_Log = LogParameters(g_L_RD_w_Log_verbose,g_L_RD_w_Log_print_skip)

    write(f, "g,L_RD,w Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(g_L_RD_w_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    idxM_Log_verbose = 2
    idxM_Log_print_skip = 1
    idxM_Log = LogParameters(idxM_Log_verbose,idxM_Log_print_skip)

    write(f, "zSzE Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(idxM_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    incumbentHJB_Log_verbose = 2
    incumbentHJB_Log_print_skip = 1
    incumbentHJB_Log = LogParameters(incumbentHJB_Log_verbose,incumbentHJB_Log_print_skip)

    write(f, "incumbent HJB Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(incumbentHJB_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    close(f)

    return AlgorithmParameters(mGrid, incumbentHJB, spinoutHJB, g, L_RD, w, idxM, g_L_RD_w_Log, idxM_Log, incumbentHJB_Log)

end

function setModelParameters()

    # General
    ρ = 0.05
    β = 0.106
    L = 1

    # Innovation
    χI = 3
    χS = 1.5
    χE = 0.7
    ψI = 0.5
    ψSE = 0.5
    λ = 1.0532733

    # Spinouts
    ν = 0.0102495
    ξ = 20
    ζ = 0

    # CNCs
    CNC = false

    # Rate of Spinout formation of spinouts (fraction of rate for incumbents)

    spinoutsFromSpinouts = 0.5

    # Spinouts ideas from different pool?

    spinoutsSamePool = false

    modelPar = ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,ξ,ζ,CNC,spinoutsFromSpinouts,spinoutsSamePool)

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

    L_RD = 0.1

    β = pm.β
    #wbar = (β^β)*(1-β)^(2-2*β);
    wbar = AuxiliaryModule.Cβ(β)

    w = wbar * ones(size(mGrid))
    #w = 0.5 * wbar * ones(pa.mGrid.numPoints,1)


    #idxM = ceil(pa.mGrid.numPoints / 2)

    idxM = 1
    #idxM = 1

    #zS = pm.ξ .* mGrid

    #zS = 0.1 * ones(pa.mGrid.numPoints,1)

    #zE = 0.1 * zS

    #zE = 0.1*ones(size(zS))
    #zE = 0 * ones(pa.mGrid.numPoints,1);

    #return InitialGuess(L_RD,w,idxM,zS,zE)
    initGuess = Guess(g,L_RD,w,idxM)

    return initGuess

end


end
