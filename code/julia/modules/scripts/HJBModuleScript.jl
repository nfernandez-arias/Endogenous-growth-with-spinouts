#---------------------------------
# Name: HJBModuleScript.jl
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

using Optim, LinearAlgebra, SparseArrays, Plots
import UnicodePlots

export solveIncumbentHJB, solveSpinoutHJB

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
	sFromE = modelPar.spinoutsFromEntrants

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack guess
    ###################################################
    w = guess.w
	wE = guess.wE
	idxM = guess.idxM
	driftNC = guess.driftNC
	wbar = wbarFunc(modelPar.β)

	zS = zSFunc(algoPar,modelPar,idxM)
	zE = zEFunc(modelPar,incumbentHJBSolution,w,wE,zS)

	V = incumbentHJBSolution.V
	zI = incumbentHJBSolution.zI
	noncompete = incumbentHJBSolution.noncompete

	τI = τIFunc(modelPar,zI,zS,zE)
	τSE = τSEFunc(modelPar,zI,zS,zE)
	τ = τI .+ τSE

	drift = driftNC * ν * (ones(size(zI)) + sFromE * zE .+ sFromS * zS .+ zI .* (1 .- noncompete)) # Take into account effect of non-competes on drift

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

	# Construct individual zS policy for computing W
	zS_density = zeros(size(zS))
	zS_density[2:end] = (zS ./ mGrid)[2:end]
	zS_density[1] = ξ

	#  Define spinout wage
	wS = (sFromS * w .+ (1-sFromS) * wbar)

	modelPar.χS * ϕSE(ξ*mGrid) * (modelPar.λ *  V[1] - modelPar.κ)  - wS


	# Spinout flow construction
	spinoutFlow = zeros(size(zS))

	#spinoutFlow = χS .* ϕSE(zS .+ zE) .* (λ * (1-ζ) * V[1]) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))
	#spinoutFlow = χS .* ϕSE(zS .+ zE) .* (λ * (1- modelPar.κ) * V[1]) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))
	spinoutFlow = max.(χS .* ϕSE(zS .+ zE) .* (λ * V[1] - modelPar.κ) - wS , 0)  # If negative due to no spinout entry, spinoutFlow should be zero.

	W = zeros(size(V))

	for i = 1:length(mGrid)-1

		j = length(mGrid) - i

		W[j] = ((drift[j] / Δm[j]) * W[j+1] + zS_density[j] * ( spinoutFlow[j] )) / (ρ + τ[j] + drift[j] / Δm[j])

	end

    return W,spinoutFlow

end

function computeOptimalIncumbentPolicy(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, V0::Array{Float64})

	## Unpack relevant model parameters

	θ = modelPar.θ
	ν = modelPar.ν
	λ = modelPar.λ
	χI = modelPar.χI
	ψI = modelPar.ψI
	CNC = modelPar.CNC

	## Unpack guesses
	w = guess.w
	wNC = guess.wNC
	wE = guess.wE
	idxM = guess.idxM
	driftNC = guess.driftNC

	mGrid,Δm = mGridBuild(algoPar.mGrid)

	zI = zeros(size(mGrid))
	noncompete = zeros(size(mGrid))

	#---------------------------#
	# Calculate optimal non-compete and optimal zI given non-compete
	# and given no non-compete.
	#---------------------------#

	#Vprime2 = (V0[3] - V0[2]) / Δm[2]    # This really should not be necessary anymore...

	for i = reverse(1:length(mGrid)-1)
		Vprime = (V0[i+1] - V0[i]) / Δm[i]

		#if i == 1
		#	Vprime = Vprime2
		#end

		#if i >= idxM
		#	Vprime = 0
		#end

		numerator = w[i] - (1-θ) * ν * Vprime
		denominator = (1- ψI) * χI * ( λ * V0[1] - V0[i])
		ratio = numerator / denominator

		#print("$(numerator - wbar)")

		if ratio > 0

			if CNC == false || numerator <= wNC[i]

				noncompete[i] = 0
				zI[i] = ratio^(-1/ψI)

			else

				noncompete[i] = 1
				ratio_CNC = wNC[i] / denominator
				zI[i] = ratio_CNC^(-1/ψI)

			end

		else

			noncompete[i] = 0
			zI[i] = 0.01 # not realy used...but haven't deleted just in case..

		end

	end

	# Some hacks to keep stability - these guesses are
	# approximately (within tolernace) TRUE IN EQUILIBRIUM
	# so innocuous to impose as assumptions.

	zI[1] = zI[2]
	zI[idxM+1:end] .= zI[idxM] * ones(size(zI[idxM+1:end]))
	zI[end] = zI[end-1]

	## This should be deletable - but for now keeping it in just in case

	#if CNC == false
	#	noncompete[:] .= 0
	#end



	return zI,noncompete

