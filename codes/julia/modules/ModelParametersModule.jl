#---------------------------------
# Name: ModelParametersModule.jl
#
# Module relating to model parameters
#
# Contains definitions of
# modelParameters composite type
#

__precompile__()

module ModelParametersModule

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

export ModelParameters;

end
