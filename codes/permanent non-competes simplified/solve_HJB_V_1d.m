function out = solve_HJB_V_1d(pa,pm,ig)

	%%%%%%%%%%%%%%%%
	%% Guesses %%%%%
	%%%%%%%%%%%%%%%%
	
	ig_V = set_init_guesses_V(pa,pm,ig);

	% Profits, determined by initil L_RD guess.
    prof = ig_V.prof;
    V0 = ig_V.V0';
    zmax = ig_V.zmax;
    
    % Initial spinout R&D guess
    zS = ig.zS;
    
    % Initial entrant R&D guess
    zbar = ig.zbar;
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
    
    %% Solving HJB
    
    HJB_d = 1;
    count = 1;
    
    while ((HJB_d > pa.HJB_V_tol) && (count <= ig_V.maxcount))
    
		%% Compute z_i^{I,n} 
		
		% First, for i = Imax, use V'(m_i) = 0.
		
		rhs = @(z) -z * (pm.chi_I * pm.phi(z) * (pm.lambda * V0(1) - V0(Imax)) - ig.w(Imax));
		
		[z fval] = fminbnd(rhs,0,zmax);
		
		zI_0(Imax) = z;
		fvalI_0(Imax) = fval;
		
		% Now calculate for i < Imax
	
		for i = 1:Imax-1
		
			rhs = @(z) -z * (pm.chi_I * pm.phi(z) * (pm.lambda * V0(1) - V0(i)) - (ig.w(i) - pm.nu * (V0(i+1) - V0(i))/pa.Delta_m(i)));
			
			[z fval] = fminbnd(rhs,0,5);
			
			zI_0(i) = z;
			fvalI_0(i) = fval;
    
		end
		
		%% Now, make vectors and matrices and compute update of V
		uvec = prof - zI_0 .* ig.w;
		%uvec = prof - zI_0 .* ig.w + zI_0 .* pm.chi_I .* pm.phi(zI_0) .* pm.lambda * V0(1);
		uvec = uvec';
		A = makeA_V(pa,pm,ig,zI_0);
		Bmat = (1/pa.delta_t_V + pm.rho) .* eye(Imax) - A;
		bvec = uvec + (1/pa.delta_t_V) .* V0;
		Bmat = sparse(Bmat);
		bvec = sparse(bvec);
		V1 = Bmat\bvec;
		
		%size_V1 = size(V1)
		%pause
		
		% Compute distance
		HJB_d = sqrt(sumsqr(V1 - V0));
		
		% Display distance
		distance = HJB_d / pa.delta_t_V
		
		if mod(count,frame_freq) == 0
			f = figure('visible','off');
            plot(pa.m_grid,V0)
            title('V(m)')
            ylim([-1.5*max(ig_V.V0),1.5*max(ig_V.V0)])
            drawnow
            F(count/frame_freq) = getframe(f);
        end
		
		% Update V0
		V0 = V1;
		
		% Update count
		count = count + 1;
   
    end 
    

    out.V = V0;
    out.zI = zI_0;
    out.zbar = pm.eta_inv(pm.wbar / (pm.chi_E * V0(1)));
    out.count = count;
    out.F = F;
    
end
