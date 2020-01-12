#=
TODO: This partial derivative extraction should be doable without the extra
temporaries utilized here, but AFAICT such an approach is hard to write
without relying on inference hacks unless we have something akin to
https://github.com/JuliaLang/julia/issues/22129.
=#
function _cast_diff(f, x)
    function element_rule(u)
        dself = Zero()
        fu, du = frule(f, u, dself, One())
        fu, extern(du)
    end
    results = broadcast(element_rule, x)
    return first.(results), last.(results)
end

function frule(::typeof(broadcast), f, x, _, Δf, Δx)
    Ω, ∂x = _cast_diff(f, x)
    return Ω, Δx .* ∂x
end

function rrule(::typeof(broadcast), f, x)
    values, derivs = _cast_diff(f, x)
    function broadcast_pullback(ΔΩ)
        return (NO_FIELDS, DoesNotExist(), @thunk(ΔΩ .* derivs))
    end
    return values, broadcast_pullback
end
