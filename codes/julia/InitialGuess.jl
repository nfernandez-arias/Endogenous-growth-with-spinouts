struct InitialGuess

    # R&D labor supply
    L_RD::Float64

    # R&D wage
    w::Array{Float64}

    # Incumbent flow profit
    profit::Float64

    # Spinout entry threshold
    idxM::Int64

    # Spinout and entrant R&D effort
    zS::Array{Float64}
    zE::Array{Float64}

end

function setInitialGuess(pa::AlgorithmParameters,pm::ModelParameters)

    L_RD = 0.1;
    β = pm.β;
    wbar = (β^β)*(1-β)^(2-2*β);
    w = 0.5 * wbar * ones(1,pa.mgridNumPoints);

    LF = β * (pm.L - L_RD) / (β + (1-β)^2);
    profit = β * (1-β)^((2-β)/β) * β^(-1) * pm.L;

    idxM = pa.mgridNumPoints;

    zS = 0.01 * ones(1,pa.mgridNumPoints);
    zE = zS;

    return InitialGuess(L_RD,w,profit,idxM,zS,zE)

end
