function [eq_out] = compute_eq(model_par,numerical_par,init_guesses,tol)

    if isempty(num_iter)
        num_iter = 10000;
    end
    
    % Initialize distance
    d = 1;
    
    while d > tol
        
        compute_eq_GIVEN_g(par,g0,tol,);
        
        
        
    


    