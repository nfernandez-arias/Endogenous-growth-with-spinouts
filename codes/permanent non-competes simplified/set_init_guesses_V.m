function d = set_init_guesses_V(pa,pm,ig)

	d.prof = pm.prof_func(pm.LF_func(ig.L_RD)) * ones(size(pa.m_grid));

	if isfield(ig,'V')
		
		d.V0 = ig.V;
		
	else 
		
	   d.V0 = d.prof / pm.rho;
	   
	end

	%d.V0 = 0.1*ones(size(d.prof));
	d.maxcount = 10;
	d.zmax = 5;

end
