function out = makeA_V(pa,pm,ig,zI_0)

	Imax = pa.m_numpoints;
	
	Amat = zeros(Imax);
	
	phi = pm.phi;
	
	for i = 1:Imax -1
	
		Amat(i,1) = zI_0(i) * pm.chi_I * pm.phi(zI_0(i)) * pm.lambda;
		Amat(i,i+1) = pm.nu * (ig.zS(i) + ig.zE(i) + zI_0(i))/pa.Delta_m(i);
		Amat(i,i) = -pm.nu * (ig.zS(i) + ig.zE(i) + zI_0(i))/pa.Delta_m(i) - zI_0(i) * pm.chi_I * phi(zI_0(i)) - (ig.zE(i) * pm.chi_E + ig.zS(i) * pm.chi_S) * pm.eta(ig.zE(i) + ig.zS(i));

	end
	
	Amat(Imax,1) =  zI_0(Imax) * pm.chi_I * pm.phi(zI_0(Imax)) * pm.lambda;
	Amat(Imax,Imax) = - zI_0(Imax) * pm.chi_I * phi(zI_0(Imax)) - (ig.zE(Imax) * pm.chi_E + ig.zS(Imax) * pm.chi_S) * pm.eta(ig.zE(Imax) + ig.zS(Imax));
	
	out = Amat;
	
end
