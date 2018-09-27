function out = solve_model(pa,pm,ig)

    L_RD_d = 1;
    w_d = 1;
    zS_d = 1;
    zbar_d = 1;
    HJB_d = 1; 
    
    ng.L_RD = ig.L_RD; 
    ng.w = ig.w;
    ng.zS = ig.zS;
    ng.zE = ig.zE;
    
    frame_freq = 1;
    F(1) = struct('cdata',[],'colormap',[]);
    f = figure('visible','off');
    
    L_RD_count = 1;
    
    L_RD_vec1 = zeros(1,ig.L_RD_maxcount);
    L_RD_vec2 = zeros(1,ig.L_RD_maxcount);
    
    while ((L_RD_d > pa.L_RD_tol) && (L_RD_count <= ig.L_RD_maxcount))
    
		% Closed form for production wage and static profit - depends on guess L_RD
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		%% NEED TO ADD THIS %%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%
		wbar = ones(size(pa.m_grid));
		prof = ones(size(pa.m_grid));
		
		w_count = 1;
		
		J(1) = struct('cdata',[],'colormap',[]);
		j = figure('visible','off');
		
		while ((w_d > pa.w_tol) && (w_count <= ig.w_maxcount))
		
			if mod(w_count,frame_freq) == 0
				j = figure('visible','off');
				plot(pa.m_grid,ng.w)
				title('w(m)')
				ylim([0,1.5*pm.wbar])
				drawnow
				J(w_count/frame_freq) = getframe(j);
			end
		
			% Now have wage guess
			% Next, we solve the game played between entrants and incumbents, 
			% taking flow profits and wages as given.
			
			% We iterate on spinout R&D effort zS and entrant R&D free entry threshold zbar
			
			z_count = 1;
			
			frame_freq = 1;
			F(1) = struct('cdata',[],'colormap',[]);
			f = figure('visible','off');
			H(1) = struct('cdata',[],'colormap',[]);
			h = figure('visible','off');
				
			while (((zS_d > pa.zS_tol) && (z_count <= ig.zS_maxcount)) || ((zbar_d > pa.zS_tol) && (z_count <= ig.zS_maxcount)))
			
				V_out = solve_HJB_V_1d(pa,pm,ng);
				
				% Consistency 
				% Construct zE1, zS1 given V_out.V, R&D wages using free entry
				zE1 = ng.zE .* (pm.chi_E * pm.eta(ng.zE + ng.zS) * V_out.V(1)) ./ ng.w;
				zS1 = min(pm.xi * pa.m_grid, ng.zS .* (pm.chi_S * pm.eta(ng.zE + ng.zS) * V_out.V(1))) ./ ng.w;
				
				zE_d = sqrt(sumsqr(zE1 - ng.zE));
				zS_d = sqrt(sumsqr(zS1 - ng.zS));
				
				ng.zE = pa.zE_UR * zE1 + (1- pa.zE_UR) * ng.zE;
				ng.zS = pa.zS_UR * zS1 + (1- pa.zS_UR) * ng.zS;
				
				% Make movies 
				if mod(z_count,frame_freq) == 0
					f = figure('visible','off');
					plot(pa.m_grid,ng.zE)
					title('z_E(m)')
					ylim([0,2])
					drawnow
					F(z_count/frame_freq) = getframe(f);
				end
        
				if mod(z_count,frame_freq) == 0
					f = figure('visible','off');
					plot(pa.m_grid,ng.zS)
					title('z_S(m)')
					ylim([0,2])
					drawnow
					H(z_count/frame_freq) = getframe(f);
				end
				
				if mod(z_count,frame_freq) == 0
					f = figure('visible','off');
					plot(pa.m_grid,(ng.zS * pm.chi_S + ng.zE * pm.chi_E) .* pm.eta(ng.zS + ng.zE))
					title('\tau_{SE}(m)')
					ylim([0,2])
					drawnow
					G(z_count/frame_freq) = getframe(f);
				end				
				
				z_count = z_count + 1;
				
			end
				
			% Now compute W directly from HJB, using 
			% boundary condition W'(m_max) = 0 and z = xi
			% NEED TO CODE THIS PART STILL 
			
			W_out = solve_HJB_W_easy(pa,pm,ng,V_out);
			
			% Consistency
			w1 = pm.wbar - pm.nu * W_out.W;
			
			w_d = sqrt(sumsqr(w1 - ng.w));
			
			ng.w = pa.w_UR * w1 + (1- pa.w_UR) * ng.w;
			
			w_count = w_count + 1;
			
		end
		
		%%% Compute mu, gamma, g, L_RD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		
		aggregation_out = aggregation(pa,pm,ng,V_out,W_out);
		
		L_RD1 = aggregation_out.L_RD;
		
		L_RD_d = abs(L_RD1 - ng.L_RD);
		
		ng.L_RD = pa.L_RD_UR * L_RD1 + (1 - pa.L_RD_UR) * ng.L_RD; 
		
		L_RD_vec1(L_RD_count) = ng.L_RD;
		L_RD_vec2(L_RD_count) = L_RD1;
		
		L_RD_count = L_RD_count + 1;
		
		L_RD_d
		L_RD_count
		%pause
	
		
	end	
           
    out.V_out = V_out;
    out.W_out = W_out;
    out.agg_eq = ng;
    out.aggregation_out = aggregation_out;
    out.F = F;
    out.H = H;
    out.G = G;
    out.V_out = V_out;
    out.ng = ng;
    out.L_RD_vec1 = L_RD_vec1;
    out.L_RD_vec2 = L_RD_vec2;
end


