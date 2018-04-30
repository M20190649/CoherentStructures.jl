#(c) 2017 Nathanael Schilling
#Various utility functions


"""
    arraymap!(du::Array{Float64},u::AbstractArray{Float64,1},p,t,odefun,howmanytimes::Int,basesize::Int)

Like `map', but operates on 1d-datastructures.
# Arguments
Apply odefun(du,u,p,t) consecutively to `howmany` subarrays of size `basesize` of `u`, and stores
the result in the relevant slice of `du`.
This is so that a "diagonalized" ODE with several starting values can
be solved without having to call the ODE solver multiple times.
"""
@inline function arraymap!(du::Array{Float64},u::Array{Float64},p,t::Float64, odefun::Function,howmanytimes::Int64,basesize::Int64)
    @inbounds for i in 1:howmanytimes
        @views @inbounds  odefun(du[1 + (i - 1)*basesize: i*basesize],u[ 1 + (i-1)*basesize:  i*basesize],p,t)
    end
end

# TODO: this is plainly assuming 2D-systems, generalize to ND-systems
@inline @inbounds function arraymap(u::StaticArrays.SVector{8,Float64},p,t::Float64, odefun::Function)::StaticArrays.SVector{8,Float64}
    p1::StaticArrays.SVector{2,Float64} = odefun((StaticArrays.@SVector Float64[u[1], u[2]]),p,t)
    p2::StaticArrays.SVector{2,Float64} = odefun((StaticArrays.@SVector Float64[u[3], u[4]]),p,t)
    p3::StaticArrays.SVector{2,Float64} = odefun((StaticArrays.@SVector Float64[u[5], u[6]]),p,t)
    p4::StaticArrays.SVector{2,Float64} = odefun((StaticArrays.@SVector Float64[u[7], u[8]]),p,t)
    StaticArrays.@SVector [p1[1],p1[2],p2[1],p2[2],p3[1],p3[2],p4[1],p4[2]]
end

"""
    tensor_invariants(T::AbstractArray{Tensors.SymmetricTensor})

computes pointwise invariants of the 2D tensor field `T`, i.e.,
smallest and largest eigenvalues, corresponding eigenvectors, trace and determinant.
"""

function tensor_invariants(T::AbstractArray{Tensors.SymmetricTensor{2,2,S,3}}) where S <: Real
    Efact = eigfact.(T)
    λ₁ = [ev[1] for ev in eigvals.(Efact)]
    λ₂ = [ev[2] for ev in eigvals.(Efact)]
    ξ₁ = [ev[:,1] for ev in eigvecs.(Efact)]
    ξ₂ = [ev[:,2] for ev in eigvecs.(Efact)]
    traceT = trace.(T)
    detT = det.(T)
    return λ₁, λ₂, ξ₁, ξ₂, traceT, detT
end


"""
    dof2U(ctx,u)

Interprets `u` as an array of coefficients ordered in dof order,
and reorders them to be in node order.
"""
function dof2U(ctx::abstractGridContext{dim} ,u::Vector) where {dim}
   n = ctx.n
   res = fill(0.0,getnnodes(ctx.grid))
   for node in 1:n
           res[node] = u[ctx.node_to_dof[node]]
      end
  return res
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
res = kmeans(v[:,1:numclusters]',numclusters+1)
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
e1 = basevec(Vec{2},1)
e2 = basevec(Vec{2},2)




function rawInvCGTensor(args...;kwargs...)
    result = invCGTensor(args...;kwargs...)
    return result[1,1], result[1,2],result[2,2]
end


function AFromPrecomputedRaw(x,index,q)
    @views return SymmetricTensor{2,2}((q[1])[3*(index-1)+1 : 3*(index-1)+3])
end


#The rhs for an ODE on interpolated vector fields
#The interpolant is passed via the p argument

#TODO: think of adding @inbounds here
function interp_rhs!(du::AbstractArray{T},u::AbstractArray{T},p,t::T) where {T <: Real}
    du[1] = p[1][u[1],u[2],t]
    du[2] = p[2][u[1],u[2],t]
end

function interp_rhs(u,p,t)
    du1 = p[1][u[1],u[2],t]
    du2 = p[2][u[1],u[2],t]
    return SVector{2}(du1, du2)
end

#Returns true for all inputs. This is the default function for inbounds checking in plot_ftle
function always_true(x,y,p)
    return true
end
