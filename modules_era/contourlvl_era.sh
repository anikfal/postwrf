#PostWRF Version 1.2 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
rm $outputdir/*.ncl $outputdir/postwrf_era_* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules_era/postwrf_era_* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_era_* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

wrftemp=( $( ls $postwrf_dir/postwrf_era_* ) )
wrfout_with_suff=`basename ${wrftemp[0]}` #In case of mulitfiles, pick the first file for naming
wrfout2=${wrfout_with_suff%.*}
cnpostname=$(echo $wrfout2 | cut -d "_" -f2-3)

if [ ${average_onoff} != "1" ]; then
  echo "All times inside" $cnpostname "are as follows:"
  ncl -nQ modules_era/timestep_era.ncl
  echo "Specify the time range (first and last time indexes) to be plotted:"
  read -p "First time index (press Enter for index 1): " tfirst_ind
  if [ -z "$tfirst_ind" ]; then
    echo "First time index has been set to 1"
    tfirst_ind=1
  fi
  export tfirst_ind
  read -p "Last time index (press Enter for the last index): " tlast_ind
  # if [ ! -z "$tlast_ind" ]; then
  # fi
  if [ -z "$tlast_ind" ]; then
    echo "Last time index has been set to the last index"
    tlast_ind="last_index_era"
  fi
  export tlast_ind
fi

if [ ${THIRDVAR_ONOFF} == "1" ]; then
  echo -e "\n Specify The Method Of Drawing Contours (1 or 2) for $CNVAR3:"
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
      ;;
    *) echo -e "\nContours Will Be Plotted Automatically." ;;
    esac
    break
  done

  echo -e "\nSelect a color pattern from the list below (a number from 1 to 10) for $CNVAR3::"
  select colpal in "Rainbow-start_from_blue" "Rainbow-start_from_red" "Rainbow-start_from_white" "Blue..Red" "Blue" "Red" "Green" "White..Yellow..Orange..Red" "White..Black" "Black..White"; do
    case $colpal in
    Rainbow-start_from_blue) colpal="rainbow" ;;
    Rainbow-start_from_red) colpal="MPL_gist_rainbow" ;;
    Rainbow-start_from_white) colpal="WhBlGrYeRe" ;;
    Blue..Red) colpal="MPL_bwr" ;;
    White..Yellow..Orange..Red) colpal="WhiteYellowOrangeRed" ;;
    Blue) colpal="WhiteBlue" ;;
    Red) colpal="MPL_Reds" ;;
    Green) colpal="MPL_Greens" ;;
    White..Black) colpal="MPL_Greys" ;;
    Black..White) colpal="MPL_gist_gray" ;;
    *)
      echo "Rainbow color pattern has been selected"
      colpal="rainbow1"
      ;;
    esac
    break
  done
fi

echo -e "\n Format Of The Images: 1, 2, 3, or 4?"
select imgfmt in "x11" "pdf" "png" "animated_gif"; do
  case $imgfmt in
  x11) ;;
  pdf) ;;
  png) ;;
  animated_gif) ;;
  *)
    echo "Output Images Will Be 'X11'"
    imgfmt="x11"
    ;;
  esac
  export imgfmt
  break
done

if [[ ${imgfmt} == "animated_gif" ]]; then
  echo -e "\n Speed of the Amimated GIF: 1, 2, or 3?"
  select anim_spd in "slow" "medium" "fast"; do
    case $anim_spd in
    slow) anim_spd="75" ;;
    medium) anim_spd="50" ;;
    fast) anim_spd="25" ;;
    *)
      echo "Animation Speed Will Be 'medium'"
      anim_spd="50"
      ;;
    esac
    break
  done
fi

if [[ ${imgfmt} == "x11" ]]; then
  outname="nclplot"
else
  read -p "$(echo -e "\n ")Name of the Output File? (Press Enter for the default name): " outname2
  if [ -z "$outname2" ]; then
    outname=$(echo "contour-level-"$cnpostname)
    echo "  Contour file will be named $outname"
  else
    outname=$(echo $outname2"-"$cnpostname)
  fi
fi
export outname
export colpal
export contvar
export Min
export Max

if [[ ${imgfmt} == "x11" ]]; then
  ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules_era
  ln -sf $postwrf_dir/postwrf_era_* $postwrf_dir/modules_era
  ln -sf $postwrf_dir/modules_era/read_wrfouts.ncl .
  ncl -nQ $postwrf_dir/modules_era/contourlvl_era.ncl
else
  mkdir -p outputs_$wrfout2
  cd outputs_$wrfout2
  export outputdir=`pwd`
  ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules_era
  ln -sf $postwrf_dir/.AllWRFVariables .
  ln -sf $postwrf_dir/postwrf_era_* $postwrf_dir/modules_era
  ln -sf $postwrf_dir/postwrf_era_* .
  ln -sf $postwrf_dir/modules_era/contourlvl_era.ncl .
  ln -sf $postwrf_dir/modules_era/read_wrfouts.ncl .
  ncl -nQ $postwrf_dir/modules_era/contourlvl_era.ncl
  mv $postwrf_dir/modules_era/*.pdf . 2>/dev/null
  mv $postwrf_dir/modules_era/*.png . 2>/dev/null
  unlink contourlvl_era.ncl 2>/dev/null
  if [[ ${imgfmt} == "animated_gif" ]]; then
    convert -delay $anim_spd *.png $outname.gif
    rm *.png
  fi
fi
rm $outputdir/*.ncl $outputdir/postwrf_era_* $outputdir/.AllWRFVariables $outputdir/eqname   2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules_era/postwrf_era_* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_era_* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname   2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null