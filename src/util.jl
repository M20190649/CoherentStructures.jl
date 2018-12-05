#(c) 2017 Nathanael Schilling & Daniel Karrasch
#Various utility functions

"""
    abstract type AbstractField
"""
abstract type AbstractField{dim, Ta, Tv} <: AbstractArray{Tv, dim} end

Base.getindex(F::AbstractField, inds::Vararg{Int,N}) where {N} = getindex(getfield(F, 2), inds...)
Base.setindex!(F::AbstractField, val, inds::Vararg{Int,N}) where {N}= setindex!(getfield(F, 2), val, inds...)
Base.size(F::AbstractField) = size(getfield(F, 2))
Base.length(F::AbstractField) = length(getfield(F, 2))
# Base.iterate(F::AbstractField) = iterate(getfield(F, 2))
Base.showarg(io::IO, F::AbstractField{dim}, toplevel) where {dim} =
    print(io, "$dim-dimensional ", typeof(F))
Base.BroadcastStyle(::Type{T}) where {T <:AbstractField} = Broadcast.ArrayStyle{T}()
function Base.similar(bc::Broadcast.Broadcasted{Broadcast.ArrayStyle{T}}, ::Type{ElType}) where {ElType, T <:AbstractField}
    # Scan the inputs for an AbstractField:
    A = find_af(bc)
    typeof(A)(A.grid_axes, similar(Array{ElType}, axes(bc)))
end

# find_af returns the first AbstractField among the arguments
find_af(bc::Base.Broadcast.Broadcasted) = find_af(bc.args)
find_af(args::Tuple) = find_af(find_af(args[1]), Base.tail(args))
find_af(x) = x
find_af(a::AbstractField, rest) = a
find_af(::Any, rest) = find_af(rest)
# TODO: define trace, determinant, dot as ScalarFields

"""
    restrict(F::AbstractField, center::SVector, r::Real)

Restrict an `AbstractField` to a cube of length `2r` centered at `center.

Currently implemented only for 2-dimensional fields.
"""
function restrict(F::AbstractField{dim}, center::SVector{dim}, r::Real) where dim
    subindices = restrict_axes(F.grid_axes, center.data, r)
    typeof(F)(getindex.(F.grid_axes, subindices), F[subindices...])
end
function restrict_axes(grid_axes, center, r)
    current_axis = first(grid_axes)
    current_center = first(center)
    init = findfirst(x -> x >= current_center - r, current_axis)
    final = findlast(x -> x <= current_center + r, current_axis)
    return (init:final, restrict_axes(Base.tail(grid_axes), Base.tail(center), r)...)
end
restrict_axes(::Tuple{}, ::Tuple{}, r) = ()

function ITP.LinearInterpolation(F::AbstractField)
    @assert !isa(F, LineField) "LineField cannot be interpolated"
    ITP.scale(ITP.interpolate(getfield(F, 2), ITP.BSpline(ITP.Linear())), F.grid_axes...)
end
function ITP.CubicSplineInterpolation(F::AbstractField)
    @assert !isa(F, LineField) "LineField cannot be interpolated"
    ITP.scale(ITP.interpolate(getfield(F, 2), ITP.BSpline(ITP.Cubic(ITP.Natural(ITP.OnGrid())))),
                        F.grid_axes...)
end

"""
    struct ScalarField <: AbstractField{dim, Ta, Tv}
"""
struct ScalarField{dim, Ta <: AbstractRange{<:Real}, Tv <: Real} <: AbstractField{dim, Ta, Tv}
    grid_axes::NTuple{dim, Ta}
    vals::Array{Tv, dim}

    function ScalarField(grid_axes::NTuple{dim, Ta}, vals::Array{Tv, dim}) where {dim, Ta <: AbstractRange{<:Real}, Tv <: Real}
        @assert length.(grid_axes) == size(vals) "lengths of axes does not match size of array"
        new{dim, Ta, Tv}(grid_axes, vals)
    end
end

