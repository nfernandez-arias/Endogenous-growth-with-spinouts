function out = solve_model(pa,pm,ig)

    L_RD_d = 1;
    w_d = 1;
    zE_d = 1;
    HJB_d = 1;
    
    ng.L_RD = ig.L_RD; 
    ng.w = ig.w;
    ng.zE = ig.zE;
    
    frame_freq = 1;
    F(1) = struct('cdata',[],'colormap',[]);
    f = figure('visible','off');
    
    L_RD_count = 1;
    
    while ((L_RD_d > pa.L_RD_tol) && (L_RD_count <= ig.L_RD_maxcount))
    
		% Closed form for production wage and static profit - depends on guess L_RD
		wbar = ones(size(pa.m_grid));
		prof = ones(size(pa.m_grid));
		
		w_count = 1;
		
		while ((w_d > pa.w_tol) && (w_count <= ig.w_maxcount))
		
			% Now have W guess, which is equivalent to a guess of the wage.
			% Next, we solve the game played between entrants and incumbents, 
			% taking flow profits and wages as given.
			
			zE_count = 1;	
				
			while ((zE_d > pa.zE_tol) && (zE_count <= ig.zE_maxcount)) 
			
				V_out = solve_HJB_V(pa,pm,ng);
				W_out = solve_HJB_W(pa,pm,ng,V_out);
				
				% Check convergence 
				zE_d = sqrt(sumsqr(W_out.zE1 - ng.zE));
				
				% Update zE 
				ng.zE = pa.zE_UR * W_out.zE1 + (1- pa.zE_UR) * ng.zE;
				
				zE_count = zE_count + 1;
			
			end
			
			% Now we check whether the wage we have assumed is consistent
			% with worker optimality.
			
			implied_wage = wbar - pm.nu * W_out.W;
			
			w_d = sqrt(sumsqr(implied_wage - ng.w));
			
			ng.w = pa.w_UR * implied_wage + (1-pa.w_UR) * ng.w;
			
			w_count = w_count + 1;
			
			
		end
		
		%%% STATIONARY DISTRIBUTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% We now have individual policies given R\&D wage.
		% We can compute the stationary distribution from these
		% individual policies using KF equation:
		
		mu = stat_dist(pa,pm,ng,V_out,W_out);
		
		%%% AGGREGATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		% Now, using this stationary distribution and the policies
		% we can compute the implied demand for R\&D labor
		
		L_RD1 = labor_demand(pa,pm,ng,V_out,W_out,mu);
		
		L_RD_d = abs(L_RD1 - ng.L_RD);
		
		ng.L_RD = pa.L_RD_UR * L_RD1 + (1 - pa.L_RD_UR) * ng.L_RD; 
		
		L_RD_count = L_RD_count + 1;
		
	end	
           
    out.V_out = V_out;
    out.W_out = W_out;
    out.agg_eq = ng;
    out.mu = mu;
    
    % out.F = F;
    
end


