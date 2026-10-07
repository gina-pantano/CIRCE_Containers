# CIRCE_Containers
Practical guide for creating a container to compile and run VASP and Wannier90 on the University of South Florida Central Instructional and Research Computing Environment (CIRCE). It is a high-performance computing cluster administered by USF Research Computing for academic and research-related workloads.

> **Repository scope**
>
> This repository documents the Docker → Apptainer → Slurm workflow used by the Quantum Chiraltronics Group (QCG). It also contains the Dockerfiles, compiler configuration files, and Slurm scripts from the technical appendices of the original Word guide.
>
> VASP itself is **not** distributed here. Users must obtain the VASP source from their account on the portal login: https://vasp.at/sign_in/portal/

---

## Contents

```text
CIRCE_Containers/
├── README.md
├── .gitignore
├── docker/
│   ├── vasp/
│   │   ├── Dockerfile
│   │   └── wannier90_make.inc
│   │   └── image.sif
│   └── wannier90/
│       └── Dockerfile
│   │   └── image.sif
├── configs/
│   └── vasp/
│       └── makefile.include
├── scripts/
│   ├── container_test.sh
│   ├── vasp_compile.sh
│   ├── vasp_job.sh
│   ├── wannier90_compile.sh
│   ├── wannier90_compile_job.sh
│   └── wannier90_job.sh
├── logs/
│   └── README.md
└── docs/
    └── ContainerNotes.docx
```

---

# Overview

Docker packages an application and its dependencies into a reproducible software environment. For this workflow, Docker is used to build the software environment, while Apptainer is used to run that environment safely on CIRCE.

### Key terms

**Container**  
A runnable instance of an image. It bundles the application environment with the libraries, dependencies, and configuration needed at runtime.

**Image**  
A read-only template used to create containers. Docker images are built from a `Dockerfile`.

**Dockerfile**  
A plain text set of instructions describing how to build a Docker image.

**Apptainer image (`.sif`)**  
The container image format used on CIRCE.

---

## General workflow

```text
Group/local machine
      │
      ▼
Create Dockerfile
      │
      ▼
Docker build image
      │
      ▼
Docker save → image.tar
      │
      ▼
Transfer image.tar to CIRCE
      │
      ▼
Apptainer build → image.sif
      │
      ▼
Compile VASP/Wannier90 running image.sif
      │
      ▼
Submit Slurm test jobs
      │
      ▼
Working container!
```

---

# 1. Install Docker

Docker requires privileged/root-level capabilities that are normally unavailable to users on HPC systems. Therefore, **do not install Docker on CIRCE**. Install Docker on a group controlled machine or local computer where you have administrator privileges.

Official installation documentation:

- Linux: https://docs.docker.com/engine/install/
- Windows: https://docs.docker.com/desktop/setup/install/windows-install/
- macOS: https://docs.docker.com/desktop/setup/install/mac-install/

## Linux example

```bash
sudo apt update
sudo apt install ca-certificates curl
sudo apt install docker.io
sudo systemctl enable --now docker
sudo docker run hello-world
```

An administrator may optionally add a trusted user to the Docker group:

```bash
sudo usermod -aG docker $USER
```

Log out and back in after this change.

> **Security note:** Membership in the `docker` group effectively grants root-level privileges. Use it only on trusted systems.

## Windows

Install WSL 2:

```powershell
wsl --install
wsl --update
wsl -l -v
```

Then install Docker Desktop and enable its WSL 2 backend.

Test:

```bash
docker --version
docker run hello-world
```

## macOS

Check the processor architecture:

```bash
uname -m
```

- `arm64` = Apple silicon
- `x86_64` = Intel Mac

For Apple silicon, explicitly build an AMD64 Linux image when the target HPC system is x86-64 such as:

```bash
docker build --platform linux/amd64 -t myimage .
```

---

# 2. Create the Docker image definition

Create a build directory:

```bash
mkdir docker
cd docker
```

Create a file named exactly:

```text
Dockerfile
```

Every Dockerfile starts from a base image. The VASP and Wannier90 examples in this repository use:

```dockerfile
FROM intel/oneapi:2026.0.0-devel-ubuntu24.04
```

The Intel oneAPI development image provides the Intel compilers, Intel MPI, and MKL environment used by these builds.

Docker Hub can be searched for other base images:

https://hub.docker.com/search

## Common Dockerfile instructions

| Instruction | Purpose |
|---|---|
| `FROM` | Select the base image |
| `RUN` | Execute a command while building the image |
| `COPY` | Copy files from the Docker build context into the image |
| `ADD` | Similar to `COPY`, with additional behaviors |
| `ENV` | Define environment variables |
| `WORKDIR` | Set the working directory inside the image |
| `CMD` | Set the image's default command |
| `USER` | Set the default user |
| `EXPOSE` | Document a network port expected by the image |

