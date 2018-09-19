function out = solve_HJB_W_easy(pa,pm,ig,V_out)

	W = zeros(size(pa.m_grid));
	Imax = length(pa.m_grid);

	tau = V_out.zI .* pm.chi_I .* pm.phi(V_out.zI) + (ig.zE .* pm.chi_E + ig.zS .* pm.chi_S) .* pm.eta(ig.zE + ig.zS);

	% Boundary condition: Right derivative W'(Imax) = 0
	
	W(Imax) = (pm.xi * (pm.chi_S * pm.eta (ig.zS(Imax) + ig.zE(Imax)) * V_out.V(1) - ig.w(Imax))) ...
				/ (pm.rho + tau(Imax));

	z_agg = V_out.zI + ig.zS + ig.zE;

	for i= Imax-1:-1:1
	
		W(i) = (z_agg(i) * pm.nu / pa.Delta_m(i) * W(i+1) ...
		        + pm.xi * (pm.chi_S * pm.eta (ig.zS(i) + ig.zE(i)) * V_out.V(1) - ig.w(i)))     ...
		/ (pm.rho + tau(i) + (z_agg(i) * pm.nu / pa.Delta_m(i)));
		
	end

	out.W = W;
	
end
