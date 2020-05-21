========
Installation
========

| On a Linux (Unix) OS, two steps are required before using PostWRF:
| 


| **1. Installing NCL:**
|   On CentOS or Fedora:

.. code-block:: bash

    sudo dnf install ncl

In case of more information, please see: `Installing NCL <https://www.ncl.ucar.edu/Download/>`_

|
|
| **2. Make the shell scripts executable:**
|   On the main directory of PostWRF:

.. code-block:: bash

    chmode +x postwrf.sh
    chmode +x modules/*.sh