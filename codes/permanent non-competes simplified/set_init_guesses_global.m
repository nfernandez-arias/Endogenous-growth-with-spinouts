function d = set_init_guesses_global(pa,pm)

    d.L_RD =  0.1;
    d.w = 0.5*pm.wbar*ones(size(pa.m_grid));
    d.zE = pm.xi * pa.m_grid;

    d.L_RD_maxcount = 1;
    d.w_maxcount = 1;
    d.zE_maxcount = 20;
    
end


