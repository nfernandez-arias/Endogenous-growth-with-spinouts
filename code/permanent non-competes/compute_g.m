function out = compute_g(pa,pm,ig,V_out,W_out,stat_dist)

    % Distribution function
    mu_fun = stat_dist;
    
    % Policy function
    %zI = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V_out.zI);
    %y = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V_out.y); %non-compete policy: y = 1 if non-compete is used
    %zE = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V_out.zE);
    tau_fun = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,W_out.tau);
    
    % Integration to compute equilibrium rate of growth, g

    fun = @(q,m) pm.lambda * q * tau_fun(q,m) * mu_fun(q,m);
    out = integral2(fun,pa.q_min,pa.q_max,pa.m_min,pa.m_max);
     
end