end

function updateMatrixA(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, A::SparseMatrixCSC{Float64,Int64}, drift::Array{Float64}, τI::Array{Float64}, τSE::Array{Float64})

	# Unpack
	λ = modelPar.λ

	# Make grid
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Update A Matrix
    for i = 1:length(mGrid)-1

		#A[i,1] = τI[i] * λ
		A[i,1] = τI[i]  # no λ term -- Moll's idea
		A[i,i+1] = drift[i] / Δm[i]
		A[i,i] = - drift[i] / Δm[i] - τI[i] - τSE[i]

    end

	#A[end,1] = τI[end] * λ
	A[end,1] = τI[end]  # no λ term -- Moll's idea
	A[end,end] = - τI[end] - τSE[end]

end

function updateV_implicit(algoPar::AlgorithmParameters, modelPar::ModelParameters, A::SparseMatrixCSC{Float64,Int64}, u::Array{Float64}, V0::Array{Float64})

	# Unpack

	timeStep = algoPar.incumbentHJB_inner.timeStep
	ρ = modelPar.ρ
	V1 = zeros(size(u))

	B = (1/timeStep + ρ) * I - A

	b = u .+ (1/timeStep) .* V0

	V1 = B \ b

	error = sum(abs.(V1-V0)) ./ timeStep

	return V1, error

end

function solveIncumbentHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, verbose = 2, print_skip = 10, implicit = true)

	V = initialGuessIncumbentHJB(algoPar,modelPar,guess)

	zI = zeros(size(V))
	noncompete = zeros(size(V))

	incumbentSolution = IncumbentSolution(V,zI,noncompete)

	return solveIncumbentHJB(algoPar,modelPar,guess,incumbentSolution,verbose,print_skip,implicit)

end

function solveIncumbentHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, incumbentHJBSolution::IncumbentSolution, verbose = 2, print_skip = 10, implicit = true)

    ## Unpack model parameters
    ##########################h

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
	θ = modelPar.θ
    ξ = modelPar.ξ

	sFromE = modelPar.spinoutsFromEntrants
	sFromS = modelPar.spinoutsFromSpinouts

	# CNCs
	CNC = modelPar.CNC

	# Wage
	wbar = wbarFunc(modelPar.β)

    # Define some auxiliary functions
    ϕI(z) = z .^(-ψI)
    ϕSE(z) = z .^(-ψSE)

    ## Unpack algorithm parameters
    ######################################

	# Outer iteration -- policy functions

	tolerance_outer = algoPar.incumbentHJB_outer.tolerance
	maxIter_outer = algoPar.incumbentHJB_outer.maxIter
	updateRate_outer = algoPar.incumbentHJB_outer.updateRate
	updateRateExponent_outer = algoPar.incumbentHJB_outer.updateRateExponent

	# Inner iteration -- solve ODE given policy function, using
	# fully implicit scheme

    timeStep = algoPar.incumbentHJB_inner.timeStep
    tolerance_inner = algoPar.incumbentHJB_inner.tolerance
    maxIter_inner = algoPar.incumbentHJB_inner.maxIter
	verbose = algoPar.incumbentHJB_inner_Log.verbose
	print_skip = algoPar.incumbentHJB_inner_Log.print_skip



    ## Unpack guess
    ###################################################
    w = guess.w
	wNC = guess.wNC
	wE = guess.wE
    #zS = guess.zS;
    #zE = guess.zE;
	idxM = guess.idxM
	driftNC = guess.driftNC

	mGrid, Δm = mGridBuild(algoPar.mGrid)

    # Compute initial guess for V, "value of staying put"
    # based on L_RD guess and profit function

    #V0 = initialGuessIncumbentHJB(algoPar,modelPar,guess)
	#plot(mGrid,V0, label = "Incumbent Value", xlabel = "Mass of spinouts")
	#png("figures/plotsGR/diagnostic_V.png")

	# Load in incumbent solution from previous iteration, as basis
	# for computing zE given zS.

	V_store = incumbentHJBSolution.V
	zI_store = incumbentHJBSolution.zI
	zS = zSFunc(algoPar,modelPar,idxM)
	zE = zEFunc(modelPar,incumbentHJBSolution,w,wE,zS)
	τSE = τSEFunc(modelPar,zI_store,zS,zE)

	# Initialize incumbent policies
	noncompete = zeros(size(V_store))
    zI = zeros(size(V_store))

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Finally calculate flow profit
	Π = profit(guess.L_RD,modelPar) .* ones(size(mGrid))

	# Initialize transition matrix
	A = spzeros(length(mGrid),length(mGrid))

    iterate_outer = 1
    error_outer = 1

	#diagNumPoints = 20
	#V_diag = zeros(length(mGrid),diagNumPoints)
	#zI_diag = zeros(length(mGrid),diagNumPoints)
	#noncompete_diag = zeros(length(mGrid),diagNumPoints)


	## NEED TO MAKE SURE USING THE RIGHT THING HERE

	# Load for first iteration
	sol = incumbentHJBSolution

	V0 = incumbentHJBSolution.V
	zI0 = incumbentHJBSolution.zI
	noncompete0 = incumbentHJBSolution.noncompete


    while iterate_outer < maxIter_outer && error_outer > tolerance_outer

		# Update drift given
		τI = τIFunc(modelPar,zI0,zS,zE)
		drift = driftNC * ones(size(mGrid)) + (1-θ) * ν * (((1 .- noncompete0) .* zI0) + (sFromS * zS) + (sFromE * zE))

		# Compute flow payoff
		#u = Π .- zI0 .* ((1 .- noncompete0) .* w + noncompete0 .* wNC)
		u = Π .+ τI .* (λ-1) .* V0[1]  .- zI0 .* ((1 .- noncompete0) .* w + noncompete0 .* wNC)  # Moll's idea -- here add (λ-1) * τI * V0[1] term

		## Implicit method

		iterate_inner = 1
		error_inner = 1

		while iterate_inner < maxIter_inner && error_inner > tolerance_inner

			# Update "transition" matrix A
			updateMatrixA(algoPar,modelPar,guess,A,drift,τI,τSE)

			# Implicit update step to compute V1 and error
			V1,error_inner = updateV_implicit(algoPar,modelPar,A,u,V0)

			if verbose == 2
				if iterate_inner % print_skip == 0
					println("solveIncumbentHJB_inner: Compute iterate $iterate_inner with error $error_inner")
				end
			end

			# Increment
			iterate_inner += 1

			# Update solution for next computation of optimal policy
			V0 = V1

		end

		if verbose >= 1
			if error_inner > tolerance_inner
				@warn("solveIncumbentHJB_inner: maxIter ($iterate_inner) attained with error $error_inner")
			elseif verbose == 2
				println("solveIncumbentHJB_inner: Converged in $iterate_inner steps")
			end
		end

		#V_diag[:,iterate] = V1
		#zI_diag[:,iterate] = zI
		#noncompete_diag[:,iterate] = noncompete


		# Compute policy given new value V0 computed above using implicit finite difference scheme
		zI1,noncompete1 = computeOptimalIncumbentPolicy(algoPar,modelPar,guess,V0)

		# Compute error
		error_outer = sum(abs.(zI1-zI0)) + sum(abs.(noncompete1 - noncompete0))

		# Print status output
		println("solveIncumbentHJB_outer: Compute iterate $iterate_outer with error $error_outer")

		# Increment
		iterate_outer += 1

		# Update guesses
		zI0 = algoPar.incumbentHJB_outer.updateRate * zI1 + (1 - algoPar.incumbentHJB_outer.updateRate) * zI0
		noncompete0 = algoPar.incumbentHJB_outer.updateRate * noncompete1 + (1 - algoPar.incumbentHJB_outer.updateRate) * noncompete0

	end

	if error_outer > tolerance_outer
		@warn("solveIncumbentHJB_outer: maxIter ($iterate_outer) attained with error $error_outer")
	else
		println("solveIncumbentHJB_outer: Converged in $iterate_outer steps with error $error_outer")
	end

    # Output
    #return V_diag,zI_diag,noncompete_diag,IncumbentSolution(V0,zI,noncompete)
	return IncumbentSolution(V0,zI0,noncompete0)

end
