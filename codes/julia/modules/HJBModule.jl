#---------------------------------
# Name: HJBModule.jl
#
# Module relating to solving HJBs
#
# Contains:
#
# Functions:
#
# solveIncumbentHJB
# solveSpinoutHJB
#
# Types:
#
# incumbentSolution
#
#

__precompile__()

module HJBModule

using AlgorithmParametersModule, ModelParametersModule, GuessModule, Optim, LinearAlgebra, SparseArrays
import AuxiliaryModule

export IncumbentSolution, solveIncumbentHJB, solveSpinoutHJB

struct IncumbentSolution

    V::Array{Float64}
    zI::Array{Float64}

end

function solveSpinoutHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, incumbentHJBSolution::IncumbentSolution)

	## Unpack model parameters
    ##########################

    # General
    ρ = modelPar.ρ;
    β = modelPar.β;
    L = modelPar.L;

    # Innovation
    χI = modelPar.χI;
    χS = modelPar.χS;
    χE = modelPar.χE;
    ψI = modelPar.ψI;
    ψSE = modelPar.ψSE;
    λ = modelPar.λ;

    # Spinouts
    ν = modelPar.ν;
    ξ = modelPar.ξ;

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack guess
    ###################################################
    w = guess.w;
    zS = guess.zS;
    zE = guess.zE;

	V = incumbentHJBSolution.V
	zI = incumbentHJBSolution.zI


	τI = AuxiliaryModule.τI(modelPar,zI)
	τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
	τ = τI + τSE

	aSE = (zS + zE)
	a = aSE + zI

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

	Imax = length(mGrid)

	W = zeros(size(V))

	W[Imax] = (zS[Imax] * ( ϕSE(zS[Imax] + zE[Imax]) * λ * V[1] - w[Imax])) / (ρ + τ[Imax])

	for i = 1:Imax-1

		j = Imax - i
		W[j] = ( (a[j] * ν / Δm[j]) * W[j+1] + zS[j] * ( ϕSE(zS[j] + zE[j]) * λ * V[1] - w[j] ) )
				/
				(ρ + τ[j] + (a[j] * ν / Δm[j]) )

	end

	W = W ./ mGrid

    return W

end

function constructMatrixA(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, zI::Array{Float64})

    ## Unpack model parameters
    ##########################

    # General
    ρ = modelPar.ρ;
    β = modelPar.β;
    L = modelPar.L;

    # Innovation
    χI = modelPar.χI;
    χS = modelPar.χS;
    χE = modelPar.χE;
    ψI = modelPar.ψI;
    ψSE = modelPar.ψSE;
    λ = modelPar.λ;

    # Spinouts
    ν = modelPar.ν;
    ξ = modelPar.ξ;

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)

    ## Unpack algorithm parameters
    ######################################
    timeStep = algoPar.incumbentHJB.timeStep
    tolerance = algoPar.incumbentHJB.tolerance
    maxIter = algoPar.incumbentHJB.maxIter

    ## Unpack guess
    ###################################################
    Π = AuxiliaryModule.profit(guess.L_RD,modelPar)
    w = guess.w
    zS = guess.zS
    zE = guess.zE

    # Construct mGrid
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Initialize A matrix
    A = zeros(length(mGrid),length(mGrid))

    ## Compute A Matrix
    ##############################################

	τI = AuxiliaryModule.τI(modelPar,zI)
	τSE = AuxiliaryModule.τSE(modelPar,zS,zE)

	aSE = (zS + zE)

    for i = range(1,length = length(mGrid) - 1)

		A[i,1] = τI[i] * λ
		A[i,i+1] = ν * (zI[i] + aSE[i]) / Δm[i]
		A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i] - τI[i] - τSE[i]
		#A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i]

    end

	iMax = length(mGrid)

	A[iMax,1] = τI[iMax] * λ
	A[iMax,iMax] = - τI[iMax] - τSE[iMax]
	#A[iMax,1] = 0
	#A[iMax,iMax] = 0

    return A

end

function solveIncumbentHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, verbose = 2, print_skip = 10)

    ## Unpack model parameters
    ##########################

    # General
    ρ = modelPar.ρ;
    β = modelPar.β;
    L = modelPar.L;

    # Innovation
    χI = modelPar.χI;
    χS = modelPar.χS;
    χE = modelPar.χE;
    ψI = modelPar.ψI;
    ψSE = modelPar.ψSE;
    λ = modelPar.λ;

    # Spinouts
    ν = modelPar.ν;
    ξ = modelPar.ξ;

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack algorithm parameters
    ######################################
    timeStep = algoPar.incumbentHJB.timeStep
    tolerance = algoPar.incumbentHJB.tolerance
    maxIter = algoPar.incumbentHJB.maxIter

	verbose = algoPar.incumbentHJB_Log.verbose
	print_skip = algoPar.incumbentHJB_Log.print_skip

    ## Unpack guess
    ###################################################
    w = guess.w;
    zS = guess.zS;
    zE = guess.zE;

    # Compute initial guess for V, "value of staying put"
    # based on L_RD guess and profit function
    V0 = AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,guess)
    zI = zeros(size(V0))
    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Finally calculate flow profit
	Π = AuxiliaryModule.profit(guess.L_RD,modelPar) * ones(size(mGrid));

    iterate = 0
    error = 1

    while iterate < maxIter && error > tolerance

        iterate += 1

        # Compute optimal policy
        # This can be parallelized eventually if I need to - essentially the only
        # part of the code that can be parallelized.

        for i=range(1,length = length(mGrid) - 1)

            rhs(z) = -z[1] * (χI * ϕI(z[1]) * (λ * V0[1] - V0[i]) - (w[i] - ν * (V0[i+1] - V0[i]) / Δm[i]))

			# Guess not necessary for univariate optimization with Optim.jl using Brent algorithm
			#zIguess = [0.1]

			# Need to restrict search to positive numbers, or else getting a complex number error!
            result = optimize(rhs,0,100)

            zI[i] = result.minimizer[1];

			#zI[i] = 0.1

        end

		# Last point hack
		zI[length(mGrid)] = zI[length(mGrid)-1]


		## Unpack tau functions
		########################################
		τI = AuxiliaryModule.τI(modelPar,zI)[:]
		τSE = AuxiliaryModule.τSE(modelPar,zS,zE)[:]

        ## Make update:
        u = Π - zI .* w
        A = constructMatrixA(algoPar,modelPar,guess,zI)
		B = (1/timeStep + ρ) * I - A

		#tauMatrix = Diagonal(τI[:] + τSE[:])
		#B = (1/timeStep + ρ) * I + tauMatrix - A

        b = u + (1/timeStep) * V0

        # Construct sparse matrices...not sure why but whatever
        #Asparse = sparse(A)
        #Bsparse = sparse(B)
        #bsparse = sparse(b)

        #V1 = Bsparse \ bsparse
		V1 = B \ b

        # Normalize error by timeStep because
        # it will always be smaller if timeStep is smaller
        error = maximum(abs,V1 - V0) / timeStep

		if verbose == 2
			if iterate % print_skip == 0
				println("solveIncumbentHJB: Compute iterate $iterate with error $error")
			end
		end

        V0 = V1

		#println("V is equal to $V0")

    end

	#println("V is equal to $V0")

	if verbose >= 1
		if error > tolerance
			@warn("solveIncumbentHJB: maxIter attained")
		elseif verbose == 2
			println("solveIncumbentHJB: Converged in $iterate steps")
		end
	end

    # Output
    return IncumbentSolution(V0,zI)

end


end
