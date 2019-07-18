




L_RD = results.finalGuess.L_RD
#γ = results.finalGuess.γ
w = results.finalGuess.w
idxM = results.finalGuess.idxM
V = results.incumbent.V
zI = results.incumbent.zI
zIfromFOC = zeros(size(zI))
noncompete = results.incumbent.noncompete
W = results.spinoutValue

zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)
zE = AuxiliaryModule.zE(modelPar,V[1],w,zS)


zS_density = zeros(size(zS))
zS_density[2:end] = (zS ./ mGrid)[2:end]
zS_density[1] = ξ

τI = AuxiliaryModule.τI(modelPar,zI)
τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
τE = AuxiliaryModule.τE(modelPar,zS,zE)
τS = zeros(size(τE))
τS[:] = τSE[:] - τE[:]

sFromS = modelPar.spinoutsFromSpinouts

L_F = AuxiliaryModule.LF(L_RD,modelPar)

τ = τI + τSE

z = zS + zE + zI
a = sFromS * zS .+ zI .* (1 .- noncompete)

finalGoodsLabor = AuxiliaryModule.LF(L_RD,modelPar)

mGrid,Δm = mGridBuild(algoPar.mGrid)

#Compute derivative of a for calculating stationary distribution

aPrime = zeros(size(a))

for i = 1:length(aPrime)-1

    aPrime[i] = (a[i+1] - a[i]) / Δm[i]

end

aPrime[end] = aPrime[end-1]

ϕSE(z) = z .^(-modelPar.ψSE)
ϕI(z) = z .^(-modelPar.ψI)
χS = modelPar.χS
λ = modelPar.λ
ρ = modelPar.ρ
ν = modelPar.ν
ξ = modelPar.ξ
ζ = modelPar.ζ
ψI = modelPar.ψI
χI = modelPar.χI
β = modelPar.β
#wbar = (β^β)*(1-β)^(2-2*β);

wbar = AuxiliaryModule.wbar(β)
Π = AuxiliaryModule.profit(results.finalGuess.L_RD,modelPar)
