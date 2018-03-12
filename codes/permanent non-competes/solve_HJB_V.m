function out = solve_HJB_V(pa,pm,ig)

    d = set_init_guesses_V(pa,pm,ig);
    
    prof = d.prof;
    V0 = d.V0;
    
    zE = pm.xi * min(pa.m_grid_2d,ig.M0);
    x0 = ig.x0;
    
    zmax = ones(size(V0));
    ymax = ones(size(V0));
    
    HJB_d = 1;
    count = 1;
    
    V1 = ones(size(V0));
    Vq = ones(size(V0));
    Vm = ones(size(V0));
    
    while ((count <= d.maxcount))
        
        V0_interp = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V0);
        Vplus = V0_interp((1+pm.lambda) * pa.q_grid_2d, zeros(size(pa.m_grid_2d)));
        
        
        for i_q = 1:length(pa.q_grid)
            for i_m = 1:length(pa.m_grid)
                
                q = pa.q_grid_2d(i_q,i_m);
                m = pa.m_grid_2d(i_q,i_m);
                
                Vq(i_q,i_m) = (pa.delta_q)^(-1) * (-1) * (V0_interp(q - pa.delta_q,m) - V0(i_q,i_m));
                Vm(i_q,i_m) = (pa.delta_m)^(-1) * (V0_interp(q,m+pa.delta_m) - V0(i_q,i_m));
                
                rhs1 = @(z) -(-pm.wbar * z + pm.chi_I*z*phi(z + zE(i_q,i_m))*(Vplus(i_q,i_m) ...
                                    - V0(i_q,i_m)) + pm.chi_E*zE(i_q,i_m)*phi(z+zE(i_q,i_m))*(-V0(i_q,i_m)));
                
                rhs0 = @(z) -(-ig.w0(i_q,i_m) * z + pm.nu * Vm(i_q,i_m) * z + pm.chi_I * z * phi(z + zE(i_q,i_m)) * (Vplus(i_q,i_m) - V0(i_q,i_m)) ...
                                                + pm.chi_E*zE(i_q,i_m)*phi(z + zE(i_q,i_m))*(-V0(i_q,i_m)));
    
                [z1,fval1] = fminbnd(rhs1,0.01,10);
                [z0,fval0] = fminbnd(rhs0,0.01,10);
                                    
                if fval1 > fval0
                    ymax(i_q,i_m) = 1;
                    zmax(i_q,i_m) = z1;
                    
                    V1(i_q,i_m) = ( V0(i_q,i_m) ...
                                    + pa.delta_t*(-rhs1(zmax(i_q,i_m)) + prof(i_q,i_m) - ig.g0*q*Vq(i_q,i_m) ...
                                    + pm.nu*zE(i_q,i_m) * Vm(i_q,i_m) - (pm.rho -ig.g0) * V0(i_q,i_m)));
                else 
                    
                    ymax(i_q,i_m) = 0;
                    zmax(i_q,i_m) = z0;
                    
                    V1(i_q,i_m) = ( V0(i_q,i_m) ...
                                    + pa.delta_t*(-rhs0(zmax(i_q,i_m)) + prof(i_q,i_m) - ig.g0*q*Vq(i_q,i_m) ...
                                    + pm.nu*zE(i_q,i_m) * Vm(i_q,i_m) - (pm.rho -ig.g0) * V0(i_q,i_m)));
                
                end
            end    
        end
        
        HJB_d = sumsqr(V1-V0);
        
        count 
        HJB_d
        
        
        V0 = V1;
        
        count = count + 1;
        
    end
    
    V1_interp = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V1);
    Vplus = V1_interp((1+pm.lambda) * pa.q_grid_2d, zeros(size(pa.m_grid_2d)));
    
    out.Vm = Vm;
    out.V = V0;
    out.Vplus = Vplus;
    out.zI = zmax;
    out.count = count;
    out.y = ymax;
    out.d = HJB_d;
    
end