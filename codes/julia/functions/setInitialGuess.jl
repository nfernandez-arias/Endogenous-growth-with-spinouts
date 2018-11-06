#---------------------------------#
# Name: setInitialGuess.jl
#
# Function for setting initial guess
# to baseline setting, for testing the model solver.

function setInitialGuess(pa::AlgorithmParameters,pm::ModelParameters)

    L_RD = 0.1;

    β = pm.β;
    wbar = (β^β)*(1-β)^(2-2*β);
    w = 0.5 * wbar * ones(pa.mGrid.numPoints,1);

    #idxM = pa.mGrid.numPoints;

    zS = 0.1 * ones(pa.mGrid.numPoints,1);

    zE = zS;
    #zE = 0 * ones(pa.mGrid.numPoints,1);

    #return InitialGuess(L_RD,w,idxM,zS,zE)
    return InitialGuess(L_RD,w,zS,zE)

end
