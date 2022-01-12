#!/bin/bash

#SBATCH --time=1:00:00        # walltime
#SBATCH --ntasks=1           # number of processor cores (i.e. tasks)
#SBATCH --nodes=1             # number of nodes
#SBATCH --mem-per-cpu=4G      # memory per CPU core
#SBATCH --job-name=mima_run   # job name
#SBATCH --partition=serc      # partition
#SBATCH --output=/scratch/users/lauraman/MiMA/ekp_jobs/%j.out
#SBATCH --error=/scratch/users/lauraman/MiMA/ekp_jobs/%j.err


# Calculate metrics with python script
# Set up conda env
. /home/users/lauraman/miniconda3/etc/profile.d/conda.sh
export PATH="/home/users/lauraman/miniconda3/bin:$PATH"
conda activate plot_env


# Get run directory
iteration_=${1?Error: no iteration given}

# Get version info by reading line run_num 
run_num=${SLURM_ARRAY_TASK_ID}
echo "${run_num}"

python ~/save_inputs_outputs/save_QBO_metrics_for_EKI.py $iteration_ $run_num
