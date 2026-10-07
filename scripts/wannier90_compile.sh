#!/bin/bash

set -e
set -x

wget https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz
tar -xf v3.1.0.tar.gz
mv wannier90-3.1.0 wannier90-3.1.0-intel
cd wannier90-3.1.0-intel

cat > make.inc <<- EOM
F90 = ifx
COMMS=mpi
MPIF90=mpiifx
FCOPTS=-O2
LDOPTS=-O2
LIBDIR = \$(MKLROOT)
LIBS   = -L\$(LIBDIR) -lmkl_core -lmkl_intel_lp64 -lmkl_sequential -lpthread
EOM

make -j4
make -j4 lib

mkdir -v bin
mkdir -v lib
mv -v libwannier.a lib/
mv -v postw90.x bin/
mv -v wannier90.x bin/
