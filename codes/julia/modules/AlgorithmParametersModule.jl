#---------------------------------
# Name: AlgorithmParametersModule.jl
#
# Module relating to algorithm parameters
#
# Contains definitions of
# algorithm types and some
# auxiliary functions.

__precompile__()

module AlgorithmParametersModule

export AlgorithmParameters, mGridParameters, mGridBuild, HJBellmanParameters, IterationParameters, LogParameters;

struct mGridParameters

    numPoints::Int
    minimum::Float64
    maximum::Float64

    logSpacing::Bool
    logSpacingMinimum::Float64

end

function mGridBuild(par::mGridParameters)

    if par.logSpacing == false

        mGridFinal = range(par.minimum, stop = par.maximum, length = par.numPoints);

    else

        temp = 10 .^range(log(10,par.logSpacingMinimum),stop = log(10,par.maximum), length = par.numPoints - 1);
        mGridFinal = insert!(temp,1,par.minimum);

    end

    Δm = zeros(size(mGridFinal))

    for i = range(1,length = length(mGridFinal) - 1)

        Δm[i] = mGridFinal[i+1] - mGridFinal[i]

    end

    Δm[end] = Δm[end - 1]

    return mGridFinal,Δm

end

struct HJBellmanParameters

    timeStep::Float64
    tolerance::Float64
    maxIter::Int64

end

struct IterationParameters

    tolerance::Float64
    maxIter::Float64
    updateRate::Float64
    updateRateExponent::Float64

end

struct LogParameters

    verbose::Int64
    print_skip::Int64

end

struct AlgorithmParameters

    mGrid::mGridParameters
    incumbentHJB::HJBellmanParameters
    spinoutHJB::HJBellmanParameters
    g::IterationParameters
    L_RD::IterationParameters
    w::IterationParameters
    zSzE::IterationParameters
    g_L_RD_w_Log::LogParameters
    zSzE_Log::LogParameters
    incumbentHJB_Log::LogParameters

end

end
