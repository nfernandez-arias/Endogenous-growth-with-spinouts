#---------------------------------#
# Name: setAlgorithmParameters.jl #
#                                 #
# This script defines an          #
# immutable struct with the the   #
# parameters for the algorithm.   #
# This includes grid sizes,       #
# tolerances for convergence, etc.#
#                                 #
# THIS CODE IS FRAGILE!!!         #
#---------------------------------#


struct AlgorithmParameters

    # State space
    mgridNumPoints::Int
    mgridMinimum::Float64
    mgridMaximum::Float64
    mgridLogSpacing::Bool

    # Finite difference
    incumbentTimeStep::Float64
    spinoutTimeStep::Float64

    # Tolerances
    researchLaborSupply_Tolerance::Float64
    researchWage_Tolerance::Float64
    researchEffortSpinouts_Tolerance::Float64
    researchEffortEntrants_Tolerance::Float64
    incumbentHJB_Tolerance::Float64
    spinoutHJB_Tolerance::Float64
    stationaryDistribution_Tolerance::Float64

    # MaxCounts
    incumbentHJB_maxCount::Int64
    L_RD_maxcount::Int64
    w_maxcount::Int64
    zS_maxcount::Int64
    zE_maxcount::Int64

    # Guess updating
    researchLaborSupply_UpdateRate::Float64
    researchWage_UpdateRate::Float64
    researchEffortSpinouts_UpdateRate::Float64
    researchEffortSpinouts_UpdateRateExponent::Float64
    researchEffortEntrants_UpdateRate::Float64
    researchEffortEntrants_UpdateRateExponent::Float64

end

function setAlgorithmParameters()

    mgridNumPoints = 100
    mgridMinimum = 0.0
    mgridMaximum = 10.0
    mgridLogSpacing = false

    incumbentTimeStep = 0.01
    spinoutTimeStep = 0.01

    researchLaborSupply_Tolerance = 0.01
    researchWage_Tolerance = 0.01
    researchEffortSpinouts_Tolerance = 0.01
    researchEffortEntrants_Tolerance = 0.01
    incumbentHJB_Tolerance = 0.01
    spinoutHJB_Tolerance = 0.01
    stationaryDistribution_Tolerance = 0.01

    incumbentHJB_maxCount = 20;
    L_RD_maxcount = 1;
    w_maxcount = 1;
    zS_maxcount = 1;
    zE_maxcount = 1;

    researchLaborSupply_UpdateRate = 0.5
    researchWage_UpdateRate = 0.5
    researchEffortSpinouts_UpdateRate = 0.5
    researchEffortSpinouts_UpdateRateExponent = 1.0
    researchEffortEntrants_UpdateRate = 0.5
    researchEffortEntrants_UpdateRateExponent = 1.0

    return AlgorithmParameters(mgridNumPoints,mgridMinimum,mgridMaximum,mgridLogSpacing,
                                   incumbentTimeStep,spinoutTimeStep,
                                   researchLaborSupply_Tolerance,researchWage_Tolerance,
                                   researchEffortSpinouts_Tolerance,researchEffortEntrants_Tolerance,
                                   incumbentHJB_Tolerance,spinoutHJB_Tolerance,stationaryDistribution_Tolerance,
                                   incumbentHJB_maxCount,L_RD_maxcount,w_maxcount,zS_maxcount,zE_maxcount,
                                   researchLaborSupply_UpdateRate,researchWage_UpdateRate,
                                   researchEffortSpinouts_UpdateRate,researchEffortSpinouts_UpdateRateExponent,
                                   researchEffortEntrants_UpdateRate,researchEffortEntrants_UpdateRateExponent)

end
