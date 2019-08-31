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

using Optim, LinearAlgebra, SparseArrays
import UnicodePlots

export solveIncumbentHJB, solveSpinoutHJB

function solveSpinoutHJB(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, incumbentHJBSolution::IncumbentSolution, μ::Array{Float64})

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
	idxM = guess.idxM
	wbar = wbarFunc(modelPar.β)

	zS = zSFunc(algoPar,modelPar,idxM)
	zE = zEFunc(modelPar,incumbentHJBSolution,w,zS)

	V = incumbentHJBSolution.V
	zI = incumbentHJBSolution.zI
	noncompete = incumbentHJBSolution.noncompete

	τI = τIFunc(modelPar,zI,zS,zE)
	τSE = τSEFunc(modelPar,zI,zS,zE)
	τ = τI .+ τSE

	a = sFromE * zE .+ sFromS * zS .+ zI .* (1 .- noncompete)  # Take into account effect of non-competes on drift

    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

	zS_density = zeros(size(zS))

	# Construct individual zS policy for computing W
	zS_density[2:end] = (zS ./ mGrid)[2:end]
	zS_density[1] = ξ

	# Spinout flow construction
	spinoutFlow = zeros(size(zS))

	if modelPar.spinoutsSamePool == true

		#spinoutFlow = χS .* ϕI(zS + zI + zE) .* (λ * (1-ζ) * V[1] ) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))
		spinoutFlow = χS .* ϕI(zS + zI + zE) .* (λ * (1- modelPar.κ) *  V[1] ) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))

	else

		#spinoutFlow = χS .* ϕSE(zS .+ zE) .* (λ * (1-ζ) * V[1]) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))
		spinoutFlow = χS .* ϕSE(zS .+ zE) .* (λ * (1- modelPar.κ) * V[1]) .- (sFromS * w + (1-sFromS) * wbar * ones(size(mGrid)))

	end

	Imax = length(mGrid)

	W = zeros(size(V))

	for i = 1:Imax-1

		j = Imax - i

		W[j] = ((a[j] *  ν / Δm[j]) * W[j+1] + zS_density[j] * ( spinoutFlow[j] )) / (ρ + τ[j] + a[j] * ν / Δm[j])

	end

    return W,spinoutFlow

end

function updateMatrixA(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, zI::Array{Float64}, noncompete::Array{Float64}, A::SparseMatrixCSC{Float64,Int64},zS::Array{Float64},zE::Array{Float64})

    ## Unpack model parameters
    ##########################

    λ = modelPar.λ;

    # Spinouts
    ν = modelPar.ν;

	sFromS = modelPar.spinoutsFromSpinouts
	sFromE = modelPar.spinoutsFromEntrants

    ## Unpack guess
    ###################################################

	idxM = guess.idxM

    # Construct mGrid
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    ## Compute A Matrix
    ##############################################

	τI = τIFunc(modelPar,zI,zS,zE)
	τSE = τSEFunc(modelPar,zI,zS,zE)

	#abar = 

    for i = 1:length(mGrid)-1

		A[i,1] = τI[i] * λ
		#A[i,1] = τI[i]  # no λ term -- Moll's idea
		A[i,i+1] = (θ * abar + (1-θ) * ν * ((1-noncompete[i]) * zI[i] + sFromS * zS[i] + sFromE * zE[i])) / Δm[i]
		A[i,i] = - (θ * abar + (1-θ) * ν * ((1-noncompete[i]) * zI[i] + sFromS * zS[i] + sFromE * zE[i])) / Δm[i] - τI[i] - τSE[i]
		#A[i,i] = - ν * (zI[i] + aSE[i]) / Δm[i]

    end

	A[end,1] = τI[end] * λ
	#A[end,1] = τI[end]  # no λ term -- Moll's idea
	A[end,end] = - τI[end] - τSE[end]

end

function updateV_implicit(algoPar::AlgorithmParameters, modelPar::ModelParameters, A::SparseMatrixCSC{Float64,Int64}, u::Array{Float64}, V0::Array{Float64})

	# Unpack

	timeStep = algoPar.incumbentHJB.timeStep
	ρ = modelPar.ρ
	V1 = zeros(size(u))

	B = (1/timeStep + ρ) * I - A

	b = u .+ (1/timeStep) .* V0

	V1 = B \ b

	error = sum(abs.(V1-V0)) ./ timeStep

	return V1, error

end

