New test example that uses MiMA to calculate QBO metrics. 

This example is a perfect model experiment, in the sense that the ground truth is 
generated using the same model and a certain combination of parameters. The parameters
used to generate the ground truth are (cwtropics) = (35). 

To run the example using a SLURM workload manager, simply do:

>> sbatch ekp_calibration.sbatch

This will create a queue on the workload manager running,

  1. ekp_init_calibration (creating initial parameters),
  2a. ekp_single_cm_run (running the forward model with the given parameters),
  2b. ekp_cont_calibration (updating parameters with EKP given the model output).

Steps 2a and 2b are iterated until the desired number of iterations
(defined in ekp_calibration.sbatch) is reached.

The results for different runs of MiMA will be stored in NetCDF format in directories
identifiable by their version number. Refer to the files version_XX.txt to identify each run with
the XX iteration of the Ensemble Kalman Process. To aggregate the parameter ensembles generated during
the calibration process, you may use the agg_mima_ekp(...) function located in helper_funcs.jl.

