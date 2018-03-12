# -*- coding: utf-8 -*-
"""
Created on Mon Sep 18 20:56:31 2017

@author: Nico
"""

import numpy as np
import scipy.interpolate as interp
from scipy import optimize
from decimal import *
getcontext().prec = 10
from numba import jit
import time

np.set_printoptions(formatter={'float': lambda x: "{0:0.5f}".format(x)})
    

def set_modelpar():   

    d = {}
    
    d["rho"] = 0.01
    d["beta"] = 0.2
    d["wbar"] = d['beta']**d['beta']*(1-d['beta'])**(1-2*d['beta'])  
    d["chi_I"] = 0.1
    d["chi_E"] = 0.1
    d["psi_I"] = 0.5
    d["psi_E"] = 0.5   
    d["lambda"] = 1.2  
    d["nu"] = 0.2
    d["theta"] = 0.05
    d["T_nc"] = 2
    d['xi'] = 1    
    return d

def set_algopar():
    
    d = {}
    
    # Create grids on which I will solve fixed point problem
    d['q_numpoints'] = 10
    d['q_max'] = 2
    d['q_min'] = 0
    d['m_numpoints'] = 5
    d['m_max'] = 1.5 
    d['q_grid'] = np.linspace(d['q_min'],d['q_max'],d['q_numpoints'])
    d['m_grid'] = np.linspace(0,d['m_max'],d['m_numpoints'])
    d['q_grid_2d'],d['m_grid_2d'] = np.meshgrid(d['q_grid'],d['m_grid'],indexing = 'ij')

    # Create grids for interpolation (for computing derivatives and simply interpolating value)
    d['q_numpoints_FINE'] = 100
    d['m_numpoints_FINE'] = 50   
    d['q_grid_FINE'] = np.linspace(0,d['q_max'],d['q_numpoints_FINE'])
    d['m_grid_FINE'] = np.linspace(0,d['m_max'],d['m_numpoints_FINE'])
    d['q_grid_2d_FINE'],d['m_grid_2d_FINE'] = np.meshgrid(d['q_grid_FINE'],d['m_grid_FINE'],indexing='ij')
    
    # Size of finite difference step for computing derivatives 
    d['delta_t'] = 0.0001
    d['delta_m'] = 0.01
    d['delta_q'] = 0.01
    
    # Algorithm tolerances
    d['HJB_V_tol'] = 10e-6 * d['delta_t']
    d['HJB_W_tol'] = 10e-5 * d['delta_t']
    d['Lf_tol'] = 10e-5
    d['g_tol'] = 10e-5
    d['wF_tol'] = 10e-5
    d['M_tol'] = 10e-5
    d['x_tol'] = 10e-5
    
    return d

def set_init_guesses_global(pa,pm):
    
    d = {}
    
    d['Lf0'] =  0.1
    d['g0'] = 0.01
    d['w0'] = pm['wbar']*np.ones(pa['q_grid_2d'].shape)
    d['M0'] = 0*np.ones(pa['q_grid_2d'].shape)
    d['x0'] = np.zeros(pa['q_grid_2d'].shape)
    
    return d
    
def set_init_guesses_V(pa,pm,ig):

    d = {}

    d['prof'] = pa['q_grid_2d'] * ig['Lf0'] *  (1 - pm['beta']) * pm['wbar']
    
    # Reasonable initial guess: value of simply making flow profits as relative quality declines 
    # to zero, assuming no risk of bein overtaken in our industry. Easiest to calculate this value 
    # directly and then normalize, because then it is just a constant flow profit, and it amounts to this:     
    d['V0'] = 1 + d['prof'] / pm['rho']
    #d['V0'] = np.ones(d['prof'].shape)
    
    
    d['maxcount'] = 500;
    
    return d

def set_init_guesses_W(pa,pm,ig,Vplus,zI):
    
    d = {}
    
    # Set initial guess for W - all zeros seems a reasonable choice that fits the boundary conditions
    d['W0'] = np.ones(pa['q_grid_2d'].shape)
    
    return d
    

def phi(z):
    p = -0.5
    return z**p

