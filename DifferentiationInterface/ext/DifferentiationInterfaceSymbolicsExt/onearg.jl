## Pushforward

struct SymbolicsOneArgPushforwardExtras{E1,E1!} <: PushforwardExtras
    pf_exe::E1
    pf_exe!::E1!
end

function DI.prepare_pushforward(f, ::AutoSymbolics, x, tx::Tangents)
    dx = first(tx)
    x_var = if x isa Number
        variable(:x)
    else
        variables(:x, axes(x)...)
    end
    dx_var = if dx isa Number
        variable(:dx)
    else
        variables(:dx, axes(dx)...)
    end
    t_var = variable(:t)
    step_der_var = derivative(f(x_var + t_var * dx_var), t_var)
    pf_var = substitute(step_der_var, Dict(t_var => zero(eltype(x))))

    res = build_function(pf_var, vcat(myvec(x_var), myvec(dx_var)); expression=Val(false))
    (pf_exe, pf_exe!) = if res isa Tuple
        res
    elseif res isa RuntimeGeneratedFunction
        res, nothing
    end
    return SymbolicsOneArgPushforwardExtras(pf_exe, pf_exe!)
end

function DI.pushforward(
    f, ::AutoSymbolics, x, tx::Tangents, extras::SymbolicsOneArgPushforwardExtras
)
    dys = map(tx.d) do dx
        v_vec = vcat(myvec(x), myvec(dx))
        dy = extras.pf_exe(v_vec)
    end
    return Tangents(dys)
end

function DI.pushforward!(
    f,
    ty::Tangents,
    ::AutoSymbolics,
    x,
    tx::Tangents,
    extras::SymbolicsOneArgPushforwardExtras,
)
    for b in eachindex(tx.d, ty.d)
        dx, dy = tx.d[b], ty.d[b]
        v_vec = vcat(myvec(x), myvec(dx))
        extras.pf_exe!(dy, v_vec)
    end
    return ty
end

function DI.value_and_pushforward(
    f, backend::AutoSymbolics, x, tx::Tangents, extras::SymbolicsOneArgPushforwardExtras
)
    return f(x), DI.pushforward(f, backend, x, tx, extras)
end

function DI.value_and_pushforward!(
    f,
    ty::Tangents,
    backend::AutoSymbolics,
    x,
    tx::Tangents,
    extras::SymbolicsOneArgPushforwardExtras,
)
    return f(x), DI.pushforward!(f, ty, backend, x, tx, extras)
end

## Derivative

struct SymbolicsOneArgDerivativeExtras{E1,E1!} <: DerivativeExtras
    der_exe::E1
    der_exe!::E1!
end

function DI.prepare_derivative(f, ::AutoSymbolics, x)
    x_var = variable(:x)
    der_var = derivative(f(x_var), x_var)

    res = build_function(der_var, x_var; expression=Val(false))
    (der_exe, der_exe!) = if res isa Tuple
        res
    elseif res isa RuntimeGeneratedFunction
        res, nothing
    end
    return SymbolicsOneArgDerivativeExtras(der_exe, der_exe!)
end

function DI.derivative(f, ::AutoSymbolics, x, extras::SymbolicsOneArgDerivativeExtras)
    return extras.der_exe(x)
end

function DI.derivative!(f, der, ::AutoSymbolics, x, extras::SymbolicsOneArgDerivativeExtras)
    extras.der_exe!(der, x)
    return der
end

function DI.value_and_derivative(
    f, backend::AutoSymbolics, x, extras::SymbolicsOneArgDerivativeExtras
)
    return f(x), DI.derivative(f, backend, x, extras)
end

function DI.value_and_derivative!(
    f, der, backend::AutoSymbolics, x, extras::SymbolicsOneArgDerivativeExtras
)
    return f(x), DI.derivative!(f, der, backend, x, extras)
end

## Gradient

struct SymbolicsOneArgGradientExtras{E1,E1!} <: GradientExtras
    grad_exe::E1
    grad_exe!::E1!
end

