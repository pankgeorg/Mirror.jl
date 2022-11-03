module Mirror

export callwith

function method_argnames(m::Method)
    argnames = ccall(:jl_uncompress_argnames, Vector{Symbol}, (Any,), m.slot_syms)
    isempty(argnames) && return argnames
    return argnames[1:m.nargs]
end

macro namedtuplefromsignature(ex, extracontext)
    quote
        symbols = collect(method_argnames($ex))[2:end]
        types = collect(($ex).sig.types)[2:end]
        NamedTuple{Tuple(symbols),Tuple{((types...))}}
    end
end

function callwith(fn::Function, json::String, extracontext::Vector{Pair{Symbol, Any}})
    args = nothing

    types = [@namedtuplefromsignature(m, extracontext) for m in methods(fn)]
    for t in types
        try
            args = JSON3.read(json, t)
            break
        catch
        end
    end

    if isnothing(args)
        e = APIArgumentError("Could not parse the arguments into any of the function's arguments")
        applicable(fn, APIArgumentError) && return fn(e)
        throw(e)
    end
    return fn(args)
end

struct APIArgumentError <: Exception
    reason::String
end

end  # Module
