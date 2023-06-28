#!/bin/bash
    filename="extract_era_equation.ncl"
filename_copy=$filename"_copy"
sed '/added_new_line_by_sed/ d' $filename > $filename_copy #cleaning previous vars added by sed
mv $filename_copy $filename #recycling the code to its prestine condition
count=`cat variables.txt | wc -l`
mm=0
 while [  $mm -lt $count ]; do
  onevar[$mm]=`sed -n "$((mm+1)) p" variables.txt`
  sed '/shell script/ a '${onevar[$mm]}' = varlist['$mm']  ;;;added_new_line_by_sed' $filename > $filename_copy
  mv $filename_copy $filename
  mm=$((mm+1))
 done
 equation=`cat totalequation.txt`
  sed '/equation from namelist.wrf/ a tc2 = '$equation'  ;;;added_new_line_by_sed' $filename > $filename_copy
  mv $filename_copy $filename
