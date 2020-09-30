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

if [ ${average_onoff} != "1" ]; then
   wrftemp=($(ls $postwrf_dir/postwrf_wrfout*))
   wrfout2=$(basename ${wrftemp[0]}) #In case of mulitfiles, pick the first file for naming
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

echo -e "\n Specify The Format Of The Images: 1, 2, or 3?"
select imgfmt in "x11" "pdf" "png"; do
   case $imgfmt in
   x11) ;;
   pdf) ;;
   png) ;;
   *) echo "Output Images Will Be 'X11'" ;;
   esac
   export imgfmt
   break
done

if [[ ${imgfmt} == "x11" ]]; then
   outname="nclplot"
else
   read -p "$(echo -e "\n ")Specify The Output File Name (Press Enter for the default name): " outname2
   cnpostname=$(echo $wrfout2 | cut -d "_" -f2-3)
   if [ -z "$outname2" ]; then
      outname=$(echo "skewt-"$cnpostname)
      echo "  SkewT file will be named $outname"
   else
      outname=$(echo $outname2"-"$cnpostname)
   fi
fi
export outname

if [[ ${imgfmt} == "x11" ]]; then
   ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
   ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
   ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
   ncl -Q $postwrf_dir/modules/skewt.ncl
else
   mkdir -p outputs_$wrfout2
   cd outputs_$wrfout2
   export outputdir=$(pwd)
   ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
   ln -sf $postwrf_dir/.AllWRFVariables .
   ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
   ln -sf $postwrf_dir/postwrf_wrfout* .
   ln -sf $postwrf_dir/modules/skewt.ncl .
   ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
   ncl -Q skewt.ncl
fi
rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null