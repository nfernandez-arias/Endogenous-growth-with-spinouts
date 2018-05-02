function d = set_init_guesses_W(pa,pm,ig,Vplus,zI)

	if isfield(ig,'W')
		
		d.W = ig.W;
		
	else 
		
		d.W = zeros(size(pa.m_grid));
	   
	end

    d.maxcount =  50;
    
end