"""
    struct VectorField <: AbstractField{dim, Ta, Tv}
"""
struct VectorField{dim, Ta <: AbstractRange{<:Real}, Tv <: SVector{dim,<:Real}}  <: AbstractField{dim, Ta, Tv}
    grid_axes::NTuple{dim,Ta}
    vecs::Array{Tv, dim}

    function VectorField(grid_axes::NTuple{dim, Ta}, vecs::Array{Tv, dim}) where {dim, Ta <: AbstractRange{<:Real}, Tv <: SVector{dim,<:Real}}
        @assert length.(grid_axes) == size(vecs) "lengths of axes does not match size of array"
        new{dim, Ta, Tv}(grid_axes, vecs)
    end
end

"""
    struct LineField <: AbstractField{dim, Ta, Tv}
"""
struct LineField{dim, Ta <: AbstractRange{<:Real}, Tv <: SVector{dim,<:Real}}  <: AbstractField{dim, Ta, Tv}
    grid_axes::NTuple{dim,Ta}
    vecs::Array{Tv, dim}

    function LineField(grid_axes::NTuple{dim, Ta}, vecs::Array{Tv, dim}) where {dim, Ta <: AbstractRange{<:Real}, Tv <: SVector{dim,<:Real}}
        @assert length.(grid_axes) == size(vecs) "lengths of axes does not match size of array"
        new{dim, Ta, Tv}(grid_axes, vecs)
    end
end

"""
    struct TensorField <: AbstractField{dim, Ta, Tv}
"""
struct TensorField{dim, Ta <: AbstractRange{<:Real}, Tv <: Tensor{dim,2,<:Real,N} where N}  <: AbstractField{dim, Ta, Tv}
    grid_axes::NTuple{dim,Ta}
    tensors::Array{Tv, dim}

    function TensorField(grid_axes::NTuple{dim, Ta}, tensors::Array{Tv, dim}) where {dim, Ta <: AbstractRange{<:Real}, Tv <: Tensor{dim,2,<:Real,N} where N}
        @assert length.(grid_axes) == size(tensors) "lengths of axes does not match size of array"
        new{dim, Ta, Tv}(grid_axes, tensors)
    end
end

"""
    struct SymmetricTensorField <: AbstractField{dim, Ta, Tv}
"""
struct SymmetricTensorField{dim, Ta <: AbstractRange{<:Real}, Tv <: SymmetricTensor{dim,2,<:Real,N} where N}  <: AbstractField{dim, Ta, Tv}
    grid_axes::NTuple{dim,Ta}
    tensors::Array{Tv, dim}

    function SymmetricTensorField(grid_axes::NTuple{dim, Ta}, tensors::Array{Tv, dim}) where {dim, Ta <: AbstractRange{<:Real}, Tv <: SymmetricTensor{dim,2,<:Real,N} where N}
        @assert length.(grid_axes) == size(tensors) "lengths of axes does not match size of array"
        new{dim, Ta, Tv}(grid_axes, tensors)
    end
end

"""
    arraymap!(du, u, p, t, odefun, N, dim)

Like `map`, but operates on 1d-datastructures.

# Arguments
Apply `odefun` consecutively to `N` subarrays of size `dim` of `u`, and store
the result in the corresponding slice of `du`.
This is so that a decoupled ODE system with several initial values can
be solved without having to call the ODE solver multiple times.
"""
@inline function arraymap!(du::Vector, u::Vector, p, t,
                            odefun, N::Int, dim::Int)
    @inbounds for i in 1:N
        @views odefun(du[1+(i - 1)*dim:i*dim], u[1+(i-1)*dim:i*dim], p, t)
    end
end

"""
    arraymap2(u, p, t, odefun) -> SVector{8}
This function is like `arraymap!(du, u, p, t, odefun, 4, 2)``,
but `du` is returned as a StaticVector.
"""
@inline function arraymap2(u::SVector{10,T}, p, t, odefun)::SVector{10,T} where T
    p0::SVector{2,T} = odefun(SVector{2,T}(u[1], u[2]), p, t)
    p1::SVector{2,T} = odefun(SVector{2,T}(u[3], u[4]), p, t)
    p2::SVector{2,T} = odefun(SVector{2,T}(u[5], u[6]), p, t)
    p3::SVector{2,T} = odefun(SVector{2,T}(u[7], u[8]), p, t)
    p4::SVector{2,T} = odefun(SVector{2,T}(u[9], u[10]), p, t)
    return SVector{10,T}(p0[1], p0[2], p1[1], p1[2], p2[1], p2[2], p3[1], p3[2], p4[1], p4[2])
