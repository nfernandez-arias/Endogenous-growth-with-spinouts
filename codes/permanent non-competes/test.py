# -*- coding: utf-8 -*-
"""
Created on Wed Feb 28 17:04:06 2018

@author: Nico
"""

import auxil as ax
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D
import time

pm = ax.set_modelpar()
pa = ax.set_algopar()
ig = ax.set_init_guesses_global(pa,pm)

#print(list(pa))
#print(list(pm))
#print(list(ig))

print(pa['HJB_V_tol'])

start = time.time()
V_out = ax.solve_HJB_V(pa,pm,ig)
end = time.time()

W_out = ax.solve_HJB_W(pa,pm,ig,V_out['Vplus'],V_out['zI'])


print(end - start)


## Make plot of solution V,W
fig = plt.figure()
ax = fig.add_subplot(121, projection='3d')
ax.plot_surface(pa['q_grid_2d'],pa['m_grid_2d'],V_out['V'])
plt.title('V(q,m)')
ax2 = fig.add_subplot(122, projection='3d')
ax2.plot_surface(pa['q_grid_2d'],pa['m_grid_2d'],W_out['W'])
plt.title('W(q,m)')
plt.show()



