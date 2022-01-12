#!/bin/bash

#SBATCH --time=2:00:00        # walltime
#SBATCH --ntasks=32           # number of processor cores (i.e. tasks)
####SBATCH --nodes=1             # number of nodes
#SBATCH --mem-per-cpu=4G      # memory per CPU core
#SBATCH --job-name=mima_run   # job name
#SBATCH --partition=serc      # partition
#SBATCH --output=/scratch/users/lauraman/MiMA/ekp_jobs/%j.out
#SBATCH --error=/scratch/users/lauraman/MiMA/ekp_jobs/%j.err


iteration_=${1?Error: no iteration given}

# Get version info by reading line run_num 
run_num=${SLURM_ARRAY_TASK_ID}
echo "${run_num}"
version=$(head -"$run_num" "versions_"$iteration_".txt" | tail -1)
# Extract version_id from filename, should give us a number of length 5. We will save the run under this name.
version_id=$(echo $version| cut -d'_' -f 4 | cut -d'.' -f 1)
echo $version_id

# RUN MiMA SIMULATION
#--------------------------------------------------------------------------------------------------------
# Set up relevant paths and modules
ulimit -s unlimited

# Use cees-beta stack
. /home/groups/s-ees/share/cees/spack_cees/scripts/cees_sw_setup-beta.sh

module purge
CEES_MODULE_SUFFIX="cees-beta"

module load devel gcc/10.
module load intel-${CEES_MODULE_SUFFIX}
module load mpich-${CEES_MODULE_SUFFIX}/
module load netcdf-c-${CEES_MODULE_SUFFIX}/
module load netcdf-fortran-${CEES_MODULE_SUFFIX}/
module load anaconda-${CEES_MODULE_SUFFIX}/
cwd=`pwd`

# Currently two libraries are not found in linking on SH03_CEES: libfabric and hwloc. Manually add them here.
export LIBFABRIC_PATH="/home/groups/s-ees/share/cees/spack_cees/spack/opt/spack/linux-centos7-zen2/intel-2021.4.0/libfabric-1.13.1-fcah2ztj7a4kigbly6vxqa7vuwesyxmr/lib/"
export HWLOC_PATH="/home/groups/s-ees/share/cees/spack_cees/spack/opt/spack/linux-centos7-zen2/intel-2021.4.0/hwloc-2.5.0-4yz4g5jbydc4euoqrbudraxssx2tcaco/lib/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LIBFABRIC_PATH}:${HWLOC_PATH}"

N_PROCS=32

#--------------------------------------------------------------------------------------------------------
# Set up run directory
PLATFORM=SH03_CEES
run="${iteration_}_${run_num}"
executable=${HOME}/MiMA/exp/exec.${PLATFORM}/mima.x
rundir=${SCRATCH}/MiMA/ekp_runs/$run

# Set up restart files and basic input files from control run (run033)
# which has input params cwtropics = 35,  cw = 35, Bt_0  = 0.0043,  Bt_nh = 0.0035
restartdir=${SCRATCH}/MiMA/runs/033   
input=${SCRATCH}/MiMA/inputs/ekp_inputs               # input file is a copy of run033 but set to 1 year for testing

# Make run dir
[ ! -d $rundir ] && mkdir $rundir
# Copy executable to rundir
cp $executable $rundir/
# Copy input to rundir
cp -r $input/* $rundir/
# Copy restart files to input
cp -r $restartdir/RESTART/*res* $rundir/INPUT/

# Edit input namelist for this iteration's parameters
# Read entry from mima_param_defs_${iteration}
mima_param_file="${SCRATCH}/MiMA/ekp_runs/${version}"
while IFS= read -r line
do
    echo "$line"
    # Change corresponding parameter in namelist
    ## Note this currently would not work if we would change cw as it would pick up cw and cwtropics
    if [[ "$line" == cwtropics* ]];
    then
        # Set cwtropics within namelist 
        sed -i "s/cwtropics = 35.0/${line}/g" $rundir/input.nml
	
    fi

done < "$mima_param_file"

#--------------------------------------------------------------------------------------------------------
# Run the model
cd $rundir
echo "run MiMA"
[ ! -d RESTART ] && mkdir RESTART
srun --ntasks $N_PROCS mima.x

CCOMB=${HOME}/MiMA/bin/mppnccombine.${PLATFORM}
$CCOMB -r atmos_daily.nc atmos_daily.nc.????
$CCOMB -r atmos_avg.nc atmos_avg.nc.????

# Run output will be saved in ${SCRATCH}/MiMA/ekp_runs/iteration_runnum/
# Job info will be saved in ${SCRATCH}/MiMA/ekp_jobs/JOBID.out 

echo "MiMA simulation for ${version} in iteration ${iteration_} finished"
echo "Output saved in $rundir"
