function out = rhs1(z,pa,pm,ig,V0,Vq,Vm,zE,i_q,i_m)

    out = (-ig.w0(i_q,i_m) * z + pm.nu * Vm(i_q,i_m) * z ...
             + pm.chi_I * z * phi(z + zE(i_q,i_m)) * (V0plus(i_q,i_m) - V0(i_q,i_m)) ...
             + pm.chi_E * zE(i_q,i_m) * phi(z + zE(i_q,i_m)) * (-V0(i_q,i_m));
         
end

