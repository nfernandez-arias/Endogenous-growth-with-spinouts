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
%{
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

%}
% Plot 2
figure
m = solve_model_out.aggregation_out.m;
a_SE = solve_model_out.aggregation_out.a_SE;
tau_SE = solve_model_out.aggregation_out.tau_SE;

subplot(4,1,1)
plot(pa.m_grid,V_out.V)
title('V(m)')
legend('V(m)')

subplot(4,1,2)
plot(pa.m_grid,a_SE)
title('\nu a^{SE}(m)')
legend('\nu a^{SE}(m)')

subplot(4,1,3)
plot(pa.m_grid,tau_SE)
title('\tau^{SE}(m)')
legend('\tau^{SE}(m)')

subplot(4,1,4)
plot(pa.m_grid,pm.chi_I * V_out.zI .* pm.phi(V_out.zI))
title('\tau^I(m)')
legend('\tau^I(m)')

figure

subplot(2,1,1)
plot(pa.m_grid,V_out.V);
title('V(m)')
legend('V(m)')

subplot(2,1,2)
plot(pa.m_grid,V_out.zI);
title('z_I(m)')
legend('z_I(m)')

figure

subplot(2,1,1)
plot(pa.m_grid,ig.zS)
title('z_S(m)')
legend('z_S(m)')

subplot(2,1,2)
plot(pa.m_grid,ig.zE)
title('z_E(m)')
legend('z_E(m)')

