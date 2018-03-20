function out = solve_HJB_W(pa,pm,ig,V_out)

    % bring into local namespace
    Vplus = V_out.Vplus;
    zI = V_out.zI;
    x0 = V_out.y; % non-compete policy by incumbents
	phi = pm.phi;
	scaleFactor = pm.scaleFactor;
	
	zE = ig.zE0;
	
	% DEPRECATED
    % translate M0 into guess about aggregate innovation effort by entrants
    %zE = pm.xi * min(pa.m_grid_2d,ig.M0);

    tau = zE + zI;
    %x0 = ig.x0;
    

    
    d = set_init_guesses_W(pa,pm,ig,Vplus,zI);
    
    W0 = d.W0; 
    
    HJB_d = 1;
    count = 1;
    
    W1 = zeros(size(W0));
    
    frame_freq = 10000;
    F(1) = struct('cdata',[],'colormap',[]);
    f = figure('visible','off');
    
    while ((HJB_d > pa.HJB_W_tol) && (count <= d.maxcount))
        
        W0_interp = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,W0);
        
        for i_q = 2:length(pa.q_grid)
            for i_m = 1:length(pa.m_grid)  
                
                q = pa.q_grid_2d(i_q,i_m);
                m = pa.m_grid_2d(i_q,i_m);
                
                Wq = pa.d_q^(-1) * (-1) * (W0_interp(q-pa.d_q,m) - W0(i_q,i_m));
                Wm = pa.delta_m^(-1) * (W0_interp(q,m+pa.delta_m) - W0(i_q,i_m));
                
                
                W1(i_q,i_m) = W0(i_q,i_m) + pa.delta_t_W * (-(pm.rho - ig.g0) * W0(i_q,i_m) - ig.g0*q*Wq + (x0(i_q,i_m)*zI(i_q,i_m)+zE(i_q,i_m)) * pm.nu * Wm    ...
                                                              +(pm.chi_I*zI(i_q,i_m) + pm.chi_E*zE(i_q,i_m)) * phi(tau(i_q,i_m)) * scaleFactor(q) * (-W0(i_q,i_m)) ...
                                                              + ( pm.chi_E * phi(tau(i_q,i_m)) * (Vplus(i_q,i_m) - W0(i_q,i_m)) > ig.w0(i_q,i_m)) ...
                                                                 * pm.xi * (pm.chi_E * phi(zI(i_q,i_m) + zE(i_q,i_m)) * scaleFactor(q) * (Vplus(i_q,i_m) - W0(i_q,i_m)) - ig.w0(i_q,i_m)));
                                
            end
        end
   
        HJB_d = sqrt(sumsqr(W1-W0))
        
        W0 = W1;
        
        
        if mod(count,frame_freq) == 0
            surf(pa.q_grid_2d,pa.m_grid_2d,W0)
            title('W(q,m)')
            zlabel('W(q,m)')
            xlabel('q')
            ylabel('m')
            zlim([0,5])
            drawnow
            set(gca,'Xdir','reverse','Ydir','reverse')
            F(round(count/frame_freq)) = getframe(f);
            %size(F(count/frame_freq).cdata)
        end
        
        count = count + 1
        
    end
    
    score = pm.chi_E * phi(tau) .* (Vplus - W0) - ig.w0;
    UR = abs(score ./ max(max(score))).^(1/pa.zE0_UR_exponent);
    
    
    % Compute implied aggregate policy
    zE1 = pm.xi * pa.m_grid_2d .* (pm.chi_E * phi(tau) .* scaleFactor(pa.q_grid_2d) .* (Vplus - W0) > ig.w0);
                    
    W = W0;
    
    out.W = W;
    out.count = count;
    out.zE0 = zE;
    out.zE1 = zE1;
    out.tau = tau;
    out.UR = UR;
    % out.M = (pm.chi_E * phi(tau) .* (Vplus - W0) > ig.w0);
    out.F = F;

end
