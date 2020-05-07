#!/bin/bash
#PostWRF Version 1.1 (Apr 2020)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
curdir=`pwd`
trap 'my_exit; exit' SIGINT SIGQUIT
count=0
my_exit()
{
curdir2=`pwd`
rm timestep_file 2> /dev/null
if [[ $curdir != $curdir2 ]]; then

wrflist=`ls wrfout*`
totnom=`echo $wrflist | wc -w`
rmcounter=1
while [ $rmcounter -le $totnom ]; do
file=`echo $wrflist | cut -d' ' -f$rmcounter`
 if [[ -L "$file" ]]; then
 rm $file 2> /dev/null
 fi
rmcounter=$((rmcounter+1))
done
unset rmcounter
fi
}

if [ ${average_onoff} != "1" ]; then
       wrfout2=`echo $wrfout | awk -F/ '{print $NF}'`  #For naming, NCL must be run by wrfout, not wrfout2
       ncl -Q modules/timestep.ncl > timestep_file
       echo " "`tail -n 1 timestep_file | cut -d " " -f 2-`
       rm timestep_file
       read -p "Specify Time_Step(s) Between The Images (Default=1): " tstep
       if [ -z "$tstep" ]; then
       echo Time_Step Has Been Set To 1
       tstep=1
       fi
       export tstep
fi

wrfout2=`echo $wrfout | awk -F/ '{print $NF}'`  #For naming, NCL must be run by wrfout, not wrfout2
echo -e "\n---------------------------------------------------------------"
mkdir -p outputs_$wrfout2
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
cd outputs_$wrfout2
ln -sf ../wrfout* .
ln -sf ../.AllWRFVariables .
echo "Converting to Geotiff. Please wait ..."
ncl -Q $postwrf_dir/modules/geotiff.ncl
geotiff_resume=`cat $postwrf_dir/modules/geo_eq_ok.txt`
if [[ $geotiff_resume == "True" ]]; then
  mv $postwrf_dir/modules/*.nc . 2> /dev/null
  for myvar in *.nc; do
    tiffile=`echo $myvar | cut --delimiter="." -f 1`
    gdal_translate -of GTiff $myvar $tiffile".tiff" &> /dev/null
    gdalwarp $tiffile".tiff" $tiffile".tif" -t_srs "+proj=longlat +ellps=WGS84" &> /dev/null
    echo "(1)     Converted to " $tiffile".tif"
    rm $tiffile".tiff" 2> /dev/null
  done
  rm *.nc 2> /dev/null
  rm wrfout* 2> /dev/null
  rm -f .AllWRFVariables 2> /dev/null
  rm -f *.txt 2> /dev/null
fi