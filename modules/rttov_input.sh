#PostWRF Version 1.2 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
  rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
  rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit $outputdir/wrf_time_list.txt 2>/dev/null
  rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
  rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

wrftemp=($(ls $postwrf_dir/postwrf_wrfout*))
wrfout2=$(basename ${wrftemp[0]}) #In case of mulitfiles, pick the first file for naming

mkdir -p outputs_$wrfout2
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
cd outputs_$wrfout2
export outputdir=$(pwd)
ln -sf $postwrf_dir/postwrf_wrfout* .
ln -sf ../.AllWRFVariables .
ln -sf ../modules/rttov_input.ncl .
ln -sf ../modules/rttov_time_list.ncl .
ln -sf ../modules/read_wrfouts.ncl .
ln -sf ../modules/rttov_input_dust.ncl .

echo "Times inside the selected wrf file(s):"
ncl -nQ rttov_time_list.ncl
read -p "Choose your time number(s) (separated by comma): " filenum

timeselected_count=$(echo $filenum | awk -F',' '{ print NF }')
wrflastcomma=$(echo $filenum | rev | cut -c1)
if [[ $wrflastcomma == "," ]]; then
  timeselected_count=$((timeselected_count - 1))
fi

varcount=0
rm -f wrf_time_list.txt 2>/dev/null
while [ $varcount -lt $timeselected_count ]; do
  mynumber=$(echo $filenum | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1))) #separating wrf number
  mynumber=$(echo $mynumber)
  echo $mynumber >>wrf_time_list.txt
  varcount=$((varcount + 1))
done
unset varcount
unset filenum

echo ""
read -p "Specify the RTTOV input file names (press enter for the default name): " tablename
if [ -z "$tablename" ]; then
  tablename="rttov_input"
fi
export tablename

ncl -nQ rttov_input.ncl

if [[ $rttov_aer_prof_onoff == 1 ]]; then
  echo "Making dust profiles ..."
  ncl -nQ rttov_input_dust.ncl
fi

rm $outputdir/*.ncl $outputdir/postwrf_wrfout* $outputdir/.AllWRFVariables $outputdir/eqname $outputdir/wrf_time_list.txt 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables*.txt $outputdir/equnit $postwrf_dir/modules/postwrf_wrfout* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_wrfout* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
