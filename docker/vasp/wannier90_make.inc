# Serial Wannier90 3.1.0 library for linking with VASP
# COMMS=mpi and MPIF90 are intentionally omitted.

F90 = ifx

FCOPTS = -O2 -fPIC
LDOPTS = -O2

LIBDIR = $(MKLROOT)/lib/intel64

LIBS = -L$(LIBDIR) \
       -lmkl_intel_lp64 \
       -lmkl_sequential \
       -lmkl_core \
       -lpthread \
       -lm \
       -ldl
