# PostWRF (Version 1.0)
A Linux-based post-processing suite for the Weather Research and Forecasting (WRF) model

In the directory of postwrf.sh:
chmode +x postwrf.sh
chmode +x modules/*.sh
ln -s /directory/of/your/wrfouts/wrfout_d0* .
Set namelist.wrf according to your desired post processing task
Execute postwrf.sh (./postwrf.sh)
