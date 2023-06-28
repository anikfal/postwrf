#!/bin/bash
trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
  rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
  rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
  rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
  rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

echo -e "\nThere are 3 sets of wind speed boundaries available:"
echo -e "Option_1: (10m/s - 20m/s - 30m/s - 40m/s)"
echo -e "Option_2: (5m/s - 10m/s - 15m/s - 20m/s)"
echo -e "Option_3: (2.5m/s - 5m/s - 7.5m/s - 10m/s)"
echo -e "\nSelect your desired option for the wind speed boundaries"
select sh_wndbnd in "Option_1" "Option_2" "Option_3"; do
  case $sh_wndbnd in
  Option_1) sh_wndbnd=1 ;;
  Option_2) sh_wndbnd=2 ;;
  Option_3) sh_wndbnd=3 ;;
  esac
  break
done

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
wrftemp=( $( ls $postwrf_dir/postwrf_wrfout* ) )
wrfout2=`basename ${wrftemp[0]}` #In case of mulitfiles, pick the first file for naming
if [[ ${imgfmt} == "x11" ]]; then
  outname="nclplot"
else
  read -p "$(echo -e "\n ")Specify The Output File Name (Press Enter for the default name): " outname2
  cnpostname=$(echo $wrfout2 | cut -d "_" -f2-3)
  if [ -z "$outname2" ]; then
    outname=$(echo "windrose-"$cnpostname)
    echo "  WindRose file will be named $outname"
  else
    outname=$(echo $outname2"-"$cnpostname)
  fi
fi

export outname
export sh_wndbnd

if [[ ${imgfmt} == "x11" ]]; then
  ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
  ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
  ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
  ncl -nQ $postwrf_dir/modules/windrose.ncl
else
  mkdir -p outputs_$wrfout2
  cd outputs_$wrfout2
  export outputdir=`pwd`
  ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
  ln -sf $postwrf_dir/.AllWRFVariables .
  ln -sf $postwrf_dir/postwrf_wrfout* $postwrf_dir/modules
  ln -sf $postwrf_dir/postwrf_wrfout* .
  ln -sf $postwrf_dir/modules/windrose.ncl .
  ln -sf $postwrf_dir/modules/read_wrfouts.ncl .
  ncl -nQ windrose.ncl
fi
rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
