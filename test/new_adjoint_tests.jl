using DifferentialEquations, SciMLSensitivity, Zygote
using QuadGK
using ForwardDiff
using Interpolations
using Test

# function for computing vector-jacobian products using Zygote
function vjp(func, eval_pt, vec_mul)
    _, func_pullback = pullback(func, eval_pt)
    vjp_result = func_pullback(vec_mul)
    return vjp_result
end

# loss function
function g(u,p,t)
    return sum((u .- 1.0).^2)
end

function lotka_volterra(u, p, t)
    x, y = u
    α, β, δ, γ = p
    dx = α * x - β * x * y
    dy = -δ * y + γ * x * y
    return [dx,dy]
end

function adjoint(u, p, t, sol)
    return -vjp((x)->lotka_volterra(x,p,t), sol(t), u)[1] - Zygote.gradient((x)->g(x,p,t), sol(t))[1]
end

u0 = [1.0, 1.0] #initial condition
tspan = (0.0, 10.0) #simulation time
p = [1.5, 1.0, 3.0, 1.0] # Lotka-Volterra parameters
prob = ODEProblem(lotka_volterra, u0, tspan, p)
sol = solve(prob, Tsit5(), abstol = 1e-14, reltol = 1e-14)

# total loss functional
function G(p)
    tmp_prob = remake(prob, p = p)
    sol = solve(tmp_prob, Tsit5(), abstol = 1e-14, reltol = 1e-14)
    res, = quadgk((t) -> g(sol(t),p,t), tspan[1], tspan[2], atol = 1e-14, rtol = 1e-10)
    return res
end

dGdp_ForwardDiff = ForwardDiff.gradient(G, p) 

integrand_values = IntegrandValues(Float64, Vector{Float64})
function callback_saving(u,t,integrator,sol)
    temp = sol(t)
    return vjp((x)->lotka_volterra(temp,x,t),integrator.p,u)[1]
end
cb = NewAdjointCallback((u,t,integrator)->callback_saving(u,t,integrator,sol), integrand_values; tdir=-1)
prob_adjoint = ODEProblem((u,p,t)->adjoint(u,p,t,sol), [0.0,0.0], (tspan[end],tspan[1]), p, callback = cb)
sol_adjoint = solve(prob_adjoint, Tsit5(), abstol = 1e-14, reltol = 1e-14)

function compute_dGdp(integrand,tspan)
    temp = zeros(length(integrand.t),4)
    for i in 1:length(integrand.t)
        for j in 1:length(integrand.integrand[1])
            temp[i,j] = integrand.integrand[i][j]
        end
    end
    res = zeros(length(integrand.integrand[1]))
    for i in 1:length(integrand.integrand[1])
        interp_linear = linear_interpolation(integrand_values.t[end:-1:1], temp[end:-1:1,i])
        res[i] = quadgk(interp_linear, tspan[1], tspan[2], atol = 1e-14, rtol = 1e-10)[1]
    end
    return res
end

dGdp_new = compute_dGdp(integrand_values,tspan)

@test isapprox(dGdp_ForwardDiff, dGdp_new, atol = 1e-4, rtol = 1e-4)

