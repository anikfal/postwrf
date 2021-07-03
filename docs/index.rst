=======================
PostWRF's Documentation
=======================

PostWRF is an interactive tool for the visualizaion and post-processing of the
`Weather Research and Forecasting (WRF) <https://www.mmm.ucar.edu/weather-research-and-forecasting-model>`_
model outputs. PostWRF as an integrated system based on the `NCAR Command Language (NCL) <https://www.ncl.ucar.edu>`_
and Linux shell scripts, acts as a bridge between atmospheric modeling and environmental science, and makes it possible for many environmental scientists to directly visualize the WRF model outputs, without any advanced knowledge in NCL scripting and WRF modeling system.

PostWRF can provide the input data for the RTTOV (radiation transfer) model, out of WRF output files. Moreover, it can visualize the RTTOV output files from ASCII format to a desired format of NetCDF, PNG, GeoTIFF, or even RGB image.

PostWRF codes are publically available at:
 https://github.com/anikfal/PostWRF

.. Go to the Satpy project_ page for source code and downloads.

.. Satpy is designed to be easily extendable to support any meteorological
.. satellite by the creation of plugins (readers, compositors, writers, etc).
.. The table at the bottom of this page shows the input formats supported by
.. the base Satpy installation.

.. note::

    PostWRF is a Linux-based software, developed on Fedora/CentOS. However, it can be tested on the Mac OS.

.. .. versionchanged:: 0.20.0

..     Dropped Python 2 support.

.. .. _project: http://github.com/pytroll/satpy

.. toctree::
    :maxdepth: 2

    pw_overview
    pw_install
    pw_extraction
    pw_geotiff
    pw_contour
    pw_cross
    pw_domain
    pw_diagram
    pw_statistical
    pw_rttov
.. Indices and tables
.. ==================

.. * :ref:`genindex`
.. * :ref:`modindex`
.. * :ref:`search`
