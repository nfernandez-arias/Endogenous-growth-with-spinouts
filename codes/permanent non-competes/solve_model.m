function out = solve_model(pa,pm,ig)

    Lf_d = 1;
    g_d = 1;
    w_d = 1;
    zE0_d = 1;
    HJB_d = 1;
    
    ng.Lf0 = ig.Lf0;
    ng.g0 = ig.g0;
    ng.w0 = ig.w0;
    ng.zE0 = ig.zE0;
    
    
    frame_freq = 1;
    F(1) = struct('cdata',[],'colormap',[]);
    f = figure('visible','off');
    
    Lf_count = 1;
    
    while ((Lf_d > pa.Lf_tol) && (Lf_count <= ig.Lf_maxcount))
        
        g_count = 1;
        
        while ((g_d > pa.g_tol) && (g_count <= ig.g_maxcount))  
            
            w_count =1;
            
            while ((w_d > pa.wF_tol) && (w_count <= ig.w_maxcount))
                
                zE0_count = 1;
                
                while ((zE0_d > pa.zE0_tol) && (zE0_count <= ig.zE0_maxcount))

                    V_out = solve_HJB_V(pa,pm,ng);
                    W_out = solve_HJB_W(pa,pm,ng,V_out);

                    % Next, check that M(q,m) is consistent with entrant optimality
                    % If not, change guess for M(q,m) to M1, calculate M_d, and 
                    % reset M0 = M1 
                    
                    zE0_count = zE0_count + 1
                    
                    zE0_d = sqrt(sumsqr(W_out.zE0 - ng.zE0))
                    
                    % update, with smoothing coefficient
                    ng.zE0 = pa.zE0_UR .* W_out.zE0 + (1 - pa.zE0_UR) .* ng.zE0;
                    
                    ng.V = V_out.V;
            
                    zE0ds(zE0_count) = zE0_d;
                    
                    if mod(zE0_count,frame_freq) == 0
                        surf(pa.q_grid_2d,pa.m_grid_2d,ng.zE0)
                        title('M(q,m)')
                        xlabel('q')
                        ylabel('m')
                        zlim([0,3])
                        drawnow
                        F(M_count/frame_freq) = getframe(f);
                        %sizE0(F(count/frame_freq).cdata)
                    end
                    
                    

                end
                
                figure(gcf)
                plot(1:zE0_count,zE0ds)
                title('Evolution of zE0')
                xlabel('iteration')
                ylabel('zE0_d')
                
                pause

            % Next, check that w(q,m) = wbar- nu * W(q,m). If not, adjust 
            % guess for w to w1, calculate wF_d, and reset wF0 = wF1 
            
            w1 = pm.wbar - pm.nu .* W_out.W;
            
            w_count = w_count + 1
            
            w_d = sqrt(sumsqr(w1 - ng.w0))
            
            ng.w0 = pa.w0_UR .* w1 + (1 - pa.w0_UR) .* ng.w0;

            pause
            
            end

        % Next, check that g is compatible, etc. For this, need to
        % calculate the stationary distribution. 
        
        stat_dist = stationary_distribution(pa,pm,ng,V_out,W_out);
        
        g1 = compute_g(pa,pm,ng,V_out,W_out,stat_dist);
        
        g_count = g_count + 1
        
        g_d = sqrt(sumsqr(g1 - ng.g0))
        
        ng.g0 = pa.g0_UR * g1 + (1 - pa.g0_UR) * ng.g0;
        
        pause
        
        end

    % Finally, check that L_F is compatible, etc. For this, ned to 
    % calculate the total labor demanded by using the above-calculated
    % stationary distribution
    
    Ltot = compute_L(pa,pm,ng,V_out,W_out,stat_dist);
    Lf1 = ng.Lf0 * Ltot^(-1);
    
    Lf_count = Lf_count + 1
    
    Lf_d = sqrt(sumsqr(Lf1 - ng.Lf0))
        
    ng.Lf0 = pa.Lf0_UR * Lf1 + (1 - pa.Lf0_UR) * ng.Lf0;
    
    %[M_d; w_d; g_d; Lf_d]
    pause
    
    end
           
    out.V_out = V_out;
    out.W_out = W_out;
    out.agg_eq = ng;
    out.F = F;
    
end
