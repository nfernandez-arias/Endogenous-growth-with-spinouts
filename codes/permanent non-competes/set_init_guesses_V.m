function d = set_init_guesses_V(pa,pm,ig)

d.prof = pa.q_grid_2d * ig.Lf0 * (1- pm.beta) * pm.wbar;

if isfield(ig,'V')
    
    d.V0 = ig.V;
    
else 
    
   d.V0 = 1.5*d.prof / pm.rho;
   
end

%d.V0 = 0.1*ones(size(d.prof));
d.maxcount = 200;

end
