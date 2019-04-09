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
    ρ = modelPar.ρ
    β = modelPar.β
    L = modelPar.L

    # Innovation
    χI = modelPar.χI
    χS = modelPar.χS
    χE = modelPar.χE
    ψI = modelPar.ψI
    ψSE = modelPar.ψSE
    λ = modelPar.λ

    # Spinouts
    ν = modelPar.ν
    ξ = modelPar.ξ

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack guess
    ###################################################
    w = guess.w
	idxM = guess.idxM

	zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)
	zE = AuxiliaryModule.zE(modelPar,incumbentHJBSolution.V[1],w,zS)

	V = incumbentHJBSolution.V
	zI = incumbentHJBSolution.zI


	τI = AuxiliaryModule.τI(modelPar,zI)
	τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
	τ = τI .+ τSE

	aSE = (zS .+ zE)
	a = aSE .+ zI

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

	zS_density = zeros(size(zS))

	# Construct individual zS policy for computing W
	zS_density[2:end] = (zS ./ mGrid)[2:end]
	zS_density[1] = ξ


	spinoutFlow = zeros(size(zS))
	# Spinout flow construction and moving to zeros
	#spinoutFlow[:] = (χS .* ϕSE(zS + zE) .* λ .* V[1] .- w)[:]
	spinoutFlow = (χS .* ϕSE(zS .+ zE) .* λ .* V[1] .- w)

	for i = 1:length(spinoutFlow)
		if spinoutFlow[i] < 1e-3
			spinoutFlow[i] = 0
		end
	end

	Imax = length(mGrid)

	W = zeros(size(V))

	W[Imax] = 0

	for i = 1:Imax-1

		j = Imax - i

		W[j] = ((a[j] *  ν / Δm[j]) * W[j+1] + zS_density[j] * ( spinoutFlow[j] )) / (ρ + τ[j] + a[j] * ν / Δm[j])
		#W[j] = ((a[j] *  ν / Δm[j]) * W[j+1] + zS[j] * ( spinoutFlow[j] )) / (ρ + τ[j] + a[j] * ν / Δm[j])

	end

	#W = W ./ mGrid

    return W,spinoutFlow

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
    A = spzeros(length(mGrid),length(mGrid))

    ## Compute A Matrix
    ##############################################

	τI = AuxiliaryModule.τI(modelPar,zI)
	τSE = AuxiliaryModule.τSE(modelPar,zS,zE)

	aSE = (zS .+ zE)

    for i = range(1,length = length(mGrid) - 1)

		#A[i,1] = τI[i] * λ
		A[i,1] = τI[i]  # no λ term -- Moll's idea
		A[i,i+1] = ν * (zI[i] + aSE[i]) / Δm[i]
		A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i] - τI[i] - τSE[i]
		#A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i]

    end

	iMax = length(mGrid)

	#A[iMax,1] = τI[iMax] * λ
	A[iMax,1] = τI[iMax] # no λ term -- Moll's idea
	A[iMax,iMax] = - τI[iMax] - τSE[iMax]
	#A[iMax,1] = 0
	#A[iMax,iMax] = 0

    return A

end

function updateMatrixA(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, zI::Array{Float64}, A::SparseMatrixCSC{Float64,Int64},zS::Array{Float64},zE::Array{Float64})

    ## Unpack model parameters
    ##########################

    # General
    #ρ = modelPar.ρ;
    #β = modelPar.β;
    #L = modelPar.L;

    # Innovation
    #χI = modelPar.χI;
    #χS = modelPar.χS;
    #χE = modelPar.χE;
    #ψI = modelPar.ψI;
    #ψSE = modelPar.ψSE;
    λ = modelPar.λ;

    # Spinouts
    ν = modelPar.ν;
    #ξ = modelPar.ξ;

    # Define some auxiliary functions
    #ϕI(z) = z .^(-ψI)

    ## Unpack algorithm parameters
    ######################################
    #timeStep = algoPar.incumbentHJB.timeStep
    #tolerance = algoPar.incumbentHJB.tolerance
    #maxIter = algoPar.incumbentHJB.maxIter

    ## Unpack guess
    ###################################################
    #Π = AuxiliaryModule.profit(guess.L_RD,modelPar)
    #w = guess.w
	idxM = guess.idxM



    # Construct mGrid
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Initialize A matrix - NO NEED, SINCE UPDATING
    #A = spzeros(length(mGrid),length(mGrid))

    ## Compute A Matrix
    ##############################################

	τI = AuxiliaryModule.τI(modelPar,zI)
	τSE = AuxiliaryModule.τSE(modelPar,zS,zE)

	#aSE = (zS .+ zE)

    for i = 1:length(mGrid)-1

		A[i,1] = τI[i] * λ
		#A[i,1] = τI[i]  # no λ term -- Moll's idea
		A[i,i+1] = ν * (zI[i] + zS[i] + zE[i]) / Δm[i]
		A[i,i] = - ν * (zI[i] + zS[i] + zE[i]) / Δm[i] - τI[i] - τSE[i]
		#A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i]

    end

	#iMax = length(mGrid)
	#A[iMax,1] = τI[iMax] * λ
	#A[iMax,iMax] = - τI[iMax] - τSE[iMax]

	A[end,1] = τI[end] * λ
	#A[end,1] = τI[end]  # no λ term -- Moll's idea
	A[end,end] = - τI[end] - τSE[end]

	#A[iMax,1] = 0
	#A[iMax,iMax] = 0

    #return A