#function updateV_explicit(algoPar::AlgorithmParameters, modelPar::ModelParameters, )

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
    ξ = modelPar.ξ

	# CNCs
	CNC = modelPar.CNC

	# Wage
	wbar = wbarFunc(modelPar.β)

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

	mGrid, Δm = mGridBuild(algoPar.mGrid)

    # Compute initial guess for V, "value of staying put"
    # based on L_RD guess and profit function

    #V0 = initialGuessIncumbentHJB(algoPar,modelPar,guess)
	V0 = incumbentHJBSolution.V
	#plot(mGrid,V0, label = "Incumbent Value", xlabel = "Mass of spinouts")
	#png("figures/plotsGR/diagnostic_V.png")

	# Load in incumbent solution from previous iteration, as basis
	# for computing zS and zE.

	V_store = incumbentHJBSolution.V
	zI_store = incumbentHJBSolution.zI
	zS = zSFunc(algoPar,modelPar,idxM)
	zE = zEFunc(modelPar,incumbentHJBSolution,w,zS)

	# Initialize incumbent policies
	noncompete = zeros(size(V0))
    zI = zeros(size(V0))

	# Some diagnostics
	#plot(mGrid,w, label = "R&D wage", xlabel = "Mass of spinouts")
	#png("figures/plotsGR/diagnostic_w.png")

	#plot(mGrid,[zS zE], label = ["zS" "zE"], xlabel = "Mass of spinouts")
	#png("figures/plotsGR/diagnostic_zSzE.png")


    ## Construct mGrid and Delta_m vectors
    mGrid,Δm = mGridBuild(algoPar.mGrid)

    # Finally calculate flow profit
	Π = profit(guess.L_RD,modelPar) .* ones(size(mGrid));

	# Initialize transition matrix
	A = spzeros(length(mGrid),length(mGrid))

    iterate = 1
    error = 1

	#diagNumPoints = 20
	#V_diag = zeros(length(mGrid),diagNumPoints)
	#zI_diag = zeros(length(mGrid),diagNumPoints)
	#noncompete_diag = zeros(length(mGrid),diagNumPoints)

	#incumbentObjective(x) = 0

    while iterate < maxIter && error > tolerance

		#print("iterate: $iterate \n")

		#---------------------------#
		# Calculate optimal non-compete and optimal zI given non-compete
		# and given no non-compete.
		#---------------------------#

		Vprime2 = (V0[3] - V0[2]) / Δm[2]

		#zS = zS(algoPar,modelPar,idxM)
		#zE = zE(modelPar,V0[1],zI,w,zS)updateV_implicit

		#print(Vprime2)

		if modelPar.spinoutsSamePool == true

			for i = reverse(1:length(mGrid)-1)
			    Vprime = (V0[i+1] - V0[i]) / Δm[i]

				if i == 1
					Vprime = Vprime2
				end

				objective1(z) = -(z * χI * ϕI(z + zS[i] + zE[i])  * ( λ * V0[1] - V0[i] ) - z * ( w[i] - ν * Vprime))
				objective2(z) = -(z * χI * ϕI(z + zS[i] + zE[i])  * ( λ * V0[1] - V0[i] ) - z * wbar)

				if CNC == false || w[i] - ν * Vprime <= wbar

					#print("Branch 1: \n")

					#incumbentObjective(z) = -(z * χI * ϕI(z + zS[i] + zE[i])  * ( λ * V0[1] - V0[i] ) - z * ( w[i] - ν * Vprime))

					#incumbentObjective(z::Float64) = 0

					#plot(0:0.01:1,objective1, label = "Incumbent Objective", xlabel = "R&D effort zI", ylabel = "Flow + continuation payoff")
					#png("figures/plotsGR/diagnostic_incumbentObjective.png")

					lower = 0
					upper = 10

					#print("zS[$i] = $(zS[i])\n")
					#print("zE[$i] = $(zE[i])\n")
					#print("λ = $λ\n")
					#print("χI = $χI\n")
					#print("V0[1] = $(V0[1])\n")
					#print("V0[$i] = $(V0[i])\n")
					#print("w[$i] = $(w[i])\n")

					#print("objective1(0.01) = $(objective1(0.01))\n")
					#print("objective1(1) = $(objective1(1))\n")

					#plot(0:0.01:1,objective1,title = "objective1", label = "incumbent objective", xlabel = "z")
					#png("figures/plotsGR/diagnostic_incumbentObjective.png")


					#print("incumbentObjective at z = 0: $(incumbentObjective(0)) \n")
					#print("incumbentOjbective at z = 1: $(incumbentObjective(1)) \n")

					result = optimize(objective1,lower,upper)

					#print("result = $result\n")

					zI[i] = Optim.minimizer(result)

					#print("zI[$i] = $(zI[i]) \n\n")

				else

					noncompete[i] = 1

					#incumbentObjective(z) = -(z * χI * ϕI(z + zS[i] + zE[i])  * ( λ * V0[1] - V0[i] ) - z * wbar)

					lower = 0
					upper = 10

					result = optimize(objective2,lower,upper)

					zI[i] = Optim.minimizer(result)

				end



			end

		else

			for i = reverse(1:length(mGrid)-1)
				Vprime = (V0[i+1] - V0[i]) / Δm[i]

				if i == 1
					Vprime = Vprime2
				end

				#if i >= idxM
				#	Vprime = 0
				#end

				numerator = w[i] - ν * Vprime
				denominator = (1- ψI) * χI * ( λ * V0[1] - V0[i])
				ratio = numerator / denominator

				#print("$(numerator - wbar)")

				if ratio > 0

					if CNC == false || numerator <= wbar

						noncompete[i] = 0
						zI[i] = ratio^(-1/ψI)

					else

						noncompete[i] = 1
						numerator_CNC = wbarFunc(modelPar.β)
						ratio_CNC = numerator_CNC / denominator
						zI[i] = ratio_CNC^(-1/ψI)

					end

				else

					noncompete[i] = 0
					zI[i] = 0.01 # not realy used...but haven't deleted just in case..

				end

			end

		end

		# Hack - "guess and verify", true in eq by continuity

		zI[end] = zI[end-1]

		#zI[1] = zI[2] #- no need for hack with Moll's method
		#noncompete[1] = noncompete[2]

		# Try this stability method
		#zI[idxM+1:end] = zI[idxM] * ones(size(zI[idxM+1:end]))
		#noncompete[idxM+1:end] = noncompete[idxM] * ones(size(zI[idxM+1:end]))

		#gr()
		#plot(mGrid,zI)
		#png("figures/plotsGR/diagnostic_zI.png")
		#print(zI)

		#plot(0:0.01:1,ϕI)
		#png("figures/plotsGR/diagnostic_ϕI.png")


		# Stability hack
		#zI[idxM+1:end] .= zI[idxM]


		## This should be deletable - but for now keeping it in just in case

		if CNC == false
			noncompete[:] .= 0
		end

		## Unpack z and tau functions
		#######################################

		#zS = zSFunc(algoPar,modelPar,idxM)[:]
		#zE = zEFunc(modelPar,V0[1],zI,w,zS)[:]

		τI = τIFunc(modelPar,zI)
		#τI = τI(modelPar,zI,zS,zE)[:]
		#τSE = τSE(modelPar,zI,zS,zE)[:]

		if implicit == true

			## Implicit method

			# Compute flow payoff
		    u = Π .- zI .* ((1 .- noncompete) .* w + noncompete .* wbarFunc(modelPar.β))
			#u = Π .+ τI .* (λ-1) .* V0[1]  .- zI .* ((1 .- noncompete) .* w + noncompete .* wbarFunc(modelPar.β))  # Moll's idea -- here add (λ-1) * τI * V0[1] term

			# Update "transition" matrix A
			updateMatrixA(algoPar,modelPar,guess,zI,noncompete,A,zS,zE)

			#print("Type of A: $(typeof(A))\n")
			#print(A)
			#print(UnicodePlots.spy(A))
			#png("spyA.png")

			# Implicit update step to compute V1 and error
			try
				V1,error = updateV_implicit(algoPar,modelPar,A,u,V0)

			catch caughtError

				#print(caughtError)
				#V1,error = updateV_explicit(algoPar,modelPar,A,u,V0)

			end

			# Hack to avoid instabiities - will be true in equilibrium
			V1[idxM+1:end] .= V1[idxM]

			# Normalize error by timeStep because
			# it will always be smaller if timeStep is smaller
			error = sum(abs.(V1-V0)) ./ timeStep

		else

			## Explicit method

			V1,error = updateV_explicit(algoPar,modelPar,guess,V0)

		end



		if verbose == 2
			if iterate % print_skip == 0
				println("solveIncumbentHJB: Compute iterate $iterate with error $error")
			end
		end

		#V_diag[:,iterate] = V1
		#zI_diag[:,iterate] = zI
		#noncompete_diag[:,iterate] = noncompete

		V0 = V1

		iterate += 1

	end

	if verbose >= 1
		if error > tolerance
			@warn("solveIncumbentHJB: maxIter attained")
		elseif verbose == 2
			println("solveIncumbentHJB: Converged in $iterate steps")
		end
	end

    # Output
    #return V_diag,zI_diag,noncompete_diag,IncumbentSolution(V0,zI,noncompete)
	return IncumbentSolution(V0,zI,noncompete)

end

function solveIncumbentHJB_explicitMethod(algoPar::AlgorithmParameters, modelPar::ModelParameters, guess::Guess, verbose = 2, print_skip = 10)

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
	wbar = wbarFunc(modelPar.β)

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
	V0 = initialGuessIncumbentHJB(algoPar,modelPar,guess)
	noncompete = zeros(size(V0))
	zI = zeros(size(V0))

	## Construct mGrid and Delta_m vectors
	mGrid,Δm = mGridBuild(algoPar.mGrid)

	# Finally calculate flow profit
	Π = profit(guess.L_RD,modelPar) .* ones(size(mGrid));

	iterate = 1
	error = 1


	while iterate < maxIter && error > tolerance


		Vprime2 = (V0[3] - V0[2]) / Δm[2]




	end



end
