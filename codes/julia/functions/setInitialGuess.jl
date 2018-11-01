#---------------------------------#
# Name: setInitialGuess.jl
#
# Function for setting initial guess
# to baseline setting, for testing the model solver.
#

function setInitialGuess(pa::AlgorithmParameters,pm::ModelParameters)

    L_RD = 0.1;
    β = pm.β;
    wbar = (β^β)*(1-β)^(2-2*β);
    w = 0.5 * wbar * ones(1,pa.mGrid.numPoints);

    LF = β * (pm.L - L_RD) / (β + (1-β)^2);
    profit = β * (1-β)^((2-β)/β) * β^(-1) * pm.L;

    idxM = pa.mGrid.numPoints;

    zS = 0.01 * ones(1,pa.mGrid.numPoints);
    zE = zS;

    return InitialGuess(L_RD,w,profit,idxM,zS,zE)

end
