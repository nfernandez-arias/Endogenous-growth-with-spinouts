function d = set_init_guesses_global(pa,pm)

    d.Lf0 =  0.1;
    d.g0 = 0.01;
    d.w0 = pm.wbar*ones(size(pa.q_grid_2d));
    d.M0 = 0*ones(size(pa.q_grid_2d));
    d.x0 = zeros(size(pa.q_grid_2d));

    
end