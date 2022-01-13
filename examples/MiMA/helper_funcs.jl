using NCDatasets
using Statistics
using Interpolations
using LinearAlgebra
using Glob
using JLD
"""
generate_mima_params(mima_params::Array{Float64}, 
                            mima_param_names::Array{String})

Generate a MIMAParameters file, setting the values (mima_params) of
a group of MIMAParameters (mima_param_names).
"""
function generate_mima_params(mima_params::Array{Float64}, mima_param_names::Array{String})
    # Generate version
    version = rand(11111:99999)
    if length(mima_params) == length(mima_param_names)
        open("mima_param_defs_$(version).txt", "w") do io
            for i in 1:length(mima_params)
                write(
                    io,
		    "$(mima_param_names[i]) = $(mima_params[i])\n",
                )
            end
        end
    else
        throw(ArgumentError("Number of parameter names must be equal to number of values provided."))
    end
    return version
end

"""
agg_mima_ekp(n_params::Integer, output_name::String="ekp_mima")

Aggregate all iterations of the parameter ensembles and write to file, given the
number of parameters in each parameter vector (p).
"""
function agg_mima_ekp(n_params::Integer, output_name::String = "ekp_mima")
    # Get versions
    version_files = glob("versions_*.txt")
    # Recover parameters of last iteration
    last_up_versions = readlines(version_files[end])

    ens_all = Array{Float64, 2}[]
    for (it_num, file) in enumerate(version_files)
        versions = readlines(file)
        u = zeros(length(versions), n_params)
        for (ens_index, version_) in enumerate(versions)
            if it_num == length(version_files)
                open("../../../ClimateMachine.jl/test/Atmos/EDMF/$(version_)", "r") do io
                    u[ens_index, :] =
                        [parse(Float64, line) for (index, line) in enumerate(eachline(io)) if index % 3 == 0]
                end
            else
                open("$(version_).output/$(version_)", "r") do io
                    u[ens_index, :] =
                        [parse(Float64, line) for (index, line) in enumerate(eachline(io)) if index % 3 == 0]
                end
            end
        end
        push!(ens_all, u)
    end
    save(string(output_name, ".jld"), "ekp_u", ens_all)
    return
end
