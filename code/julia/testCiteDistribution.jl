function GammaFunc(p,gammaLambda,grid)

  gamma = zeros(size(grid))

  gamma[1] = 1 - (1-p) * gammaLambda / (p + (1-p) * gammaLambda)

  for i = 2:length(gamma)

    gamma[i] = gamma[i-1] * ( (1-p) * gammaLambda / (p + (1-p) * gammaLambda))

  end

  return gamma

end
