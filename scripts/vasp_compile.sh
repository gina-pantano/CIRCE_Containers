#!/bin/bash -l
#SBATCH --job-name=compile_vasp
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
    --bind "$SLURM_SUBMIT_DIR:$SLURM_SUBMIT_DIR" \
    --bind /dev/shm:/dev/shm \
    "$SLURM_SUBMIT_DIR/image.sif" \
    bash -lc "
        source /opt/intel/oneapi/setvars.sh --force
        cd '$SLURM_SUBMIT_DIR/vasp.6.4.3'
        make DEPS=1 -j\${SLURM_CPUS_PER_TASK} all
    "
