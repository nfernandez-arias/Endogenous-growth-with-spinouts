#!/usr/bin/env wolframscript
(* ::Package:: *)

Subscript[z, I][c_] := (((1-\[Psi]) * Subscript[\[Chi], I] * (\[Lambda] - 1)) / (c + Subscript[\[Chi], E] * \[Lambda]))^(1/\[Psi])


Subscript[\[Tau], I][c_] := Subscript[\[Chi], I]*Subscript[z, I][c]^(1-\[Psi])


Subscript[\[Tau], S][c_] := \[Nu]*Subscript[z, I][c]


Subscript[L, RD][c_] := (Subscript[\[Chi], E]+((1-\[Beta])*K)/(1+((1-\[Beta])/K)^(1/\[Beta])))^-1*(((1-\[Beta])*K)/(1+((1-\[Beta])/K)^(1/\[Beta]))+(\[Lambda]-1)*Subscript[\[Chi], I] Subscript[z, I][c]^(1-\[Psi])-Subscript[z, I][c]*(c+Subscript[\[Chi], E]\[Lambda])-\[Rho] + Subscript[\[Chi], E]*Subscript[z, I][c])


Subscript[L, F][c_] := (1-Subscript[L, RD][c]) / (1 + ((1-\[Beta])/K)^(1/\[Beta]))


p[c_] := (1-\[Beta])*K*Subscript[L, F][c]


Subscript[\[Tau], E][c_] := (p[c] * Subscript[\[Chi], E]* \[Lambda] / w) + (\[Lambda]-1) * Subscript[\[Tau], I][c] - Subscript[z, I][c]*(c + Subscript[\[Chi], E]*\[Lambda]) - \[Rho]


Subscript[z, E][c_] := Subscript[\[Tau], E][c] / Subscript[\[Chi], E]


g[c_] := (\[Lambda]-1) * (Subscript[\[Tau], I][c] + Subscript[\[Tau], S][c]+Subscript[\[Tau], E][c])


Y[c_] := ((1-\[Beta])^(1-2\[Beta])/\[Beta]^(1-\[Beta]))*Subscript[L, F][c]


V = w / (Subscript[\[Chi], E]*\[Lambda])


w = K


W[c_] := (Y[c] - (Subscript[\[Tau], E][c])*\[Kappa]*V - c*Subscript[z, I][c]*V)/(\[Rho]-g[c])


Subscript[W, 2][c_] := (Y[c] - (Subscript[\[Tau], E][c]+Subscript[\[Tau], S][c])*\[Kappa]*V)/(\[Rho]-g[c])


