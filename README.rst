====================================
FEniCS build recipes for TU Chemnitz
====================================

0. Login to ``tyche.mathematik.tu-chemnitz.de``.

1. Set ``FENICS_PREFIX`` in ``fenics.conf`` as desired.

2. Run ``build.sh`` to build. You can do::

    nohup ./build.sh > build.log 2>&1 < /dev/null &

   and watch the build from other terminal by
   ``tail -f build.log``.

3. Run ``source fenics.conf`` to use. You can do cleanup by
   ``rm -rf "${FENICS_PREFIX}/src"`` if you want.
