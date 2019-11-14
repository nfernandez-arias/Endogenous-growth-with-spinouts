

mutable struct IncumbentSolution

    V::Array{Float64}
    zI::Array{Float64}
	noncompete::Array{Int64}

end

struct AuxiliaryEquilibriumVariables

    μ::Array{Float64}
    γ::Array{Float64}
    t::Array{Float64}

end

struct ModelSolution

    finalGuess::Guess
    incumbent::IncumbentSolution
    spinoutValue::Array{Float64}
    auxiliary::AuxiliaryEquilibriumVariables

end
