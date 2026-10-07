#!/bin/bash
module load gcc/13.4.0
module load apptainer/1.4.4

apptainer exec /work/g/gmpantano/image_test/image.sif /bin/bash
