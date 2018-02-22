# -*- coding: utf-8 -*-
"""
Created on Fri Oct 20 09:35:47 2017

@author: Nico
"""

import numpy as np
import scipy.interpolate as ip
import matplotlib.pyplot as plt

def func(x,y): 
    return x*(1-x)*np.cos(4*np.pi*x) * np.sin(4*np.pi*y**2)**2

grid_x, grid_y = np.mgrid[0:1:10j,0:1:20j]

points = np.random.rand(10,2)
values = func(points[:,0],points[:,1])

grid_z0 = ip.griddata(points,values,(grid_x,grid_y),method = 'nearest')
grid_z1 = ip.griddata(points,values,(grid_x,grid_y),method = 'linear')
grid_z2 = ip.griddata(points,values,(grid_x,grid_y),method = 'cubic')