### Build context

When a command such as

```bash
docker build -t vasp_image /home/gmpantano/mythings/docker/vasp
```

is run, the final directory is the **Docker build context**. Files required by `COPY` instructions must be inside that context.

For the VASP image in this repository, the build directory should contain:

```text
docker/vasp/
├── Dockerfile
└── wannier90_make.inc
```

The serial Wannier90 library built in the VASP image is used for VASP-to-Wannier90 support. See documentation for reference: https://vasp.at/wiki/Makefile.include

---

# 3. Build, export, transfer, and convert the image

For QCG members, connect to the Docker node while on IRIS before running Docker commands:

```bash
ssh gmpantano@qcg-docker
```

Adapt the username as needed and use your normal password for IRIS.

## Build the VASP environment image

From the repository root:

```bash
docker build -t vasp_image /home/gmpantano/mythings/docker/vasp
```

To keep a complete build record (have not tested myself):

```bash
docker build --progress=plain -t vasp_image /home/gmpantano/mythings/docker/vasp 2>&1 \
    | tee logs/vasp_docker_build.log
```

See [`logs/README.md`](logs/README.md) for the expected build-log location.

## List local images

```bash
docker images
```

## Export the image

Save the completed Docker image as a transferable archive:

```bash
docker save -o /home/gmpantano/mythings/docker/image.tar vasp_image:latest
```

> **Important:** Do not save `image.tar` inside the Docker build directory. The archive can be many gigabytes and keeping it inside the build context can lead to complications if the image needs rebuilt.

## Transfer to CIRCE

Example:

```bash
rsync -avP /home/gmpantano/mythings/docker/image.tar USER@CIRCE:/destination/path/
```

`-P` shows transfer progress and preserves a partially transferred file if the connection is interrupted.

## Convert the Docker archive to Apptainer

On CIRCE:

```bash
module load apps/apptainer/1.3.5
apptainer build /path/where/you/want/image.sif docker-archive:///path/to/image.tar
```

The generated `image.sif` is the image used for compilation and running jobs.

## Test the container interactively

Request a compute-node shell:

```bash
srun \
    --partition=qcg_gayles_2022 \
    --qos=qcg_gayles22 \
    --pty /bin/bash -i
```

Then load Apptainer and open a shell inside the container:

```bash
module load gcc/13.4.0
module load apptainer/1.4.4

apptainer exec \
    /work/g/gmpantano/image_test/image.sif \
    /bin/bash
```

A reusable example is provided at:

[`scripts/container_test.sh`](scripts/container_test.sh)

---

# 4A. Compile and run VASP

## Obtain the VASP source

Download the licensed source from the VASP portal or another authorized source and place the .tgz file in the directory where VASP will be compiled.

Example:

```text
vasp.6.4.3.tgz
```

Extract it:

```bash
tar -xzvf vasp.6.4.3.tgz
```

## Add `makefile.include`

Copy:

[`configs/vasp/makefile.include`](configs/vasp/makefile.include)

into the VASP source directory:

```text
vasp.6.4.3/
├── makefile.include
├── src/
├── build/
└── ...
```

## Compile VASP

The example compilation job is:

[`scripts/vasp_compile.sh`](scripts/vasp_compile.sh)

Submit it from the directory containing the VASP source and `image.sif`:

```bash
sbatch scripts/vasp_compile.sh
```

The script uses one Slurm task with 32 CPUs and compiles VASP inside the Apptainer environment.

## Run a test VASP job

Use:

[`scripts/vasp_job.sh`](scripts/vasp_job.sh)

Update these variables for the actual installation:

```bash
IMAGE=/path/to/image.sif
VASP=/path/to/vasp.6.4.3/bin/vasp_ncl
```

Then submit:

```bash
sbatch scripts/vasp_job.sh
```

The example requests:

```text
2 nodes
32 MPI tasks/node
64 MPI tasks total
5800 MB/task
```

The production command is launched through:

```bash
srun --mpi=pmi2 apptainer exec ...
```

### VASP workflow

```text
Obtain VASP source
      ↓
Extract archive
      ↓
Add and edit makefile.include
      ↓
Compile inside image.sif
      ↓
Locate VASP executable
      ↓
Submit Slurm test
      ↓
Verify MPI execution
```

---

# 4B. Compile and run Wannier90

The standalone Wannier90 workflow uses a separate, MPI-enabled Wannier90 build.

## Build the Wannier90 Docker environment

```bash
docker build -t wannier90-image ./docker/wannier90
```

Export and convert the image using the same Docker → `image.tar` → Apptainer procedure described above.

## Compile Wannier90 3.1.0

