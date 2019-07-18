using Optim

function f(x)

    log_file = open("figures/Optim_Bug_Example_Log.txt","a")

    write(log_file,"Iteration: x1 = $(x[1]); x2 = $(x[2])\n")

    close(log_file)

    return x[1] + x[2]^2 - 1

end


initial_x = [0.0 0.0]

lower = [-0.5 -0.5]
upper = [1.5 1.5]


inner_optimizer = LBFGS()

#results = optimize(f,lower,upper,initial_x,Fminbox(inner_optimizer),Optim.Options(iterations = 0, store_trace = true, show_trace = true))

results = optimize(f,initial_x,inner_optimizer,Optim.Options(iterations = 0, store_trace = true, show_trace = true))
