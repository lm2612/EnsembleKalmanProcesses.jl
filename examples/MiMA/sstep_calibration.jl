using Distributions
using JLD
using ArgParse
using NCDatasets
using LinearAlgebra
#using DelimitedFiles
using CSV
using DataFrames
# Import EnsembleKalmanProcesses modules
using EnsembleKalmanProcesses.EnsembleKalmanProcessModule
using EnsembleKalmanProcesses.Observations
using EnsembleKalmanProcesses.ParameterDistributionStorage

include(joinpath(@__DIR__, "helper_funcs.jl"))

"""
ek_update(iteration_::Int64)

Update MIMAParameters ensemble using Ensemble Kalman Inversion,
return the ensemble and the parameter names.
"""
function ek_update(iteration_::Int64)
    # Recover versions from last iteration
    versions = readlines("versions_$(iteration_).txt")
    
    # Use known u_names and n_params, could eventually set this up by reading from output file (as done in ClimateMachine example)
    u_names = ["cwtropics"]
    n_params = length(u_names)
   
    # Recover ensemble from last iteration, [N_ens, N_params]
    N = length(versions)
    u = zeros(N, n_params)

    # Get ensemble parameter inputs from txt file
    basedir = "/scratch/users/lauraman/MiMA/ekp_runs/"
    filename = "QBO_metrics.csv"

    
    for (ens_index, version_) in enumerate(versions)
        input_filename = "$(basedir)/$(version_)"
        open(input_filename, "r") do io
            line = readline(io)
            for (u_index, u_name) in enumerate(u_names)
                u[ens_index, u_index] = parse(Float64, (strip(string(split(line, "$(u_name) = ")[2]), [' '])) )
            end 
        end
    end
    u = Array(u')
    println(u)

    println("Get truth")
    # Get observations / truth output
    y_names = ["std20", "std77"]
    yt = zeros(0)
    yt_var_list = []


    truthdir = "/scratch/users/lauraman/MiMA/runs/033/"
    runname = "$(truthdir)/$(filename)"
    df = DataFrame(CSV.File(runname))
    yt_ = zeros(length(y_names))
    for (y_index, y_name) in enumerate(y_names)
        yt_[y_index] = df[1, y_name] 
    end 
    println(yt_)

    # Also get variance for truth 
    y_names_var = ["std20_var", "std77_var"]
    yt_var_ = zeros(length(y_names_var))
    for (y_index, y_name) in enumerate(y_names_var)
        yt_var_[y_index] = df[1, y_name] 
    end 
    # Convert to diagonal covariance matrix 
    yt_var_ = diagm(yt_var_)
    println(yt_var_)

    # Add nugget to variance (regularization)
    println(Matrix(0.1I, size(yt_var_)[1], size(yt_var_)[2]))
    yt_var_ = yt_var_ + Matrix(0.1I, size(yt_var_)[1], size(yt_var_)[2])
    println(yt_var_)
    println(yt_var_list)
    append!(yt, yt_)
    push!(yt_var_list, yt_var_)

    # Get outputs from .csv file
    println("Get outputs")
    g_names = y_names
    g_ens = zeros(N, length(g_names))
    basedir = "/scratch/users/lauraman/MiMA/ekp_runs/"
    filename = "QBO_metrics.csv"
    for (ens_index, version_) in enumerate(versions)
        runname = "$(basedir)/$(iteration_)_$(ens_index)/$(filename)"
        df = DataFrame(CSV.File(runname))
        colnames = names(df)
        for (g_index, g_name) in enumerate(g_names)
            g_ens[ens_index, g_index] = df[1, g_name]
        end

    end
    g_ens = Array(g_ens')
    print(g_ens)

    # Construct EKP
    ekobj = EnsembleKalmanProcess(u, yt_, yt_var_, Inversion())
    println(ekobj)
    # Advance EKP
    update_ensemble!(ekobj, g_ens)
    # Get new step
    u_new = get_u_final(ekobj)
    println(u_new)
    return u_new, u_names
end

# Read iteration number of ensemble to be recovered
s = ArgParseSettings()
@add_arg_table s begin
    "--iteration"
    help = "Calibration iteration number"
    arg_type = Int
    default = 1
end
parsed_args = parse_args(ARGS, s)
iteration_ = parsed_args["iteration"]

println(iteration_)
# Perform update
ens_new, param_names = ek_update(iteration_)
params_arr = [col[:] for col in eachcol(ens_new)]

# Generate new identifiers
versions = map(param -> generate_mima_params(param, param_names), params_arr)
open("versions_$(iteration_+1).txt", "w") do io
    for version in versions
        write(io, "mima_param_defs_$(version).txt\n")
    end
end
