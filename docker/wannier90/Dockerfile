FROM intel/oneapi:2026.0.0-devel-ubuntu24.04

RUN apt update \
    && apt install -y --no-install-recommends \
        libxml2-dev \
        build-essential \
        cmake \
        wget \
        vim \
        openmpi-bin \
        openmpi-common \
        libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/
