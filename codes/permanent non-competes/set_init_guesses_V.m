function d = set_init_guesses_V(pa,pm,ig)

d.prof = pa.q_grid_2d * ig.Lf0 * (1- pm.beta) * pm.wbar;

d.V0 = d.prof / pm.rho;
%d.V0 = 0.1*ones(size(d.prof));
d.maxcount = 500;

end
