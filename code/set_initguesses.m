function [init_guesses] = set_initguesses(model_par,numerical_par)
    
    % Load relevant model parameters
    beta = model_par.beta;
    qgrid = numerical_par.qgrid;
    mgrid = numerical_par.mgrid;
    
    w0 = (beta ^ beta) * (1-beta)^(1-2*beta);
    
    init_guesses.g = 0.015;
    init_guesses.sigma = 0.02;
    
    init_guesses.tau = 0.01 * ones(length(qgrid),length(mgrid));
    init_guesses.w_E = w0 * ones(size(init_guesses.tau));

end

    
    
    
    
    
    
    