function DI.prepare_gradient(f, ::AutoSymbolics, x)
    x_var = variables(:x, axes(x)...)
    # Symbolic.gradient only accepts vectors
    grad_var = gradient(f(x_var), vec(x_var))

    res = build_function(grad_var, vec(x_var); expression=Val(false))
    (grad_exe, grad_exe!) = res
    return SymbolicsOneArgGradientExtras(grad_exe, grad_exe!)
end

function DI.gradient(f, ::AutoSymbolics, x, extras::SymbolicsOneArgGradientExtras)
    return reshape(extras.grad_exe(vec(x)), size(x))
end

function DI.gradient!(f, grad, ::AutoSymbolics, x, extras::SymbolicsOneArgGradientExtras)
    extras.grad_exe!(vec(grad), vec(x))
    return grad
end

function DI.value_and_gradient(
    f, backend::AutoSymbolics, x, extras::SymbolicsOneArgGradientExtras
)
    return f(x), DI.gradient(f, backend, x, extras)
end

function DI.value_and_gradient!(
    f, grad, backend::AutoSymbolics, x, extras::SymbolicsOneArgGradientExtras
)
    return f(x), DI.gradient!(f, grad, backend, x, extras)
end

## Jacobian

struct SymbolicsOneArgJacobianExtras{E1,E1!} <: JacobianExtras
    jac_exe::E1
    jac_exe!::E1!
end

function DI.prepare_jacobian(
    f, backend::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}}, x
)
    x_var = variables(:x, axes(x)...)
    jac_var = if backend isa AutoSparse
        sparsejacobian(vec(f(x_var)), vec(x_var))
    else
        jacobian(f(x_var), x_var)
    end

    res = build_function(jac_var, x_var; expression=Val(false))
    (jac_exe, jac_exe!) = res
    return SymbolicsOneArgJacobianExtras(jac_exe, jac_exe!)
end

function DI.jacobian(
    f,
    ::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgJacobianExtras,
)
    return extras.jac_exe(x)
end

function DI.jacobian!(
    f,
    jac,
    ::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgJacobianExtras,
)
    extras.jac_exe!(jac, x)
    return jac
end

function DI.value_and_jacobian(
    f,
    backend::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgJacobianExtras,
)
    return f(x), DI.jacobian(f, backend, x, extras)
end

function DI.value_and_jacobian!(
    f,
    jac,
    backend::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgJacobianExtras,
)
    return f(x), DI.jacobian!(f, jac, backend, x, extras)
end

## Hessian

struct SymbolicsOneArgHessianExtras{G,E2,E2!} <: HessianExtras
    gradient_extras::G
    hess_exe::E2
    hess_exe!::E2!
end

function DI.prepare_hessian(f, backend::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}}, x)
    x_var = variables(:x, axes(x)...)
    # Symbolic.hessian only accepts vectors
    hess_var = if backend isa AutoSparse
        sparsehessian(f(x_var), vec(x_var))
    else
        hessian(f(x_var), vec(x_var))
    end

    res = build_function(hess_var, vec(x_var); expression=Val(false))
    (hess_exe, hess_exe!) = res

    gradient_extras = DI.prepare_gradient(f, maybe_dense_ad(backend), x)
    return SymbolicsOneArgHessianExtras(gradient_extras, hess_exe, hess_exe!)
end

function DI.hessian(
    f,
    ::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgHessianExtras,
)
    return extras.hess_exe(vec(x))
end

function DI.hessian!(
    f,
    hess,
    ::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgHessianExtras,
)
    extras.hess_exe!(hess, vec(x))
    return hess
end

function DI.value_gradient_and_hessian(
    f,
    backend::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgHessianExtras,
)
    y, grad = DI.value_and_gradient(f, maybe_dense_ad(backend), x, extras.gradient_extras)
    hess = DI.hessian(f, backend, x, extras)
    return y, grad, hess
end

function DI.value_gradient_and_hessian!(
    f,
    grad,
    hess,
    backend::Union{AutoSymbolics,AutoSparse{<:AutoSymbolics}},
    x,
    extras::SymbolicsOneArgHessianExtras,
)
    y, _ = DI.value_and_gradient!(
        f, grad, maybe_dense_ad(backend), x, extras.gradient_extras
    )
    DI.hessian!(f, hess, backend, x, extras)
    return y, grad, hess
end
