function out = compute_L(pa,pm,ig,V_out,W_out,stat_dist)

    L_I = ((1-pm.beta) / (ig.w0)) * ig.Lf0;
    
    mu = gridded_interpolant(pa.q_grid_2d,pa.m_grid_2d,stat_dist)
    tau = gridded_interpolant(pa.q_grid_2d,pa.m_grid_2d,W_out.tau);
    
    fun = tau * stat_dist;
    
    L_RD = integral2(fun,pa.q_min,pa.q_max,pa.m_min,pa.m_max);

    out.L = ig.Lf0 + L_I + L_RD;
end