#!/bin/bash
#Author: Amirhossein Nikfal <https://github.com/anikfal>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
       rm $outputdir/*.ncl $outputdir/postwrf_era_* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
       rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit $postwrf_dir/modules_era/postwrf_era_* 2>/dev/null
       rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_era_* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
       rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

wrftemp=( $( ls $postwrf_dir/postwrf_era_* ) )
wrfout_with_suff=`basename ${wrftemp[0]}` #In case of multifiles, pick the first file for naming
wrfout2=${wrfout_with_suff%.*}
cnpostname=$(echo $wrfout2 | cut -d "_" -f2-3)

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
if [ -z "$tlast_ind" ]; then
echo "Last time index has been set to the last index"
tlast_ind="last_index_era"
fi
export tlast_ind

echo -e "\n---------------------------------------------------------------"
echo -e "Extracting data by bilinear interpolatoin\n"
mkdir -p outputs_$wrfout2
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
cd outputs_$wrfout2
export outputdir=$(pwd)
ln -sf ../.AllWRFVariables .
echo -e "\nPostWRF: Extracting variables ...\n"
ln -sf $postwrf_dir/modules_era/extract_era.ncl .
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules_era
ln -sf $postwrf_dir/.AllWRFVariables .
ln -sf $postwrf_dir/postwrf_era_* $postwrf_dir/modules_era
ln -sf $postwrf_dir/postwrf_era_* .
ncl -nQ extract_era.ncl
echo -e "\nPostWRF: Extracting variables finished.\n"

rm $outputdir/*.ncl $outputdir/postwrf_era_* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit $postwrf_dir/modules_era/postwrf_era_* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_era_* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
