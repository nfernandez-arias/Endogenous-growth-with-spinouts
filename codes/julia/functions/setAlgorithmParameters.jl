#---------------------------------
# Name: setAlgorithmParameters.jl
#
# Function for setting algorithm parameters
# to baseline setting, for testing the model solver.
#


function setAlgorithmParameters()

    mgrid_numPoints = 100;
    mgrid_minimum = 0.0;
    mgrid_maximum = 10.0;
    mgrid_logSpacing = true;
    mgrid_logSpacingMinimum = 0.01;

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum);

    incumbentHJB_timeStep = 0.01;
    incumbentHJB_tolerance = 0.01;
    incumbentHJB_maxIter = 20;

    incumbentHJB = HJBellmanParameters(incumbentHJB_timeStep,incumbentHJB_tolerance,incumbentHJB_maxIter);

    spinoutHJB_timeStep = 0.01;
    spinoutHJB_tolerance = 0.01;
    spinoutHJB_maxIter = 20;

    spinoutHJB = HJBellmanParameters(spinoutHJB_timeStep,spinoutHJB_tolerance,spinoutHJB_maxIter);

    L_RD_tolerance = 0.01;
    L_RD_maxIter = 1;
    L_RD_updateRate = 0.5;
    L_RD_updateRateExponent = 1;

    L_RD = IterationParameters(L_RD_tolerance,L_RD_maxIter,L_RD_updateRate,L_RD_updateRateExponent);

    w_tolerance = 0.01;
    w_maxIter = 1;
    w_updateRate = 0.5;
    w_updateRateExponent = 1;

    w = IterationParameters(w_tolerance,w_maxIter,w_updateRate,w_updateRateExponent);

    zS_tolerance = 0.01;
    zS_maxIter = 1;
    zS_updateRate = 0.5;
    zS_updateRateExponent = 1;

    zS = IterationParameters(zS_tolerance,zS_maxIter,zS_updateRate,zS_updateRateExponent);

    zE_tolerance = 0.01;
    zE_maxIter = 1;
    zE_updateRate = 0.5;
    zE_updateRateExponent = 1;

    zE = IterationParameters(zE_tolerance,zE_maxIter,zE_updateRate,zE_updateRateExponent);

    return AlgorithmParameters(mGrid,incumbentHJB,spinoutHJB,L_RD,w,zS,zE);

end
