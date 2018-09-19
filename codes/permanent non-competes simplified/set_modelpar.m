function d = set_modelpar()

    d.rho = 0.03;
    d.beta = 0.2;
    d.betatilde = d.beta^d.beta*(1-d.beta)^(2-2*d.beta);
    d.wbar = d.betatilde;
    d.chi_I = 1.5;
    d.chi_E = .5;
    d.chi_S = 1.5;
    d.psi_I = 0.5;
	d.psi_SE = 0.5;
    d.lambda_I = 1.2;
    d.lambda_SE = 1.2;
    d.lambda = d.lambda_I;  
    d.nu = 0.2;
    d.xi = 0.1;   
    d.Ltot = 1;
    
    % Aggregate decreasing returns to scale in innovation effort
    d.phi_min = 0.000000001;
    d.phi = @(z) (d.phi_min + z).^(-d.psi_I);
    
    d.phi_inv = @(x) x.^(-1/d.psi_I);
    
    d.eta_min = 0.00000000001;
    d.eta = @(z) (d.eta_min + z).^(-d.psi_SE); 
    
    d.eta_inv = @(x) x.^(-1/d.psi_SE);
    
    % Profit as function of L_RD guess
    
    d.LF_func = @(L_RD) (d.beta * (d.Ltot-L_RD) / (d.beta + (1-d.beta)^2));
    d.prof_func = @(L_F) d.beta * (1- d.beta)^((2-d.beta)/d.beta) * d.betatilde^(-1) * L_F; 
    
end
