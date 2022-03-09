#!/bin/bash

#SBATCH -p medium
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH -c 24
#SBATCH -C scratch2
#SBATCH --mail-type=BEGIN,END,FAIL

# THOSE BUFFER TASKS ARE SUPER IMPORTANT!!!!!!
# say you want 1 node but X parallel tasks (-c designates cpus, -n designates tasks, according to gwdg, use -c when you can keep it to a single node) (https://docs.gwdg.de/doku.php?id=en:services:application_services:high_performance_computing:running_jobs_slurm)
# keep it modest so you don't gotta wait
# need to use a node with access to scratch1 to do more than 24 cores at once! (unless you go for a fat+ partition...)
# for repository users: obviously this batch script won't work on the SLURM-based compute resource that YOU have access to as-is. You'll need to modify to match your own details. But this should be a decent template at least?

cd /scratch2/jgoodma/Mirror-Analysis/Analysis-Scripts # hard-coded directory here, too

module load matlab/R2020b

# Kick off matlab
matlab -c "/home/uni08/jgoodma/.matlab/R2020b/R2020b_licenses/network.lic" -nodisplay < Call.m