#!/bin/bash
#PostWRF Version 1.1 (Apr 2020)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
curdir=`pwd`
trap 'my_exit; exit' SIGINT SIGQUIT
count=0

my_exit()
{
curdir2=`pwd`
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
       echo -e "\nThere are 3 sets of wind speed boundaries available:"
       echo -e "Option_1: (10m/s - 20m/s - 30m/s - 40m/s)"
       echo -e "Option_2: (5m/s - 10m/s - 15m/s - 20m/s)"
       echo -e "Option_3: (2.5m/s - 5m/s - 7.5m/s - 10m/s)"
       echo -e "\nSelect your desired option for the wind speed boundaries" 
       select sh_wndbnd in "Option_1" "Option_2" "Option_3"
       do
        case $sh_wndbnd in
                Option_1) sh_wndbnd=1;;
                Option_2) sh_wndbnd=2;;
                Option_3) sh_wndbnd=3;;
       esac
       break
      done

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
     wrfout2=`echo $wrfout | awk -F/ '{print $NF}'`  #For naming, NCL must be run by wrfout, not wrfout2 
     if [[ ${imgfmt} == "x11" ]]; then
      outname="nclplot"
     else
    read -p "`echo -e "\n "`Specify The Output File Name (Press Enter for the default name): " outname2
     cnpostname=`echo $wrfout2 | cut -d "_" -f2-3`
      if [ -z "$outname2" ]; then
       outname=`echo "windrose-"$cnpostname`
       echo "  WindRose file will be named $outname"
      else
       outname=`echo $outname2"-"$cnpostname`
      fi
     fi
    export outname

       export sh_wndbnd

     if [[ ${imgfmt} == "x11" ]]; then
      ncl -Q $postwrf_dir/modules/windrose.ncl
     else
       mkdir -p outputs_$wrfout2
       cd outputs_$wrfout2
       ln -s ../wrfout* .
       ncl -Q ../modules/windrose.ncl
       rm wrfout*
     fi
