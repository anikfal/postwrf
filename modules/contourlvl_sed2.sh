#!/bin/bash
if [[ $contour_onoff == 1 ]]; then
    filename="contourlvl_equation.ncl"
else
    filename="cross_equation.ncl"
fi
filename_copy=$filename"_copy"

sed '/added_new_line_by_sed222/ d' $filename >$filename_copy #cleaning previous vars added by sed
mv $filename_copy $filename                                  #recycling the code to its initial condition
count=$(cat variablesCN2.txt | wc -l)
mm=0
cp totalequationCN2.txt totalequationCN20.txt

if [[ $(cat variablesCN2.txt | wc -l) == $(sort variablesCN2.txt | uniq | wc -l) ]]; then #check if no variable is repeated
    while [ $mm -lt $count ]; do
        onevar[$mm]=$(sed -n "$((mm + 1)) p" variablesCN2.txt)
        sed '/shell script222/ a '${onevar[$mm]}' = varlist['$mm']  ;;;added_new_line_by_sed222' $filename >$filename_copy
        mv $filename_copy $filename
        mm=$((mm + 1))
    done
    equation=$(cat totalequationCN2.txt) #spaces should be removed
    equation=$(echo "${equation// /}")
    sed '/equation from namelist.wrf222/ a tc_plane2 = '$equation'  ;;;added_new_line_by_sed222' $filename >$filename_copy
    mv $filename_copy $filename

else #in case one or more variables are repeated
    chars=({a..z})
    while [ $mm -lt $count ]; do
        onevar[$mm]=$(sed -n "$((mm + 1)) p" variablesCN2.txt)
        sed '/shell script222/ a '${onevar[$mm]}${chars[mm]}' = varlist['$mm']  ;;;added_new_line_by_sed222' $filename >$filename_copy
        mv $filename_copy $filename
        sed "s/\b${onevar[$mm]}\b/${onevar[$mm]}${chars[mm]}/" totalequationCN2.txt >totalequationCN2_altered
        mv totalequationCN2_altered totalequationCN2.txt
        mm=$((mm + 1))
    done
    equation=$(cat totalequationCN2.txt) #spaces should be removed
    equation=$(echo "${equation// /}")
    sed '/equation from namelist.wrf222/ a tc_plane2 = '$equation'  ;;;added_new_line_by_sed222' $filename >$filename_copy
    mv $filename_copy $filename
fi
