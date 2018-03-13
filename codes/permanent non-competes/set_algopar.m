function d = set_algopar()
    
    d.q_numpoints = 40;
    d.q_max = 1.5;
    d.q_min = 0;
    d.m_numpoints = 5;
    d.m_max = 1; 
    d.q_grid = linspace(d.q_min,d.q_max,d.q_numpoints);
    d.m_grid = linspace(0,d.m_max,d.m_numpoints);
    [d.q_grid_2d,d.m_grid_2d] = ndgrid(d.q_grid,d.m_grid);

    d.q_numpoints_FINE = 100;
    d.m_numpoints_FINE = 50;
    d.q_grid_FINE = linspace(0,d.q_max,d.q_numpoints_FINE);
    d.m_grid_FINE = linspace(0,d.m_max,d.m_numpoints_FINE);
    [d.q_grid_2d_FINE,d.m_grid_2d_FINE] = ndgrid(d.q_grid_FINE,d.m_grid_FINE);
    
    d.delta_t = 0.01;
    d.delta_m = 0.0001;
    d.delta_q = 0.0001;
    
    d.HJB_V_tol = 10e-6 * d.delta_t;
    d.HJB_W_tol = 10e-5 * d.delta_t;
    d.Lf_tol = 10e-5;
    d.g_tol = 10e-5;
    d.wF_tol = 10e-5;
    d.M_tol = 10e-5; 
    d.x_tol = 10e-5;

end
