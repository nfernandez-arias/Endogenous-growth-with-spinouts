pm = set_modelpar();
pa = set_algopar();
ig = set_init_guesses_global(pa,pm); 

pa.HJB_V_tol;

tic 
V_out = solve_HJB_V(pa,pm,ig);
toc
%% 
v = VideoWriter('myFile_V.avi');
open(v);
for f = 1:length(V_out.F)
    writeVideo(v,V_out.F(f).cdata)
end
close(v);

%%
tic
W_out = solve_HJB_W(pa,pm,ig,V_out.Vplus,V_out.zI);


w = VideoWriter('myFile_W.avi');
open(w);
for f = 1:length(W_out.F)
    writeVideo(w,W_out.F(f).cdata)
end
close(w);


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

