# -*- coding: utf-8 -*-
"""
Created on Mon Sep 18 20:56:31 2017

@author: Nico
"""

import numpy as np
import scipy.interpolate as interp
from scipy import optimize 
from numba import jit

def set_modelpar():   

    d = {}
    
    d["rho"] = 0.01
    d["beta"] = 0.2
    d["wbar"] = d['beta']**d['beta']*(1-d['beta'])**(1-2*d['beta'])  
    d["chi_I"] = 1
    d["chi_E"] = 1 
    d["psi_I"] = 0.5
    d["psi_E"] = 0.5   
    d["lambda"] = 1.1  
    d["nu"] = 0.1
    d["theta"] = 0.05
    d["T_nc"] = 2
    d['xi'] = 0.2
    
    return d

def set_algopar():
    
    d = {}
    
    # Create grids on which I will solve fixed point problem
    d['q_numpoints'] = 10
    d['q_max'] = 10
    d['m_numpoints'] = 5
    d['m_max'] = 5  
    d['q_grid'] = np.linspace(0,d['q_max'],d['q_numpoints'])
    d['m_grid'] = np.linspace(0,d['m_max'],d['m_numpoints'])
    d['q_grid_2d'],d['m_grid_2d'] = np.meshgrid(d['q_grid'],d['m_grid'],indexing = 'ij')

    # Create grids for interpolation (for computing derivatives and simply interpolating value)
    d['q_numpoints_FINE'] = 100
    d['m_numpoints_FINE'] = 50   
    d['q_grid_FINE'] = np.linspace(0,d['q_max'],d['q_numpoints_FINE'])
    d['m_grid_FINE'] = np.linspace(0,d['m_max'],d['m_numpoints_FINE'])
    d['q_grid_2d_FINE'],d['m_grid_2d_FINE'] = np.meshgrid(d['q_grid_FINE'],d['m_grid_FINE'],indexing='ij')
    
    # Size of finite difference step for computing derivatives 
    d['delta_t'] = 0.01
    d['delta_m'] = 0.01
    d['delta_q'] = 0.01
    
    # Algorithm tolerances
    d['HJB_V_tol'] = 10e-5
    d['HJB_W_tol'] = 10e-5
    d['Lf_tol'] = 10e-5
    d['g_tol'] = 10e-5
    d['wF_tol'] = 10e-5
    
    return d

def set_init_guesses_global(pa,pm):
    
    d = {}
    
    d['Lf0'] =  0.1
    d['g0'] = 0.015
    d['w0'] = pm['wbar']*np.ones(pa['q_grid_2d'].shape)
    d['M0'] = np.ones(pa['q_grid_2d'].shape)
    d['x0'] = np.ones(pa['q_grid_2d'].shape)
    
    return d
    
def set_init_guesses_V(pa,pm,ig):

    d = {}

    d['prof'] = pa['q_grid_2d'] * ig['Lf0'] *  (1 - pm['beta']) * pm['wbar']
    
    # Reasonable initial guess: value of simply making flow profits as relative quality declines 
    # to zero, assuming no risk of bein overtaken in our industry. Easiest to calculate this value 
    # directly and then normalize, because then it is just a constant flow profit, and it amounts to this:     
    d['V0'] = d['prof'] / pm['rho']
    
    return d

def set_init_guesses_W(pa,pm,ig,V,V_interp,zI):
    
    d = {}

    d['V_win'] = V_interp((1+pm['lambda']) * pa['q_grid_2d'],np.zeros(pa['m_grid_2d'].shape))
    
    # Set initial guess for W - all zeros seems a reasonable choice that fits the boundary conditions
    d['W0'] = np.zeros(pa['q_grid_2d'].shape)
    
    return d
    

def phi(z):
    p = -0.5
    return z**p


@jit()




