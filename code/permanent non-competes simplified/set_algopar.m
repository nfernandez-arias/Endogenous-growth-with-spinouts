function d = set_algopar(pm)
    
	% Linearly-spaced grid
	% Set m parameters
	
	%d.m_numpoints = 4000;
    %d.m_min = 0;
    %d.m_max = 2; 
    %d.m_grid = linspace(0,d.m_max,d.m_numpoints);
	
    
    
	% Log-spaced grid (may be helpful later)
    d.m_numpoints = 4000;
    d.m_min = log(0.001) / log(10);
    d.m_max = log(10) / log(10);
    %d.m_grid = logspace(d.m_min,d.m_max,d.m_numpoints);
    d.m_grid = [0 logspace(d.m_min,d.m_max,d.m_numpoints -1)];
	
       
    d.Delta_m = zeros(size(d.m_grid));
   
    for i = 1:length(d.m_grid)-1
		d.Delta_m(i) = d.m_grid(i+1) - d.m_grid(i);
    end
    
    d.Delta_m(end) = d.Delta_m(end-1);
    
    %% t-grid
    d.t_max = 150;
    d.t_numpoints = 640;
    
    %% Finite difference
    d.delta_t_V = 1;
    d.delta_t_W = 0.1;
    %d.d_m = 0.0001;
    
    %% Simulation
    d.sim_delta_t = 1; 
    d.num_draws = 100;
    d.run_time = 10;
    
    %% Guess updating
    % _UR suffix means "update rate"
    d.zS_UR = 1;
    d.zS_UR_exponent = 2;
    d.zE_UR = 1;
    d.zE_UR_exponent = 2;
    d.w_UR = 1;
    d.L_RD_UR = 0.1;
    d.V_0_UR = 0.8;
    
    %% Tolerances
    d.HJB_V_tol = 0.001 * d.delta_t_V;
    d.HJB_W_tol = 10e-10 * d.delta_t_W;
    d.L_RD_tol = 10e-3;
    d.w_tol = 10e-3;
    d.zS_tol = 10e-4;
    d.mu_tol = 10e-4;
    d.V_0_tol = 10e-4;

end