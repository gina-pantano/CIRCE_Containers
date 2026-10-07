# Build logs

The original Word guide refers to the output from the VASP Docker image build, but that build-output file was **not included in the uploaded source document** used to create this repository.

When the original VASP build log is available, place it here as:

```text
logs/vasp_docker_build.log
```

For future builds, capture a complete plain-text Docker build log with:

```bash
docker build --progress=plain -t testimage /path/to/docker/vasp 2>&1 \
    | tee logs/vasp_docker_build.log
```

This keeps a record of:
- the base image and layers used,
- downloaded dependencies,
- compiler and Intel oneAPI checks,
- zlib/SZIP/HDF5/Wannier90 compilation,
- warnings or errors,
- the final Docker image build status.

Do **not** commit `image.tar` or `image.sif` to Git. They are large generated artifacts and are excluded by the repository `.gitignore`.
