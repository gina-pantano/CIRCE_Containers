#!/bin/bash -l
#SBATCH --job-name=compile_wannier90
#SBATCH --partition=qcg_gayles_2022
#SBATCH --qos=qcg_gayles22
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64G
#SBATCH --time=03:00:00
#SBATCH -o compile-%j.out
#SBATCH -e compile-%j.err

set -e
set -x

module load gcc/13.4.0
module load apptainer/1.4.4

apptainer exec \
    --bind /work:/work \
    /work/g/gmpantano/image_test/image.sif \
    bash wannier90_compile.sh
