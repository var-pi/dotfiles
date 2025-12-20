if Base.isinteractive()
    try
        using Revise
    catch e
        @warn "Revise not found in current environment stack."
    end
end
