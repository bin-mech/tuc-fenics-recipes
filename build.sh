#!/bin/bash
set -e

# Number of process for parallel make steps
: ${PROCS:=4}

# Load paths and version
source fenics.conf

# Choose dependencies versions
EIGEN_VERSION=3.3.4
PYBIND11_VERSION=2.2.3
PETSC_VERSION=3.9.1
SLEPC_VERSION=3.9.1
MPI4PY_VERSION=3.0.0
PETSC4PY_VERSION=3.9.1
SLEPC4PY_VERSION=3.9.0
DOLFIN_VERSION="${FENICS_VERSION}.post1"

# Create directory for downloading sources
mkdir -p "${FENICS_PREFIX}/src"

# Update pip, the system one is buggy
pip3 install --user pip

# Install FEniCS Python packages
pip3 install --prefix="${FENICS_PREFIX}" fenics-ffc==${FENICS_VERSION}

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

# Install PETSc
cd "${FENICS_PREFIX}/src"
wget -O petsc-${PETSC_VERSION}.tar.gz http://bitbucket.org/petsc/petsc/get/v${PETSC_VERSION}.tar.gz
mkdir petsc-${PETSC_VERSION}
cd petsc-${PETSC_VERSION}
tar --strip-components=1 -xzf ../petsc-${PETSC_VERSION}.tar.gz
./configure --with-debugging=0 --COPTFLAGS="-O2" --CXXOPTFLAGS="-O2" --FOPTFLAGS="-O2" --download-metis --download-parmetis --download-ptscotch --download-suitesparse --download-openblas --download-scalapack --download-mumps --download-superlu --download-superlu_dist --download-hypre --download-hdf5 --download-hdf5-configure-arguments="--enable-parallel" --prefix="${FENICS_PREFIX}" --with-make-np=${PROCS}
make
make install
export PETSC_DIR="${FENICS_PREFIX}"

# Install SLEPc
#cd "${FENICS_PREFIX}/src"
#wget -O slepc-${SLEPC_VERSION}.tar.gz http://bitbucket.org/slepc/slepc/get/v${SLEPC_VERSION}.tar.gz
#mkdir slepc-${SLEPC_VERSION}
#cd slepc-${SLEPC_VERSION}
#tar --strip-components=1 -xzf ../slepc-${SLEPC_VERSION}.tar.gz
#./configure --prefix="${FENICS_PREFIX}"
#make -j ${PROCS}
#make install
#export SLEPC_DIR="${FENICS_PREFIX}"

# Install various Python packages
pip3 install --upgrade --prefix="${FENICS_PREFIX}" --ignore-installed numpy jupyter matplotlib sympy pkgconfig
#pip3 install --prefix="${FENICS_PREFIX}" https://bitbucket.org/mpi4py/mpi4py/downloads/mpi4py-${MPI4PY_VERSION}.tar.gz
pip3 install --prefix="${FENICS_PREFIX}" https://bitbucket.org/petsc/petsc4py/downloads/petsc4py-${PETSC4PY_VERSION}.tar.gz
#pip3 install --prefix="${FENICS_PREFIX}" https://bitbucket.org/slepc/slepc4py/downloads/slepc4py-${SLEPC4PY_VERSION}.tar.gz

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
pip3 install --prefix="${FENICS_PREFIX}" .

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
pip3 install --prefix="${FENICS_PREFIX}" .
