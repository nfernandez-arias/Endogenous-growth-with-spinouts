function [modelpar] = set_modelpar()
    
    % Production of intermediate and final goods
    modelpar.rho = 0.01;
    modelpar.beta = 0.2;
    
    % R&D
    modelpar.chi_I = 1;
    modelpar.chi_E = 1;
    modelpar.psi_I = 0.5;
    modelpar.psi_E = 0.5;
    modelpar.lambda = 1.1;
    
    % Knowledge leakage
    modelpar.nu = 0.1;
    modelpar.theta = 0.05;
    
    % Non-compete
    modelpar.T_nc = 2;
   
end

    
    
    
    
    
    
    