end

"""
    arraymap3(u, p, t, odefun) -> SVector{21}
This function is like `arraymap!(du, u, pt, odefun, 7, 3)
but `du` is returned as a StaticVector.
"""
@inline function arraymap3(u::SVector{21,T}, p, t, odefun)::SVector{21,T} where T
    p0::SVector{3,T} = odefun(SVector{3}(u[1], u[2], u[3]), p, t)
    p1::SVector{3,T} = odefun(SVector{3}(u[4], u[5], u[6]), p, t)
    p2::SVector{3,T} = odefun(SVector{3}(u[7], u[8], u[9]), p, t)
    p3::SVector{3,T} = odefun(SVector{3}(u[10], u[11], u[12]), p, t)
    p4::SVector{3,T} = odefun(SVector{3}(u[13], u[14], u[15]), p, t)
    p5::SVector{3,T} = odefun(SVector{3}(u[16], u[17], u[18]), p, t)
    p6::SVector{3,T} = odefun(SVector{3}(u[19], u[20], u[21]), p, t)
    return SVector{21,T}(p0[1], p0[2], p0[3],
                         p1[1], p1[2], p1[3], p2[1], p2[2], p2[3],
                         p3[1], p3[2], p3[3], p4[1], p4[2], p4[3],
                         p5[1], p5[2], p5[3], p6[1], p6[2], p6[3])
end

"""
    tensor_invariants(T) -> λ₁, λ₂, ξ₁, ξ₂, traceT, detT

Returns pointwise invariants of the 2D symmetric tensor field `T`, i.e.,
smallest and largest eigenvalues, corresponding eigenvectors, trace and determinant.
# Example
```
T = [SymmetricTensor{2,2}(rand(3)) for i in 1:10, j in 1:20]
λ₁, λ₂, ξ₁, ξ₂, traceT, detT = tensor_invariants(T)
```
All output variables have the same array arrangement as `T`; e.g., `λ₁` is a
10x20 array with scalar entries.
"""
function tensor_invariants(T::SymmetricTensor{2,2,S,3}) where S <: Real
    E = eigen(T)
    λ₁ = eigvals(E)[1]
    λ₂ = eigvals(E)[2]
    ξ₁ = SVector{2}(eigvecs(E)[:,1])
    ξ₂ = SVector{2}(eigvecs(E)[:,2])
    traceT = tr(T)
    detT = det(T)
    return λ₁, λ₂, ξ₁, ξ₂, traceT, detT
end
function tensor_invariants(T::SymmetricTensorField{2})
    E = eigen.(T.tensors)
    evals = eigvals.(E)
    λ₁ = ScalarField(T.grid_axes, [ev[1] for ev in evals])
    λ₂ = ScalarField(T.grid_axes, [ev[2] for ev in evals])
    evecs = eigvecs.(E)
    ξ₁ = LineField(T.grid_axes, [SVector{2}(ev[:,1]) for ev in evecs])
    ξ₂ = LineField(T.grid_axes, [SVector{2}(ev[:,2]) for ev in evecs])
    traceT = ScalarField(T.grid_axes, tr.(T.tensors))
    detT = ScalarField(T.grid_axes, det.(T.tensors))
    return λ₁, λ₂, ξ₁, ξ₂, traceT, detT
end

"""
    dof2node(ctx,u)

Interprets `u` as an array of coefficients ordered in dof order,
and reorders them to be in node order.
"""
function dof2node(ctx::abstractGridContext{dim}, u::Vector) where {dim}
   # n = ctx.n
   # res = fill(0.0, JuAFEM.getnnodes(ctx.grid))
   # for node in 1:n
   #         res[node] = u[ctx.node_to_dof[node]]
   #    end
   # TODO: isn't this just reordering? ctx.n == getnnodes(ctx.grid) by construction
  return u[ctx.node_to_dof[1:ctx.n]]
