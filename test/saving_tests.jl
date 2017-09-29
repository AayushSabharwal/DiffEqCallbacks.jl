using Base.Test, OrdinaryDiffEq, DiffEqProblemLibrary, DiffEqCallbacks

# save_everystep, scalar problem
prob = prob_ode_linear
saved_values = SavedValues(Float64, Float64)
cb = SavingCallback((t,u,integrator)->u, saved_values)
sol = solve(prob, Tsit5(), callback=cb)
@test all(idx -> sol.t[idx] == saved_values.t[idx], eachindex(saved_values.t))
@test all(idx -> sol.u[idx] == saved_values.saveval[idx], eachindex(saved_values.t))

# save_everystep, inplace problem
prob2D = prob_ode_2Dlinear
saved_values = SavedValues(eltype(prob2D.tspan), typeof(prob2D.u0))
cb = SavingCallback((t,u,integrator)->copy(u), saved_values)
sol = solve(prob2D, Tsit5(), callback=cb)
@test all(idx -> sol.t[idx] .== saved_values.t[idx], eachindex(saved_values.t))
@test all(idx -> all(sol.u[idx] .== saved_values.saveval[idx]), eachindex(saved_values.t))

saved_values = SavedValues(eltype(prob2D.tspan), eltype(prob2D.u0))
cb = SavingCallback((t,u,integrator)->u[1], saved_values)
sol = solve(prob2D, Tsit5(), callback=cb)
@test all(idx -> sol.t[idx] == saved_values.t[idx], eachindex(saved_values.t))
@test all(idx -> sol.u[idx][1] == saved_values.saveval[idx], eachindex(saved_values.t))

# saveat, scalar problem
saved_values = SavedValues(Float64, Float64)
saveat = linspace(prob.tspan..., 10)
cb = SavingCallback((t,u,integrator)->u, saved_values, saveat=saveat)
sol = solve(prob, Tsit5(), callback=cb)
@test all(idx -> saveat[idx] == saved_values.t[idx], eachindex(saved_values.t))
@test all(idx -> abs(sol(saveat[idx]) - saved_values.saveval[idx]) < 5.e-15, eachindex(saved_values.t))

# saveat, inplace problem
saved_values = SavedValues(eltype(prob2D.tspan), typeof(prob2D.u0))
saveat = linspace(prob2D.tspan..., 10)
cb = SavingCallback((t,u,integrator)->copy(u), saved_values, saveat=saveat)
sol = solve(prob2D, Tsit5(), callback=cb)
@test all(idx -> saveat[idx] == saved_values.t[idx], eachindex(saved_values.t))
@test all(idx -> norm(sol(saveat[idx]) - saved_values.saveval[idx]) < 5.e-15, eachindex(saved_values.t))

saved_values = SavedValues(eltype(prob2D.tspan), eltype(prob2D.u0))
saveat = linspace(prob2D.tspan..., 10)
cb = SavingCallback((t,u,integrator)->u[1], saved_values, saveat=saveat)
sol = solve(prob2D, Tsit5(), callback=cb)
@test all(idx -> saveat[idx] == saved_values.t[idx], eachindex(saved_values.t))
@test all(idx -> abs(sol(saveat[idx])[1] - saved_values.saveval[idx]) < 5.e-15, eachindex(saved_values.t))
