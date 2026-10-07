#!/bin/bash -l
#SBATCH --partition=qcg_gayles_2022
#SBATCH --qos=qcg_gayles22
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=32
#SBATCH --mem-per-cpu=5800MB
#SBATCH --time=05:00:00
#SBATCH -e slurm-%j.err
#SBATCH -o slurm-%j.out

set -x
set -e

module load gcc/13.4.0
module load apptainer/1.4.4

srun --mpi=pmi2 apptainer exec \
    --bind /dev/shm:/dev/shm \
    --bind /work:/work \
    /work/g/gmpantano/image_test/image.sif \
    /work/g/gmpantano/image_test/wannier90-3.1.0-intel/bin/wannier90.x \
    wannier90.1
