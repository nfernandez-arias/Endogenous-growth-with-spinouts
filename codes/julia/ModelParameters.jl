struct ModelParameters

    ## General parameters
    #################
    # Discount rate
    ρ::Float64
    # 1/(1-β) is markup
    β::Float64
    # Total labor endowment
    L::Float64

    ## Returns to R&D
    ##################
    # Scaled
    χI::Float64
    χS::Float64
    χE::Float64
    # Curvature
    ψI::Float64
    ψSE::Float64
    # Step size of quality ladder
    λ::Float64

    ## Spinouts
    ###############
    # Knowledge spillover rate
    ν::Float64
    # Size of spinout
    ξ::Float64

end

function setModelParameters()

    # General
    ρ = 0.03;
    β = 0.2;
    L = 1.0;

    # Innovation
    χI = 1.5;
    χS = 1.5;
    χE = 0.5;
    ψI = 0.5;
    ψSE = 0.5;
    λ = 1.2;

    # Spinouts
    ν = 0.2;
    ξ = 0.1;

    return ModelParameters(ρ,β,L,χI,χS,χE,ψI,ψSE,λ,ν,ξ);

end
