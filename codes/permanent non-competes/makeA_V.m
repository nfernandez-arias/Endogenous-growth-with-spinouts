function out = makeA_V(pa,pm,ig,z,y)

	Imax_q = length(pa.q_grid);
	Imax_m = length(pa.m_grid);
	
	%scalefactor = pm.scalefactor;
	
	idx = @(i_q,i_m) (i_q - 1) * Imax_m + i_m;
	
	out = zeros(Imax_q * Imax_m);

	for i_m = 1:Imax_m - 1
	
		m = pa.m_grid(i_m);
	
		% No extrapolation necessary
		
		i_q = 1;
		
		q = pa.q_grid(i_q);
		
		i1 = idx(i_q,i_m);
		
		%{
		if i_m == 4
			-ig.g0 * q / pa.Delta_q(i_q)
			-(pm.chi_I*z(i_q,i_m) + pm.chi_E*ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) / pa.Delta_m(i_m)
			pause
		end
		%}
		
		out(i1,i1) = ... %-ig.g0*q / pa.Delta_q(i_q) ...
					 -(pm.chi_I*z(i_q,i_m) + pm.chi_E*ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) ...
					 - pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
		
		
		out(i1,idx(i_q,i_m+1)) = pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
	
		
		for i_q = 2:Imax_q-(pa.q_m-1)-1
			
			q = pa.q_grid(i_q);
			
			%q = 1;
			
			i1 = idx(i_q,i_m);
			
			
			out(i1,i1) = -ig.g0*q / pa.Delta_q(i_q) ...
					     -(pm.chi_I*z(i_q,i_m) + pm.chi_E*ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) ...
					     - pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
					     
	
			out(i1,idx(i_q-1,i_m)) = ig.g0 * pa.q_grid(i_q) / pa.Delta_q(i_q);
			
			out(i1,idx(i_q,i_m+1)) = pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
			
			out(i1,idx(i_q + pa.q_m,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(pa.q_grid(i_q));
			
		end
		
		% Extrapolate based on future values of q
		
		for i_q = Imax_q-(pa.q_m-1):Imax_q-1
		
			q = pa.q_grid(i_q);
		
			i1 = idx(i_q,i_m);
		
			out(i1,i1) = -ig.g0*q / pa.Delta_q(i_q) ...
					     -(pm.chi_E*ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) ...
					     - pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
			
			out(i1,idx(i_q-1,i_m)) = ig.g0 * q / pa.Delta_q(i_q);
			
			out(i1,idx(i_q,i_m+1)) = pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
			
			%out(i1,idx(i_q,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (1 - pm.lambda/((1+pm.lambda)^(1/pa.q_m) - 1));
			
			%out(i1,idx(i_q + 1,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) *  (pm.lambda/((1+pm.lambda)^(1/pa.q_m) - 1));
		
		end
	
		
		% Extrapolate based on past values of q
		
		i_q = Imax_q;
		
		i1 = idx(i_q,i_m);
		
		q = pa.q_grid(i_q);
		
		out(i1,i1) = -ig.g0*q / pa.Delta_q(i_q) ...
					     -(pm.chi_E*ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) ...
					     - pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
			
		out(i1,idx(i_q-1,i_m)) = ig.g0 * q / pa.Delta_q(i_q);
		
		out(i1,idx(i_q,i_m+1)) = pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
		
		%out(i1,idx(i_q,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (1 + pm.lambda/(1-(1+pm.lambda)^(-1/pa.q_m)));
		
		%out(i1,idx(i_q-1,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (-pm.lambda/(1-(1+pm.lambda)^(-1/pa.q_m)));
		
	end
	
	%% Set i_m = I_m values, using boundary condition that V_m = 0 for large values of m

	i_m = Imax_m;
	m = pa.m_grid(i_m);

	% No extrapolation necessary
	
	i_q = 1;
		
	q = pa.q_grid(i_q);
	
	i1 = idx(i_q,i_m);
		
	out(i1,i1) = -(pm.chi_I*z(i_q,i_m) + pm.chi_E*ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q);
				%-ig.g0*q / pa.Delta_q(i_q)
	

	%out(i1,idx(i_q,i_m+1)) = pm.nu * (ig.zE0(i_q,i_m) + (1-y(i_q,i_m))*z(i_q,i_m)) / pa.Delta_m(i_m);
	
	out(i1,idx(i_q + pa.q_m,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q);
	
	for i_q = 2:Imax_q-(pa.q_m-1)-1
	
		q = pa.q_grid(i_q);
	
		i1 = idx(i_q,i_m);
		
		out(i1,i1) = -ig.g0*q / pa.Delta_q(i_q) - (pm.chi_I * z(i_q,i_m) + pm.chi_E * ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q);
					 
		out(i1,idx(i_q-1,i_m)) = ig.g0 * q / pa.Delta_q(i_q);
		
		out(i1,idx(i_q + pa.q_m,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q);
		
	end
	
	% Extrapolate based on higher values of q
	
	for i_q = Imax_q-(pa.q_m-1):Imax_q-1
	
		q = pa.q_grid(i_q);
	
		i1 = idx(i_q,i_m);
	
		out(i1,i1) = -ig.g0*q / pa.Delta_q(i_q) - (pm.chi_E * ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q);
		
		out(i1,idx(i_q-1,i_m)) = ig.g0 * q / pa.Delta_q(i_q);
		
		%out(i1,idx(i_q,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (1 - pm.lambda/((1+pm.lambda)^(1/pa.q_m) - 1));
		
		%out(i1,idx(i_q + 1,1)) =  pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (pm.lambda/((1+pm.lambda)^(1/pa.q_m) - 1));
	
	end
	
	% Extrapolate based on lower values of q 
	
	i_q = Imax_q;
	q = pa.q_grid(i_q);
	
	i1 = idx(i_q,i_m);
	
	out(i1,i1) = -ig.g0*q / pa.Delta_q(i_q) - ( pm.chi_E * ig.zE0(i_q,i_m)) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q);
		
	out(i1,idx(i_q-1,i_m)) = ig.g0 * q / pa.Delta_q(i_q);
	
	%out(i1,idx(i_q,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (1 + pm.lambda/(1-(1+pm.lambda)^(-1/pa.q_m)));
	
	%out(i1,idx(i_q-1,1)) = pm.chi_I * z(i_q,i_m) * pm.phi(z(i_q,i_m) + ig.zE0(i_q,i_m)) * pm.scaleFactor(q) * (-pm.lambda/(1-(1+pm.lambda)^(-1/pa.q_m)));
		
	
	%figure
	%spy(out)
	%pause
	
end


