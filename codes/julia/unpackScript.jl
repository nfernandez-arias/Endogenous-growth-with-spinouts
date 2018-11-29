
L_RD = results.finalGuess.L_RD
w = results.finalGuess.w
zS = results.finalGuess.zS
zE = results.finalGuess.zE
V = results.incumbent.V
zI = results.incumbent.zI
zIfromFOC = zeros(size(zI))
W = results.spinoutValue

τI = AuxiliaryModule.τI(modelPar,zI)
τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
τE = AuxiliaryModule.τE(modelPar,zS,zE)
τS = zeros(size(τE))
τS[:] = τSE[:] - τE[:]

τ = τI + τSE

a = zS + zE + zI

mGrid,Δm = mGridBuild(algoPar.mGrid)

ϕSE(z) = z .^(-modelPar.ψSE)
ϕI(z) = z .^(-modelPar.ψI)
χS = modelPar.χS
λ = modelPar.λ
ρ = modelPar.ρ
ν = modelPar.ν
ξ = modelPar.ξ
ψI = modelPar.ψI
χI = modelPar.χI

Π = AuxiliaryModule.profit(results.finalGuess.L_RD,modelPar)
