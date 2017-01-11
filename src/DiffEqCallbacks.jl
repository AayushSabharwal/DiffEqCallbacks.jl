module DiffEqCallbacks

  using DiffEqBase

  type AutoAbstolAffect{T}
    curmax::T
  end
  # Now make `affect!` for this:
  function (p::AutoAbstolAffect)(integrator)
    p.curmax = max(p.curmax,integrator.u)
    integrator.opts.abstol = p.curmax * integrator.opts.reltol
    u_modified!(integrator,false)
  end

  function AutoAbstol(save=true;init_curmax=1e-6)
    affect! = AutoAbstolAffect(init_curmax)
    condtion = (t,u,integrator) -> true
    save_positions = (save,false)
    DiscreteCallback(condtion,affect!,save_positions)
  end

  export AutoAbstol

end # module