end

"""
    kmeansresult2LCS(kmeansresult)

Takes the result-object from kmeans(),
and returns a coefficient vector (in dof order)
corresponding to (interpolated) indicator functions.

# Example
```
v, λ = eigs(K,M)
numclusters = 5
res = kmeans(permutedims(v[:,1:numclusters]),numclusters+1)
u = kmeansresult2LCS(res)
plot_u(ctx,u)
```
"""
function kmeansresult2LCS(kmeansresult)
    n = length(kmeansresult.assignments)
    numclusters = size(kmeansresult.centers)[2]
    u = zeros(n,numclusters)
    for j in 1:n
        for i in 1:numclusters
            u[j,i] = kmeansresult.assignments[j] == i ? 1.0 : 0.0
        end
    end
    return u
end


#Unit Vectors in R^2
const e1 = Tensors.basevec(Vec{2}, 1)
const e2 = Tensors.basevec(Vec{2}, 2)

function rawInvCGTensor(args...; kwargs...)
    result = invCGTensor(args...; kwargs...)
    return result[1,1], result[1,2], result[2,2]
end

function AFromPrecomputedRaw(x, index, q)
    @views return SymmetricTensor{2,2}((q[1])[3*(index-1)+1 : 3*(index-1)+3])
end


#Returns true for all inputs. This is the default function for inbounds checking in plot_ftle
function always_true(x,y,p)
    return true
end


"""
    getH(ctx)

Return the mesh width of a regular grid.
"""
function getH(ctx::abstractGridContext)
    supportedRegularGridTypes = ["regular triangular grid",
                    "regular P2 triangular grid",
                    "regular Delaunay grid",
                    "regular P2 Delaunay grid",
                    "regular quadrilateral grid",
                    "regular P2 quadrilateral grid",
                    ]

    supported1DGridTypes = ["regular 1d grid",
                    "regular 1d P2 grid"]

    if ctx.gridType ∈ supportedRegularGridTypes
        hx = (ctx.spatialBounds[2][1] - ctx.spatialBounds[1][1])/(ctx.numberOfPointsInEachDirection[1] - 1)
        hy = (ctx.spatialBounds[2][2] - ctx.spatialBounds[1][2])/(ctx.numberOfPointsInEachDirection[1] - 1)

        return sqrt(hx^2 + hy^2)
    elseif ctx.gridType ∈ supported1DGridTypes
        hx = (ctx.spatialBounds[2][1] - ctx.spatialBounds[2][1])/(ctx.numberOfPointsInEachDirection[1] - 1)
        return hx
    else
        error("Mesh width for this grid type not yet implemented")
    end
end


#divrem that returns the first value as an Int
#TODO: maybe optimize this?
function gooddivrem(x, y)
        a, b = divrem(x, y)
        return Int(a), b
end

function goodmod(a, b)
    return Base.mod(a, b)
end


function gooddivrem(x::ForwardDiff.Dual, y)
        a, b = divrem(x, y)
        if !iszero(b)
            return Int(ForwardDiff.value(a)), b
        else
            aret = Int(ForwardDiff.value(a))
            return aret, x - aret * y
        end
end


function goodmod(x::ForwardDiff.Dual, y)
    a,b = gooddivrem(x, y)
    if b < 0
        return b + y
    else
        return b
    end
end

#TODO: Document this
 function unzip(A::Array{T}) where T
    res = map(x -> x[], T.parameters)
    res_len = length(res)
    for t in A
        for i in 1:res_len
            push!(res[i], t[i])
        end
    end
    res
end


"""
    periodic_diff(x, y, p)

Return the number `z` with minimum absolute value so that `y + z ≡ x (mod p)``.
"""
function periodic_diff(xin, yin, p)
    x = Base.mod(xin, p)
    y = Base.mod(yin, p)
    if x >= y
        dplus = x - y
        dminus = y - (x - p)
        result = abs(dplus) < abs(dminus) ? dplus : -dminus
    else
        result = -periodic_diff(y, x, p)
    end
    #@assert Base.mod(yin + result - xin,p) == 0.0
    return result
end
