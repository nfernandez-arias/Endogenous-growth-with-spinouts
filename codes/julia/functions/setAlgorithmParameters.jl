#---------------------------------
# Name: setAlgorithmParameters.jl
#
# Function for setting algorithm parameters
# to baseline setting, for testing the model solver.
#


function setAlgorithmParameters()

    mgrid_numPoints = 500;
    mgrid_minimum = 0.0;
    mgrid_maximum = 1;
    mgrid_logSpacing = true;
    mgrid_logSpacingMinimum = 0.00001;

    mGrid = mGridParameters(mgrid_numPoints,mgrid_minimum,mgrid_maximum,mgrid_logSpacing,mgrid_logSpacingMinimum);

    incumbentHJB_timeStep = 1;
    incumbentHJB_tolerance = 0.001;
    incumbentHJB_maxIter = 50;

    incumbentHJB = HJBellmanParameters(incumbentHJB_timeStep,incumbentHJB_tolerance,incumbentHJB_maxIter);

    spinoutHJB_timeStep = 0.01;
    spinoutHJB_tolerance = 0.01;
    spinoutHJB_maxIter = 1;

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

    zSzE_tolerance = 0.01;
    zSzE_maxIter = 1;
    zSzE_updateRate = 0.5;
    zSzE_updateRateExponent = 1;

    zSzE = IterationParameters(zSzE_tolerance,zSzE_maxIter,zSzE_updateRate,zSzE_updateRateExponent);

    # Logging parameters

    L_RD_w_Log_verbose = 2;
    L_RD_w_Log_print_skip = 10;
    L_RD_w_Log = LogParameters(L_RD_w_Log_verbose,L_RD_w_Log_print_skip);

    zSzE_Log_verbose = 2;
    zSzE_Log_print_skip = 10;
    zSzE_Log = LogParameters(zSzE_Log_verbose,zSzE_Log_print_skip);

    incumbentHJB_Log_verbose = 2;
    incumbentHJB_Log_print_skip = 1;
    incumbentHJB_Log = LogParameters(incumbentHJB_Log_verbose,incumbentHJB_Log_print_skip);



    return AlgorithmParameters(mGrid, incumbentHJB, spinoutHJB, L_RD, w, zSzE, L_RD_w_Log, zSzE_Log, incumbentHJB_Log);

end
