filename="contourlvl_era_equation.ncl"
filename_copy=$filename"_copy"

sed '/added_new_line_by_sed333/ d' $filename >$filename_copy #cleaning previous vars added by sed
mv $filename_copy $filename                                  #recycling the code to its initial condition
count=$(cat variablesCN3.txt | wc -l)
mm=0
cp totalequationCN3.txt totalequationCN30.txt

if [[ $(cat variablesCN3.txt | wc -l) == $(sort variablesCN3.txt | uniq | wc -l) ]]; then #check if no variable is repeated
    while [ $mm -lt $count ]; do
        onevar[$mm]=$(sed -n "$((mm + 1)) p" variablesCN3.txt)
        sed '/shell script333/ a '${onevar[$mm]}' = varlist['$mm']  ;;;added_new_line_by_sed333' $filename >$filename_copy
        mv $filename_copy $filename
        mm=$((mm + 1))
    done
    equation=$(cat totalequationCN3.txt) #spaces should be removed
    equation=$(echo "${equation// /}")
    sed '/equation from namelist.wrf333/ a tc_plane33 = '$equation'  ;;;added_new_line_by_sed333' $filename >$filename_copy
    mv $filename_copy $filename

else #in case one or more variables are repeated
    chars=({a..z})
    while [ $mm -lt $count ]; do
        onevar[$mm]=$(sed -n "$((mm + 1)) p" variablesCN3.txt)
        sed '/shell script333/ a '${onevar[$mm]}${chars[mm]}' = varlist['$mm']  ;;;added_new_line_by_sed333' $filename >$filename_copy
        mv $filename_copy $filename
        sed "s/\b${onevar[$mm]}\b/${onevar[$mm]}${chars[mm]}/" totalequationCN3.txt >totalequationCN3_altered
        mv totalequationCN3_altered totalequationCN3.txt
        mm=$((mm + 1))
    done
    equation=$(cat totalequationCN3.txt) #spaces should be removed
    equation=$(echo "${equation// /}")
    sed '/equation from namelist.wrf333/ a tc_plane33 = '$equation'  ;;;added_new_line_by_sed333' $filename >$filename_copy
    mv $filename_copy $filename
fi
