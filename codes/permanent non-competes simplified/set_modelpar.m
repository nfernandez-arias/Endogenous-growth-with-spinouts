function d = set_modelpar()

    d.rho = 0.03;
    d.beta = 0.2;
    d.wbar = d.beta^d.beta*(1-d.beta)^(1-2*d.beta);
    d.chi_I = 0.03;
    d.chi_E = 0.03;
    d.chi_S = 0.06;
    d.psi_I = 0.5;
	d.psi_SE = 0.5;
    d.lambda_I = 0.2;
    d.lambda_SE = 0.2;
    d.lambda = d.lambda_I;  
    d.nu = 0.2;
    d.xi = 0.1;   
    
    % Aggregate decreasing returns to scale in innovation effort
    d.phi_min = 0.00001;
    d.phi = @(z) (d.phi_min + z).^(d.psi_I);
    
    d.eta_min = 0.00001;
    d.eta = @(z) (d.eta_min + z).^(d.psi_SE);
    
end
