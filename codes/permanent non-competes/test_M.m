%%

pm = set_modelpar();
pa = set_algopar();
ig = set_init_guesses_global(pa,pm); 

ng.Lf0 = ig.Lf0;
ng.g0 = ig.g0;
ng.w0 = ig.w0;
ng.M0 = ig.M0;

%%

frame_freq = 1;
F(1) = struct('cdata',[],'colormap',[]);
M_count = 1;


M_d = 1;

while ((M_d > pa.M_tol) && (M_count <= ig.M_maxcount))

    V_out = solve_HJB_V(pa,pm,ng);
    W_out = solve_HJB_W(pa,pm,ng,V_out);

    % Next, check that M(q,m) is consistent with entrant optimality
    % If not, change guess for M(q,m) to M1, calculate M_d, and 
    % reset M0 = M1 

    

    M_d = sqrt(sumsqr(W_out.M - ng.M0))

    % update, with smoothing coefficient
    ng.M0 = pa.M0_UR .* W_out.M + (1 - pa.M0_UR) .* ng.M0;

    ng.V = V_out.V;

    Mds(M_count) = M_d;

    if mod(M_count,frame_freq) == 0
		f = figure('visible','off');
        surf(pa.q_grid_2d,pa.m_grid_2d,ng.M0)
        title('M(q,m)')
        xlabel('q')
        ylabel('m')
        zlim([0,3])
        drawnow
        F(M_count/frame_freq) = getframe(f);
        %size(F(count/frame_freq).cdata)
    end
    
    M_count = M_count + 1
end

%% 

m = VideoWriter('myFile_M.avi');
open(m);
for f = 1:length(F)
    writeVideo(m,F(f).cdata)
end
close(m);
