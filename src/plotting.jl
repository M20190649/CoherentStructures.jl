using GR
using Tensors

include("util.jl")


#TODO: Make this also work for P2-Lagrange
#TODO: Make this much more efficient
function plot_u(ctx::gridContext,dof_values::Vector{Float64},nx=50,ny=50,LL=Vec{2}([0.0,0.0]),UR=Vec{2}([1.0,1.0]))
    x1 = Float64[]
    x2 = Float64[]
    values = Float64[]
    const u_values =  dof2U(ctx,dof_values)
    for y in linspace(LL[2] + 1e-8, UR[2] -1.e-8,ny)
        for x in linspace(LL[1] + 1.e-8,UR[1]-1.e-8,nx)
            push!(x1,x)
            push!(x2,y)
            current_point = Vec{2}([x,y])
            push!(values, evaluate_function(ctx, Vec{2}(current_point),u_values))
        end
    end
    #Plots.plot(x1,x2,values;t=:contourf)#,colormap=GR.COLORMAP_JET)
    GR.contourf(x1,x2,values,colormap=GR.COLORMAP_JET)
end


function plot_spectrum(λ)
    GR.plot(real.(λ),imag.(λ),"x")
end