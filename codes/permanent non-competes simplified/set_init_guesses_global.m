function d = set_init_guesses_global(pa,pm)

    d.L_RD =  0.1;
    d.w = 0.1*pm.wbar*ones(size(pa.m_grid));
    d.prof = pm.prof_func(pm.LF_func(d.L_RD));
    d.zS = min(pm.xi * pa.m_grid,1.3);
    %d.zS = zeros(size(pa.m_grid));
    d.zbar = 0.5;
    d.zE = max(0,d.zbar - d.zS);
    
    d.L_RD_maxcount = 1;
    d.w_maxcount = 1;
    d.zS_maxcount = 20;
    d.zbar_maxcount = 1;
    
end


