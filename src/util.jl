#(c) 2017 Nathanael Schilling
#Various utility functions


#The following function is like `map', but operates on 1d-datastructures.
#@param t::Float64 is just some number
#@param x::Float64 must have howmanytimes*basesize elements
#@param myfun is a function that takes arguments (t, x, result)
#     where t::Float64, x is an Array{Float64} of size basesize,
#       and result::Array{Float64} is of size basesize
#       myfun is assumed to return the result into the result array passed to it
#This function applies myfun consecutively to slices of x, and stores
#the result in the relevant slice of result.
#This is so that a "diagonalized" ODE with several starting values can
#be solved without having to call the ODE multiple times.
@everywhere @inline function arraymap(myfun,howmanytimes::Int64,basesize::Int64,t::Float64,x::Array{Float64},result::Array{Float64})
    @inbounds for i in 1:howmanytimes
        @views @inbounds  myfun(t,x[ 1 + (i-1)*basesize:  i*basesize],result[1 + (i - 1)*basesize: i*basesize])
    end
end

#Reorders an array of values corresponding to dofs from a DofHandler
#To the order which the nodes of the grid would be
function dof2U(ctx::abstractGridContext{dim} ,u::Vector) where {dim}
   n = ctx.n
   res = fill(0.0,getnnodes(ctx.grid))
   for node in 1:n
           res[node] = u[ctx.node_to_dof[node]]
      end
  return res
end


#Unit Vectors in R^2
e1 = basevec(Vec{2},1)
e2 = basevec(Vec{2},2)

