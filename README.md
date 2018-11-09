# PostWRF (Version 1.0)
A Linux-based post-processing suite for the Weather Research and Forecasting (WRF) model.

On the release tab, you can get a more developed version (v1.0-iran), with the capability of overlaying Iran's provinces on the contour maps, as well as other small developments and bug-fixes.

How to run
In the directory of postwrf.sh:
chmode +x postwrf.sh
chmode +x modules/*.sh
ln -s /directory/of/your/wrfouts/wrfout_d0* .
Set namelist.wrf according to your desired post processing task
Execute postwrf.sh (./postwrf.sh)
