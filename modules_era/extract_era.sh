#PostWRF Version 1.2 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
       rm $outputdir/*.ncl $outputdir/postwrf_era_* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
       rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit $postwrf_dir/modules_era/postwrf_era_* 2>/dev/null
       rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_era_* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
       rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
}

# wrftemp=($(ls $postwrf_dir/postwrf_era_*))
# wrfout2=$(basename ${wrftemp[0]}) #In case of mulitfiles, pick the first file for naming

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
# echo -e "Method of grid interpolation: 1, 2, or 3?\n"
# select interpolvar in "NearestPoint" "Bilinear" "IDW"; do
#        case $interpolvar in
#        NearestPoint) ;;
#        Bilinear) ;;
#        IDW) ;;
#        *)
#               echo "Output Images Will Be 'X11'"
#               interpolvar="NearestPoint"
#               ;;
#        esac
#        export interpolvar
#        break
# done
mkdir -p outputs_$wrfout2
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules
cd outputs_$wrfout2
export outputdir=$(pwd)
# ln -sf $postwrf_dir/postwrf_wrfout* .
# mv $postwrf_dir/modules/wrfout_d* .
ln -sf ../.AllWRFVariables .
echo -e "\nPostWRF: Extracting variables ...\n"
# if [[ ${interpolvar} == "IDW" ]]; then
#        echo -e "\nInerpolation by the method of Inverse Distance Weight (IDW) ...\n"
# elif [[ ${interpolvar} == "Bilinear" ]]; then
#        echo -e "\nBilinear Inerpolation ...\n"
# else
#        echo -e "\nInerpolation by the method of NearestPoint ...\n"
# fi
ln -sf $postwrf_dir/modules_era/extract_era.ncl .
ln -sf $postwrf_dir/.AllWRFVariables $postwrf_dir/modules_era
ln -sf $postwrf_dir/.AllWRFVariables .
ln -sf $postwrf_dir/postwrf_era_* $postwrf_dir/modules_era
ln -sf $postwrf_dir/postwrf_era_* .
ln -sf $postwrf_dir/modules_era/contourlvl_era.ncl .
# ln -sf $postwrf_dir/modules_era/read_wrfouts.ncl .
ncl -nQ extract_era.ncl
echo -e "\nPostWRF: Extracting variables finished.\n"

rm $outputdir/*.ncl $outputdir/postwrf_era_* $outputdir/.AllWRFVariables $outputdir/eqname 2>/dev/null
rm $outputdir/totalequation.txt $outputdir/variables.txt $outputdir/equnit $postwrf_dir/modules_era/postwrf_era_* 2>/dev/null
rm $postwrf_dir/*.ncl $postwrf_dir/postwrf_era_* $postwrf_dir/.AllWRFVariables $postwrf_dir/eqname 2>/dev/null
rm $postwrf_dir/totalequation.txt $postwrf_dir/variables.txt $postwrf_dir/equnit 2>/dev/null
