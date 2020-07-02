#!/usr/bin/env wolframscript
(* ::Package:: *)

\[Theta]=2


\[Beta]=0.065


K=\[Beta]^\[Beta] (1-\[Beta])^(1-2 \[Beta])


w=K


(* ::InheritFromParent:: *)
(*0*)


\[Rho]=0.03


\[Lambda]=1.4


Subscript[\[Chi], I]=4


Subscript[\[Chi], E]=.1


\[Kappa]=0.3


\[Psi]=0.5


\[Nu]=2


Subscript[L, RD]=0.05


Subscript[L, F]=1-Subscript[L, RD]


Subscript[\[Pi], 0] = (1-\[Beta])*K*Subscript[L, F]


x[f_]:=Boole[(1-(1-\[Kappa]) \[Lambda]) \[Nu]>f]


Subscript[f, 0]=(1-(1-\[Kappa]) \[Lambda]) \[Nu]


Subscript[z, E][f_]:=((Subscript[\[Chi], E]*(1-\[Kappa])*\[Lambda])/(Subscript[\[Chi], i]*(\[Lambda]-1)-f))^(1/\[Psi])


Subscript[z, e][0]


Subscript[\[Chi], i]


Subscript[\[Tau], E][f_]:=Subscript[\[Chi], E] Subscript[z, E][f]^(1-\[Psi])


Subscript[z, i][f_]:=Subscript[L, RD]-Subscript[z, e][f]


Subscript[\[Tau], S][f_]:=(1-x[f]) \[Nu] Subscript[z, I][f]


g[f_]:=(\[Lambda]-1) (Subscript[\[Chi], I] Subscript[z, I][f]+Subscript[\[Tau], E][f]+Subscript[\[Tau], S][f])


r[f_]:=\[Theta] g[f]+\[Rho]


V[f_]:=Subscript[\[Pi], 0]/(r[f]+Subscript[\[Tau], e][f])


Subscript[z, e][0]


Subscript[w, RD][f_]:=V[f]*(Subscript[\[Chi], i]*(\[Lambda]-1)-f)


Y[f_]:=((1-\[Beta])^(1-2 \[Beta]) Subscript[L, F][f])/\[Beta]^(1-\[Beta])


W[f_]:=(x[f] (Y[f]-Subscript[\[Tau], E][f] \[Kappa] \[Lambda] V[f]-V[f] f Subscript[z, I][f])^(1-\[Theta]))/((1-\[Theta]) (\[Rho]-g[f] (1-\[Theta])))+((1-x[f]) (Y[f]-(Subscript[\[Tau], E][f]+Subscript[\[Tau], S][f]) \[Kappa] \[Lambda] V[f])^(1-\[Theta]))/((1-\[Theta]) (\[Rho]-g[f] (1-\[Theta])))


Subscript[W, 2][f_]:=(x[f] (Y[f]-Subscript[\[Tau], E][f] \[Kappa] \[Lambda] V[f])^(1-\[Theta]))/((1-\[Theta]) (\[Rho]-g[f] (1-\[Theta])))+((1-x[f]) (Y[f]-(Subscript[\[Tau], E][f]+Subscript[\[Tau], S][f]) \[Kappa] \[Lambda] V[f])^(1-\[Theta]))/((1-\[Theta]) (\[Rho]-g[f] (1-\[Theta])))


Subscript[W, 3][f_]:=(x[f] Y[f]^(1-\[Theta]))/((1-\[Theta]) (\[Rho]-g[f] (1-\[Theta])))+((1-x[f]) Y[f]^(1-\[Theta]))/((1-\[Theta]) (\[Rho]-g[f] (1-\[Theta])))


a=0


V[a]
Subscript[z, I][a]
Subscript[\[Chi], I] Subscript[z, I][a]
Subscript[\[Tau], S][a]
Subscript[z, E][a]
Subscript[\[Tau], E][a]


Subscript[L, RD][a]
Subscript[L, F][a]
g[a]
Subscript[g, 2][a]
r[a]
Subscript[r, 2][a]
Y[a]
W[a]


Plot[V[a],{a,0,2 Subscript[f, 0]}]


Plot[Subscript[z, I][a],{a,0,2 Subscript[f, 0]}]


Plot[Subscript[\[Chi], I] Subscript[z, I][a]+Subscript[\[Tau], S][a],{a,0,2 Subscript[f, 0]}]


(* ::CodeText:: *)
(**)


Plot[Subscript[z, E][a],{a,0,2 Subscript[f, 0]}]


Plot[g[a],{a,0,2 Subscript[f, 0]}]


Plot[r[a],{a,0,2 Subscript[f, 0]}]


Plot[Subscript[L, F][a],{a,0,2 Subscript[f, 0]}]


Plot[Subscript[L, RD][a],{a,0,2 Subscript[f, 0]}]


Plot[W[a],{a,0,2 Subscript[f, 0]}]


Plot[Subscript[W, 2][a],{a,0,2 Subscript[f, 0]}]


Plot[Subscript[W, 3][a],{a,0,2 Subscript[f, 0]}]
