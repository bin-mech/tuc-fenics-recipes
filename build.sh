#!/bin/bash
set -e -x

# Number of process for parallel make steps
: ${PROCS:=$(($(nproc)/2+1))}

# Update pip, the system one is buggy
PIP_VERSION=10.0.1
USER_SITE=$(python3 -c"import site, sys; sys.stdout.write(site.getusersitepackages())")
mkdir -p "${USER_SITE}"
export PYTHONPATH="${USER_SITE}:${PYTHONPATH}"
PIP3="python3 -m pip"
${PIP3} install --user pip==${PIP_VERSION}

# Load paths and FEniCS version
source fenics.conf

# Choose dependencies versions
PETSC_VERSION=3.8.4
SLEPC_VERSION=3.8.3
NUMPY_VERSION=1.14.5
MATPLOTLIB_VERSION=2.2.2
SCIPY_VERSION=1.1.0
JUPYTER_VERSION=1.0.0
SYMPY_VERSION=1.1.1
PLY_VERSION=3.11
FLUFLLOCK_VERSION=3.2
SIX_VERSION=1.11.0
#MPI4PY_VERSION=3.0.0
PETSC4PY_VERSION=3.8.1
SLEPC4PY_VERSION=3.8.0
EIGEN_VERSION=3.3.4
DOLFIN_VERSION="${FENICS_VERSION}.post0"

# Compiler flags
export CFLAGS="-O2 -pipe -march=native -ftree-vectorize"
export CXXFLAGS="-O2 -pipe -march=native -ftree-vectorize"
export FFLAGS="-O2 -pipe -march=native -ftree-vectorize"

# Create directory for downloading sources
mkdir -p "${FENICS_PREFIX}/src"

# Install PETSc
cd "${FENICS_PREFIX}/src"
wget -O petsc-${PETSC_VERSION}.tar.gz http://bitbucket.org/petsc/petsc/get/v${PETSC_VERSION}.tar.gz
mkdir -p petsc-${PETSC_VERSION}
cd petsc-${PETSC_VERSION}
tar --strip-components=1 -xzf ../petsc-${PETSC_VERSION}.tar.gz
rm ../petsc-${PETSC_VERSION}.tar.gz
./configure \
    --with-debugging=0 \
    --with-fortran-bindings=0 \
    --COPTFLAGS="${CFLAGS}" \
    --CXXOPTFLAGS="${CXXFLAGS}" \
    --FOPTFLAGS="${FFLAGS}" \
    --download-metis \
    --download-parmetis \
    --download-ptscotch \
    --download-suitesparse \
    --download-openblas \
    --download-scalapack \
    --download-mumps \
    --download-superlu \
    --download-superlu_dist \
    --download-hypre \
    --download-hdf5 --download-hdf5-configure-arguments="--enable-parallel" \
    --prefix="${FENICS_PREFIX}" \
    --with-make-np=${PROCS}
make
make install
make clean
export PETSC_DIR="${FENICS_PREFIX}"

# Install SLEPc
cd "${FENICS_PREFIX}/src"
wget -O slepc-${SLEPC_VERSION}.tar.gz http://bitbucket.org/slepc/slepc/get/v${SLEPC_VERSION}.tar.gz
mkdir -p slepc-${SLEPC_VERSION}
cd slepc-${SLEPC_VERSION}
tar --strip-components=1 -xzf ../slepc-${SLEPC_VERSION}.tar.gz
rm ../slepc-${SLEPC_VERSION}.tar.gz
./configure --prefix="${FENICS_PREFIX}"
make
make install
make clean
export SLEPC_DIR="${FENICS_PREFIX}"

# Build NumPy, Matplotlib, SciPy against our BLAS/LAPACK
NPY_NUM_BUILD_JOBS=${PROCS} OPENBLAS="${FENICS_PREFIX}/lib/libopenblas.a" \
    ${PIP3} install -vv --prefix="${FENICS_PREFIX}" --upgrade --ignore-installed \
    --no-binary="numpy,matplotlib,scipy" \
    numpy==${NUMPY_VERSION} \
    matplotlib==${MATPLOTLIB_VERSION} \
    scipy==${SCIPY_VERSION}

# Install other Python packages
${PIP3} install -vv --prefix="${FENICS_PREFIX}" --upgrade --ignore-installed \
    jupyter==${JUPYTER_VERSION} \
    sympy==${SYMPY_VERSION} \
    ply==${PLY_VERSION} \
    flufl.lock==${FLUFLLOCK_VERSION} \
    six==${SIX_VERSION}

# Build mpi4py, petsc4py, slepc4py from source
#${PIP3} install -vv --prefix="${FENICS_PREFIX}" \
#    https://bitbucket.org/mpi4py/mpi4py/downloads/mpi4py-${MPI4PY_VERSION}.tar.gz
${PIP3} install -vv --prefix="${FENICS_PREFIX}" \
    https://bitbucket.org/petsc/petsc4py/downloads/petsc4py-${PETSC4PY_VERSION}.tar.gz
${PIP3} install -vv --prefix="${FENICS_PREFIX}" \
    https://bitbucket.org/slepc/slepc4py/downloads/slepc4py-${SLEPC4PY_VERSION}.tar.gz

# Install Eigen headers
cd "${FENICS_PREFIX}/src"
wget -O eigen-${EIGEN_VERSION}.tar.gz http://bitbucket.org/eigen/eigen/get/${EIGEN_VERSION}.tar.gz
mkdir -p eigen-${EIGEN_VERSION}
cd eigen-${EIGEN_VERSION}
tar --strip-components=1 -xzf ../eigen-${EIGEN_VERSION}.tar.gz
rm ../eigen-${EIGEN_VERSION}.tar.gz
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make install
rm -rf ../build

# Install FEniCS Python packages
cd "${FENICS_PREFIX}/src"
${PIP3} install -vv --prefix="${FENICS_PREFIX}" fenics-ffc==${FENICS_VERSION}
${PIP3} install -vv --prefix="${FENICS_PREFIX}" \
    https://bitbucket.org/fenics-project/instant/downloads/instant-${FENICS_VERSION}.tar.gz

# Get DOLFIN (post release)
cd "${FENICS_PREFIX}/src"
wget https://bitbucket.org/fenics-project/dolfin/downloads/dolfin-${DOLFIN_VERSION}.tar.gz
mkdir -p dolfin
cd dolfin
tar --strip-components=1 -xzf ../dolfin-${DOLFIN_VERSION}.tar.gz
rm ../dolfin-${DOLFIN_VERSION}.tar.gz

# Build dolfin
cd "${FENICS_PREFIX}/src/dolfin"
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make -j ${PROCS}
make install
rm -rf ../build

# Get mshr
cd "${FENICS_PREFIX}/src"
wget https://bitbucket.org/fenics-project/mshr/downloads/mshr-${FENICS_VERSION}.tar.gz
mkdir -p mshr
cd mshr
tar --strip-components=1 -xzf ../mshr-${FENICS_VERSION}.tar.gz
rm ../mshr-${FENICS_VERSION}.tar.gz

# Build mshr
cd "${FENICS_PREFIX}/src/mshr"
mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make -j ${PROCS}
make install
rm -rf ../build
