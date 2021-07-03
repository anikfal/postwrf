========
Overview
========
For each post-processing task, there are one or more corresponding NCL scripts which are
automatically modified by the Linux shell scripts. The end user does not need to make any direct
modifications on the NCL scripts, rather, the Linux shell scripts act as
proxies between NCL codes and the end user, in modifying the NCL codes
with regard to some primary input data, provided by the user.

Software structure
==================

The processing steps through PostWRF is depicted below as a flowchart diagram:

.. figure:: images/flowchart.png
   :scale: 50 %
   :alt: map to buried treasure
   
   PostWRF structure and run processes

Run PostWRF
===========

Modify namelist.wrf and enable the section associated with the desired post-processing task:

.. code-block:: bash

    vi namelist.wrf

Run the tool:

.. code-block:: bash

    ./postwrf.sh

The user can Run postwrf.sh with some special switches. Each switch is described by the command bellow:

.. code-block:: bash

    ./postwrf.sh -h
