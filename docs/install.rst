============
Installation
============

| On a Linux (Unix) OS, two steps are required before using PostWRF:
| 


| **1. Installing NCL:**
|   On CentOS or Fedora:

.. code-block:: bash

    sudo dnf install ncl

If need more information, please see: `NCL download and installation <https://www.ncl.ucar.edu/Download/>`_

|
|
| **2. Make the shell scripts executable:**
|   On the main directory of PostWRF:

.. code-block:: bash

    chmod +x postwrf.sh
    chmod +x modules/*.sh
