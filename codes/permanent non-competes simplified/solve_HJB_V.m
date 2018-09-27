function out = solve_HJB_V(pa,pm,ig)

    d = set_init_guesses_V(pa,pm,ig);
    
    prof = d.prof;
    V0 = d.V0;
    zS = ig.zS0;
    phi = pm.phi;
    scaleFactor = pm.scaleFactor;
    %zS = pm.xi * min(pa.m_grid_2d,ig.M0);
    %x0 = ig.x0;
    
    %zmax = zeros(size(V0));
    %ymax = ones(size(V0));
    
    Imax_q = length(pa.q_grid);
    Imax_m = length(pa.m_grid);
	totalLength = Imax_q * Imax_m;
	zmax = zeros(1,totalLength);
	ymax = ones(1,totalLength);
    
    %idx_m = @(j) mod(j,Imax_m);
    %idx_q = @(j) (j - idx_m(j)) / Imax_m + 1;
    
    idx_m = mod(1:totalLength,Imax_m) + Imax_m * (mod(1:totalLength,Imax_m) == 0);
    idx_q = ((1:totalLength) - idx_m) / Imax_m + ones(size(idx_m));
    
    idx = @(i_q,i_m) (i_q - 1) * Imax_m + i_m;

    %size(idx_m)
    %size(idx_q)
    %pause
    
    HJB_d = 1;
    count = 1;
    
    V1 = zeros(size(V0));
    Vq = ones(size(V0));
    Vm = ones(size(V0));
    
    % Movie parameter
    frame_freq = 1;
    F(1) = struct('cdata',[],'colormap',[]);
    
    while ((HJB_d > pa.HJB_V_tol) && (count <= d.maxcount))
    
		%pa.q_grid_2d 
		%pause 
        V0_interp = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V0);
        Vplus = V0_interp((1+pm.lambda) * pa.q_grid_2d, zeros(size(pa.m_grid_2d)));

        %Vq(1,:) = zeros(size(Vq(1,:)));
        
        
        
        z1_prev = 0.1;
        z0_prev = 0.1;
        
        tic
        parfor ii = 1:Imax_q*Imax_m
			
			i_q = idx_q(ii);
			i_m = idx_m(ii);
			
			q = pa.q_grid_2d(i_q,i_m);
			m = pa.m_grid_2d(i_q,i_m);
			
			Vq = (pa.d_q)^(-1) * (-1) * (V0_interp(q - pa.d_q,m) - V0(i_q,i_m));
			Vm = (pa.d_m)^(-1) * (V0_interp(q,m+pa.d_m) - V0(i_q,i_m));
			
			rhs1 = @(z) -(-pm.wbar * z + pm.chi_I*z*phi(z + zS(i_q,i_m)) * scaleFactor(q) *(Vplus(i_q,i_m) ...
                                    - V0(i_q,i_m)) + pm.chi_E*zS(i_q,i_m)*phi(z+zS(i_q,i_m))* scaleFactor(q) * (-V0(i_q,i_m)));
               
			rhs0 = @(z) -(-ig.w0(i_q,i_m) * z + pm.nu * Vm * z + pm.chi_I * z * phi(z + zS(i_q,i_m)) * scaleFactor(q) * (Vplus(i_q,i_m) - V0(i_q,i_m)) ...
                                                + pm.chi_E*zS(i_q,i_m)*phi(z + zS(i_q,i_m))* scaleFactor(q) * (-V0(i_q,i_m)));
			
			[z1,fval1] = fminbnd(rhs1,0,30);
			[z0,fval0] = fminbnd(rhs0,0,30);
			
			%[z1, fval1] = fminsearch(rhs1,z1_prev);
			%[z0, fval0] = fminsearch(rhs0,z0_prev);
			
			
			if fval1 > fval0 
				ymax(ii) = 1;
				zmax(ii) = z1;
				
				%V1(i_q,i_m) = ( V0(i_q,i_m) ...
				%                + pa.delta_t_V*(-rhs1(zmax(i_q,i_m)) + prof(i_q,i_m) - ig.g0*q*Vq(i_q,i_m) ...
				%                + pm.nu*zS(i_q,i_m) * Vm(i_q,i_m) - (pm.rho -ig.g0) * V0(i_q,i_m)));
			else 
				
				ymax(ii) = 0;
				zmax(ii) = z0;
				
				%V1(i_q,i_m) = ( V0(i_q,i_m) ...
				%                + pa.delta_t_V*(-rhs0(zmax(i_q,i_m)) + prof(i_q,i_m) - ig.g0*q*Vq(i_q,i_m) ...
				%                + pm.nu*zS(i_q,i_m) * Vm(i_q,i_m) - (pm.rho -ig.g0) * V0(i_q,i_m)));
			
			end
			
			
        end
        
        ymax = reshape(ymax,Imax_m,Imax_q)';
        zmax = reshape(zmax,Imax_m,Imax_q)';
        
        zmax(1,:) = zeros(size(zmax(1,:)));
        
        toc
        %pause
       
        %}
        
        %{
        tic
        for i_q = 2:length(pa.q_grid)
            for i_m = 1:length(pa.m_grid)
                
                q = pa.q_grid_2d(i_q,i_m);
                m = pa.m_grid_2d(i_q,i_m);
                
                %Vq(i_q,i_m) = (pa.Delta_q(i_q,i_m))^(-1) * (-1) * (V0(i_q - 1,i_m) - V0(i_q, i_m));
                %Vm(i_q,i_m) = (pa.delta-
                
                Vq(i_q,i_m) = (pa.d_q)^(-1) * (-1) * (V0_interp(q - pa.d_q,m) - V0(i_q,i_m));
                Vm(i_q,i_m) = (pa.d_m)^(-1) * (V0_interp(q,m+pa.d_m) - V0(i_q,i_m));
                
                rhs1 = @(z) -(-pm.wbar * z + pm.chi_I*z*phi(z + zS(i_q,i_m)) * scaleFactor(q) *(Vplus(i_q,i_m) ...
                                    - V0(i_q,i_m)) + pm.chi_E*zS(i_q,i_m)*phi(z+zS(i_q,i_m))* scaleFactor(q) * (-V0(i_q,i_m)));
                
                rhs0 = @(z) -(-ig.w0(i_q,i_m) * z + pm.nu * Vm(i_q,i_m) * z + pm.chi_I * z * phi(z + zS(i_q,i_m)) * scaleFactor(q) * (Vplus(i_q,i_m) - V0(i_q,i_m)) ...
                                                + pm.chi_E*zS(i_q,i_m)*phi(z + zS(i_q,i_m))* scaleFactor(q) * (-V0(i_q,i_m)));
    
                [z1,fval1] = fminbnd(rhs1,0,10);
                [z0,fval0] = fminbnd(rhs0,0,10);
                                    
                if fval1 > fval0
                    ymax(i_q,i_m) = 1;
                    zmax(i_q,i_m) = z1;
                    
                    %V1(i_q,i_m) = ( V0(i_q,i_m) ...
                    %                + pa.delta_t_V*(-rhs1(zmax(i_q,i_m)) + prof(i_q,i_m) - ig.g0*q*Vq(i_q,i_m) ...
                    %                + pm.nu*zS(i_q,i_m) * Vm(i_q,i_m) - (pm.rho -ig.g0) * V0(i_q,i_m)));
                else 
                    
                    ymax(i_q,i_m) = 0;
                    zmax(i_q,i_m) = z0;
                    
                    %V1(i_q,i_m) = ( V0(i_q,i_m) ...
                    %                + pa.delta_t_V*(-rhs0(zmax(i_q,i_m)) + prof(i_q,i_m) - ig.g0*q*Vq(i_q,i_m) ...
                    %                + pm.nu*zS(i_q,i_m) * Vm(i_q,i_m) - (pm.rho -ig.g0) * V0(i_q,i_m)));
                
                end
            end
        end
        toc
        pause
        %}
       
        
        % Construct matrices for computation of next step in implicit method
        %tic
        Amat = makeA_V(pa,pm,ig,zmax,ymax);
        %toc
        %pause
        %max(max(isnan(Amat)))
        %pause
        V0prime = V0';
        
        %figure
        %spy(Bmat)
        %pause
        
        
        % Compute flow payoff for computing update step 
        % Remember - conditioning on whether a non-compete is used!
        flowvec = prof - (1-ymax) .* zmax.*ig.w0 - ymax .* zmax .* pm.wbar;
        
        for i_m = 1:Imax_m
        
			i_q = 1;
			
			%% Here, "dirty fix" to make sure V(0,m) = 0 for all m at every iteration:
			
			Amat(idx(i_q,i_m),idx(i_q,i_m)) = 1 - (pa.delta_t_V^(-1) + pm.rho);
			Amat(idx(i_q,i_m),[1:idx(i_q,i_m)-1 idx(i_q,i_m)+1:Imax_m*Imax_q]) = zeros(size([1:idx(i_q,i_m)-1 idx(i_q,i_m)+1:Imax_m*Imax_q]));
			
			% The issue was coming from the fact that zmax was positive, making flowvec negative in the first iteration. So
			% just hardcode flowvec(i_q,:) = 0. 
			
			flowvec(i_q,i_m) = 0;
        
			for i_q = Imax_q-(pa.q_m-1):Imax_q
			
				flowvec(i_q,i_m) = flowvec(i_q,i_m) + pm.chi_I * zmax(i_q,i_m) * pm.phi(zmax(i_q,i_m) + ig.zS0(i_q,i_m)) * pm.scaleFactor(pa.q_grid(i_q)) * (Vplus(i_q,i_m) - V0(i_q,i_m));
				
			end
		end
		
		Bmat = (pa.delta_t_V^(-1) + (pm.rho - ig.g0)) * eye(size(Amat)) - Amat;
        
        
        flowvec = flowvec';
        flowvec = flowvec(:); 
        
        % Define RHS of equation to be solved
        bvec = flowvec + pa.delta_t_V^(-1) * V0prime(:);
        
        %{
        tic
        V1 = reshape(Bmat \ bvec,length(pa.m_grid),length(pa.q_grid))';
		toc
		pause
		%}
        
        % Implicit update step:
        
		%tic
        Bmat = sparse(Bmat);
        bvec = sparse(bvec);

        V1 = full(reshape(Bmat \ bvec,length(pa.m_grid),length(pa.q_grid))');
        %toc 
        %pause
        

        
        HJB_d = sqrt(sumsqr(V1-V0));
        

        HJB_d / pa.delta_t_V
        
        
        V0 = V1;
        
           
        % Make plots for movie
        %{
        if mod(count,frame_freq) == 0
			f = figure('visible','off');
            surf(pa.q_grid_2d,pa.m_grid_2d,V0)
            title('V(q,m)')
            xlabel('q')
            ylabel('m')
            zlim([0,1.5*max(max(d.V0))])
            drawnow
            F(count/frame_freq) = getframe(f);
        end
        %}
        count
        count = count + 1;
        
        
    end
    
    V1_interp = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V1);
    Vplus = V1_interp((1+pm.lambda) * pa.q_grid_2d, zeros(size(pa.m_grid_2d)));
    
    out.Vm = Vm;
    out.V = V0;
    out.V1 = V1;
    out.prof = prof;
    out.Vplus = Vplus;
    out.zI = zmax;
    out.zS = zS;
    out.zbar = pm.eta_inv(pm.wbar / (pm.chi_E * V0(1)));
    out.count = count;
    out.y = ymax;
    out.d = HJB_d;
    out.F = F;
    out.Amat = Amat;
    out.Bmat = Bmat;
    out.bvec = bvec;
    out.flowvec = flowvec;
    
  
    
    
    
    
    
end
