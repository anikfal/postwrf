#!/bin/bash
#PostWRF Version 1.1 (Apr 2020)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

echo -e " \nMethod of Cross-Section: 1, 2, or 3?\n"
select crossmode in "One-point-and-an-angle" "Two-points"; do

  ncl $postwrf_dir/modules/crossguidance.ncl >ncltemp
  lon1=$(tail -n 4 ncltemp | head -n 1)
  lon1=$(echo $lon1 | cut -d' ' -f2) #remove spaces
  lat1=$(tail -n 3 ncltemp | head -n 1)
  lat1=$(echo $lat1 | cut -d' ' -f2) #remove spaces
  lon2=$(tail -n 2 ncltemp | head -n 1)
  lon2=$(echo $lon2 | cut -d' ' -f2) #remove spaces
  lat2=$(tail -n 1 ncltemp)
  lat2=$(echo $lat2 | cut -d' ' -f2) #remove spaces

  case $crossmode in
  One-point-and-an-angle) # echo -e "\nCross-Section Will Be Plotted by one pivot point and an angle"
    #echo "."
    #echo "."
    echo -e "\nEnter the lat & lon of the pivot point:"
    echo -e "\nGuidance:"
    sed -n '/Range of / p' ncltemp
    rm -f ncltemp
    echo ""
    read -p " Longitude of the pivot point ($lon1 to $lon2): " plon
    while [ -z $plon ]; do
      read -p "  Enter a value between $lon1 and $lon2: " plon
    done
    read -p " Latitude of the pivot point ($lat1 to $lat2): " plat
    while [ -z $plat ]; do
      read -p "  Enter a value between $lat1 and $lat2: " plat
    done
    export plat
    export plon
    varrr=True
    echo "."
    echo "."
    echo "."
    echo -e "\nGuidance for selecting the angle of cross-section:"
    echo "South-North is 0 degree; West-East is 90 degree"
    while [ $varrr == True ]; do
      echo ""
      read -p "Select the Angle of the cross-section line (0 to 180): " crossangle
      if [[ $crossangle -ge 0 && $crossangle -le 180 ]] 2>/dev/null; then
        crossdir=$crossangle
        break
      fi
      echo " Not valid. Enter a number between 0 to 180"
    done
    echo "Your angle is" $crossdir "degree(s)"
    export crossdir
    ;;

  Two-points)
    echo -e "\nCross-Sections Will Be Plotted by 2 points (start and end):\n"
    echo "Guidance:"
    sed -n '/Range of / p' ncltemp
    rm -f ncltemp
    echo -e "\n"
    read -p " Start Longitude ($lon1 to $lon2): " slon
    while [ -z $slon ]; do
      read -p "  Enter a value between $lon1 and $lon2: " slon
    done
    read -p " Start Latitude ($lat1 to $lat2): " slat
    while [ -z $slat ]; do
      read -p "  Enter a value between $lat1 and $lat2: " slat
    done
    read -p " End Longitude ($lon1 to $lon2): " elon
    while [ -z $elon ]; do
      read -p "  Enter a value between $lon1 and $lon2: " elon
    done
    read -p " End Latitude ($lat1 to $lat2): " elat
    while [ -z $elat ]; do
      read -p "  Enter a value between $lat1 and $lat2: " elat
    done
    export slat
    export slon
    export elat
    export elon
    ;;

  esac
  export crossmode
  break
done

echo ""

if [[ ${xTHIRDVAR_ONOFF} == "1" ]]; then #code aaah
  echo -e "\n Specify The Method Of Drawing Contours (1 or 2) for $xCNVAR3:"
  select contvar in "Automatic" "Manual"; do
    case $contvar in
    Automatic) echo -e "\nContour Lines Will Be Set Automatically ...\n" ;;
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
      # Intv="NULL"
      ;;
    *) echo -e "\nContours Will Be Plotted Automatically." ;;
    esac
    break
  done
  export contvar
  export Min
  export Max
  # export Intv

  echo -e "\nSelect a color pattern from the list below (a number from 1 to 10):"
  select colpal in "Rainbow-start_from_blue" "Rainbow-start_from_red" "Rainbow+white-start_from_white" "Blue..Red" "Blue" "Red" "Green" "White..Yellow..Orange..Red" "White..Black" "Black..White"; do
    case $colpal in
    Rainbow-start_from_blue) colpal="rainbow1" ;;
    Rainbow-start_from_red) colpal="MPL_gist_rainbow1" ;;
    Rainbow+white-start_from_white) colpal="WhBlGrYeRe1" ;;
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
    break
  done
  export colpal
fi #code aaah

wrftemp=( $( ls $postwrf_dir/postwrf_wrfout* ) )
wrfout2=`basename ${wrftemp[0]}` #In case of mulitfiles, pick the first file for naming
if [ ${average_onoff} != "1" ]; then
  ncl modules/timestep.ncl >timestep_file
  echo " "$(tail -n 1 timestep_file | cut -d " " -f 2-)
  rm timestep_file
  read -p "Specify Time_Step(s) Between The Images (Default=1): " tstep
  if [ -z "$tstep" ]; then
    echo Time_Step Has Been Set To 1
    tstep=1
  fi
  export tstep
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
  read -p "$(echo -e "\n ")Specify The Output File Name (Press Enter for automatic naming): " outname2
  cnpostname=$(echo $wrfout2 | cut -d "_" -f2-3)
  if [ -z "$outname2" ]; then
    outname=$(echo "cross-section-"$cnpostname)
    echo "  CrossSection file will be named $outname"
  else
    outname=$(echo $outname2"-"$cnpostname)
  fi
fi
export outname

if [[ ${imgfmt} == "x11" ]]; then
  ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
  ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
  ncl -Q $postwrf_dir/modules/cross.ncl
else
  mkdir -p outputs_$wrfout2
  cd outputs_$wrfout2
  export outputdir=`pwd`
  ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
  ln -sf $postwrf_dir/.AllWRFVariables .
  ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
  ln -sf $postwrf_dir/postwrf_wrfout* .
  ln -sf $postwrf_dir/modules/cross.ncl .
  ncl -Q cross.ncl
  mv ../modules/*.pdf . 2>/dev/null
  mv ../modules/*.png . 2>/dev/null
  unlink cross.ncl 2>/dev/null
  if [[ ${imgfmt} == "animated_gif" ]]; then
    convert -delay $anim_spd *.png $outname.gif
    rm *.png
  fi
fi
rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