The compilation script is:

[`scripts/wannier90_compile.sh`](scripts/wannier90_compile.sh)

It downloads Wannier90 3.1.0 and creates:

```text
wannier90-3.1.0-intel/
├── bin/
│   ├── wannier90.x
│   └── postw90.x
└── lib/
    └── libwannier.a
```

Important `make.inc` settings:

```makefile
F90 = ifx
COMMS=mpi
MPIF90=mpiifx
```

`COMMS=mpi` and `MPIF90=mpiifx` make the standalone Wannier90 executable MPI-enabled.

The commands:

```bash
make -j4
make -j4 lib
```

use four build jobs to accelerate compilation. `-j4` does not itself provide MPI parallelism.

Submit the wrapper job:

```bash
sbatch scripts/wannier90_compile_job.sh
```

## Run Wannier90

Use:

[`scripts/wannier90_job.sh`](scripts/wannier90_job.sh)

Example:

```bash
sbatch scripts/wannier90_job.sh
```

The example launches `wannier90.x` through Slurm on two nodes.

### Wannier90 workflow

```text
Build/convert Wannier90 container
      ↓
Run wannier90_compile.sh
      ↓
Create MPI-enabled wannier90.x
      ↓
Submit Slurm test job
      ↓
Verify parallel execution
```

---

# Appendix files

The original technical appendices have been separated into working repository files.

| Original appendix | Repository file |
|---|---|
| Appendix A — VASP container Dockerfile | [`docker/vasp/Dockerfile`](docker/vasp/Dockerfile) |
| Appendix B — Wannier90 container Dockerfile | [`docker/wannier90/Dockerfile`](docker/wannier90/Dockerfile) |
| Appendix C — `wannier90_make.inc` | [`docker/vasp/wannier90_make.inc`](docker/vasp/wannier90_make.inc) |
| Appendix D — VASP `makefile.include` | [`configs/vasp/makefile.include`](configs/vasp/makefile.include) |
| Appendix E — VASP compile script | [`scripts/vasp_compile.sh`](scripts/vasp_compile.sh) |
| Appendix F — VASP Slurm job | [`scripts/vasp_job.sh`](scripts/vasp_job.sh) |
| Appendix G — Wannier90 compile scripts | [`scripts/wannier90_compile.sh`](scripts/wannier90_compile.sh), [`scripts/wannier90_compile_job.sh`](scripts/wannier90_compile_job.sh) |
| Appendix H — Wannier90 Slurm job | [`scripts/wannier90_job.sh`](scripts/wannier90_job.sh) |
| Appendix I — useful commands | See below |

---

# Useful commands

Check CIRCE disk quota:

```bash
show-quota.sh
```

Check quota for `/work`:

```bash
show-quota.sh /work
```

List Docker images:

```bash
docker images
```

Remove a Docker image:

```bash
docker rmi IMAGE_NAME_OR_ID
```

Export an image:

```bash
docker save -o image.tar IMAGE_NAME:TAG
```

Build an Apptainer image from the Docker archive:

```bash
apptainer build image.sif docker-archive://image.tar
```

Find the libraries used by an executable inside the container:

```bash
apptainer exec \
    --bind /work:/work \
    image.sif \
    ldd /path/to/executable
```

For the tested standalone Wannier90 executable, `ldd` showed Intel MPI libraries such as `libmpifort.so.12` and `libmpi.so.12` from the Intel oneAPI MPI installation.

---

# Rebuilding an image

Docker and Apptainer images should be treated as generated artifacts.

If the environment must change:

1. Edit the `Dockerfile` or supporting build files.
2. Run `docker build` again.
3. Export a new `image.tar`.
4. Transfer the new archive to CIRCE.
5. Regenerate `image.sif`.
6. Re-run the test jobs with new `image.sif` file.

---

# Build logs

A build log is valuable because it records the exact point at which a dependency or compiler check succeeded or failed.

Capture a Docker build with:

```bash
docker build --progress=plain -t testimage ./docker/vasp 2>&1 \
    | tee logs/vasp_docker_build.log
```
---

# Notes

- Paths in the example scripts are specific to the original QCG setup and should be changed for another user or installation.
- Confirm the currently available CIRCE module versions with `module avail` before reproducing the workflow.
- The standalone Wannier90 image and the VASP image serve different purposes: the VASP image contains the Wannier90 library used for VASP linking, while the standalone Wannier90 workflow builds an MPI-enabled `wannier90.x`.
- The VASP source is licensed and is intentionally not included in this repository.

---

## Original documentation

The source Word guide is retained at:

[`docs/ContainerNotes.docx`](docs/ContainerNotes.docx)

This README reorganizes that guide into a repository-oriented workflow and separates the technical appendices into reusable files.
