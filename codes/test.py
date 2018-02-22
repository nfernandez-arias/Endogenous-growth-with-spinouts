# -*- coding: utf-8 -*-
"""
Created on Mon Sep 18 17:37:00 2017

@author: Nico
"""

#import random
import numpy as np
import quantecon as qe

from numba import jit

def qm(x0,n):
    x = np.empty(n+1)
    x[0] = x0
    for t in range(n):
        x[t+1] = 4 * x[t] * (1-x[t])
    return x

qm_numba = jit(qm)
#qe.util.tic()

#qm(0.1,int(10**7))
#time1 = qe.util.toc()

qe.util.tic()
qm_numba(0.1,int(10**7))
time2 = qe.util.toc()





    