%% Clear results
clear;

%% Initialize

pm = set_modelpar();
pa = set_algopar(pm);
ig = set_init_guesses_global(pa,pm);

ig_V = set_init_guesses_V(pa,pm,ig);

%% Calculate

V_out = solve_HJB_V_1d(pa,pm,ig);

%% Plots

figure
subplot(4,1,1)
plot(pa.m_grid,ig_V.V0)
title('V^0(m)')

subplot(4,1,2)
plot(pa.m_grid,V_out.V)
title('V(m)')

subplot(4,1,3)
plot(pa.m_grid,V_out.zI)
title('z_I(m)')

tau = (pm.chi_S * ig.zS + pm.chi_E * ig.zE ) .* pm.eta(ig.zS + ig.zE);

%subplot(4,1,4)
%plot(pa.m_grid,tau)
%title('\tau(m)')

subplot(4,1,4)
plot(pa.m_grid, ig.zE, pa.m_grid, pa.m_grid .* ig.zS)
title('z_E(m),z_S(m)')


%% Make video

m = VideoWriter('V_video.avi');
open(m);
for f = 1:length(V_out.F)
    writeVideo(m,V_out.F(f).cdata)
end
close(m);

