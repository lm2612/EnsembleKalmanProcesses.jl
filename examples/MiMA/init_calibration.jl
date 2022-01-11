using Distributions
using ArgParse
# Import EnsembleKalmanProcesses modules
using EnsembleKalmanProcesses.EnsembleKalmanProcessModule
using EnsembleKalmanProcesses.Observations
using EnsembleKalmanProcesses.ParameterDistributionStorage
include(joinpath(@__DIR__, "helper_funcs.jl"))

# Set parameter priors
param_names = ["cwtropics"]
n_param = length(param_names)
prior_dist = [Parameterized(Normal(35, 10))]
constraints = [[no_constraint()]]
priors = ParameterDistribution(prior_dist, constraints, param_names)

# Construct initial ensemble
N_ens = 10
initial_params = construct_initial_ensemble(priors, N_ens)
# Generate MiMA Parameters files
params_arr = [row[:] for row in eachrow(initial_params')]
versions = map(param -> generate_mima_params(param, param_names), params_arr)

# Store version identifiers for this ensemble in a common file
open("versions_1.txt", "w") do io
    for version in versions
        write(io, "mima_param_defs_$(version).jl\n")
    end
end
