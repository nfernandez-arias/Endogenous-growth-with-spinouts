function d = set_init_guesses_V(pa,pm,ig)

	d.prof = pm.prof_func(pm.LF_func(ig.L_RD)) * ones(size(pa.m_grid));
	d.V_maxcount = 30;
	d.V_0_maxcount = 1;
	

	if isfield(ig,'V')
		
		d.V0 = ig.V;
		
	else 
		
	   d.V0 = d.prof / pm.rho;
	   
	end
	
	if isfield(ig,'V_0')
	
		d.V_0 = ig.V_0;
		
	else
	
		d.V_0 = d.prof(1) / pm.rho;
		
	end
	
	if isfield(ig,'M')
	
		d.M = ig.M;
		
	else
	
		d.M = pa.m_grid(end);
		
	end
	
	d.zmax = 5;

end
