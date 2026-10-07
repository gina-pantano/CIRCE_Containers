FROM intel/oneapi:2026.0.0-devel-ubuntu24.04

# Use bash and source Intel oneAPI environment in every RUN step
SHELL ["/bin/bash", "-c"]

# Installation locations inside the container
ENV INSTALL_PREFIX=/usr/local
ENV WANNIER90_ROOT=${INSTALL_PREFIX}/wannier90
ENV HDF5_ROOT=${INSTALL_PREFIX}
ENV PATH=${INSTALL_PREFIX}/wannier90/bin:${PATH}
ENV LD_LIBRARY_PATH=${INSTALL_PREFIX}/lib:${INSTALL_PREFIX}/lib64:${LD_LIBRARY_PATH}
ENV LIBRARY_PATH=${INSTALL_PREFIX}/lib:${INSTALL_PREFIX}/lib64:${LIBRARY_PATH}
ENV CPATH=${INSTALL_PREFIX}/include:${CPATH}

#=====================================================================
# System packages
#=====================================================================
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        m4 \
        cmake \
        make \
        wget \
        curl \
        git \
        rsync \
        unzip \
        tar \
        gzip \
        xz-utils \
        pkg-config \
        vim \
        ca-certificates && \
    rm -rf /var/lib/apt/lists/*

#=====================================================================
# Verify Intel oneAPI tools
#=====================================================================
RUN source /opt/intel/oneapi/setvars.sh --force >/dev/null 2>&1 && \
    echo "Intel C compiler:" && \
    which icx && \
    icx --version && \
    echo "Intel C++ compiler:" && \
    which icpx && \
    icpx --version && \
    echo "Intel Fortran compiler:" && \
    which ifx && \
    ifx --version && \
    echo "Intel MPI C wrapper:" && \
    which mpiicx && \
    mpiicx --version && \
    echo "Intel MPI C++ wrapper:" && \
    which mpiicpx && \
    mpiicpx --version && \
    echo "Intel MPI Fortran wrapper:" && \
    which mpiifx && \
    mpiifx --version && \
    echo "Intel MPI launcher:" && \
    which mpirun && \
    echo "MKLROOT=${MKLROOT}" && \
    test -f "${MKLROOT}/lib/intel64/libmkl_core.so"

#=====================================================================
# 1. ZLIB
#=====================================================================
WORKDIR /build/zlib
RUN source /opt/intel/oneapi/setvars.sh --force && \
    wget https://zlib.net/zlib-1.3.2.tar.gz && \
    tar -xzf zlib-1.3.2.tar.gz && \
    cd zlib-1.3.2 && \
    CC=icx ./configure --prefix=${INSTALL_PREFIX} && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    echo "zlib done"

#=====================================================================
# 2. SZIP
#=====================================================================
WORKDIR /build/szip
RUN source /opt/intel/oneapi/setvars.sh --force && \
    wget https://support.hdfgroup.org/ftp/lib-external/szip/2.1.1/src/szip-2.1.1.tar.gz && \
    tar -xzf szip-2.1.1.tar.gz && \
    cd szip-2.1.1 && \
    CC=icx ./configure --prefix=${INSTALL_PREFIX} && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    echo "szip done"

#=====================================================================
# 3. HDF5 (parallel, Fortran enabled — required by VASP)
#=====================================================================
WORKDIR /build/hdf5
RUN source /opt/intel/oneapi/setvars.sh --force && \
    wget -O hdf5-1.14.6.tar.gz \
    https://github.com/HDFGroup/hdf5/archive/refs/tags/hdf5_1.14.6.tar.gz && \
    tar -xzf hdf5-1.14.6.tar.gz && \
    cd hdf5-hdf5_1.14.6 && \
    autoreconf -fi && \
    CC=mpiicx \
    CXX=mpiicpx \
    FC=mpiifx \
    ./configure \
        --prefix=${INSTALL_PREFIX} \
        --enable-parallel \
        --enable-fortran \
        --enable-hl \
        --enable-shared \
        --with-zlib="${INSTALL_PREFIX}" \
        --with-szlib="${INSTALL_PREFIX}" && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    echo "HDF5 installation complete" && \
    find "${INSTALL_PREFIX}" \
        \( -name "libhdf5_fortran*" -o -name "hdf5.mod" \) \
        -print

#=====================================================================
# 4. WANNIER90
# wannier90_make.inc is copied from build context
#=====================================================================
COPY wannier90_make.inc /build/wannier90/make.inc

WORKDIR /build/wannier90
RUN source /opt/intel/oneapi/setvars.sh --force && \
    wget https://github.com/wannier-developers/wannier90/archive/v3.1.0.tar.gz && \
    tar -xzf v3.1.0.tar.gz && \
    cp make.inc wannier90-3.1.0/make.inc && \
    cd wannier90-3.1.0 && \
    make -j$(nproc) && \
    make -j$(nproc) lib && \
    mkdir -p ${INSTALL_PREFIX}/wannier90/{bin,lib,include} && \
    cp wannier90.x postw90.x ${INSTALL_PREFIX}/wannier90/bin/ && \
    cp libwannier.a ${INSTALL_PREFIX}/wannier90/lib/ && \
    echo "Wannier90 done"

WORKDIR /workspace
