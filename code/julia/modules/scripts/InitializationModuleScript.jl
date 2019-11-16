#---------------------------------
# Name: InitializationModuleScript.jl
#
# Module containing scripts for initializaiton
# in main.jl
#

export setAlgorithmParameters, setModelParameters, setInitialGuess

function setAlgorithmParameters()

    outerLoopMax = 200

    f = open("./figures/algoPar.txt", "w")

    mgrid_numPoints = 2000
    mgrid_minimum = 0.0
    mgrid_maximum = 0.2
    mgrid_logSpacing = true
    mgrid_logSpacingMinimum = 1e-8 * mgrid_maximum

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum)

    write(f, "mGrid Parameters \n---------------\n")
    for n in fieldnames(mGridParameters)
        temp = getfield(mGrid,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    # Set parameters for inner loop - solving PDE using implicit scheme GIVEN policy function

    incumbentHJB_inner_timeStep = 1000
    incumbentHJB_inner_tolerance = 1e-8
    incumbentHJB_inner_maxIter = 30

    incumbentHJB_inner = HJBellmanParameters(incumbentHJB_inner_timeStep,incumbentHJB_inner_tolerance,incumbentHJB_inner_maxIter)

    write(f, "Incumbent HJB Parameters \n---------------\n")
    for n in fieldnames(HJBellmanParameters)
        temp = getfield(incumbentHJB_inner,n)
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

    incumbentHJB_outer_tolerance = 1e-5
    incumbentHJB_outer_maxIter = 15
    incumbentHJB_outer_updateRate = 0.1
    incumbentHJB_outer_updateRateExponent = 1

    incumbentHJB_outer = IterationParameters(incumbentHJB_outer_tolerance,incumbentHJB_outer_maxIter,incumbentHJB_outer_updateRate,incumbentHJB_outer_updateRateExponent)

    write(f, "g Iteration Parameters \n---------------\n")
    for n in fieldnames(IterationParameters)
        temp = getfield(incumbentHJB_outer,n)
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
    idxM_updateRate = 0.6
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

    incumbentHJB_outer_Log_verbose = 2
    incumbentHJB_outer_Log_print_skip = 2
    incumbentHJB_outer_Log = LogParameters(incumbentHJB_outer_Log_verbose,incumbentHJB_outer_Log_print_skip)

    write(f, "incumbent HJB Outer Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(incumbentHJB_outer_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    incumbentHJB_inner_Log_verbose = 2
    incumbentHJB_inner_Log_print_skip = 2
    incumbentHJB_inner_Log = LogParameters(incumbentHJB_inner_Log_verbose,incumbentHJB_inner_Log_print_skip)

    write(f, "incumbent HJB Inner Logging Parameters \n---------------\n")
    for n in fieldnames(LogParameters)
        temp = getfield(incumbentHJB_inner_Log,n)
        write(f,"$n: $temp \n")
    end
    write(f, "\n\n")

    close(f)

    return AlgorithmParameters(mGrid, incumbentHJB_outer, incumbentHJB_inner, spinoutHJB, g, L_RD, w, idxM, g_L_RD_w_Log, idxM_Log, incumbentHJB_outer_Log, incumbentHJB_inner_Log)

end

function setModelParameters()

    # General
    ρ = 0.05
    β = 0.106
    L = 1

    # Innovation
    χI = 2.1973
    χE = 0.6923
    χS = 1.5 * χE
    ψI = 0.5
    ψSE = 0.5
    λ = 1.07998
    #λ = 1.10

    # Spinouts
    #ν = 0.0102495
    ν = .255
    θ = 0.55
    ξ = 1
    ζ = 0

    # Creative destruction cost
    κ = 0

    # CNCs
    CNC = true

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

    wNC = wbar * ones(size(mGrid))
    wE = wbar * ones(size(mGrid))

    idxM = ceil(pa.mGrid.numPoints * 0.5)
    #idxM = 1

    driftNC = 0.1

    initGuess = Guess(g,L_RD,w,wNC,wE,idxM,driftNC)

    return initGuess

end