Simplify[W'[c]]


\[Beta] = .06


K = \[Beta]^\[Beta]*(1-\[Beta])^(1-2*\[Beta])


\[Kappa] = .3


\[Lambda] = 1.1


Subscript[\[Chi], I]=1


Subscript[\[Chi], E]=1


\[Nu] = 0.05


(* ::InheritFromParent:: *)
(*0.05*)


\[Rho] = 0.06


\[Psi] = 0.5


p[c]


Plot[W[c],{c,0,1}]


Plot[Subscript[W, 2][c],{c,0,1}]


(* ::InheritFromParent:: *)
(*Graphics[{{{}, {}, Annotation[{RGBColor[0.368417, 0.506779, 0.709798], AbsoluteThickness[1.6], Opacity[1.], Line[CompressedData["*)
(*1:eJwV0Hs4lHkUB3CkshSGSqNcxlIRv1eWoWTPQUUm7WPisS2VdNmWlEr37TKt*)
(*USsWkfstiUII48nSknRZJqVhqWVomuxgeHVFbWbf/eM83+fzz3nO93BC9/N3*)
(*aaipqfky83/67FJ0NA0FfHtalHxqowuFmp7Gkf1sR5huLMgyZ/xNXnp2NXsN*)
(*tN+91vTWmULe4+6qHLY/SAIFZmmMA3dO3LnE3gmsvFD7AS6FfdR5z3h2FHjW*)
(*ReQccqIwf/53MbHsaPhluDEjz4FCgVb10l/ZKXB75Pp9HTsKv998pWL8TSHo*)
(*+aza5MuhUEclCPYyrYCit2ujGhdQaOU3prh3sQZ6ytom782h8Gj7Skh/XwdO*)
(*R8QDfA0KjWpYUnX1RoiJUIFykmCtzFP8ZHUzNC/ca2BEE2wOy1m0WdkCwWfr*)
(*5j58TfDDEje9mxEPgXtEvmp7H0GNqVL9RVat4H3OufZSJ0GuKqR2U7kYTC53*)
(*CHPFBMXRju0PbJ7Al6G0y3r3CZoljkzdGHsK42FG0SZ3CI5M9Eu77J/BG3cV*)
(*e0xEsHC4vlX3Nwl8kmwz215OUNekmJbLO+FdgIznUEww7ifR7nzLv6BlaDLu*)
(*Vj7Bj1gq33OmGz54HPXuySAY5dBSs+BeDxz0T+grSCbYX95ysYPzAuLdeGXs*)
(*eIKfwzqzrE/8Da3zz5+QxhBc7j57end9L5jauKo7Cwh6FXB+vGUkhRhzKwc8*)
(*SfCoyTaLl8H9kGjJ0+k6TNBWGaDT7TsAttyAquJIgoZ641otnwbAWkixqXCC*)
(*mo1ZFV9nv4TKgroSp90Ewx3rn3/Fk4HtrHW334cQLF0fmv/HRxm4G0gzx4KY*)
(*f44Y6w+mvoKuMN+TwYEERZu8ZqSskcO8Z3qnY/gEz3gL82oG5ZC4VLvfdCNB*)
(*Tp9Pz1Xha9BX5rQNrie4yjk6he0wCBnr363Yt5ZgsOmTKXXJIHCLlhgFuTP7*)
(*W+NlkYJ/ILTjZYS2G8F0za1RfEsFtK3xvGK8krlfKirQaFGAz9MSfX8ngjNP*)
(*CfxXHhiCvg06Mv4Kgmo3tlbIDIZBIDlkX2pH8GBmRbxB8zCoNIRH2qwJ3ll+*)
(*QYu1bwSS5IZphksIsnwO2p7TVcKxF9zj5RYEe+2eSo43KME4reujoRnBylyw*)
(*lG8dBTevSPGjRQS3VHBZJtOjkPk6qDB3IcGzwiuC3pIxWNhWdc59PsGbCpMs*)
(*3Q003Ix1cSYGBC/kCEOkG2lQS6rONWe8kz9qVe5HQ7tiy2xDxosbGip9A2lw*)
(*HIPeCRbB2ISgB3GhNCR9dky5y3gPN+ON9nEaHJKaVgcwtoie5z27iAaNVJ/9*)
(*p/QJTrv8PLf7Og3WJ3b8u5/x89FXz4pKaZjxqCg2lHFiYPWWdbdoSJ9ZVuLF*)
(*WGXDPyRsoCG8rWySxbi3IyF3hoSG1Mpd4iI9grdjJnZIumh4NddwbwbjFNdt*)
(*1ld7aFgWrpgTx5h3jdR4SGnQitPmH2D8+7HHfwqGaJA7LRt2ZZxq55Tgp6Qh*)
(*cjsrmTA+IMv259BMnx84bhzGyzbs7W96T8PzxaKUWYw11TsLEydoqM9w8ZjS*)
(*JTggcg0L+URDPk82PsK4IewqZf+FhsNzqvKljNPMdD6oVDTY1Bb7dTD+D1i2*)
(*Ma8=*)
(*"]]}, "Charting`Private`Tag$1993#1"]}, {}}, AspectRatio -> GoldenRatio^(-1), Axes -> {True, True}, AxesLabel -> {None, None}, AxesOrigin -> {0, 15.028940726969342`}, DisplayFunction -> Identity, Frame -> {{False, False}, {False, False}}, FrameLabel -> {{None, None}, {None, None}}, FrameTicks -> {{Automatic, Charting`ScaledFrameTicks[{Identity, Identity}]}, {Automatic, Charting`ScaledFrameTicks[{Identity, Identity}]}}, GridLines -> {None, None}, GridLinesStyle -> Directive[GrayLevel[0.5, 0.4]], ImagePadding -> All, Method -> {"DefaultBoundaryStyle" -> Automatic, "DefaultGraphicsInteraction" -> {"Version" -> 1.2, "TrackMousePosition" -> {True, False}, "Effects" -> {"Highlight" -> {"ratio" -> 2}, "HighlightPoint" -> {"ratio" -> 2}, "Droplines" -> {"freeformCursorMode" -> True, "placement" -> {"x" -> "All", "y" -> "None"}}}}, "DefaultMeshStyle" -> AbsolutePointSize[6], "ScalingFunctions" -> None, "CoordinatesToolOptions" -> {"DisplayFunction" -> ({(Identity[#]& )[Part[#, 1]], (Identity[#]& )[Part[#, 2]]}& ), "CopiedValueFunction" -> ({(Identity[#]& )[Part[#, 1]], (Identity[#]& )[Part[#, 2]]}& )}}, PlotRange -> {{0, 1}, {15.028940726969342`, 15.609973835259321`}}, PlotRangeClipping -> True, PlotRangePadding -> {{Scaled[0.02], Scaled[0.02]}, {Scaled[0.05], Scaled[0.05]}}, Ticks -> {Automatic, Automatic}]*)


Plot[c*Subscript[z, I][c]*V,{c,0,1}]
