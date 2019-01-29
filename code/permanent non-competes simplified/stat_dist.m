function out = stat_dist(pa,pm,ig,V_out)

	a = pm.nu * (V_out.zI + ig.zS + ig.zE);
	tau = pm.chi_I * V_out.zI .* pm.phi(V_out.zI) ...
		  + (pm.chi_S * ig.zS + pm.chi_E * ig.zE) .* pm.eta(ig.zS + ig.zE);
	
	mu = ones(size(pa.m_grid));
	Imax = length(pa.m_grid);
		  
	mu_d = 1;
	count = 1;
	
	while ((mu_d > pa.mu_tol) && (count <= ig.maxcount))
	
		mu(1) = ig.mu;
		sum = mu(1) * pa.Delta_m(1);
		
		for i=1:Imax-1
		
			mu(i+1) = (a(i) / pa.Delta_m(i))^(-1) * ( (a(i+1)/pa.Delta_m(i)) - tau(i)) * mu(i);
			sum = sum + mu(i+1) * pa.Delta_m(i+1);
			
		end
		
		% decrease initial guess if sum is greater than 1.
		mu1 = mu(1) / sum;
		
		mu_d = abs(mu1 - mu(1));
		
		ig.mu = pa.mu_UR * mu1 + (1- pa.mu_UR) * mu(1);
		
	end
	
	out.a = a;
	out.mu = mu;
	
end
