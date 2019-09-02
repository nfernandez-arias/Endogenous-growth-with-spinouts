#---------------------------------
# Name: ModelParametersModuleScript.jl
#
# Module relating to model parameters
#
# Contains definitions of
# modelParameters composite type
#

export ModelParameters, IncumbentSolution

mutable struct ModelParameters

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
	# Fraction non-competing
	θ::Float64
    # Size of spinout
    ξ::Float64
    # Employee knowledge value discount
    ζ::Float64

	# Creative destruction deadweight loss discount
	κ::Float64

    CNC::Bool

    spinoutsFromSpinouts::Float64
	spinoutsFromEntrants::Float64

    spinoutsSamePool::Bool

end

mutable struct IncumbentSolution

    V::Array{Float64}
    zI::Array{Float64}
	noncompete::Array{Int64}

end
