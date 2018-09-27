function out = solve_HJB_V_1d(pa,pm,ig)

	%%%%%%%%%%%%%%%%%%%%%%%%%
	%% Data and guesses %%%%%
	%%%%%%%%%%%%%%%%%%%%%%%%%
		
	% idx_M records the index of the threshold value m, such that for m' > m, zE = 0 and spinouts are at free entry condition.
	idx_M = ig.idx_M;
	
	ig_V = set_init_guesses_V(pa,pm,ig);

	% Profits, determined by initil L_RD guess.
    prof = ig_V.prof;
    V0 = ig_V.V0';
    V_0 = ig_V.V_0;
    zmax = ig_V.zmax;
    zI_0 = ones(size(prof));
    
    % Initial spinout R&D guess
    zS = ig.zS;
    
    % Initial entrant R&D guess
    %zbar = ig.zbar;
    zE = ig.zE;
    
    % Total spinout + entrant R&D victory arrival rate
    tau = (pm.chi_S .* zS  + pm.chi_E .* zE ) .* pm.eta(zS + zE);
    
    % Convenience
    phi = pm.phi;
    Imax = pa.m_numpoints;
    
    % Plotting for tests
    frame_freq = 1;
    F(1) = struct('cdata',[],'colormap',[]);
    f = figure('visible','off');
	H(1) = struct('cdata',[],'colormap',[]);
    h = figure('visible','off');
    
    %% Solving HJB
    
    V_0_d = 1;
    V_0_count = 1;
    V_0_vec = zeros(1,1);
    
    %while ((V_0_d > pa.V_0_tol) && (V_0_count <= ig_V.V_0_maxcount))
    
	%	V_0_vec(V_0_count) = V_0;
    
		HJB_d = 1;
		count = 1;
		
		while ((HJB_d > pa.HJB_V_tol) && (count <= ig_V.V_maxcount))
		
			%% DEPRECATED CODE %%
			
			%% Compute z_i^{I,n} 
			
			% First, for i = Imax, use V'(m_i) = 0.
			
			%rhs = @(z) -z * (pm.chi_I * pm.phi(z) * (pm.lambda * V0(1) - V0(Imax)) - ig.w(Imax));
			
			%[z fval] = fminbnd(rhs,0,zmax);
			
			%zI_0(Imax) = z;
			%fvalI_0(Imax) = fval;
			
			%zI_0(end) = pm.phi_inv(ig.w(end) ./ (pm.chi_I * (pm.lambda * V0(1) - V0(end))));
			
			%size(zI_0(idx_M:end))
			%size(pm.phi_inv(ig.w(idx_M:end) ./ (pm.chi_I * (pm.lambda * V0(1) * ones(size(ig.w(idx_M:end))) - V0(idx_M:end)))))
			%size(ig.w(idx_M:end))
			%size(V0(idx_M:end))
			%size((pm.lambda * V0(1) * ones(size(ig.w(idx_M:end))) - V0(idx_M:end)))
			%pause
			
			% For m > M, 
			
			zI_0(idx_M:end) = pm.phi_inv(ig.w(idx_M:end) ./ (pm.chi_I * (pm.lambda * V0(1) * ones(size(ig.w(idx_M:end))) - V0(idx_M:end)'))); 
			
			% Now calculate for i < Imax
		
			for i = 1:idx_M-1
			
				rhs = @(z) -z * (pm.chi_I * pm.phi(z) * (pm.lambda * V0(1) - V0(i)) - (ig.w(i) - pm.nu * (V0(i+1) - V0(i))/pa.Delta_m(i)));
				
				[z fval] = fminbnd(rhs,0,zmax);
				
				zI_0(i) = z;
				fvalI_0(i) = fval;
		
			end
			
			%% Now, make vectors and matrices and compute update of V
			uvec = prof - zI_0 .* ig.w;
			%uvec = prof - zI_0 .* ig.w + zI_0 .* pm.chi_I .* pm.phi(zI_0) .* pm.lambda * V_0;
			uvec = uvec';
			A = makeA_V(pa,pm,ig,zI_0);
			Bmat = (1/pa.delta_t_V + pm.rho) .* eye(Imax) - A;
			bvec = uvec + (1/pa.delta_t_V) .* V0;
			Bmat = sparse(Bmat);
			bvec = sparse(bvec);
			V1 = Bmat\bvec;
			
			% Compute distance
			HJB_d = sqrt(sumsqr(V1 - V0));
			
			% Display distance
			distance = HJB_d / pa.delta_t_V
			
			if mod(count,frame_freq) == 0
				f = figure('visible','off');
				plot(pa.m_grid,V0)
				title('V(m)')
				ylim([0,5*max(ig_V.V0)])
				drawnow
				F(count/frame_freq) = getframe(f);
			end
			
			if mod(count,frame_freq) == 0
				f = figure('visible','off');
				plot(pa.m_grid,zI_0)
				title('z_I(m)')
				ylim([0,pm.xi*pa.m_grid(end)])
				drawnow
				H(count/frame_freq) = getframe(f);
			end
			
			% Update V0
			V0 = V1;
			
			% Update count
			count = count + 1;
	   
		end 
		
	%	V_0_d = abs(V_0 - V0(1));
		
	%	V_0 = pa.V_0_UR * V0(1) + (1 - pa.V_0_UR) * V_0;
		
	%	V_0_count = V_0_count + 1;
%	end

    out.V = V0;
    out.zI = zI_0;
    %out.zbar = pm.eta_inv(pm.wbar / (pm.chi_E * V0(1)));
    out.count = count;
    out.F = F;
    out.H = H;
    out.V_0_vec = V_0_vec;
    
end
