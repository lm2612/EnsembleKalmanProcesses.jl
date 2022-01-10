#!/bin/bash

#SBATCH --time=1:00:00        # walltime
#SBATCH --ntasks=1            # number of processor cores (i.e. tasks)
#SBATCH --nodes=1             # number of nodes
#SBATCH --mem-per-cpu=6G      # memory per CPU core
#SBATCH --job-name=cm_run     # job name
#SBATCH --partition=serc      # partition
#SBATCH --output=oe_files/cm_run_%j.out
#SBATCH --error=oe_files/cm_run_%j.err

#module load julia/1.5.2 hdf5/1.10.1 netcdf-c/4.6.1 openmpi/4.0.1
module load julia hdf5 netcdf openmpi

iteration_=${1?Error: no iteration given}


run_num=${SLURM_ARRAY_TASK_ID}
version=$(head -"$run_num" "versions_"$iteration_".txt" | tail -1)

julia --project=../../../ClimateMachine.jl -e 'using Pkg; Pkg.instantiate(); Pkg.API.precompile()'

julia --project=../../../ClimateMachine.jl ../../../ClimateMachine.jl/test/Atmos/EDMF/stable_bl_anelastic1d.jl --diagnostics 60ssecs --cparam-file $version
mv ../../../ClimateMachine.jl/test/Atmos/EDMF/$version $version'.output/'
echo "CM simulation for ${version} in iteration ${iteration_} finished"

