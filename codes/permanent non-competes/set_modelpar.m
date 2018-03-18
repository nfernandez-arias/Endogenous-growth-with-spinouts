function d = set_modelpar()

    d.rho = 0.03;
    d.beta = 0.2;
    d.wbar = d.beta^d.beta*(1-d.beta)^(1-2*d.beta);
    d.chi_I = 0.03;
    d.chi_E = 0.03;
    d.psi_I = 0.5;
    d.psi_E = 0.5;  
    d.lambda = 1.2;  
    d.nu = 0.2;
    %d.theta = 0.05;
    %d.T_nc = 2;
    d.xi = 0.2;   
    d.p1 = -0.5;
    d.p2 = -0.1;
    
    
    % Aggregate decreasing returns to scale in innovation effort
    d.phi = @(z) z.^(d.p1);
    % Decreasing efficiency of R&D for higher quality goods 
    d.scaleFactor = @(z) z.^(d.p2);
    
end
