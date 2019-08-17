
using Optim

χI = 3
ψI = 0.5
ϕI(z) = z^-ψI
λ = 1.0532733
V0 = 0.8522423425
zE = 0.5986

wRD = 0.72166623555


objective1(z) = -(z * χI * ϕI(z + zE)  *  (λ-1) * V0 - z * ( wRD ))
objective2(z) = -1 * objective1(z)

lower = 0.01
upper = 100

plot(0:0.01:0.1,objective1,title = "objective1")
png("/home/nico/Desktop/objective1.png")
plot(0:0.01:0.1,objective2, title = "objective2")
png("/home/nico/Desktop/objective2.png")

results1 = optimize(objective1,lower,upper)

results2 = optimize(objective2,lower,upper)
