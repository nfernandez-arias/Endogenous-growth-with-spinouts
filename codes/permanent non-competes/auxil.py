# -*- coding: utf-8 -*-
"""
Created on Mon Sep 18 20:56:31 2017

@author: Nico
"""

import numpy as np
import scipy.interpolate as interp
from scipy import optimize
from numba import jit

def set_model():   

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
    d['HJB_AB_tol'] = 10e-5
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
    d['F0'] = np.ones(pa['q_grid_2d'].shape)
    
    return d
    
def set_init_guesses_AB(pa,pm,ig):

    d = {}

    d['prof'] = pa['q_grid_2d'] * ig['Lf0'] *  (1 - pm['beta']) * pm['wbar']
    
    # Reasonable initial guess: value of simply making those 
    d['A0'] = d['prof'] / (pm['rho'] + ig['g0']) 
    
    return d

def set_init_guesses_W(pa,pm,ig,A,A_interp,zI):
    
    d = {}

    d['A_win'] = A_interp((1+pm['lambda']) * pa['q_grid_2d'],np.zeros(pa['m_grid_2d'].shape))
    
    d['zE'] = pm['xi'] * np.minimum(pa['m_grid_2d'],ig['F0'])
    
    # Set initial guess for W_F
    # d['W_F'] =
    
    # Will we need inintial guess for W_NC? I think no, because we can solve it gi#ven W_F simply by integrating.
    
    return d
    

def phi(z):
    p = -0.5
    return z**p


@jit()




def solve_HJB_A(pa,pm,ig):

    out = {}
    
    d = set_init_guesses_AB(pa,pm,ig)
    # flow profits as function of q
    prof = d[prof]
    A0 = d[A0]
    
    # Initial guesses for value functions A(q,m,n) and B(q) 
    # are contained in argument ig
    
    zE = pm['xi'] * np.minimum(pa['m_grid_2d'],ig['F0'])
    
    zmax = np.ones(A0.shape)
    
    HJB_d = 1
    count = 1
    
    A1 = np.ones(A0.shape)
    #B1 = np.ones(B0.shape)
    
    while HJB_d > pa['HJB_AB_tol']:
    #while count <= 100:  
        # First step is to create interpolant
        A0_interp = interp.Rbf(pa['q_grid_2d'],pa['m_grid_2d'],A0)
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
                for i_n,n in enumerate(pa['n_grid']):
                    
                    # Should probably rewrite this as a function and jit THIS, 
                    # so that it runs once and figures out what its types should be.
                    # If I understand how numba works correctly...
                    
                    # Use interpolation + finite difference to compute all derivative terms on the RHS
                    
                    Aq = pa['delta_q']**(-1) * (A0_interp(q+pa['delta_q'],m,n) - A0[i_q,i_m,i_n]) 
                    Am = pa['delta_m']**(-1) * (A0_interp(q,m + pa['delta_m'],n) - A0[i_q,i_m,i_n])
                    An = pa['delta_n']**(-1) * (A0_interp(q,m,n+pa['delta_n']) - A0[i_q,i_m,i_n]) 
                    
                    # Construct anonymous function for maximizing
                    
                    rhs = lambda z: -( -ig['w0'][i_q,i_m,i_n] * z 
                                     + pm['chi_I']*z*phi(z+zE[i_q,i_m,i_n])*A0_interp((1+pm['lambda'])*q,0,0) 
                                     - (pm['chi_I']*z + pm['chi_E']*zE[i_q,i_m,i_n])*phi(z+zE[i_q,i_m,i_n])*A0[i_q,i_m,i_n] 
                                     + pm['nu']*z*An )
                    
                    optimum = optimize.minimize(rhs,1,bounds = [(0.01,2)], method = 'L-BFGS-B', options={'maxiter': 100, 'disp': True})
                    zmax[i_q,i_m,i_n] = optimum.x
                    z = optimum.x
                    #zmax = 0.5
                    # Update 
                    
                    A1[i_q,i_m,i_n] = ( A0[i_q,i_m,i_n] 
                                        + pa['delta_t']*(-rhs(z) + prof[i_q,i_m,i_n] - ig['g0']*q*Aq 
                                        + pm['nu']*zE[i_q,i_m,i_n] * An
                                        + (1/pm['T_nc']) * n * (Am - An) - (pm['rho'] -ig['g0']) * A0[i_q,i_m,i_n]))
                    
        # Compute distance between A0 and A1
        
        HJB_d = np.sum(np.square(A0-A1)) 
        
        # Update guesses
        A0 = A1
        #B0 = B1
        
        count = count + 1
        
    out['A'] = A0
    out['A_interp'] = interp.Rbf(pa['q_grid_3d'],pa['m_grid_3d'],pa['n_grid_3d'],A0)
    out['zI'] = zmax
    #out['B0'] = B0
    return out

    
def solve_HJB_W(pa,pm,ng,A,A_interp,zI):
    
    
    tau = d['zE'] + zI
    
    
    d = set_init_guesses_W(pa,pm,ng,A,A_interp,zI)
    
    W_NC0 = d['W_NC0']
    W_F0 = d['W_F0']    
        
    out = {}
    
    W_NC = W_NC0
    W_F = W_F0 
    
    out['W_NC'] = W_NC
    out['W_F'] = W_F
    
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
    ng['F0'] = ig['F0']
    
    while Lf_d > pa['Lf_tol']:
        
        
        while g_d > pa['g_tol']:
        
          
            while wF_d > pa['wF_tol']: 
                
                A_out = solve_HJB_A(pa,pm,ng)
                # Compute aggregate innovation effort
                W_F,W_NC = solve_HJB_W(pa,pm,ng,A_out['A'],A_out['A_interp'],A_out['zI'])
                
                
                
    out = {}
           
    out['A_out'] = A_out
    out['W_NC'] = W_NC
    out['W_F'] = W_F
    
    return out
                

            
   
        

        

                
                



                
                
                
                
                
        
    
    

    
    


