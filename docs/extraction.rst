============================
WRF and ERA5 Data extraction
============================


The very first step in running PostWRF is modifying namelist.wrf:

.. code-block:: bash

    vi namelist.wrf

Time-series of the WRF variables
================================

The first section in namelist.wrf corresponds to the data extraction:


.. role:: raw-html(raw)
    :format: html

.. |s| unicode:: U+00A0 .. non-breaking space


+-------------------------------------------------------------------------------------------------------------------------------+
| \==================== DATA EXTRACTION \======================= :raw-html:`<br />`                                             |
| \============================================================ :raw-html:`<br />`                                              |
| WRF_Extract_On-Off |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| = 1 :raw-html:`<br />`                             |
| ERA5_Extract_On-Off |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| = 0 :raw-html:`<br />`                            |
|                                                                                                                               |
| WRF_variable_name |s| |s| |s| |s| |s| |s| |s| |s| |s| = pvo :raw-html:`<br />`                                                |
| Location_names |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| = Berlin, London :raw-html:`<br />`                        |
| Location_latitudes |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| = 52.52, 51.51 :raw-html:`<br />`                              |
| Location_longitudes |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| = 13.40, 00.10        :raw-html:`<br />`                          |
|                                                                                                                               |
| \+Vertical_profile_plot_on_off |s| |s|  = 0     :raw-html:`<br />`                                                            |
| \+Vprofile_X_axis_decimals     |s| |s| |s| |s| = 3                                                                            |
+-------------------------------------------------------------------------------------------------------------------------------+


After modifying namelist.wrf, run the software by:

.. code-block:: bash

    ./postwrf.sh

| During the run process, the method of data extraction (interpolation) will be inquired. Three interpolation methods are available:

1. Nearest point
2. Bilinear
3. IDW

| The Output as an ascii file will be saved in a folder with a name similar to the name of the selected WRF file:

+-------------------------------------------------------------------------------------------------------------------------------+
| \--------------------------------------------------------------------------------------------------------- :raw-html:`<br />` |
| \ WRF output variable: pvo (Potential Vorticity) - unit_scale: PVU :raw-html:`<br />`                                         |
| \--------------------------------------------------------------------------------------------------------- :raw-html:`<br />` |
| |s| |s| |s| |s| |s| |s| |s| |s| |s| |s| Time |s| |s| |s| |s|   Berlin_(52.52-13.40)  |s| |s| |s| |s|  London_(51.51-00.10)    |
| 2021-11-01_06:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.26  |s| |s| |s| |s| |s| |s| |s| |s| -0.33    :raw-html:`<br />`       |
| 2021-11-01_07:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.27  |s| |s| |s| |s| |s| |s| |s| |s| -0.25    :raw-html:`<br />`       |
| 2021-11-01_08:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.29  |s| |s| |s| |s| |s| |s| |s| |s| -0.22    :raw-html:`<br />`       |
| 2021-11-01_09:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.28  |s| |s| |s| |s| |s| |s| |s| |s| -0.24    :raw-html:`<br />`       |
| 2021-11-01_10:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.25  |s| |s| |s| |s| |s| |s| |s| |s| -0.22    :raw-html:`<br />`       |
| 2021-11-01_11:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.22  |s| |s| |s| |s| |s| |s| |s| |s| -0.15    :raw-html:`<br />`       |
| 2021-11-01_12:00:00  |s| |s| |s| |s| |s| |s| |s| |s| -0.18 |s| |s| |s| |s| |s| |s| |s| |s| |s| 0.01  :raw-html:`<br />`       |
| 2021-11-01_13:00:00 |s| |s| |s| |s| |s| |s| |s| |s| |s| 0.22 |s| |s| |s| |s| |s| |s| |s| |s| 1.79 :raw-html:`<br />`          |
| 2021-11-01_14:00:00 |s| |s| |s| |s| |s| |s| |s| |s| |s| 2.59 |s| |s| |s| |s| |s| |s| |s| |s|  3.91   :raw-html:`<br />`       |
| 2021-11-01_15:00:00 |s| |s| |s| |s| |s| |s| |s| |s| |s| 3.22  |s| |s| |s| |s| |s| |s| |s| |s| 5.22    :raw-html:`<br />`      |
| 2021-11-01_16:00:00 |s| |s| |s| |s| |s| |s| |s| |s| |s| 2.53  |s| |s| |s| |s| |s| |s| |s| |s| 6.81    :raw-html:`<br />`      |
+-------------------------------------------------------------------------------------------------------------------------------+

.. .. csv-table:: WRF output variable: pvo (Potential Vorticity) - unit_scale: PVU
..    :file: values-pvo-Bilinear
..    :widths: 40, 20, 20

.. note::
   ERA5 data can tbe extracted by the same method. Set *ERA5_Extract_On-Off* to 1, and *WRF_Extract_On-Off* to 0. For ERA5 data, only one method (bilinear) is applied for interpolation. Moreover, unlike the WRF data, for ERA5 data the start and end of time slots can be specified.

Plotting vertical profiles (for WRF outputs)
============================================

If +Vertical_profile_plot_on_off is set to 1, the vertical profiles of the locations (Berlin and London) 
will be plotted:

.. figure:: images/vertical_plot-d01_2020-04-01.000003.png
   :scale: 60 %
   :alt: map to buried treasure
   
   Vertical profiles of the potential vorticity over two locations of London and Berlin
