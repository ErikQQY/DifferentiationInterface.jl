using Pkg
Pkg.add("ForwardDiff")

using ComponentArrays: ComponentArrays
using DifferentiationInterface, DifferentiationInterfaceTest
import DifferentiationInterfaceTest as DIT
using ForwardDiff: ForwardDiff
using StaticArrays: StaticArrays
using Test

LOGGING = get(ENV, "CI", "false") == "false"

struct MyTag end

backends = [
    AutoForwardDiff(),
    AutoForwardDiff(; chunksize=5),
    AutoForwardDiff(; tag=ForwardDiff.Tag(MyTag(), Float64)),
]

for backend in backends
    @test check_available(backend)
    @test check_inplace(backend)
end

## Dense

test_differentiation(
    backends, default_scenarios(; include_constantified=true); logging=LOGGING
);

test_differentiation(
    AutoForwardDiff(),
    default_scenarios(;
        include_normal=false, include_batchified=false, include_cachified=true
    );
    logging=LOGGING,
);

test_differentiation(
    AutoForwardDiff(); correctness=false, type_stability=:prepared, logging=LOGGING
);

test_differentiation(
    AutoForwardDiff(; chunksize=5);
    correctness=false,
    type_stability=:full,
    excluded=[:hessian],
    logging=LOGGING,
);

test_differentiation(
    backends,
    vcat(component_scenarios(), static_scenarios()); # FD accesses individual indices
    excluded=vcat(SECOND_ORDER, [:jacobian]),  # jacobian is super slow for some reason
    logging=LOGGING,
);

## Sparse

test_differentiation(MyAutoSparse(AutoForwardDiff()), default_scenarios(); logging=LOGGING);

test_differentiation(
    MyAutoSparse(AutoForwardDiff()),
    sparse_scenarios(; include_constantified=true);
    sparsity=true,
    logging=LOGGING,
);

## Static

test_differentiation(AutoForwardDiff(), static_scenarios(); logging=LOGGING)

@testset verbose = true "No allocations on StaticArrays" begin
    filtered_static_scenarios = filter(static_scenarios(; include_batchified=false)) do scen
        DIT.function_place(scen) == :out && DIT.operator_place(scen) == :out
    end
    data = benchmark_differentiation(
        AutoForwardDiff(),
        filtered_static_scenarios;
        benchmark=:prepared,
        excluded=[:hessian, :pullback],  # TODO: figure this out
        logging=LOGGING,
    )
    @testset "Analyzing benchmark results" begin
        @testset "$(row[:scenario])" for row in eachrow(data)
            @test row[:allocs] == 0
        end
    end
end;
