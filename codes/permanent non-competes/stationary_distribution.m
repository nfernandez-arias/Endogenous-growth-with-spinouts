function out = stationary_distribution(pa,pm,ig,V_out,W_out)

    size(V_out.zI)
    size(V_out.y)
    size(V_out.zE)
    size(W_out.tau)
    size(pa.q_grid_2d)
    size(pa.m_grid_2d)
    
    % Policy functions
    zI = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V_out.zI);
    y = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V_out.y); %non-compete policy: y = 1 if non-compete is used
    zE = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,V_out.zE);
    tau = griddedInterpolant(pa.q_grid_2d,pa.m_grid_2d,W_out.tau);
    
    % Algorithm parameters
    num_draws = pa.num_draws; %i.e. how many j do we simulate
    run_time = pa.run_time; %i.e. how long do we run model to compute stationary distrib
    delta_t = pa.sim_delta_t;
    num_points_t = round(run_time / delta_t);
    t_grid = linspace(0,run_time,num_points_t);
    rng('default')
    qm_draws = zeros(length(1:num_draws));
    
    % Build exhaustive 2-column grid
    qm_2col_grid = [pa.q_grid_2d(:) pa.m_grid_2d(:)];
     
    % Algorithm
    
    draws = zeros(num_draws,2);
    
    parfor i_n = 1:num_draws
        
       q0 = 1;
       m0 = 0;
       
       for i_t = 1:num_points_t
           
           % Always, there is some drift at rate -gq in the q direction...
           
           q0 = q0 - ig.g0* q0 * delta_t;
           
           % ... and some drift in the positive m direction (due to spillovers by 
           % entrants and by incumbents who set y = 0):
            
           m0 = m0 + pm.nu * ((1-y(q0,m0)) * zI(q0,m0) + zE(q0,m0)) * delta_t;
           
           % Sometimes -- with probability tau(q0,m0)*delta_t -- an innovation occurs.
           
           if binornd(1,tau(q0,m0)*delta_t) == 1
               
               q0 = (1+ pm.lambda) * q0;
               m0 = 0;
               
           end
           
           % Finally, if the above does not work, can always add exogenous 
           % product death, where the product is then replaced by a new
           % product of average quality (i.e. q0 = 1, m0 = 0 above).
           % For now, let's see what happens with the above.
           
       end
       
       data = [q0 m0];
       
       % Finally, record results of this draw in vector 
       draws(i_n,:) = data;
    end
    
    % Compute Kernel Density estimate
    
    [mu,qm_2col_grid] = ksdensity(draws);
    
    out = mu;

end