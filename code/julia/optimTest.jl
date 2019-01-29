using Optim
rosenbrock(x) =  (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2

struct MyType

    value::Vector{Float64}

end

function rosenbrock2(x)

    # Construct instance of my type
    typeInstance = MyType(x)

    return (1.0 - typeInstance.value[1])^2 + 100.0 * (typeInstance.value[2] - typeInstance.value[1]^2)^2

end

result = optimize(rosenbrock2, zeros(2), BFGS())

println("$result")
