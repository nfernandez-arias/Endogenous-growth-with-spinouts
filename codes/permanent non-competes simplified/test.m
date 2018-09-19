%% Clear results
clear;

%% Initialize

pm = set_modelpar();
pa = set_algopar(pm);
ig = set_init_guesses_global(pa,pm);

%ig_V = set_init_guesses_V(pa,pm,ig);

%% Solve model
tic
solve_model_out = solve_model2(pa,pm,ig);
toc
%% Make videos
m = VideoWriter('zE_video.avi');
open(m);
for f = 1:length(solve_model_out.F)
    writeVideo(m,solve_model_out.F(f).cdata)
end
close(m);

m = VideoWriter('zS_video.avi');
open(m);
for f = 1:length(solve_model_out.H)
    writeVideo(m,solve_model_out.H(f).cdata)
end
close(m);

m = VideoWriter('tau_SE_video.avi');
open(m);
for f = 1:length(solve_model_out.G)
    writeVideo(m,solve_model_out.G(f).cdata)
end
close(m);

m = VideoWriter('w_video.avi');
open(m);
for f = 1:length(solve_model_out.J)
    writeVideo(m,solve_model_out.J(f).cdata)
end
close(m);

% Make V videos

V_out = solve_model_out.V_out;

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

%% Plots

muhat = solve_model_out.aggregation_out.muhat;
gammahat = solve_model_out.aggregation_out.gammahat;
tauhat = solve_model_out.aggregation_out.tauhat;

tgrid = linspace(0,pa.t_max,pa.t_numpoints);

figure

subplot(3,1,1)
plot(tgrid,muhat)
title('\mu(s)')
legend('\mu(s)')

subplot(3,1,2)
plot(tgrid,gammahat)
title('\gamma(s)')
legend('\gamma(s)')

subplot(3,1,3)
plot(tgrid,tauhat)
title('\tau(s)')
legend('\tau(s)')


% Plot 2
figure
m = solve_model_out.aggregation_out.m;
a = solve_model_out.aggregation_out.a;
tau = solve_model_out.aggregation_out.tau;

subplot(3,1,1)
plot(tgrid,m)
title('m(s)')
legend('m(s)')

subplot(3,1,2)
plot(pa.m_grid,a)
title('a(m)')
legend('a(m)')

subplot(3,1,3)
plot(pa.m_grid,tau)
title('\tau(m)')
legend('\tau(m)')

figure

subplot(3,1,1)
plot(pa.m_grid,V_out.V);
title('V(m)')
legend('V(m)')

subplot(3,1,2)
plot(pa.m_grid,V_out.zI);
title('z_I(m)')
legend('z_I(m)')

W_out = solve_model_out.W_out;
subplot(3,1,3)
plot(pa.m_grid,W_out.W);
title('W(m)')
legend('W(m)')





%% Plots

figure
subplot(5,1,1)
plot(pa.m_grid,ig_V.V0)
title('V^0(m)')

subplot(5,1,2)
plot(pa.m_grid,V_out.V)
ccccylim([0,inf]);
subplot(5,1,3)
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




