%%
clear
pm = set_modelpar();
pa = set_algopar(pm);
ig = set_init_guesses_global(pa,pm); 

ng.Lf0 = ig.Lf0;
ng.g0 = ig.g0;
ng.zE0 = ig.zE0;
ng.w0 = ig.w0;


%%

frame_freq = 1;
F(1) = struct('cdata',[],'colormap',[]);
zE0_count = 1;


zE0_d = 1;

while ((zE0_d > pa.zE_tol) && (zE0_count <= ig.zE_maxcount))

    V_out = solve_HJB_V(pa,pm,ng);
    
    %{
    figure
    surf(pa.q_grid_2d,pa.m_grid_2d,V_out.V)
    title('V(q,m)')
    xlabel('q')
    ylabel('m')
    zlim([0,1.5 * max(max(V_out.V))])
    drawnow
    pause
    %}
    
    W_out = solve_HJB_W(pa,pm,ng,V_out);
    
    %{
    figure
    surf(pa.q_grid_2d,pa.m_grid_2d,W_out.W)
    title('W(q,m)')
    xlabel('q')
    ylabel('m')
    zlim([-10,0.00001 + 1.5 * max(max(W_out.W))])
    drawnow
    pause
    %}

    % Next, check that M(q,m) is consistent with entrant optimality
    % If not, change guess for M(q,m) to M1, calculate zE0_d, and 
    % reset zE0 = M1 

    

    zE0_d = sqrt(sumsqr(W_out.zE1 - ng.zE0))
	
	UR = W_out.UR;
	UR = ones(size(W_out.UR));
	
	% adaptive smoothing coeffficient
	ng.zE0 = UR .* pa.zE0_UR .* W_out.zE1 + (1-UR .* pa.zE0_UR) .* ng.zE0;
	
    % update, with smoothing coefficient
    %ng.zE0 = pa.zE0_UR .* W_out.zE1 + (1 - pa.zE0_UR) .* ng.zE0;

    ng.V = V_out.V;
    ng.W = W_out.W;

    zEds(zE0_count) = zE0_d;
	
    if mod(zE0_count,frame_freq) == 0
		f = figure('visible','off');
        surf(pa.q_grid_2d,pa.m_grid_2d,ng.zE0)
        title('zE(q,m)')
        xlabel('q')
        ylabel('m')
        zlim([0,3])
        drawnow
        F(zE0_count/frame_freq) = getframe(f);
        %size(F(count/frame_freq).cdata)
    end
    
    
    zE0_count = zE0_count + 1
end 

%% 

m = VideoWriter('myFile_zE.avi');
open(m);
for f = 1:length(F)
    writeVideo(m,F(f).cdata)
end
close(m);

%% Marginal benefit from innovation for entrants

f = figure
surf(pa.q_grid_2d,pa.m_grid_2d,pm.chi_E * phi(W_out.tau) .* (V_out.Vplus - W_out.W) - ig.w0)
title('Marginal benefit of innovation effort for entrants')
xlabel('q')
ylabel('m')
zlim([-1,.5*max(max(V_out.Vplus - W_out.W))])
drawnow

%% zE1

f = figure
surf(pa.q_grid_2d,pa.m_grid_2d,W_out.zE1)
title('zE1(q,m)')
xlabel('q')
ylabel('m')
zlim([-1,3])
drawnow


%% Vplus
f = figure
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.Vplus)
title('V^+(q,m)')
xlabel('q')
ylabel('m')
zlim([0,1.5 * max(max(V_out.V))])
drawnow

%% zI
f = figure
surf(pa.q_grid_2d,pa.m_grid_2d,V_out.zI)
title('z^I(q,m)')
xlabel('q')
ylabel('m')
zlim([0,3])
drawnow

