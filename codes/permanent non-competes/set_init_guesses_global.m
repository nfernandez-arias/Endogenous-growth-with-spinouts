function d = set_init_guesses_global(pa,pm)

    d.Lf0 =  0.1;
    d.g0 = 0.01;
    d.w0 = 0.5*pm.wbar*ones(size(pa.q_grid_2d));
    %d.zE0 = 0.5*ones(size(pa.q_grid_2d));
    %d.zE0 = min(pa.q_grid_2d,pm.xi * (pa.m_grid_2d));
    d.zE0 = pm.xi * pa.m_grid_2d;
    %d.M0 = ones(size(pa.q_grid_2d));
    %d.x0 = zeros(size(pa.q_grid_2d));

    d.Lf_maxcount = 1;
    d.g_maxcount = 1;
    d.w_maxcount = 1;
    d.zE_maxcount = 60;
    
end
