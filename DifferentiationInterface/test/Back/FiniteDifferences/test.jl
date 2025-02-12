using Pkg
Pkg.add("FiniteDifferences")

using DifferentiationInterface, DifferentiationInterfaceTest
using FiniteDifferences: FiniteDifferences
using Test

LOGGING = get(ENV, "CI", "false") == "false"

for backend in [AutoFiniteDifferences(; fdm=FiniteDifferences.central_fdm(3, 1))]
    @test check_available(backend)
    @test !check_inplace(backend)
end

test_differentiation(
    AutoFiniteDifferences(; fdm=FiniteDifferences.central_fdm(3, 1)),
    default_scenarios(; include_constantified=true, include_cachified=true);
    excluded=SECOND_ORDER,
    logging=LOGGING,
);
