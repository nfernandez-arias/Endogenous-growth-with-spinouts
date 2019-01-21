using Optim

function f(x)

    println(x)
    x[1]^2 + 2x[1] * x[2] + 2*x[2]^2

end

function optimize_function(f,x0,lower,upper)

    inner_optimizer = GradientDescent()
    #results = optimize(f,lower,upper,x0,Fminbox(inner_optimizer),Optim.Options(iterations = 1,store_trace = false, show_trace = false))
    results = optimize(f,x0,method = inner_optimizer,iterations = 0)

end

x0 = zeros(2)
lower = zeros(2)
upper = zeros(2)

x0[1] = 1
x0[2] = 4

lower[1] = -5
lower[2] = -5

upper[1] = 5
upper[2] = 5

results = optimize_function(f,x0,lower,upper)
