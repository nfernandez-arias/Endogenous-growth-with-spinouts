    N = 10

    iGrid = 1:1:N

    start = 2

    bvec = zeros(size(iGrid))

    try

        for i = start:start+N-1
            bvec[i] = iGrid[i]
        end

    catch err

        if isa(err,BoundsError)

            start = 1

            #print(start)

            for i = start:start+N-1
                bvec[i] = iGrid[i]
            end

        end

    finally

        print(bvec)

    end
