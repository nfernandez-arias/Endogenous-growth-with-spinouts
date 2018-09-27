# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 16:47:30 2018

@author: Nico
"""

import auxil as ax
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

pm = ax.set_modelpar()
pa = ax.set_algopar()
ig = ax.set_init_guesses_global(pa,pm)

print(pa['HJB_V_tol'])

V_out = ax.solve_HJB_V(pa,pm,ig)

## Make plot of solution V
fig = plt.figure()
ax2 = fig.add_subplot(111, projection='3d')
ax2.plot_surface(pa['m_grid_2d'],pa['q_grid_2d'],V_out['V'])
plt.show()

