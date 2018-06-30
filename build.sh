#!/bin/bash
set -e

# Number of process for parallel make steps
: ${PROCS:=4}

# Update pip, the system one is buggy
PIP_VERSION=10.0.1
USER_PREFIX="${HOME}/.local"
export PATH="${USER_PREFIX}/bin:${PATH}"
export PYTHONPATH="${USER_PREFIX}/lib/python3.6/site-packages:${PYTHONPATH}"
pip3 install --user pip==${PIP_VERSION}

# Load paths and FEniCS version
source fenics.conf

# Choose dependencies versions
PETSC_VERSION=3.9.1
SLEPC_VERSION=3.9.1
NUMPY_VERSION=1.14.5
MATPLOTLIB_VERSION=2.2.2
JUPYTER_VERSION=1.0.0
SYMPY_VERSION=1.1.1
PKGCONFIG_VERSION=1.3.1
#MPI4PY_VERSION=3.0.0
PETSC4PY_VERSION=3.9.1
SLEPC4PY_VERSION=3.9.0
EIGEN_VERSION=3.3.4
PYBIND11_VERSION=2.2.3
DOLFIN_VERSION="${FENICS_VERSION}.post1"

# Create directory for downloading sources
mkdir -p "${FENICS_PREFIX}/src"

# Install PETSc
cd "${FENICS_PREFIX}/src"
wget -O petsc-${PETSC_VERSION}.tar.gz http://bitbucket.org/petsc/petsc/get/v${PETSC_VERSION}.tar.gz
mkdir petsc-${PETSC_VERSION}
cd petsc-${PETSC_VERSION}
tar --strip-components=1 -xzf ../petsc-${PETSC_VERSION}.tar.gz
./configure --with-debugging=0 --with-fortran-bindings=0 --COPTFLAGS="-O2" --CXXOPTFLAGS="-O2" --FOPTFLAGS="-O2" --download-metis --download-parmetis --download-ptscotch --download-suitesparse --download-openblas --download-scalapack --download-mumps --download-superlu --download-superlu_dist --download-hypre --download-hdf5 --download-hdf5-configure-arguments="--enable-parallel" --prefix="${FENICS_PREFIX}" --with-make-np=${PROCS}
make
make install
export PETSC_DIR="${FENICS_PREFIX}"

# Install SLEPc
cd "${FENICS_PREFIX}/src"
wget -O slepc-${SLEPC_VERSION}.tar.gz http://bitbucket.org/slepc/slepc/get/v${SLEPC_VERSION}.tar.gz
mkdir slepc-${SLEPC_VERSION}
cd slepc-${SLEPC_VERSION}
tar --strip-components=1 -xzf ../slepc-${SLEPC_VERSION}.tar.gz
./configure --prefix="${FENICS_PREFIX}"
make -j ${PROCS}
make install
export SLEPC_DIR="${FENICS_PREFIX}"

# Install various Python packages
NPY_NUM_BUILD_JOBS=${PROCS} OPENBLAS="${FENICS_PREFIX}/lib/libopenblas.a" pip3 install -vv --prefix="${FENICS_PREFIX}" --upgrade --ignore-installed --no-binary="numpy,matplotlib" numpy==${NUMPY_VERSION} matplotlib==${MATPLOTLIB_VERSION}
pip3 install -vv --prefix="${FENICS_PREFIX}" --upgrade --ignore-installed jupyter==${JUPYTER_VERSION} sympy==${SYMPY_VERSION} pkgconfig==${PKGCONFIG_VERSION}
#pip3 install -vv --prefix="${FENICS_PREFIX}" https://bitbucket.org/mpi4py/mpi4py/downloads/mpi4py-${MPI4PY_VERSION}.tar.gz
pip3 install -vv --prefix="${FENICS_PREFIX}" https://bitbucket.org/petsc/petsc4py/downloads/petsc4py-${PETSC4PY_VERSION}.tar.gz
pip3 install -vv --prefix="${FENICS_PREFIX}" https://bitbucket.org/slepc/slepc4py/downloads/slepc4py-${SLEPC4PY_VERSION}.tar.gz

# Install Eigen headers
cd "${FENICS_PREFIX}/src"
wget -O eigen-${EIGEN_VERSION}.tar.gz http://bitbucket.org/eigen/eigen/get/${EIGEN_VERSION}.tar.gz
mkdir eigen-${EIGEN_VERSION}
cd eigen-${EIGEN_VERSION}
tar --strip-components=1 -xzf ../eigen-${EIGEN_VERSION}.tar.gz
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make install

# Install pybind11 headers
cd "${FENICS_PREFIX}/src"
wget -O pybind11-${PYBIND11_VERSION}.tar.gz https://github.com/pybind/pybind11/archive/v${PYBIND11_VERSION}.tar.gz
tar -xzf pybind11-${PYBIND11_VERSION}.tar.gz
cd pybind11-${PYBIND11_VERSION}
mkdir build
cd build
cmake -DPYBIND11_TEST=off -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make install

# Install FEniCS Python packages
pip3 install -vv --prefix="${FENICS_PREFIX}" fenics-ffc==${FENICS_VERSION}

# Get DOLFIN (post release)
cd "${FENICS_PREFIX}/src"
git clone -b ${DOLFIN_VERSION} https://bitbucket.org/fenics-project/dolfin.git

# Build dolfin C++ library
cd "${FENICS_PREFIX}/src/dolfin"
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make -j ${PROCS}
make install

# Build dolfin Python library
cd "${FENICS_PREFIX}/src/dolfin/python"
pip3 install -vv --prefix="${FENICS_PREFIX}" .

# Install dolfin Python demos
cd "${FENICS_PREFIX}/src/dolfin/python/demo"
python3 generate-demo-files.py
mkdir -p "${FENICS_PREFIX}/share/dolfin/demo/python"
cp -r * "${FENICS_PREFIX}/share/dolfin/demo/python"

# Get mshr
cd "${FENICS_PREFIX}/src"
git clone -b ${FENICS_VERSION} https://bitbucket.org/fenics-project/mshr.git

# Build mshr C++ library
cd "${FENICS_PREFIX}/src/mshr"
mkdir build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${FENICS_PREFIX}" ../
make -j ${PROCS}
make install

# Build mshr Python library
cd "${FENICS_PREFIX}/src/mshr/python"
pip3 install -vv --prefix="${FENICS_PREFIX}" .
