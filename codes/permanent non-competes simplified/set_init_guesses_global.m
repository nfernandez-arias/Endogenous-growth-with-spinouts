function d = set_init_guesses_global(pa,pm)

    d.L_RD =  0.1;
    d.mu(1) = 1;
    d.w = 1.2*pm.wbar*ones(size(pa.m_grid));
    d.prof = pm.prof_func(pm.LF_func(d.L_RD));
    d.idx_M = pa.m_numpoints;
    
    d.zS = pm.xi * pa.m_grid;
    d.zE = 0.1*ones(size(pa.m_grid));
    
    d.L_RD_maxcount = 1;
    d.w_maxcount = 1;
    d.zS_maxcount = 1;
    d.zE_maxcount = 1;
    %d.mu_maxcount = 1;
    
end