def rhs0(z,pa,pm,ig,V0,V0plus,Vq,Vm,zE,i_q,i_m):

    return -(-pm['wbar'] * z + pm['chi_I']*z*phi(z + zE[i_q,i_m])*(V0plus[i_q,i_m] 
                                    - V0[i_q,i_m]) + pm['chi_E']*zE[i_q,i_m]*phi(z+zE[i_q,i_m])*(-V0[i_q,i_m]))


def rhs1(z,pa,pm,ig,V0,V0plus,Vq,Vm,zE,i_q,i_m):

    return -(-ig['w0'][i_q,i_m] * z + pm['nu'] * Vm[i_q,i_m] * z + pm['chi_I'] * z * phi(z + zE[i_q,i_m]) * (V0plus[i_q,i_m] - V0[i_q,i_m]) 
                                                + pm['chi_E']*zE[i_q,i_m]*phi(z + zE[i_q,i_m])*(-V0[i_q,i_m]))






#@jit()



#@jit(nopython = True)
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
    
    #print(zE)
    #wait = input("Press Enter to continue ...")
    
    
    
    zmax = np.ones(V0.shape)
    ymax = np.ones(V0.shape)
    
    HJB_d = 1
    count = 1
    
    V1 = np.ones(V0.shape)
    Vq = np.ones(V0.shape)
    Vm = np.ones(V0.shape)
    #B1 = np.ones(B0.shape)
    
    while HJB_d > pa['HJB_V_tol'] and count <= d['maxcount']:  
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
                
                Vq[i_q,i_m] = pa['delta_q']**(-1) * (-1)*(V0_interp(q-pa['delta_q'],m) - V0[i_q,i_m])  
                Vm[i_q,i_m] = pa['delta_m']**(-1) * (V0_interp(q,m + pa['delta_m']) - V0[i_q,i_m])

                # Construct anonymous function for maximizing
                # For using numba, may have to replace this with an actual function that is defined outside, and takes as parameters the things below that change throughout the loop:
                # V0, V0plus, x0, etc.
                
                #rhs1 = lambda z: -(-ig['w0'][i_q,i_m] * z + pm['nu'] * Vm[i_q,i_m] * z + pm['chi_I'] * z * phi(z + zE[i_q,i_m]) * (V0plus[i_q,i_m] - V0[i_q,i_m]) 
                #                                + pm['chi_E']*zE[i_q,i_m]*phi(z + zE[i_q,i_m])*(-V0[i_q,i_m]))
    
                #rhs0 = lambda z: -(-pm['wbar'] * z + pm['chi_I']*z*phi(z + zE[i_q,i_m])*(V0plus[i_q,i_m] 
                #                    - V0[i_q,i_m]) + pm['chi_E']*zE[i_q,i_m]*phi(z+zE[i_q,i_m])*(-V0[i_q,i_m]))
                
                #rhs = lambda z: -( - x0[i_q,i_m] * ig['w0'][i_q,i_m] * z 
                #                 + pm['chi_I']*z*phi(z+zE[i_q,i_m])*V0plus[i_q,i_m] 
                #                 - (pm['chi_I']*z + pm['chi_E']*zE[i_q,i_m])*phi(z+zE[i_q,i_m])*V0[i_q,i_m] 
                #                 + (1- x0[i_q,i_m]) *  pm['nu']*z*Vm )
                
                #z0 = 1.0
                #bounds = (0.01,10)
                
                
                optimum1 = optimize.minimize(rhs1,1,args = (pa,pm,ig,V0,V0plus,Vq,Vm,zE,i_q,i_m), bounds = [(0.01,10)])
                optimum0 = optimize.minimize(rhs0,1,args = (pa,pm,ig,V0,V0plus,Vq,Vm,zE,i_q,i_m), bounds = [(0.01,10)])
                
                #optimum1 = optimize.minimize(rhs1,z0,bounds = [(0.01, 10)], method = 'L-BFGS-B', options={'maxiter': 100, 'disp': True})
                #optimum0 = optimize.minimize(rhs0,z0,bounds = [(0.01, 10)], method = 'L-BFGS-B', options={'maxiter': 100, 'disp': True})
                
                if optimum1.fun > optimum0.fun:
                    ymax[i_q,i_m] = 1
                    zmax[i_q,i_m] = optimum1.x
                    
                    V1[i_q,i_m] = ( V0[i_q,i_m] 
                                    + pa['delta_t']*(-rhs1(zmax[i_q,i_m],pa,pm,ig,V0,V0plus,Vq,Vm,zE,i_q,i_m) + prof[i_q,i_m] - ig['g0']*q*Vq[i_q,i_m] 
                                    + pm['nu']*zE[i_q,i_m] * Vm[i_q,i_m] - (pm['rho'] -ig['g0']) * V0[i_q,i_m]))
                    
                else:
                    ymax[i_q,i_m] = 0
                    zmax[i_q,i_m] = optimum0.x
                    
                    V1[i_q,i_m] = ( V0[i_q,i_m] 
                                    + pa['delta_t']*(-rhs0(zmax[i_q,i_m],pa,pm,ig,V0,V0plus,Vq,Vm,zE,i_q,i_m) + prof[i_q,i_m] - ig['g0']*q*Vq[i_q,i_m] 
                                    + pm['nu']*zE[i_q,i_m] * Vm[i_q,i_m] - (pm['rho'] -ig['g0']) * V0[i_q,i_m]))
                
                
                #zmax[i_q,i_m] = optimum.x
                #z = optimum.x
                #zmax[i_q,i_m] = optimum.x
                #z,y = optimum.x
 
                #V1[i_q,i_m] = ( V0[i_q,i_m] 
                #                    + pa['delta_t']*(-rhs(z) + prof[i_q,i_m] - ig['g0']*q*Vq 
                #                    + pm['nu']*zE[i_q,i_m] * Vm - (pm['rho'] -ig['g0']) * V0[i_q,i_m]))
                
                    
        # Compute distance between A0 and A1
        #print(count)
        #print(np.square(V0-V1))
        #wait = input("Press Enter to continue ...")
        
        HJB_d = np.sum(np.square(V0-V1))
        print([count,HJB_d])
        #HJB_d_printed = Decimal(HJB_d)
        #"{1:.5f}".format(HJB_d)
        #print(HJB_d_printed)
        #print(zmax)
        #print(ymax)
        #wait = input("Press Enter to continue ...")
     
        
        #f"HJB_d = {HJB_d:.10f}"
        #print(np.abs(V1))
        #print("V0",V0)
        #print("V1",V1)
        #print("abs(V1-V0)",np.abs(V1-V0))
        #wait = input("Press Enter to continue ...")
        # Update guesses
        V0 = np.copy(V1)
        #B0 = B1
        
        count = count + 1
    
    #print(zmax)
    V1_interp = interp.Rbf(pa['q_grid_2d'],pa['m_grid_2d'],V0)
    Vplus = V1_interp((1+pm['lambda'])*pa['q_grid_2d'],np.zeros(pa['m_grid_2d'].shape))
    
    out['Vm'] = Vm
    out['V'] = V0
    out['Vplus'] = Vplus
    out['zI'] = zmax
    out['count'] = count
    out['y'] = ymax
    out['d'] = HJB_d
    #out['B0'] = B0
    return out

    
