#---------------------------------
# Name: InitializationModuleScript.jl
#
# Module containing scripts for initializaiton
# in main.jl
#

export setAlgorithmParameters, setModelParameters, setInitialGuess

function setAlgorithmParameters()

    outerLoopMax = 100

    f = open("./figures/algoPar.txt", "w")

    mgrid_numPoints = 700
    mgrid_minimum = 0.0
    mgrid_maximum = 0.2
    mgrid_logSpacing = true
    mgrid_logSpacingMinimum = 1e-10 * mgrid_maximum

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum)

    write(f, "mGrid Parameters \n---------------\n")
    for n in fieldnames(mGridParameters)
        temp = getfield(mGrid,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    incumbentHJB_timeStep = 100
    incumbentHJB_tolerance = 1e-8
    incumbentHJB_maxIter = 20

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
    w_updateRate = 0.3
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
    incumbentHJB_Log_print_skip = 2
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
    χI = 2.1973
    χE = 0.5
    χS = 2 * χE
    ψI = 0.5
    ψSE = 0.5
    λ = 1.07998
    #λ = 1.10

    # Spinouts
    #ν = 0.0102495
    ν = 0.2
    θ = 0.5
    ξ = 1
    ζ = 0

    # Creative destruction cost
    κ = 0.4

    # CNCs
    CNC = false

    # Rate of Spinout formation of spinouts and entrants

    spinoutsFromSpinouts = 0
    spinoutsFromEntrants = 0.000000001

    # Spinouts ideas from different pool?

    spinoutsSamePool = false

    modelPar = ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,θ,ξ,ζ,κ,CNC,spinoutsFromSpinouts,spinoutsFromEntrants,spinoutsSamePool)

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
    wbar = wbarFunc(β)
    w = 0.5 * wbar * ones(size(mGrid))

    wNC = w
    wE = w

    idxM = ceil(pa.mGrid.numPoints / 2)

    driftNC = 0.1

    initGuess = Guess(g,L_RD,w,wNC,wE,idxM,driftNC)

    return initGuess

end
