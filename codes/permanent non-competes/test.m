pm = set_modelpar();
pa = set_algopar();
ig = set_init_guesses_global(pa,pm); 

pa.HJB_V_tol;

tic 
V_out = solve_HJB_V(pa,pm,ig);
toc

v = VideoWriter('myFile.avi');
open(v);
for f = 1:length(V_out.F)
    writeVideo(v,V_out.F(f).cdata)
end
close(v);

%movie(f,V_out.F)
%mplay(f)

%{
subplot(2,2,1)
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.V)
title('V(q,m)')
subplot(2,2,2)
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.prof)
title('\pi(q,m)')
subplot(2,2,3)
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.zE)
title('z^E(q,m)')
subplot(2,2,4)
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.zI)
title('z^I(q,m)')
%}

