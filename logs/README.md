# Build logs

The original Word guide refers to the output from the VASP Docker image build and the output file was uploaded under logs:

```text
logs/vasp_docker_build.log
```

For future builds, capture a complete plain text Docker build log with example command:

```bash
docker build --progress=plain -t vasp_image /path/to/docker/vasp 2>&1 \
    | tee logs/vasp_docker_build.log
```

This keeps a record of:
- the base image and layers used,
- downloaded dependencies,
- compiler and Intel oneAPI checks,
- zlib/SZIP/HDF5/Wannier90 compilation,
- warnings or errors,
- the final Docker image build status.
