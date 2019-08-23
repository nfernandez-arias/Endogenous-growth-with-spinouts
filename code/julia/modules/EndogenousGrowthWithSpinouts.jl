module EndogenousGrowthWithSpinouts

    #using Revise

    include("scripts/AlgorithmParametersModuleScript.jl")
    include("scripts/ModelParametersModuleScript.jl")
    include("scripts/GuessModuleScript.jl")
    include("scripts/AuxiliaryModuleScript.jl")
    include("scripts/InitializationModuleScript.jl")
    include("scripts/HJBModuleScript.jl")
    include("scripts/ModelSolverScript.jl")

end
