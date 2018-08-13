#!/bin/bash
#PostWRF Version 1.0 (May 2018)
#This shell script uses a NCL code to draw the map of WRF model domain.
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

curdir=`pwd`

trap 'my_exit; exit' SIGINT SIGQUIT
count=0

my_exit()
{
curdir2=`pwd`
rm timestep_file 2> /dev/null
if [[ $curdir != $curdir2 ]]; then

wrflist=`ls wrfout*`
totnom=`echo $wrflist | wc -w`
rmcounter=1
while [ $rmcounter -le $totnom ]; do
file=`echo $wrflist | cut -d' ' -f$rmcounter`
 if [[ -L "$file" ]]; then
 rm $file 2> /dev/null
 fi
rmcounter=$((rmcounter+1))
done

unset rmcounter
fi
}
    wrfout2=`echo $wrfout | awk -F/ '{print $NF}'`  #For naming, NCL must be run by wrfout, not wrfout2
     ncl modules/timestep.ncl > timestep_file
     echo " "`tail -n 1 timestep_file | cut -d " " -f 2-`
     rm timestep_file
     read -p "Specify Time_Step(s) Between The Images (Default=1): " tstep
    if [ -z "$tstep" ]; then
       echo Time_Step Has Been Set To 1
       tstep=1
    fi
    export tstep

    echo -e "\n Specify The Format Of The Images: 1, 2, or 3?"
     select imgfmt in "x11" "pdf" "png"
      do
       case $imgfmt in
        x11);;
        pdf);;
        png);;
          *) echo "Output Images Will Be 'X11'"
       esac
       export imgfmt
       break
      done
 
     if [[ ${imgfmt} == "x11" ]]; then
      outname="nclplot"
     else
    read -p "`echo -e "\n "`Specify The Output File Name (Press Enter for the default name): " outname2
     cnpostname=`echo $wrfout2 | cut -d "_" -f2-3`
      if [ -z "$outname2" ]; then
       outname=`echo "skewt-"$cnpostname`
       echo "  SkewT file will be named $outname"
      else
       outname=`echo $outname2"-"$cnpostname`
      fi
     fi
    export outname

     if [[ ${imgfmt} == "x11" ]]; then
      ncl modules/skewt.ncl
     else
       mkdir -p outputs_$wrfout2
       cd outputs_$wrfout2
       ln -s ../wrfout* .
       ncl ../modules/skewt.ncl
       rm wrfout*
    fi
