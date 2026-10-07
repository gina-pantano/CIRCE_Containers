#!/bin/bash -l
#SBATCH --partition=qcg_gayles_2022
#SBATCH --qos=qcg_gayles22
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=32
#SBATCH --mem-per-cpu=5800MB
#SBATCH --time=08:00:00
#SBATCH -o slurm-%j.out
#SBATCH -e slurm-%j.err

set -e
set -x

module purge
module load gcc/13.4.0
module load apptainer/1.4.4

IMAGE=/work/g/gmpantano/image_test/vasp_test/new_test/image.sif
VASP=/work/g/gmpantano/image_test/vasp_test/new_test/vasp.6.4.3/bin/vasp_ncl

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
ulimit -s unlimited

echo $(date)

srun --mpi=pmi2 \
    apptainer exec \
    --bind /work:/work \
    --bind /dev/shm:/dev/shm \
    "$IMAGE" \
    bash -lc "
        source /opt/intel/oneapi/setvars.sh --force >/dev/null 2>&1
        export OMP_NUM_THREADS=1
        export MKL_NUM_THREADS=1
        exec '$VASP'
    " > result.out

echo $(date)
