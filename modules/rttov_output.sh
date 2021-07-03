#!/bin/bash
#PostWRF Version 1.2 (May 2021)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
  rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/rttov_output.ncl 2>/dev/null
  rm $outputdir/variables.txt $outputdir/wrf_time_list.txt $outputdir/*_values_*.dat 2>/dev/null
  rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $outputdir/"$rttov_output_prefix"* 2>/dev/null
  rm $postwrf_dir/variables.txt $outputdir/rttov_output.sh $outputdir/rttov_output_rgb.py $outputdir/rgb.txt 2>/dev/null
}

wrftemp=($(ls $postwrf_dir/postwrf_wrfout*))
wrfout2=$(basename ${wrftemp[0]}) #In case of mulitfiles, pick the first file for naming
mkdir -p outputs_$wrfout2
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
cd outputs_$wrfout2
export outputdir=$(pwd)
ln -sf $postwrf_dir/postwrf_wrfout* .
ln -sf ../.AllWRFVariables .
ln -sf ../modules/read_wrfouts.ncl .
ln -sf ../modules/rttov_output.ncl .
ln -sf ../modules/rttov_output.sh .
ln -sf $postwrf_dir/"$rttov_output_prefix"* .

echo -e "\n Specify the output format: 1, 2, 3, or 4?"
select imgfmt in "NetCDF" "PNG" "GeoTIFF" "RGB-Image"; do
  case $imgfmt in
  RGB-Image) echo " RGB image needs Python packages of numpy, pillow, and netCDF4" ;;
  *) echo "Output images will be NetCDF" ;;
  esac
  export imgfmt
  break
done
echo ""

for rttov_output in $rttov_output_prefix*; do #converting each rttov output to brightness
  if [[ $rttov_brightness_onoff == 1 ]]; then
    export radiation_extract=brightness_values_$rttov_output
    echo Extracting brightness values from $rttov_output
    cat $rttov_output | sed -n '/BRIGHTNESS/{n;p}' >$radiation_extract #print the line after pattern (BRIGHTNESS)
  fi
  if [[ $rttov_reflectance_onoff == 1 ]]; then
    export radiation_extract=reflectane_values_$rttov_output
    echo Extracting reflectance values from $rttov_output
    cat $rttov_output | sed -n '/REFLECTANCES/{n;p}' >$radiation_extract #print the line after pattern (BRIGHTNESS)
  fi
  if [[ $rttov_radiance_onoff == 1 ]]; then
    export radiation_extract=radiance_values_$rttov_output
    echo Extracting radiance values from $rttov_output
    cat $rttov_output | sed -n '/RADIANCES/{n;p}' >$radiation_extract #print the line after pattern (BRIGHTNESS)
  fi
  if [[ $rttov_emissivity_onoff == 1 ]]; then
    export radiation_extract=emissivity_values_$rttov_output
    echo Extracting emissivity values from $rttov_output
    cat $rttov_output | sed -n '/EMISSIVITIES/{n;p}' >$radiation_extract #print the line after pattern (BRIGHTNESS)
  fi
done
echo ""

if [[ $imgfmt != "PNG" ]]; then
  for rttov_output in *_values_*.dat; do
    echo "Processing $rttov_output ..."
    export radiation_file=$rttov_output
    export ncfilename=${rttov_output%.*}
    ncl -nQ rttov_output.ncl
  done
  if [[ $imgfmt == "GeoTIFF" ]]; then
    for var in band*.nc; do
      echo Converting $var to GeoTIFF ...
      varname=${var%.*}
      gdal_translate -of GTiff $var $varname".tif" &>/dev/null
      gdalwarp $varname".tif" $varname".tiff" -t_srs "+proj=longlat +ellps=WGS84" &>/dev/null
    done
    rm $outputdir/*.nc $outputdir/*.tif 2>/dev/null
  fi
  if [[ $imgfmt == "RGB-Image" ]]; then
    ln -sf ../modules/rttov_output_rgb.py .
    ln -sf $postwrf_dir/rgb.txt . 2>/dev/null
    python rttov_output_rgb.py
    rm *values*.nc 2>/dev/null
  fi

else ##PNG image
  ln -sf ../modules/rttov_output_png.ncl .
  echo -e "\n Specify The Method Of Drawing Contours (1 or 2):"
  select contvar in "Automatic" "Manual"; do
    case $contvar in
    Automatic) echo -e "\nContour Lines Will Be Set Automatically ..." ;;
    Manual)
      echo ""
      read -p "Contour Lines Min Value (press Enter for the best value): " Min
      if [ -z ${Min} ]; then
        echo " Got no input. Best Min value will be set automatically."
        Min="NULL"
      fi
      echo ""
      read -p "Contour Lines Max Value (press Enter for the best value): " Max
      if [ -z ${Max} ]; then
        echo " Got no input. Best Max value will be set automatically."
        Max="NULL"
      fi
      echo ""
      Intv="NULL"
      ;;
    *) echo -e "\nContours Will Be Plotted Automatically." ;;
    esac
    export Max
    export Min
    export Intv
    export contvar
    break
  done
  echo -e "\nSelect a color pattern from the list below (a number from 1 to 10) for $CNVAR3::"
  select colpal in "Rainbow-start_from_blue" "Rainbow-start_from_red" "Rainbow-start_from_white" "Blue..Red" "Blue" "Red" "Green" "White..Yellow..Orange..Red" "White..Black" "Black..White"; do
    case $colpal in
    Rainbow-start_from_blue) colpal="rainbow1" ;;
    Rainbow-start_from_red) colpal="MPL_gist_rainbow1" ;;
    Rainbow-start_from_white) colpal="WhBlGrYeRe1" ;;
    Blue..Red) colpal="BlueRed1" ;;
    White..Yellow..Orange..Red) colpal="WhiteYellowOrangeRed1" ;;
    Blue) colpal="WhiteBlue1" ;;
    Red) colpal="MPL_Reds1" ;;
    Green) colpal="WhiteGreen1" ;;
    White..Black) colpal="WandB" ;;
    Black..White) colpal="BandW" ;;
    *)
      echo "Rainbow color pattern has been selected"
      colpal="rainbow1"
      ;;
    esac
    export colpal
    break
  done
  for rttov_output in *_values_*.dat; do
    echo ""
    echo "Processing $rttov_output ..."
    export radiation_file=$rttov_output
    export ncfilename=${rttov_output%.*}
    ncl -nQ rttov_output_png.ncl
  done
fi

rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/wrf_time_list.txt 2>/dev/null
rm $outputdir/variables*.txt $postwrf_dir/modules/postwrf_wrfout* $outputdir/*_values_*.dat $outputdir/rttov_output_rgb.py 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $outputdir/rttov_output.ncl 2>/dev/null
rm $postwrf_dir/variables.txt $outputdir/rttov_output.sh $outputdir/"$rttov_output_prefix"* $outputdir/rgb.txt 2>/dev/null