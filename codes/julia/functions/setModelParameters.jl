#---------------------------------
# Name: setModelParameters.jl
#
# Function for setting model parameters
# to baseline setting, for testing the model solver.
#

function setModelParameters()

    # General
    ρ = 0.03;
    β = 0.2;
    L = 1.0;

    # Innovation
    χI = 1.5;
    χS = 1;
    χE = 0.5;
    ψI = 0.7;
    ψSE = 0.5;
    λ = 1.2;

    # Spinouts
    ν = 0.3;
    ξ = 0.2;

    return ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,ξ);

end
