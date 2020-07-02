#!/usr/bin/env wolframscript
(* ::Package:: *)

Subscript[\[Beta], 0][\[Beta]_]:=\[Beta]^\[Beta] (1-\[Beta])^(1-2 \[Beta])


Subscript[L, F][\[Beta]_,L_]:=(1-L)/(1+((1-\[Beta])/Subscript[\[Beta], 0][\[Beta]])^(1/\[Beta]))


(* ::InheritFromParent:: *)
(*(1-L)/(1+((1-\[Beta])^(2 \[Beta]) \[Beta]^-\[Beta])^(1/\[Beta]))*)


Y[\[Beta]_,L_]:=((1-\[Beta])^(1-2 \[Beta]) Subscript[L, F][\[Beta],L])/\[Beta]^(1-\[Beta])


(* ::InheritFromParent:: *)
(*((1-\[Beta])^(1-2 \[Beta]) \[Beta]^(-1+\[Beta]) (1-L))/(1+((1-\[Beta])^(2 \[Beta]) \[Beta]^-\[Beta])^(1/\[Beta]))*)


Subscript[\[Pi], 0][\[Beta]_,L_]:=(1-\[Beta]) Subscript[\[Beta], 0][\[Beta]] Subscript[L, F][\[Beta],L]


(* ::InheritFromParent:: *)
(*((1-\[Beta])^(2-2 \[Beta]) \[Beta]^\[Beta] (1-L))/(1+((1-\[Beta])^(2 \[Beta]) \[Beta]^-\[Beta])^(1/\[Beta]))*)


Subscript[z, E][k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=((\[Chi] (1-\[Kappa]) \[Lambda])/(\[Eta] (\[Lambda]-1)-k \[Nu]))^(1/\[Psi])


Subscript[\[Tau], E][k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=\[Chi] Subscript[z, E][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L]^(1-\[Psi])


Subscript[z, I][k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=L-Subscript[z, E][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L]


Subscript[\[Tau], I][k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=\[Eta] Subscript[z, I][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L]


g[k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=(\[Lambda]-1) (Subscript[\[Tau], E][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L]+Subscript[\[Tau], I][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L])


r[k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=\[Theta] g[k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L]+\[Rho]


V[k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=Subscript[\[Pi], 0]/(r[k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu]]+Subscript[\[Tau], E][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu]])


W[k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=(Y-V[k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L] (Subscript[\[Tau], E][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L] \[Kappa] \[Lambda]+Subscript[z, I][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L] k \[Nu]))^(1-\[Theta])/((1-\[Theta]) (\[Rho]-g[k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L] (1-\[Theta])))


Reduce[D[W[k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L],k] > 0,{k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Psi],\[Theta],\[Rho],\[Nu],L}]


Cons[k_,\[Beta]_,\[Chi]_,\[Eta]_,\[Kappa]_,\[Lambda]_,\[Psi]_,\[Theta]_,\[Rho]_,\[Nu]_,L_]:=Y-V[k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Theta],\[Rho],\[Nu]] (Subscript[\[Tau], E][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Theta],\[Rho],\[Nu]] \[Kappa] \[Lambda]+Subscript[z, I][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Theta],\[Rho],\[Nu]] k \[Nu])


\!\(
\*SubscriptBox[\(\[PartialD]\), \(k\)]Cons\)


Reduce[Derivative[1][Cons][k,\[Beta],\[Chi],\[Eta],\[Kappa],\[Lambda],\[Theta],\[Rho],\[Nu],L]>0,k]
