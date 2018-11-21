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
    χI = 3;
    χS = 1.5;
    χE = 1;
    ψI = 0.3;
    ψSE = 0.3;
    λ = 1.2;

    # Spinouts
    ν = 0.3;
    ξ = 0.2;

    return ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,ξ);

end
