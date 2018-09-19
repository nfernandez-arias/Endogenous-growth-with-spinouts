function out = aggregation(pa,pm,ng,V_out,W_out)

	%% Here, implement the solution to the system of equations

	%% Implelent change of variables
	% First, compute drift a(m): 
	
	a = (ng.zE + ng.zS + V_out.zI) * pm.nu;
	a_interp = griddedInterpolant(pa.m_grid,a);

	% Construct t grid
	t_grid = linspace(0,pa.t_max,pa.t_numpoints);
	Delta_t = t_grid(2) - t_grid(1);
	
	m = zeros(size(t_grid));
	% Compute m(t)
	for i = 2:length(t_grid)
	
		for j = 1:i-1
		
			m(i) = m(i) + a_interp(m(j));
			
		end
		
	end
	
	m = m*Delta_t;
	
	% Now compute tau(t) = tau(m(t))
	tau = (pm.chi_E * ng.zE + pm.chi_S * ng.zS) .* pm.eta(ng.zE + ng.zS) ...
			+ pm.chi_I * V_out.zI .* pm.phi(V_out.zI);
	tau_interp = griddedInterpolant(pa.m_grid,tau)
	tauhat = zeros(size(t_grid));
	tauhat = tau_interp(m);
	
	% This will return objects mu, gamma defined in m'-space. Since mu is a density, defining it in m-space will require a change of variables term, dm/dm' or something. come to that later.
	
	function g_eq_out = g_eq(x)
	
		gtauhat_integral = zeros(size(t_grid));
		
		gtauhat_integral(1) = 0;
		
		for i = 2:length(t_grid)
			
			for j = 1:i-1
			
				%size(gtauhat_integral)
				%size(tauhat)
				%pause
				gtauhat_integral(i) = gtauhat_integral(i) + x + tauhat(j);
			
			end
		
		end
		
		gtauhat_integral = gtauhat_integral * Delta_t;
		
		integral = sum(exp(-1 * gtauhat_integral)) * Delta_t;
		
		g_eq_out = ((pm.lambda - 1) / pm.lambda) * integral^(-1) - x;
		
	end
	
	% Solve for root to find equilibrium g
	 
	g0 = 0;
	g = fzero(@g_eq,g0);
	
	% Use equation from system to compute C given g
	
	C = (pm.lambda - 1) / pm.lambda * g^(-1);
	
	%% Now compute C_mu using system - have to integral again
	
	tauhat_integral = zeros(size(t_grid));
		
	tauhat_integral(1) = 0;
	
	for i = 2:length(t_grid)
		
		for j = 1:i-1
		
			tauhat_integral(i) = tauhat_integral(i) + tauhat(j);
		
		end
	
	end
	
	tauhat_integral = tauhat_integral * Delta_t;
	
	integral = sum(exp(-1 * tauhat_integral)) * Delta_t;
	
	C_mu = integral^(-1);
	
	%% Finally compute C_gamma
	
	C_gamma = C^(-1) * C_mu^(-1);
	
	%% Compute L_RD
	% Now, we have gamma (requires C_gamma and g) and mu (requires C_mu) so we can 
	% compute L_RD by aggregating. 
	
	z_agg = ng.zE + ng.zS + V_out.zI;
	z_agg_interp = griddedInterpolant(pa.m_grid,z_agg);
	zhat_agg = z_agg_interp(m);
	
	
	% Next construct mu, gamma
	gammahat = zeros(size(t_grid));
	muhat = gammahat;
	
	gammahat = C_gamma * exp(-g*t_grid);
	muhat = C_mu * exp(-1 * tauhat_integral);
	
	% Finally, can compute L_RD

	L_RD = zhat_agg * (gammahat .* muhat)' * Delta_t;
	
	
	
	out.g = g;
	out.C_mu = C_mu;
	out.C_gamma = C_gamma;
	out.tau = tau;
	out.tauhat = tauhat;
	out.m = m;
	out.a = a;
	%out.a_interp = a_interp;
	out.L_RD = L_RD;
	out.muhat = muhat;
	out.gammahat = gammahat;
	

end
