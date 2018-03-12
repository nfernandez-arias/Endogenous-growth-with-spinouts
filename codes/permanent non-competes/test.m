

pm = set_modelpar();
pa = set_algopar();
ig = set_init_guesses_global(pa,pm);


pa.HJB_V_tol;

tic 
V_out = solve_HJB_V(pa,pm,ig);
toc

%subplot(1,2,1)
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.V)

