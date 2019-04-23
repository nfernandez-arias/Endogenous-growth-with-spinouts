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
	noncompete::Array{Int64}

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
	ζ = modelPar.ζ
	sFromS = modelPar.spinoutsFromSpinouts

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack guess
    ###################################################
    w = guess.w
	idxM = guess.idxM
	wbar = AuxiliaryModule.wbar(modelPar.β)

	zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)
	zE = AuxiliaryModule.zE(modelPar,incumbentHJBSolution.V[1],w,zS)

	V = incumbentHJBSolution.V
	zI = incumbentHJBSolution.zI
	noncompete = incumbentHJBSolution.noncompete


	τI = AuxiliaryModule.τI(modelPar,zI)
	τSE = AuxiliaryModule.τSE(modelPar,zS,zE)
	τ = τI .+ τSE

	a = sFromS * zS .+ zI .* (1 .- noncompete)  # Take into account effect of non-competes on drift

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

	zS_density = zeros(size(zS))

	# Construct individual zS policy for computing W
	zS_density[2:end] = (zS ./ mGrid)[2:end]
	zS_density[1] = ξ

	# Spinout flow construction
	spinoutFlow = zeros(size(zS))
	spinoutFlow = χS .* ϕSE(zS .+ zE) .* (λ * V[1] - ζ) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))

	Imax = length(mGrid)

	W = zeros(size(V))

	for i = 1:Imax-1

		j = Imax - i

		W[j] = ((a[j] *  ν / Δm[j]) * W[j+1] + zS_density[j] * ( spinoutFlow[j] )) / (ρ + τ[j] + a[j] * ν / Δm[j])

	end

    return W,spinoutFlow

end

function updateMatrixA(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, zI::Array{Float64}, noncompete,A::SparseMatrixCSC{Float64,Int64},zS::Array{Float64},zE::Array{Float64})

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
	sFromS = modelPar.spinoutsFromSpinouts


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

    for i = 1:length(mGrid)-1

		#A[i,1] = τI[i] * λ
		A[i,1] = τI[i]  # no λ term -- Moll's idea
		A[i,i+1] = ν * ((1-noncompete[i]) * zI[i] + sFromS * zS[i] + zE[i]) / Δm[i]
		A[i,i] = - ν * ((1-noncompete[i]) * zI[i] + sFromS * zS[i] + zE[i]) / Δm[i] - τI[i] - τSE[i]
		#A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i]

    end

	#iMax = length(mGrid)
	#A[iMax,1] = τI[iMax] * λ
	#A[iMax,iMax] = - τI[iMax] - τSE[iMax]

	#A[end,1] = τI[end] * λ
	A[end,1] = τI[end]  # no λ term -- Moll's idea
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

	# CNCs
	CNC = modelPar.CNC

	# Wage
	wbar = AuxiliaryModule.wbar(modelPar.β)

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
	noncompete = zeros(size(V0))
    zI = zeros(size(V0))

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Finally calculate flow profit
	Π = AuxiliaryModule.profit(guess.L_RD,modelPar) .* ones(size(mGrid));

	# Initialize transition matrix
	A = spzeros(length(mGrid),length(mGrid))

    iterate = 0
    error = 1

    while iterate < maxIter && error > tolerance

		#frame = plot(x = mGrid, y = V0, Geom.line, Guide.xlabel("m"),
		#	Guide.ylabel("V"), Guide.title("Incumbent value V"), Theme(background_color=colorant"white"))

        iterate += 1

		#---------------------------#
		# Calculate optimal non-compete and optimal zI given non-compete
		# and given no non-compete.
		#---------------------------#

		for i= 1:length(mGrid)-1

		    Vprime = (V0[i+1] - V0[i]) / Δm[i]

		    numerator = w[i] - ν * Vprime
		    denominator = (1- ψI) * χI * ( λ * V0[1] - V0[i])
		    ratio = numerator / denominator

			#print("$(numerator - wbar)")

			if ratio > 0

				if numerator <= wbar
					noncompete[i] = 0
					#noncompete[i] = 1
					zI[i] = ratio^(-1/ψI)
					#numerator_CNC = AuxiliaryModule.wbar(modelPar.β)
					#ratio_CNC = numerator_CNC / denominator
					#zI[i] = ratio_CNC^(-1/ψI)

				else
					noncompete[i] = 1
					numerator_CNC = AuxiliaryModule.wbar(modelPar.β)
					ratio_CNC = numerator_CNC / denominator

					zI[i] = ratio_CNC^(-1/ψI)
					#zI[i] = ratio^(-1/ψI)
				end

			else

				noncompete[i] = 0
				#noncompete[i] = 1
				zI[i] = 0.01

			end

		end

		# Hack - "guess and verify", true in eq by continuity

		zI[1] = zI[2] #- no need for hack with Moll's method
		noncompete[1] = noncompete[2]
		zI[end] = zI[end-1]
		noncompete[end] = noncompete[end-1]

		zI[idxM+1:end] .= zI[idxM]

		if CNC == false
			noncompete[:] .= 0
		end

		## Unpack tau functions
		########################################
		τI = AuxiliaryModule.τI(modelPar,zI)[:]

		zS = AuxiliaryModule.zS(algoPar,modelPar,idxM)[:]
		zE = AuxiliaryModule.zE(modelPar,V0[1],w,zS)[:]

		τSE = AuxiliaryModule.τSE(modelPar,zS,zE)[:]

	    ## Make update:
	    #u = Π .- zI .* ((1 .- noncompete) .* w + noncompete .* AuxiliaryModule.wbar(modelPar.β))
		u = Π .+ τI .* (λ-1) .* V0[1]  .- zI .* ((1 .- noncompete) .* w + noncompete .* AuxiliaryModule.wbar(modelPar.β))  # Moll's idea -- here add (λ-1) * τI * V0[1] term
		#A = constructMatrixA(algoPar,modelPar,guess,zI)
		updateMatrixA(algoPar,modelPar,guess,zI,noncompete,A,zS,zE)

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

	if verbose >= 1
		if error > tolerance
			@warn("solveIncumbentHJB: maxIter attained")
		elseif verbose == 2
			println("solveIncumbentHJB: Converged in $iterate steps")
		end
	end

    # Output
    return IncumbentSolution(V0,zI,noncompete)

end


end
