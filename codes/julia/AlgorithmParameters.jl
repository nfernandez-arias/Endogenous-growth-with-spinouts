#---------------------------------#
# Name: AlgorithmParameters.jl    #
#                                 #
# Contains definitions of
# algorithm types and some
# auxiliary functions.
#

struct mGridParameters

    numPoints::Int
    minimum::Float64
    maximum::Float64

    logSpacing::Bool
    logSpacingMinimum::Float64

end

function mGridBuild(par::mGridParameters)

    if par.logSpacing == false

        return range(par.minimum, stop = par.maximum, length = par.numPoints);

    else

        temp = 10 .^range(log(10,par.logSpacingMinimum),stop = log(10,par.maximum), length = par.numPoints - 1);
        return insert!(temp,1,par.minimum);

    end

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

struct AlgorithmParameters

    mGrid::mGridParameters
    incumbentHJB::HJBellmanParameters
    spinoutHJB::HJBellmanParameters
    L_RD::IterationParameters
    w::IterationParameters
    zS::IterationParameters
    zE::IterationParameters

end
