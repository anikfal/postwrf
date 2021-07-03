#!/bin/bash
#PostWRF Version 1.1 (Apr 2020)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
       rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
       rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit 2>/dev/null
       rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
       rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

wrftemp=($(ls $postwrf_dir/postwrf_wrfout*))
wrfout2=$(basename ${wrftemp[0]}) #In case of mulitfiles, pick the first file for naming
# wrfout2=$(echo $wrfout | awk -F/ '{print $NF}') #For naming, NCL must be run by wrfout, not wrfout2

if [[ $verticalplotonoff != 1 ]]; then
       echo -e "\n---------------------------------------------------------------"
       echo -e "Method of grid interpolation: 1, 2, or 3?\n"
       select interpolvar in "NearestPoint" "Bilinear" "IDW"; do
              case $interpolvar in
              NearestPoint) ;;
              Bilinear) ;;
              IDW) ;;
              *)
                     echo "Output Images Will Be 'X11'"
                     interpolvar="NearestPoint"
                     ;;
              esac
              export interpolvar
              break
       done

       mkdir -p outputs_$wrfout2
       ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
       cd outputs_$wrfout2
       export outputdir=$(pwd)
       ln -sf $postwrf_dir/postwrf_wrfout* .
       # mv $postwrf_dir/modules/wrfout_d* .
       ln -sf ../.AllWRFVariables .
       echo -e "\nPostWRF: Extracting variables ...\n"
       if [[ ${interpolvar} == "IDW" ]]; then
              echo -e "\nInerpolation by the method of Inverse Distance Weight (IDW) ...\n"
       elif [[ ${interpolvar} == "Bilinear" ]]; then
              echo -e "\nBilinear Inerpolation ...\n"
       else
              echo -e "\nInerpolation by the method of NearestPoint ...\n"
       fi
       ln -sf $postwrf_dir/modules/extract.ncl .
       ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
       ncl -nQ extract.ncl
       echo -e "\nPostWRF: Extracting variables finished.\n"
else
       myvar="Vprofile_X_axis_decimals"
       verticaldecimal=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
       export verticaldecimal=$(echo $verticaldecimal)                                            #Remove spaces
       unset myvar

       if [ ${average_onoff} != "1" ]; then
              # wrfout2=$(echo $wrfout | awk -F/ '{print $NF}') #For naming, NCL must be run by wrfout, not wrfout2
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

       echo ""
       read -p "$nclwrfvar0 minimum value for the X axis (press Enter to put automaticly): " Min
       if [ -z ${Min} ]; then
              echo " Got no input. Best Minimum value will be set automatically."
              Min="NULL"
       fi
       echo ""
       read -p "$nclwrfvar0 maximum value for the X axis (press Enter to put automaticly): " Max
       if [ -z ${Max} ]; then
              echo " Got no input. Best Max value will be set automatically."
              Max="NULL"
       fi
       echo ""
       export Max
       export Min

       echo -e "\n Specify the format of the images: 1, 2, or 3?"
       select imgfmt in "x11" "pdf" "png"; do
              case $imgfmt in
              x11) ;;
              pdf) ;;
              png) ;;
              *) echo "Output images will be 'X11'" ;;
              esac
              export imgfmt
              break
       done

       if [[ ${imgfmt} == "x11" ]]; then
              outname="nclplot"
       else
              read -p "$(echo -e "\n ")Specify the output file name (press enter for the default name): " outname2
              cnpostname=$(echo $wrfout2 | cut -d "_" -f2-3)
              if [ -z "$outname2" ]; then
                     outname=$(echo "vertical_plot-"$cnpostname)
                     echo "  Vertical plot will be named $outname"
              else
                     outname=$(echo $outname2"-"$cnpostname)
              fi
       fi
       export outname

       if [[ ${imgfmt} == "x11" ]]; then
              ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
              ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
              ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
              ncl -nQ $postwrf_dir/modules/profile.ncl
       else
              mkdir -p outputs_$wrfout2
              ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
              cd outputs_$wrfout2
              export outputdir=$(pwd)
              ln -sf $postwrf_dir/postwrf_wrfout* .
              ln -s ../.AllWRFVariables .
              echo -e "\nPostWRF: Extracting variables by vertical plots ...\n"
              ln -s ../modules/profile.ncl .
              ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
              ncl -nQ profile.ncl
              rm postwrf_wrfout* 2>/dev/null
              mv ../modules/*.pdf . 2>/dev/null
              mv ../modules/*.png . 2>/dev/null
              if [[ ${imgfmt} == "animated_gif" ]]; then
                     convert -delay $anim_spd *.png $outname.gif
                     rm *.png
              fi
       fi
fi

rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
