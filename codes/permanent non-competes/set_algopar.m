function d = set_algopar(pm)
    
    %% Grids
    % q parameters

	% Deprecated (used for explicit method) - linearly spaced grid
    %d.q_numpoints = 15;
    %d.q_max = 3;
    %d.q_min = 0;
    %d.q_grid = linspace(d.q_min,d.q_max,d.q_numpoints);
    
    % For implicit method: log-spaced grid.
    d.q_upbar = 5;
    d.q_lowbar = 0.1;
    d.q_m = 5;
	d.q_n = floor((d.q_m / log(1+pm.lambda)) * (log(d.q_upbar) - log(d.q_lowbar)));
    
    d.q_grid = zeros(size(1:(d.q_n+1)));
    d.Delta_q = zeros(size(1:(d.q_n+1)));
    
    d.q_grid(1) = 0;
    d.q_grid(2) = d.q_lowbar;
    
    for i = 3:d.q_n+1
		d.q_grid(i) = (1+pm.lambda)^(1/d.q_m) * d.q_grid(i-1);
	end
	
	% Will use to calculate left-derivatives by finite-difference 
	
	for i = 2:d.q_n+1
		d.Delta_q(i) = d.q_grid(i) - d.q_grid(i-1);
	end
	

    
	% Deprecated - linearly-spaced grid
	% Set m parameters
	%d.m_numpoints = 15;
    %d.m_min = 0;
    %d.m_max = 3; 
    %d.m_grid = linspace(0,d.m_max,d.m_numpoints);
    
    d.m_numpoints = 30;
    d.m_min = log(0.001) / log(10);
    d.m_max = log(5) / log(10);
    d.m_grid = logspace(d.m_min,d.m_max,d.m_numpoints);
    
    [d.q_grid_2d,d.m_grid_2d] = ndgrid(d.q_grid,d.m_grid);

	%{
    d.q_numpoints_FINE = 100;
    d.m_numpoints_FINE = 50;
    d.q_grid_FINE = linspace(0,d.q_max,d.q_numpoints_FINE);
    d.m_grid_FINE = linspace(0,d.m_max,d.m_numpoints_FINE);
    [d.q_grid_2d_FINE,d.m_grid_2d_FINE] = ndgrid(d.q_grid_FINE,d.m_grid_FINE);
    %}
    
    %% Finite difference
    d.delta_t_V = 2;
    d.delta_t_W = 0.15;
    d.delta_m = 0.0001;
    d.d_q = 0.0001;
    
    %% Simulations
    d.sim_delta_t = 0.1;
    d.num_draws = 100;
    d.run_time = 10;
    
    %% Guess updating
    % _UR suffix means "update rate"
    d.zE0_UR = 1;
    d.zE0_UR_exponent = 1;
    d.g0_UR = 0.1;
    d.w0_UR = 0.1;
    d.Lf0_UR = 0.1;
    
    %% Tolerances
    d.HJB_V_tol = 10e-4 * d.delta_t_V;
    d.HJB_W_tol = 10e-4 * d.delta_t_W;
    d.Lf_tol = 10e-3;
    d.g_tol = 10e-3;
    d.wF_tol = 10e-3;
    d.zE_tol = 10e-5; 
    d.x_tol = 10e-3;

end
