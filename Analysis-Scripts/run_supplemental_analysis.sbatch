#!/bin/bash

#SBATCH -p medium
#SBATCH -t 24:00:00
#SBATCH -N 1
#SBATCH -c 24
#SBATCH -C scratch
#SBATCH --mail-type=BEGIN,END,FAIL

cd /scratch/users/jgoodma/Mirror-Analysis/Analysis-Scripts # hard-coded directory here, too

# module load matlab/R2020b
module load matlab

# Kick off matlab
# matlab -c "/home/uni08/jgoodma/.matlab/R2020b/R2020b_licenses/network.lic" -nodisplay < supplementalCall.m
matlab -nodisplay < supplementalCall.m