====================================
FEniCS build recipes for TU Chemnitz
====================================

Building FEniCS
===============

0. Login to ``tyche.mathematik.tu-chemnitz.de`` (or other machine).

1. Set ``FENICS_PREFIX`` in ``fenics.conf`` as desired.

2. Run ``build.sh`` to build. Alternatively you can do::

    nohup ./build.sh > build.log 2>&1 < /dev/null &

   to prevent the build being killed when terminal
   hangs up (by timeout or closing the SSH session);
   watch the build progress from any terminal by
   ``tail -f build.log``.

3. To test the build run::

    pip3 install --user pytest

    source fenics.conf

    # Run unit tests sequentially
    cd "${FENICS_PREFIX}/src/dolfin/test/unit/python"
    python3 -mpytest

    # Run unit tests in parallel
    cd "${FENICS_PREFIX}/src/dolfin/test/unit/python"
    XFAILS_IN_PARALLEL="test_tao_linear_bound_solver"  # failing tests!?!
    mpirun -n 3 python3 -mpytest -k "not ${XFAILS_IN_PARALLEL}"

    # Test interactive plotting with Matplotlib
    cd "${FENICS_PREFIX}/src/dolfin/demo/documented/poisson/python"
    python3 demo_poisson.py
    mpirun -n 3 python3 demo_poisson.py

4. You might want to add::

    export DIJITSO_CACHE_DIR=...
    export INSTANT_CACHE_DIR=...
    export INSTANT_ERROR_DIR=...

   into ``fenics.conf``.
   If not set, the defaults are ``~/.cache/{dijitso,instant}``.

5.  Install the conf script and clean the sources::

     cp fenics.conf "${FENICS_PREFIX}"
     rm -rf "${FENICS_PREFIX}/src"

Using FEniCS
============

``source fenics.conf`` to use.
