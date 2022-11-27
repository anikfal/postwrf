#PostWRF Version 1.2 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
  rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
  rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
  rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
  rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

if [ ${average_onoff} != "1" ]; then
  ncl -nQ modules/timestep.ncl >timestep_file
  echo " "$(tail -n 1 timestep_file | cut -d " " -f 2-)
  rm timestep_file
  read -p "Specify Time_Step(s) Between The Images (Default=1): " tstep
  if [ -z "$tstep" ]; then
    echo Time_Step Has Been Set To 1
    tstep=1
  fi
  export tstep
fi

wrftemp=($(ls $postwrf_dir/postwrf_wrfout*))
wrfout2=$(basename ${wrftemp[0]}) #In case of mulitfiles, pick the first file for naming
echo -e "\n---------------------------------------------------------------"
mkdir -p outputs_$wrfout2
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
cd outputs_$wrfout2
export outputdir=$(pwd)
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
ln -sf $postwrf_dir/.AllWRFVariables .
ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
ln -sf $postwrf_dir/postwrf_wrfout* .
ln -sf $postwrf_dir/modules/geotiff.ncl .
ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
echo "Converting to Geotiff. Please wait ..."
ncl -nQ $postwrf_dir/modules/geotiff.ncl
geotiff_resume=$(cat $postwrf_dir/modules/geo_eq_ok.txt)
if [[ $geotiff_resume == "True" ]]; then
  mv $postwrf_dir/modules/*.nc . 2>/dev/null
  for myvar in *.nc; do
    tiffile=$(echo $myvar | cut --delimiter="." -f 1)
    gdal_translate -of GTiff $myvar $tiffile".tiff" -oo IGNORE_XY_AXIS_NAME_CHECKS=YES &>/dev/null
    gdalwarp $tiffile".tiff" $tiffile".tif" -t_srs "+proj=longlat +ellps=WGS84" &>/dev/null
    echo "(1)     Converted to " $tiffile".tif"
    rm $tiffile".tiff" 2>/dev/null
  done
  rm *.nc 2>/dev/null

fi
rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