def solve_HJB_W(pa,pm,ig,Vplus,zI):
    
    zE = pm['xi'] * np.minimum(pa['m_grid_2d'],ig['M0'])
    tau = zE + zI
    x0 = ig['x0']
    
    d = set_init_guesses_W(pa,pm,ig,Vplus,zI)
    
    W0 = d['W0']
    
    W0_interp = interp.Rbf(pa['q_grid_2d'],pa['m_grid_2d'],W0)
    
    out = {}
    
    HJB_d = 1
    count = 1
    
    W1 = np.ones(W0.shape)
    
    #while HJB_d > pa['HJB_W_tol']:
    while HJB_d > pa['HJB_W_tol'] and count <= 500:   
        for i_q,q in enumerate(pa['q_grid']):   
            for i_m,m in enumerate(pa['m_grid']):    
                
                Wq = pa['delta_q']**(-1) * (-1) * (W0_interp(q-pa['delta_q'],m) - W0[i_q,i_m])
                Wm = pa['delta_m']**(-1) * (W0_interp(q,m+pa['delta_m']) - W0[i_q,i_m]) 
                
                
                W1[i_q,i_m] = W0[i_q,i_m] + pa['delta_t'] * (-(pm['rho']- ig['g0']) * W0[i_q,i_m] -ig['g0']*q*Wq + (x0[i_q,i_m]*zI[i_q,i_m]+zE[i_q,i_m]) * pm['nu'] * Wm 
                                                              +(pm['chi_I']*zI[i_q,i_m] + pm['chi_E']*zE[i_q,i_m]) * phi(zI[i_q,i_m] + zE[i_q,i_m])* (-W0[i_q,i_m])
                                                              + int(m < ig['M0'][i_q,i_m]) * (pm['xi']*(pm['chi_E']*phi(zI[i_q,i_m] + zE[i_q,i_m])*(Vplus[i_q,i_m] - W0[i_q,i_m])
                                                                                                        - ig['w0'][i_q,i_m])))
                '''
                if m < ig['M0'][i_q,i_m]:
        
                    W1[i_q,i_m] = (W0[i_q,i_m] + pa['delta_t'] * (-ig['g0']*q*Wq + (x0[i_q,i_m]*zI[i_q,i_m] + zE[i_q,i_m])*pm['nu']*Wm 
                                  + (pm['chi_I']*zI[i_q,i_m] + pm['chi_E']*zE[i_q,i_m]) * phi(zI[i_q,i_m] + zE[i_q,i_m])* (-W0[i_q,i_m])
                                  + pm['chi_E']*pm['xi']*phi(zI[i_q,i_m] + zE[i_q,i_m])*(Vplus[i_q,i_m] - W0[i_q,i_m]) - ig['w0'][i_q,i_m] * pm['xi']  
                                  - (pm['rho'] - ig['g0']) * W0[i_q,i_m]))
                else: 
                    
                     W1[i_q,i_m] = (W0[i_q,i_m] + pa['delta_t'] * (-ig['g0']*q*Wq + ((1-x0[i_q,i_m])*zI[i_q,i_m] + zE[i_q,i_m])*pm['nu']*Wm 
                                  + (pm['chi_I']*zI[i_q,i_m] + pm['chi_E']*zE[i_q,i_m]) * phi(zI[i_q,i_m] + zE[i_q,i_m]) *(-W0[i_q,i_m]) 
                                  - (pm['rho'] - ig['g0']) * W0[i_q,i_m]))
                '''     
         
        HJB_d = np.sum(np.square(W0 - W1))
        
        W0 = np.copy(W1)
        
        count = count + 1
                    
    W = np.copy(W0)
    
    out['W'] = W
    out['count'] = count
    out['zE'] = zE
    
    return out
    


