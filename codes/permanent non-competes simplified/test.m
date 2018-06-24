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
subplot(5,1,1)
plot(pa.m_grid,ig_V.V0)
title('V^0(m)')

subplot(5,1,2)
plot(pa.m_grid,V_out.V)
ccccylim([0,inf]);ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc
subplot(5,1,3)cccc
plot(pa.m_grid,V_out.zI)
title('z_I(m)')
ylim([0,inf])

tau = (pm.chi_S * ig.zS  + pm.chi_E * ig.zE ) .* pm.eta(ig.zS + ig.zE);

subplot(5,1,4)
plot(pa.m_grid, ig.zE, pa.m_grid, ig.zS)
title('z_E(m),z_S(m)')
legend('z_E','z_S')

tau_I = pm.chi_I * V_out.zI .* pm.phi( V_out.zI);

subplot(5,1,5)
plot(pa.m_grid, tau, pa.m_grid, tau_I, pa.m_grid, ig.zS  + ig.zE)
title('Innovation effort and arrival rate')
legend('\tau(m)','\tau_I(m)','z_E(m) + z_S(m)')
ylim([0,inf])

%% Make video

m = VideoWriter('V_video.avi');
open(m);
for f = 1:length(V_out.F)
    writeVideo(m,V_out.F(f).cdata)
end
close(m);

m = VideoWriter('zI_video.avi');
open(m);
for f = 1:length(V_out.H)
    writeVideo(m,V_out.H(f).cdata)
end
close(m);

