function d = set_init_guesses_W(pa,pm,ig,Vplus,zI)

	if isfield(ig,'W')
		
		d.W0 = ig.W;
		
	else 
		
		d.W0 = ones(size(pa.q_grid_2d));
	   
	end

    d.maxcount = 500;
    
end
