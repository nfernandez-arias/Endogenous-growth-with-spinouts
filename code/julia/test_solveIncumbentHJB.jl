include("loadPath.jl")

using Plots
gr()
#using Compat

#using Revise
using EndogenousGrowthWithSpinouts

algoPar = setAlgorithmParameters()
modelPar = setModelParameters()
mGrid,Δm = mGridBuild(algoPar.mGrid)
initGuess = setInitialGuess(algoPar,modelPar,mGrid)

#initGuess2 = setInitialGuess(algoPar,modelPar,mGrid)

sol = IncumbentSolution(zeros(size(mGrid)) * 0.5,zeros(size(mGrid)),zeros(size(mGrid)))
#sol = IncumbentSolution(EndogenousGrowthWithSpinouts.initialGuessIncumbentHJB(algoPar,modelPar,initGuess),zeros(size(mGrid)),zeros(size(mGrid)))

#objective_diag,V_diag,zI_diag,out = solveIncumbentHJB_shooting(algoPar,modelPar,initGuess,sol)
V_diag,zI_diag,out = solveIncumbentHJB(algoPar,modelPar,initGuess,sol)

anim = @animate for i = 1:length(V_diag[1,:])
    plot(mGrid,V_diag[:,i], title = "V_diag[:,$i]", ylims = (0,1))
end
gif(anim,"figures/plotsGR/V_innermost_animation.gif",fps = 5)

anim = @animate for i = 1:length(zI_diag[1,:])
    plot(mGrid,zI_diag[:,i], title = "zI_diag[:,$i]")
end
gif(anim,"figures/plotsGR/zI_innermost_animation.gif",fps = 5)

#anim = @animate for i = 1:length(objective_diag[1,:])
    plot(0:0.1:10,objective_diag[:,i], title = "objective_diag[:,$i]")
#end
#gif(anim,"figures/plotsGR/objective_diag_animation.gif",fps = 5)

V = out.V
zI = out.zI

function computeVprime(V)

    err = zeros(size(mGrid))
    V1 = copy(V)
    Vprime = zeros(size(V))
    V1prime = copy(Vprime)
    #V1[1] = V1[2]

    for i = 1:length(mGrid)-1

        Vprime[i] = (V[i+1] - V[i]) / Δm[i]
        V1prime[i] = (V1[i+1] - V1[i]) / Δm[i]

    end

    Vprime[end] = Vprime[end-1]
    V1prime[end] = V1prime[end-1]
    V1prime[1] = V1prime[2]

    return Vprime,V1prime

end


ρ = modelPar.ρ
ν = modelPar.ν

zS = zSFunc(algoPar,modelPar,initGuess.idxM)

a = modelPar.spinoutsFromSpinouts * zS .+ zI

zE = initGuess.zE
w = initGuess.w




τSE = τSEFunc(modelPar,zI,zS,zE)

Π = profit(initGuess.L_RD,modelPar)

ψI = modelPar.ψI
χI = modelPar.χI
λ = modelPar.λ
ϕI(z) = z.^(-1/ψI)

errors1 = zeros(size(V_diag))
errors2 = zeros(size(V_diag))

for i=1:length(V_diag[1,:])

    zI = zI_diag[:,i]
    V = V_diag[:,i]
    Vprime,V1prime = computeVprime(V)

    errors1[:,i] = (ρ .+ τSE) .* V .- Π .- a .* ν .* Vprime .- zI .* (χI .* ϕI(zI + zS) .* (λ .* V[1] .- V) .- w)
    errors2[:,i] = (ρ .+ τSE) .* V .- Π .- a .* ν .* V1prime .- zI .* (χI .* ϕI(zI + zS) .* (λ .* V[1] .- V) .- w)

end

anim = @animate for i = 1:length(errors1[1,:])
    plot(mGrid,errors1[:,i], title = "errors1[:,$i]")
end
gif(anim,"figures/plotsGR/V_innerMostErrors_animation_1.gif",fps = 5)

anim = @animate for i = 1:length(errors2[1,:])
    plot(mGrid,errors2[:,i], title = "errors2[:,$i]")
end
gif(anim,"figures/plotsGR/V_innerMostErrors_animation_2.gif",fps = 5)