def solve_model(pa,pm,ig):
    
    # convergence tolerances are in pa
    # initial guesses are in ig
    
    Lf_d = 1
    g_d = 1
    wF_d = 1
    M_d = 1
    x_d = 1
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
                while M_d > pa['M_tol']:
                    while x_d > pa['x_tol']: 
                
                        V_out = solve_HJB_V(pa,pm,ng)
                        # Compute aggregate innovation effort
                        W_out = solve_HJB_W(pa,pm,ng,V_out['V'],V_out['V_interp'],V_out['zI'])
                        
                        # Check that x0(q,m) is consistent with incumbent optimality 
                        # If not, update it to a different guess x1(q,m)
                        # and set x_d = np.sum(np.square(x1 - x0))
                        # and finally reset x0 = x1 
                    
                    # Next, check that M(q,m) is consistent with entrant optimality
                    # If not, change guess for M(q,m) to M1, calculate M_d, and 
                    # reset M0 = M1 
                    
                # Next, check that w(q,m) = wbar- nu * W(q,m). If not, adjust 
                # guess for w to w1, calculate wF_d, and reset wF0 = wF1 
                
            # Next, check that g is compatible, etc.
            
        # Finally, check that L_F is compatible, etc.
        
                
    out = {}
           
    out['V_out'] = V_out
    out['W_out'] = W_out
    
    return out
                

            
   
        

        

                
                



                
                
                
                
                
        
    
    

    
    


