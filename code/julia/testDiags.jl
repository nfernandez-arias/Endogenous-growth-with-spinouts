
anim = @animate for i = 1:length(w_diag[1,:])
    plot(mGrid,[w_diag[:,i] EndogenousGrowthWithSpinouts.wbarFunc(modelPar.β) * ones(size(mGrid))], labels = ["R&D wage: iterate $i" "Production wage"], ylims = (min(0,1.5 * minimum(w_diag)),1.5 * maximum(w_diag)), legend = :bottomright)
end
gif(anim,"figures/plotsGR/w_animation.gif",fps = 5)

anim = @animate for i = 1:length(V_diag[1,:])
    plot(mGrid,V_diag[:,i], ylims = (min(0,1.2 * minimum(V_diag)),1.2 * maximum(V_diag)), label = "V(m): iterate $i")
end
gif(anim,"figures/plotsGR/V_animation.gif",fps = 5)

anim = @animate for i = 1:length(W_diag[1,:])
    plot(mGrid,W_diag[:,i], ylims = (min(0,1.2 * minimum(W_diag)), 1.2  * maximum(W_diag)), label = "W(m): iterate $i")
end
gif(anim,"figures/plotsGR/W_animation.gif",fps = 5)


anim = @animate for i = 1:length(μ_diag[1,:])
    plot(mGrid,μ_diag[:,i], label = "mu(m): iterate $i")
end
gif(anim,"figures/plotsGR/μ_animation.gif",fps = 5)

plot(1:length(g_diag[:]),g_diag[:])
png("figures/plotsGR/g_diagnostic.png")

plot(1:length(L_RD_diag[:]),L_RD_diag[:])
png("figures/plotsGR/L_RD_diagnostic.png")
