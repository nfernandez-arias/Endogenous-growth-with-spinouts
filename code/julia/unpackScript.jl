

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
θ = modelPar.θ
κ = modelPar.κ

L_RD = results.finalGuess.L_RD
#γ = results.finalGuess.γ
w = results.finalGuess.w
wE = results.finalGuess.wE
wNC = results.finalGuess.wNC
idxM = results.finalGuess.idxM
driftNC = results.finalGuess.driftNC
V = results.incumbent.V
zI = results.incumbent.zI
zIfromFOC = zeros(size(zI))
noncompete = results.incumbent.noncompete
W = results.spinoutValue

zS = EndogenousGrowthWithSpinouts.zSFunc(algoPar,modelPar,idxM)
zE = EndogenousGrowthWithSpinouts.zEFunc(modelPar,results.incumbent,w,zS)

zS_density = zeros(size(zS))
zS_density[2:end] = (zS ./ mGrid)[2:end]
zS_density[1] = modelPar.ξ

τI = EndogenousGrowthWithSpinouts.τIFunc(modelPar,zI,zS,zE)
τSE = EndogenousGrowthWithSpinouts.τSEFunc(modelPar,zI,zS,zE)
τE = EndogenousGrowthWithSpinouts.τEFunc(modelPar,zI,zS,zE)
τS = zeros(size(τE))
τS[:] = τSE[:] - τE[:]

sFromS = modelPar.spinoutsFromSpinouts
sFromE = modelPar.spinoutsFromEntrants

L_F = EndogenousGrowthWithSpinouts.LF(L_RD,modelPar)

τ = τI + τSE

z = zS + zE + zI
aTotal = ν^(-1) * (ones(size(zI)) * driftNC + ν * (1-θ) * (sFromE * zE .+ sFromS * zS .+ zI .* (1 .- noncompete)))
aBarIncumbents = ν^(-1) * EndogenousGrowthWithSpinouts.abarIncumbentsFunc(algoPar,modelPar,zI,μ,γ)
aBar = ν^(-1) * EndogenousGrowthWithSpinouts.abarFunc(algoPar,modelPar,zI,zS,zE,μ,γ)
aCompeting = aTotal - ν^(-1) *  driftNC * ones(size(zI))
aNonCompeting = aTotal - aCompeting

finalGoodsLabor = EndogenousGrowthWithSpinouts.LF(L_RD,modelPar)

mGrid,Δm = mGridBuild(algoPar.mGrid)

#Compute derivative of a for calculating stationary distribution

a = aTotal

aPrime = zeros(size(a))

for i = 1:length(aPrime)-1

    aPrime[i] = (a[i+1] - a[i]) / Δm[i]

end

aPrime[end] = aPrime[end-1]

#wbar = (β^β)*(1-β)^(2-2*β);

wbar = EndogenousGrowthWithSpinouts.wbarFunc(β)
Π = EndogenousGrowthWithSpinouts.profit(results.finalGuess.L_RD,modelPar)
idxCNC = findfirst( (noncompete .> 0)[:] )
