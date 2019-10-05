
export zI_CNC_decomp

function zI_CNC_decomp(algoPar::AlgorithmParameters,modelPar::ModelParameters,initGuess::Guess)

    mGrid,Δm = mGridBuild(algoPar.mGrid)

    λ = modelPar.λ
    θ = modelPar.θ
    β = modelPar.β
    ν = modelPar.ν
    ζ = modelPar.ζ
    χI = modelPar.χI

    wbar = wbarFunc(β)

    results_noNC,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess,false)   # overloaded function
    results_NC,zSfactor,zEfactor,spinoutFlow = solveModel(algoPar,modelPar,initGuess,true)

    V_noNC = results_noNC.incumbent.V
    V_NC = results_NC.incumbent.V

    W_noNC = results_noNC.spinoutValue
    W_NC = results_NC.spinoutValue

    zI_noNC = results_noNC.incumbent.zI
    zI_NC = results_NC.incumbent.zI

    x_noNC = results_noNC.incumbent.noncompete
    x_NC = results_NC.incumbent.noncompete

    w_noNC = results_noNC.finalGuess.w
    w_NC = results_NC.finalGuess.w

    wE_noNC = results_noNC.finalGuess.wE
    wE_NC = results_NC.finalGuess.wE

    Vprime_noNC = zeros(size(mGrid))
    Vprime_NC = zeros(size(mGrid))

    μ_noNC = results_noNC.auxiliary.μ
    μ_NC = results_NC.auxiliary.μ

    γ_noNC = results_noNC.auxiliary.γ
    γ_NC = results_NC.auxiliary.γ

    for i = 1:length(mGrid)-1

        Vprime_noNC[i] = (V_noNC[i+1] - V_noNC[i]) / Δm[i]
        Vprime_NC[i] = (V_NC[i+1] - V_NC[i]) / Δm[i]

    end

    Vprime_noNC[1] = Vprime_noNC[2]
    Vprime_NC[1] = Vprime_NC[2]

    Wcal_noNC = WcalFunc(algoPar,modelPar,results_noNC.finalGuess,W_noNC,μ_noNC,γ_noNC,false)
    Wcal_NC = WcalFunc(algoPar,modelPar,results_NC.finalGuess,W_NC,μ_NC,γ_NC,true)

    noncompeteEffect_num = wbar .- ν * (θ * (1-ζ) * Wcal_NC .- (1-θ) * ((1-ζ) * W_NC + Vprime_NC))
    noncompeteEffect_denom = x_NC .* (wbar .- (1-ζ) * ν * θ * Wcal_NC) + (1 .- x_NC) .* noncompeteEffect_num

    noncompeteEffect = noncompeteEffect_num ./ noncompeteEffect_denom

    term1_noNC = χI * (λ * V_noNC[1] .- V_noNC) ./ (wbar .- ν * (θ * (1-ζ) * Wcal_noNC .- (1-θ) * ((1-ζ) * W_noNC + Vprime_noNC)))
    term1_NC = χI * (λ * V_NC[1] .- V_NC) ./ (wbar .- ν * (θ * (1-ζ) * Wcal_NC .- (1-θ) * ((1-ζ) * W_NC + Vprime_NC)))

    println(size(term1_noNC))

    println(size(term1_NC))

    println(size(noncompeteEffect))

    return (term1_NC ./ term1_noNC).^2, noncompeteEffect.^2, results_noNC, results_NC

end
