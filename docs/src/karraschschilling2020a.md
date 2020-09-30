# Material barriers in Turbulent flow (Karrasch & Schilling 2020)

We need to use several packages. Below shows to install specific versions that should work. You can also try it without pinnin the specific versions. You'll only need to do this the first time you run this example. Due to julia-specific factors, all commands used here will take much longer the first time they are run.
```julia
import Pkg
Pkg.add("FourierFlows")
Pkg.add("GeophysicalFlows")
Pkg.add("Plots")
Pkg.add("AxisArrays")
Pkg.add(Pkg.PackageSpec(url="https://github.com/KristofferC/JuAFEM.jl.git"))
Pkg.add(Pkg.PackageSpec(url="https://github.com/CoherentStructures/CoherentStructures.jl.git"))
Pkg.add(Pkg.PackageSpec(url="https://github.com/CoherentStructures/OceanTools.jl.git"))
Pkg.pin(Pkg.PackageSpec(name="FourierFlows", version="0.4.1"))
Pkg.pin(Pkg.PackageSpec(name="GeophysicalFlows", version="0.3.3"))
```

## Generating a turbulent velocity field

We begin by importing some packages used later, and by setting up a computational domain.

```julia
using FourierFlows, GeophysicalFlows, GeophysicalFlows.TwoDTurb, Plots, Random
Random.seed!(1234)
mygrid = TwoDGrid(256, 2π)
x, y = gridpoints(mygrid)
xs = ys = range(-π, stop=π, length=257)[1:end-1];
```

To avoid decay of the flow we employ stochastic forcing. The code below is modified from the example given in the [GeophysicalFlows.jl](https://github.com/FourierFlows/GeophysicalFlows.jl) documentation.

```julia
ε = 0.001 # Energy injection rate
kf, dkf = 6, 2.0 # Waveband where to inject energy
Kr = [mygrid.kr[i] for i=1:mygrid.nkr, j=1:mygrid.nl]
force2k = @. exp(-(sqrt(mygrid.Krsq) - kf)^2 / (2 * dkf^2))
force2k[(mygrid.Krsq .< 2.0^2) .| (mygrid.Krsq .> 20.0^2) .| (Kr .< 1) ] .= 0
ε0 = FourierFlows.parsevalsum(force2k .* mygrid.invKrsq/2.0,
                                mygrid) / (mygrid.Lx*mygrid.Ly)
force2k .= ε/ε0 * force2k
function calcF!(Fh, sol, t, cl, args...)
    eta = exp.(2π * im * rand(Float64, size(sol))) / sqrt(cl.dt)
    eta[1,1] = 0
    @. Fh = eta * sqrt(force2k)
    nothing
end
```

We now setup the remaining parameters used in the simulation. We numerically solve the vorticity (transport) equation

$ \partial_t \zeta = - u\cdot \nabla \zeta  -\nu\zeta + f.  $

Here $u(x,y) = (u_1(x,y),u_2(x,y))^T$ is the (incompressible) velocity field, and $\zeta = \partial_x u_2 - \partial_y u_1$ is its vorticity.
The parameter  $\nu$  has the value  $10^{-2}$ and is the coefficient of the drag term, $f$ represents the forcing.

```julia
prob = TwoDTurb.Problem(nx=256, Lx=2π, ν=1e-2, nν=0, dt=1e-2,
    stepper="FilteredRK4", calcF=calcF!, stochastic=true)
TwoDTurb.set_zeta!(prob, GeophysicalFlows.peakedisotropicspectrum(mygrid, 2, 0.5))
```

```julia
using Distributed
addprocs()
using SharedArrays
# we use these variables to store the result
us = SharedArray{Float64}(256, 256, 400)
vs = SharedArray{Float64}(256, 256, 400)
zs = SharedArray{Float64}(256, 256, 400);
```

We run this simulation until $t=500$ to work in a statistically equilibrated state,
and then save the result at time steps of size 0.2.

```julia
@time stepforward!(prob, round(Int, 500 / prob.clock.dt))
@time for i in 1:400
    stepforward!(prob, 20); TwoDTurb.updatevars!(prob)
    vs[:,:,i] = prob.vars.v
    us[:,:,i] = prob.vars.u
    zs[:,:,i] = prob.vars.zeta
end
```

The generation of the velocity field by the above code takes just a few minutes.
Below, we show the vorticity field at $t = 500$.

```julia
heatmap(xs, ys, zs[:,:,1];
    color=:viridis, aspect_ratio=1, xlim=extrema(xs), ylim=extrema(ys))
```

```@raw html
<img src="https://raw.githubusercontent.com/natschil/misc/master/images/turbulence_1.png"/>
```

We first setup a periodic interpolation of the velocity field, using the [OceanTools.jl](https://github.com/CoherentStructures/OceanTools.jl) package.

```julia
@everywhere using CoherentStructures, OceanTools
const CS = CoherentStructures
const OT = OceanTools
ts = range(0.0, step=20prob.clock.dt, length=400)
p2 = OT.ItpMetadata(xs, ys, ts, (us, vs), OT.periodic, OT.periodic, OT.flat);
```

We are now ready to compute material barriers.

```julia
vortices, singularities, bg = CS.materialbarriers(
       uv_trilinear, xs, ys, range(0.0, stop=5.0, length=11),
       LCSParameters(boxradius=π/2, indexradius=0.1, pmax=1.4,
                     merge_heuristics=[combine_20_aggressive]),
       p=p2, on_torus=true);
```

The `materialbarriers` function calculates the transport tensor field $\mathbf{T}$
used in the material-barriers approach (using finite differences for the linearized flow
map $D\Phi$) and calculates material barriers. The result is shown below.


```julia
plot_vortices(vortices, singularities, [-π, -π], [π, π];
    bg=bg, include_singularities=true, barrier_width=4, barrier_color=:red,
    colorbar=:false, aspect_ratio=1)
```

```@raw html
<img src="https://raw.githubusercontent.com/natschil/misc/master/images/turbulence_2.png"/>
```

We plot the vortices found over the vorticity field:
```julia
using AxisArrays
Zs = AxisArray(zs[:,:,1], xs, ys)
plot_vortices(vortices, singularities, [-π, -π], [π, π];
    bg=Zs, logBg=false, include_singularities=false, barrier_width=3, barrier_color=:red,
    colorbar=:false, aspect_ratio=1)
```

```@raw html
<img src="https://raw.githubusercontent.com/natschil/misc/master/images/turbulence_3.png"/>
```

Here they are advected forwards in time:

```julia
vortexflow = vortex -> flow(uv_trilinear, vortex, [0., 5.]; p=p2)[end]
Zs = AxisArray(zs[:,:,26], xs, ys)
plot_vortices(vortexflow.(vortices), singularities, [-π, -π], [π, π];
    bg=Zs, logBg=false, include_singularities=false, barrier_width=3, barrier_color=:red,
    colorbar=:false, aspect_ratio=1)
```

```@raw html
<img src="https://raw.githubusercontent.com/natschil/misc/master/images/turbulence_4.png"/>
```

One of the vortices has been advected so that it is no longer in the field of view of the image, and the plotting function doesn't know that the domain is periodic.
