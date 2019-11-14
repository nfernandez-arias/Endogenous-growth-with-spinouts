
fpsSetting = 4

anim = @animate for i = 1:length(w_diag[1,:])
    plot(mGrid,[w_diag[:,i] EndogenousGrowthWithSpinouts.wbarFunc(modelPar.β) * ones(size(mGrid))], labels = ["R&D wage: iterate $i" "Production wage"], ylims = (min(0,1.5 * minimum(w_diag)),1.5 * maximum(w_diag)), legend = :bottomright)
end
gif(anim,"figures/plotsGR/w_animation.gif",fps = fpsSetting)

#num = 3710
#V_diag_trunc = V_diag[1:num,:]

anim = @animate for i = 1:length(V_diag[1,:])
    plot(mGrid,V_diag[:,i], ylims = (min(0,1.2 * minimum(V_diag[:,i])),1.2 * maximum(V_diag[:,i])), label = "V(m): outer loop iterate $i")
end
gif(anim,"figures/plotsGR/V_animation.gif",fps = fpsSetting)

V_diag_transformed = log.(abs.(V_diag) .+ 1)

anim = @animate for i = 1:length(V_diag_transformed[1,:])
    plot(mGrid,V_diag_transformed[:,i], ylims = (min(0,1.2 * minimum(V_diag_transformed)),1.2 * maximum(V_diag_transformed)), label = "log(abs(V(m))+1): outer loop iterate $i")
end
gif(anim,"figures/plotsGR/V_logish_animation.gif",fps = fpsSetting)



anim = @animate for i = 1:length(V_diag_inner[1,:])
    plot(mGrid,V_diag_inner[:,i], ylims = (min(0,1.2 * minimum(V_diag_inner)),1.2 * maximum(V_diag_inner)), label = "V(m): idxM loop iterate $i")
end
gif(anim,"figures/plotsGR/V_inner_animation.gif",fps = fpsSetting)


anim = @animate for i = 1:length(W_diag[1,:])
    plot(mGrid,W_diag[:,i], ylims = (min(0,1.2 * minimum(W_diag)), 1.2  * maximum(W_diag)), label = "W(m): iterate $i")
end
gif(anim,"figures/plotsGR/W_animation.gif",fps = fpsSetting)


anim = @animate for i = 1:length(μ_diag[1,:])
    plot(mGrid,μ_diag[:,i], label = "mu(m): iterate $i")
end
gif(anim,"figures/plotsGR/μ_animation.gif",fps = fpsSetting)

plot(1:length(g_diag[:]),g_diag[:])
png("figures/plotsGR/g_diagnostic.png")

plot(1:length(L_RD_diag[:]),L_RD_diag[:])
png("figures/plotsGR/L_RD_diagnostic.png")

plot(1:length(idxM_diag_inner[:]),idxM_diag_inner[:])
png("figures/plotsGR/idxM_inner_diagnostic.png")
