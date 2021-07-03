sed '/added_new_line_by_sed333/ d' geotiff_equation.ncl > geotiff_equation_copy #cleaning previous vars added by sed
mv geotiff_equation_copy geotiff_equation.ncl #recycling the code to its initial condition
count=`cat variablesCN3.txt | wc -l`
mm=0
cp totalequation.txt totalequation0.txt

 if [[ `cat variablesCN3.txt | wc -l` == `sort variablesCN3.txt | uniq | wc -l` ]]; then #check if no variable is repeated
    while [  $mm -lt $count ]; do
        onevar[$mm]=`sed -n "$((mm+1)) p" variablesCN3.txt`
    sed '/shell script333/ a '${onevar[$mm]}' = varlist['$mm']  ;;;added_new_line_by_sed333' geotiff_equation.ncl > geotiff_equation_copy
    mv geotiff_equation_copy geotiff_equation.ncl
    mm=$((mm+1))
    done
    equation=`cat totalequation.txt` #spaces should be removed
    equation=`echo "${equation// }"`
    sed '/equation from namelist.wrf333/ a tc_plane3 = '$equation'  ;;;added_new_line_by_sed333' geotiff_equation.ncl > geotiff_equation_copy
    mv geotiff_equation_copy geotiff_equation.ncl

 else #in case one or more variables are repeated
    chars=( {a..z} )
    while [  $mm -lt $count ]; do
        onevar[$mm]=`sed -n "$((mm+1)) p" variablesCN3.txt`
        sed '/shell script333/ a '${onevar[$mm]}${chars[mm]}' = varlist['$mm']  ;;;added_new_line_by_sed333' geotiff_equation.ncl > geotiff_equation_copy
        mv geotiff_equation_copy geotiff_equation.ncl
        sed "s/\b${onevar[$mm]}\b/${onevar[$mm]}${chars[mm]}/" totalequation.txt > totalequation_altered
        mv totalequation_altered totalequation.txt
        mm=$((mm+1))
    done
    equation=`cat totalequation.txt` #spaces should be removed
    equation=`echo "${equation// }"`
    sed '/equation from namelist.wrf333/ a tc_plane3 = '$equation'  ;;;added_new_line_by_sed333' geotiff_equation.ncl > geotiff_equation_copy
    mv geotiff_equation_copy geotiff_equation.ncl
 fi