end

function updateV(algoPar::AlgorithmParameters, modelPar::ModelParameters, A::SparseMatrixCSC{Float64,Int64}, u::Array{Float64}, V0::Array{Float64})

	# Unpack

	timeStep = algoPar.incumbentHJB.timeStep
	ρ = modelPar.ρ
	V1 = zeros(size(u))

	# Try-catch formulation

	#try

		B = (1/timeStep + ρ) * I - A

		b = u .+ (1/timeStep) .* V0

		V1 = B \ b

		#error = maximum(abs.(V1-V0)) ./ timeStep

		#return V1,error

	# catch err

	#	if isa(err,LoadError)

	#		timeStep = 1

	#		B = (1/timeStep + ρ) * I - A

	#		b = u .+ (1/timeStep) .* V0

	#		V1 = B \ b

			#error = maximum(abs.(V1-V0)) ./ timeStep

			#return V1,error

	#	end

	#finally

		error = maximum(abs.(V1-V0)) ./ timeStep

		return V1, error

	#end

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
    #zS = guess.zS;
    #zE = guess.zE;
	idxM = guess.idxM

    # Compute initial guess for V, "value of staying put"
    # based on L_RD guess and profit function
    V0 = AuxiliaryModule.initialGuessIncumbentHJB(algoPar,modelPar,guess)
    zI = zeros(size(V0))
	zIalt = zeros(size(V0))
    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Finally calculate flow profit
	Π = AuxiliaryModule.profit(guess.L_RD,modelPar) .* ones(size(mGrid));

	A = spzeros(length(mGrid),length(mGrid))

    iterate = 0
    error = 1

    while iterate < maxIter && error > tolerance

		#frame = plot(x = mGrid, y = V0, Geom.line, Guide.xlabel("m"),
		#	Guide.ylabel("V"), Guide.title("Incumbent value V"), Theme(background_color=colorant"white"))

        iterate += 1

		#---------------------------#
		# Calculate zI using FOC
		#---------------------------#

		for i= 1:length(mGrid)-1

		    Vprime = (V0[i+1] - V0[i]) / Δm[i]

		    numerator = w[i] - ν * Vprime
		    denominator = (1- ψI) * χI * ( λ * V0[1] - V0[i])
		    ratio = numerator / denominator

			if ratio > 0
				zI[i] = ratio^(-1/ψI)
			else
				zI[i] = 0.1
			end

		end

		# Hack - "guess and verify", true in eq by continuity

		zI[1] = zI[2] #- no need for hack with Moll's method
		zI[end] = zI[end-1]

		#---------------------------#
		# DEPRECATED CODE
		#---------------------------#

        # Compute optimal policy
        # This can be parallelized eventually if I need to - essentially the only
        # part of the code that can be parallelized.

		#if iterate <= 0

		  #  for i= 1:length(mGrid)-1

		  #      rhs(z) = -z[1] * (χI * ϕI(z[1]) * (λ * V0[1] - V0[i]) - (w[i] - ν * (V0[i+1] - V0[i]) / Δm[i]))

				# Guess not necessary for univariate optimization with Optim.jl using Brent algorithm
				#zIguess = [0.1]

				# Need to restrict search to positive numbers, or else getting a complex number error!
		  #      result = optimize(rhs,0,1)

		  #      zI[i] = result.minimizer[1];

				#zI[i] = 0

		#    end

	#	else

		## Unpack tau functions
		########################################
		τI = AuxiliaryModule.τI(modelPar,zI)[:]

		zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)[:]
		zE = AuxiliaryModule.zE(modelPar,V0[1],w,zS)[:]

		τSE = AuxiliaryModule.τSE(modelPar,zS,zE)[:]

	    ## Make update:
	    u = Π .- zI .* w
		#u = Π .+ ((λ-1) * τI .* V0[1])  .- (zI .* w)  # Moll's idea -- here add (λ-1) * τI * V0[1] term
		#A = constructMatrixA(algoPar,modelPar,guess,zI)
		updateMatrixA(algoPar,modelPar,guess,zI,A,zS,zE)

		V1,error = updateV(algoPar,modelPar,A,u,V0)

	    # Normalize error by timeStep because
	    # it will always be smaller if timeStep is smaller
	    #error = maximum(abs.(V1-V0)) ./ timeStep

		if verbose == 2
			if iterate % print_skip == 0
				println("solveIncumbentHJB: Compute iterate $iterate with error $error")
			end
		end

	    V0 = V1

	end

	#println("V is equal to $V0")

	if verbose >= 1
		if error > tolerance
			@warn("solveIncumbentHJB: maxIter attained")
		elseif verbose == 2
			println("solveIncumbentHJB: Converged in $iterate steps")
		end
	end

	#gif(anim, "anim.gif", fps = 1)

    # Output
    return IncumbentSolution(V0,zI)

end


end
