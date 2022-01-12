#!/bin/bash

#SBATCH --job-name=ekp_cal   # job name
#SBATCH --partition=serc     # partition
#SBATCH --time=1:00:00       # walltime
#SBATCH --ntasks=1           # number of processor cores (i.e. tasks)
#SBATCH --nodes=1            # number of nodes
#SBATCH --mem-per-cpu=6G     # memory per CPU core
#SBATCH --output=oe_files/ekp_cal_%j.out
#SBATCH --error=oe_files/ekp_cal_%j.err

# Size of the ensemble
n=10
# Number of EK iterations
n_it=5

module purge
#module load julia/1.5.2 hdf5/1.10.1 netcdf-c/4.6.1 openmpi/4.0.1
module load julia hdf5 netcdf openmpi

export JULIA_NUM_THREADS=${SLURM_CPUS_PER_TASK:=1}
export JULIA_MPI_BINARY=system
export JULIA_CUDA_USE_BINARYBUILDER=false

# run instantiate/precompile serial
julia --project -e 'using Pkg; Pkg.instantiate(); Pkg.build()'
julia --project -e 'using Pkg; Pkg.precompile()'
echo "Project instantiated and precompiled"

# First call to calibrate.jl will create the ensemble files from the priors
echo "Setting up init_calibration"
id_init_ens=$(sbatch --parsable ekp_init_calibration.sbatch)
echo "Done init_calibration"

# Loop over each EK iteration
for it in $(seq 1 1 $n_it)
do
    # Parallel runs of forward model
    echo "Running iteration ${it}"
    if [ "$it" = "1" ]; then
        id_ens_array=$(sbatch --parsable --kill-on-invalid-dep=yes --dependency=afterok:$id_init_ens --array=1-$n ekp_single_mima_run.sbatch $it)
    else
        id_ens_array=$(sbatch --parsable --kill-on-invalid-dep=yes --dependency=afterok:$id_ek_upd --array=1-$n ekp_single_mima_run.sbatch $it)
    fi
    echo "Done run, get output"
    # Run python script to get QBO output here
    echo "Done, running calibration"
    id_ek_upd=$(sbatch --parsable --kill-on-invalid-dep=yes --dependency=afterok:$id_ens_array --export=n=$n ekp_cont_calibration.sbatch $it)
    echo "Done calibration"
done

