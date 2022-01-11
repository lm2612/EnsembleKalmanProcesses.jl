#!/bin/bash

#SBATCH --time=2:00:00        # walltime
#SBATCH --ntasks=32           # number of processor cores (i.e. tasks)
####SBATCH --nodes=1             # number of nodes
#SBATCH --mem-per-cpu=4G      # memory per CPU core
#SBATCH --job-name=mima_run   # job name
#SBATCH --partition=serc      # partition
#SBATCH --output=${SCRATCH}/MiMA/ekp_jobs/${1}_%j.out
#SBATCH --error==${SCRATCH}/MiMA/ekp_jobs/${1}_%j.err


iteration_=${1?Error: no iteration given}

run_num=${SLURM_ARRAY_TASK_ID}
version=$(head -"$run_num" "versions_"$iteration_".txt" | tail -1)

# RUN MiMA SIMULATION

#--------------------------------------------------------------------------------------------------------
# Set up relevant paths and modules
ulimit -s unlimited

# Use cees-beta stack
. /home/groups/s-ees/share/cees/spack_cees/scripts/cees_sw_setup-beta.sh
module purge
CEES_MODULE_SUFFIX="cees-beta"
module load devel gcc/10.  intel-${CEES_MODULE_SUFFIX}  mpich-${CEES_MODULE_SUFFIX}/
module load netcdf-c-${CEES_MODULE_SUFFIX}/ netcdf-fortran-${CEES_MODULE_SUFFIX}/ anaconda-${CEES_MODULE_SUFFIX}/
cwd=`pwd`

# Currently two libraries are not found in linking on SH03_CEES: libfabric and hwloc. Manually add them here.
export LIBFABRIC_PATH="/home/groups/s-ees/share/cees/spack_cees/spack/opt/spack/linux-centos7-zen2/intel-2021.4.0/libfabric-1.13.1-fcah2ztj7a4kigbly6vxqa7vuwesyxmr/lib/"
export HWLOC_PATH="/home/groups/s-ees/share/cees/spack_cees/spack/opt/spack/linux-centos7-zen2/intel-2021.4.0/hwloc-2.5.0-4yz4g5jbydc4euoqrbudraxssx2tcaco/lib/"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${LIBFABRIC_PATH}:${HWLOC_PATH}"

N_PROCS=32

#--------------------------------------------------------------------------------------------------------
# Set up run directory
PLATFORM=SH03_CEES
run=${iteration_}
executable=${HOME}/MiMA/exp/exec.${PLATFORM}/mima.x
### Set up input namelist input=${SCRATCH}/MiMA/inputs/$run
rundir=${SCRATCH}/MiMA/ekp_runs/$run
# Start from control run output in run032
restartdir=${SCRATCH}/MiMA/runs/032   

# Make run dir
[ ! -d $rundir ] && mkdir $rundir
# Copy executable to rundir
cp $executable $rundir/
# Copy input to rundir
cp -r $input/* $rundir/
# Copy restart files to input
cp -r $restartdir/RESTART/*res* $rundir/INPUT/

#--------------------------------------------------------------------------------------------------------
# Run the model
cd $rundir
echo "run MiMA"
[ ! -d RESTART ] && mkdir RESTART

srun --ntasks $N_PROCS mima.x

CCOMB=${HOME}/MiMA/bin/mppnccombine.${PLATFORM}
$CCOMB -r atmos_daily.nc atmos_daily.nc.????
$CCOMB -r atmos_avg.nc atmos_avg.nc.????

# Run output will be saved in ${SCRATCH}/MiMA/ekp_runs/XX/
# Job info will be saved in ${SCRATCH}/MiMA/ekp_jobs/XX_JOBID.out 

echo "MiMA simulation for ${version} in iteration ${iteration_} finished"