def solve_HJB_V(pa,pm,ig):

    out = {}
    
    d = set_init_guesses_V(pa,pm,ig)
    # flow profits as function of q
    prof = d['prof']
    V0 = d['V0']
    
    # Initial guesses for value functions A(q,m,n) and B(q) 
    # are contained in argument ig
    
    zE = pm['xi'] * np.minimum(pa['m_grid_2d'],ig['M0'])
    x0 = ig['x0']
    
    zmax = np.ones(V0.shape)
    
    HJB_d = 1
    count = 1
    
    V1 = np.ones(V0.shape)
    #B1 = np.ones(B0.shape)
    
    while HJB_d > pa['HJB_V_tol']:
    #while count <= 100:  
        # First step is to create interpolant
        V0_interp = interp.Rbf(pa['q_grid_2d'],pa['m_grid_2d'],V0)
        V0plus = V0_interp((1+pm['lambda'])*pa['q_grid_2d'],np.zeros(pa['m_grid_2d'].shape))
       #B0_interp = interp.Rbf(pa['q_grid_3d'],pa['m_grid_3d'],pa['n_grid_3d'],B0)
        
        # Interpolate onto finer grid 
        #A0_FINE = A0_interp(pa['q_grid_3d_FINE'],pa['m_grid_3d_FINE'],pa['n_grid_3d_FINE'])
        #B0_FINE = B0_interp(pa['q_grid_3d_FINE'],pa['m_grid_3d_FINE'],pa['n_grid_3d_FINE'])
        
        # Next, loop through all values - no way to avoid, since we need
        # to find the zero of a polynomial to perform the optimization on 
        # the RHS
        
        #################################################################################
        #Should be able to parallelize below, however. No reason to do this in sequence!#
        #################################################################################
        
        for i_q,q in enumerate(pa['q_grid']):   
            for i_m,m in enumerate(pa['m_grid']):    
                
                
                # Should probably rewrite this as a function and jit THIS, 
                # so that it runs once and figures out what its types should be.
                # If I understand how numba works correctly...
                
                # Use interpolation + finite difference to compute all derivative terms on the RHS
                # Upwind scheme: take forward difference when drift is positive, backward difference when drift 
                # is negative. Hence, take backward difference when computing Vq, forward difference when computing Vm
                
                Vq = pa['delta_q']**(-1) * (-1)*(V0_interp(q-pa['delta_q'],m) - V0[i_q,i_m])  
                Vm = pa['delta_m']**(-1) * (V0_interp(q,m + pa['delta_m']) - V0[i_q,i_m])

                # Construct anonymous function for maximizing
                
                rhs = lambda z: -( - x0[i_q,i_m] * ig['w0'][i_q,i_m] * z 
                                 + pm['chi_I']*z*phi(z+zE[i_q,i_m])*V0plus[i_q,i_m] 
                                 - (pm['chi_I']*z + pm['chi_E']*zE[i_q,i_m])*phi(z+zE[i_q,i_m])*V0[i_q,i_m] 
                                 + (1- x0[i_q,i_m]) *  pm['nu']*z*Vm )
                
                optimum = optimize.minimize(rhs,1,bounds = [(0.001,10)], method = 'L-BFGS-B', options={'maxiter': 100, 'disp': True})
                zmax[i_q,i_m] = optimum.x
                z = optimum.x
                #zmax = 0.5
                # Update 
                
                V1[i_q,i_m] = ( V0[i_q,i_m] 
                                    + pa['delta_t']*(-rhs(z) + prof[i_q,i_m] - ig['g0']*q*Vq 
                                    + pm['nu']*zE[i_q,i_m] * Vm - (pm['rho'] -ig['g0']) * V0[i_q,i_m]))
                    
        # Compute distance between A0 and A1
        
        HJB_d = np.sum(np.square(V0-V1)) 
        
        # Update guesses
        V0 = V1
        #B0 = B1
        
        count = count + 1
    
    V1_interp = interp.Rbf(pa['q_grid_2d'],pa['m_grid_2d'],V0)
    Vplus = V1_interp((1+pm['lambda'])*pa['q_grid_2d'],np.zeros(pa['m_grid_2d'].shape))
    
    out['V'] = V0
    out['Vplus'] = Vplus
    out['zI'] = zmax
    #out['B0'] = B0
    return out

    
def solve_HJB_W(pa,pm,ig,Vplus,zI):
    
    zE = pm['xi'] * np.minimum(pa['m_grid_2d'],ig['M0'])
    tau = zE + zI
    
    
    d = set_init_guesses_W(pa,pm,ig,Vplus,zI)
    
    W0 = d['W0']
    
    W0_interp = interp.Rbf(pa['q_grid_2d'],pa['m_grid_2d'],W0)
    
    out = {}
    
    HJB_d = 1
    count = 1
    
    while HJB_d > pa['HJB_W_tol']:
        
        for i_q,q in enumerate(pa['q_grid']):   
            for i_m,m in enumerate(pa['m_grid']):    
                
                Wq = pa['delta_q']**(-1) * (-1) * (W0_interp(q-pa['delta_q'],m) - W0[i_q,i_m])
                Wm = pa['delta_m']**(-1) * (W0_interp(q,m+pa['delta_m']) - W0[i_q,i_m]) 
        
                
                
                
    W = W0
    
    out['W']
    
    return out
    


def solve_model(pa,pm,ig):
    
    # convergence tolerances are in pa
    # initial guesses are in ig
    
    Lf_d = 1
    g_d = 1
    wF_d = 1
    HJB_d = 1
    
    ng = {}
    
    ng['Lf0'] = ig['Lf0']
    ng['g0'] = ig['g0']
    ng['w0'] = ig['w0']
    ng['M0'] = ig['F0']
    ng['x0'] = ig['x0']
    
    while Lf_d > pa['Lf_tol']:
        while g_d > pa['g_tol']:   
            while wF_d > pa['wF_tol']: 
                
                V_out = solve_HJB_V(pa,pm,ng)
                # Compute aggregate innovation effort
                W = solve_HJB_W(pa,pm,ng,V_out['V'],V_out['V_interp'],V_out['zI'])
                
                
                
    out = {}
           
    out['V_out'] = V_out
    out['W'] = W
    
    return out
                

            
   
        

        

                
                



                
                
                
                
                
        
    
    

    
    


