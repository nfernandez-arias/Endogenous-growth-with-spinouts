module TestModule

using TestModule2

export testFunction, f

function testFunction(x)

    return x^2

end

function f(x)

    return g(x)

end

end
