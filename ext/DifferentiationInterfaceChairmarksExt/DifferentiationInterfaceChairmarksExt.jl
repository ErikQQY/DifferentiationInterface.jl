module DifferentiationInterfaceChairmarksExt

using ADTypes: AbstractADType
using Chairmarks: @be, Benchmark, Sample
using DifferentiationInterface
using DifferentiationInterface: mysimilar
using DifferentiationInterface.DifferentiationTest: Scenario, BenchmarkData, record!
using Test: @testset, @test

## Pushforward

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(pushforward),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, dx, dy) = deepcopy(scen)
    extras = prepare_pushforward(f, ba, x)
    bench1 = @be mysimilar(dy) value_and_pushforward!!(f, _, ba, x, dx, extras)
    if allocations && dy isa Number
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_pushforward!!, scen, bench1)
    return nothing
end

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(pushforward),
    scen::Scenario{true};
    allocations::Bool,
)
    (; f, x, y, dx, dy) = deepcopy(scen)
    f! = f
    extras = prepare_pushforward(f!, ba, y, x)
    bench1 = @be (mysimilar(y), mysimilar(dy)) value_and_pushforward!!(
        f!, _[1], _[2], ba, x, dx, extras
    )
    if allocations
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_pushforward!!, scen, bench1)
    return nothing
end

## Pullback

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(pullback),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, dx, dy) = deepcopy(scen)
    extras = prepare_pullback(f, ba, x)
    bench1 = @be mysimilar(dx) value_and_pullback!!(f, _, ba, x, dy, extras)
    if allocations && dy isa Number
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_pullback!!, scen, bench1)
    return nothing
end

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(pullback),
    scen::Scenario{true};
    allocations::Bool,
)
    (; f, x, y, dx, dy) = deepcopy(scen)
    f! = f
    extras = prepare_pullback(f!, ba, y, x)
    bench1 = @be (mysimilar(y), mysimilar(dx)) value_and_pullback!!(
        f!, _[1], _[2], ba, x, dy, extras
    )
    if allocations
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_pullback!!, scen, bench1)
    return nothing
end

## Derivative

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(derivative),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, y, dy) = deepcopy(scen)
    extras = prepare_derivative(f, ba, x)
    bench1 = @be mysimilar(dy) value_and_derivative!!(f, _, ba, x, extras)
    # only test allocations if the output is scalar
    if allocations && y isa Number
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_derivative!!, scen, bench1)
    return nothing
end

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(derivative),
    scen::Scenario{true};
    allocations::Bool,
)
    (; f, x, y, dy) = deepcopy(scen)
    f! = f
    extras = prepare_derivative(f!, ba, y, x)
    bench1 = @be (mysimilar(y), mysimilar(dy)) value_and_derivative!!(
        f!, _[1], _[2], ba, x, extras
    )
    if allocations
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_derivative!!, scen, bench1)
    return nothing
end

## Gradient

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(gradient),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, dx) = deepcopy(scen)
    extras = prepare_gradient(f, ba, x)
    bench1 = @be mysimilar(dx) value_and_gradient!!(f, _, ba, x, extras)
    if allocations
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_gradient!!, scen, bench1)
    return nothing
end

## Jacobian

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(jacobian),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, y) = deepcopy(scen)
    extras = prepare_jacobian(f, ba, x)
    jac_template = Matrix{eltype(y)}(undef, length(y), length(x))
    bench1 = @be mysimilar(jac_template) value_and_jacobian!!(f, _, ba, x, extras)
    # never test allocations
    record!(data, ba, op, value_and_jacobian!!, scen, bench1)
    return nothing
end

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(jacobian),
    scen::Scenario{true};
    allocations::Bool,
)
    (; f, x, y) = deepcopy(scen)
    f! = f
    extras = prepare_jacobian(f!, ba, y, x)
    jac_template = Matrix{eltype(y)}(undef, length(y), length(x))
    bench1 = @be (mysimilar(y), mysimilar(jac_template)) value_and_jacobian!!(
        f!, _[1], _[2], ba, x, extras
    )
    if allocations
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, value_and_jacobian!!, scen, bench1)
    return nothing
end

## Second derivative

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(second_derivative),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, y, dy) = deepcopy(scen)
    extras = prepare_second_derivative(f, ba, x)
    bench1 = @be second_derivative(f, ba, x, extras)
    # only test allocations if the output is scalar
    if allocations && y isa Number
        @test 0 == minimum(bench1).allocs
    end
    record!(data, ba, op, second_derivative, scen, bench1)
    return nothing
end

## Hessian-vector product

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(hvp),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, y, dx) = deepcopy(scen)
    extras = prepare_hvp(f, ba, x)
    bench1 = @be hvp(f, ba, x, dx, extras)
    # no test for now
    record!(data, ba, op, hvp, scen, bench1)
    return nothing
end

## Hessian

function run_benchmark!(
    data::BenchmarkData,
    ba::AbstractADType,
    op::typeof(hessian),
    scen::Scenario{false};
    allocations::Bool,
)
    (; f, x, y) = deepcopy(scen)
    extras = prepare_hessian(f, ba, x)
    bench1 = @be hessian(f, ba, x, extras)
    # no test for now
    record!(data, ba, op, hessian, scen, bench1)
    return nothing
end

end # module
