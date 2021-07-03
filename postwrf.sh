#!/bin/bash
#PostWRF Version 1.1 (Apr 2020)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
export postwrf_dir=$(pwd)
trap 'my_exit; exit' SIGINT SIGQUIT
count=0
my_exit() {
  echo -e "\n Ctrl-C, exiting ..."
  rm .wrfvars 2>/dev/null
  rm .listfile 2>/dev/null
  rm .AllWRFVariables 2>/dev/null
  cd $postwrf_dir
  rm variablesCN1.txt variablesCN2.txt variablesCN3.txt eqname equnit totalequation.txt variables.txt 2>/dev/null
}
while getopts hdf:i option; do
  case $option in
  h)
    echo -e "  Some options are as follows:"
    echo "    -d,  print the choosable diagnostic variables which are not inside the WRF file"
    echo "    -f,  print the choosable variables inside the WRF file (need WRF file as argument)"
    echo "    -h,  display this help"
    echo "    -i,  PostWRF version and basic informations"
    ;;
  d) cat modules/readme ;;
  f) if [[ $(echo $2 | rev | cut -c -3 | rev) == ".nc" ]]; then
    ncl_filedump $2 | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' >.wrfvars
    ncl_filedump $2 | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >>.wrfvars
    ncl_filedump $2 | grep "( Time, south_north, west_east" | awk '{print $2}' >>.wrfvars
    ncl_filedump $2 | grep "Variable" | grep -v "f" | awk '{print $2}' >>.wrfvars
    echo -e "\n  List of variables inside $2:"
    echo ""
    var_list=$(cat .wrfvars)
    echo $var_list | sed 's/ /,  /g'
    rm .wrfvars
  else
    ncl_filedump "$2.nc" | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' >.wrfvars
    ncl_filedump "$2.nc" | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >>.wrfvars
    ncl_filedump "$2.nc" | grep "( Time, south_north, west_east" | awk '{print $2}' >>.wrfvars
    ncl_filedump "$2.nc" | grep "Variable" | grep -v "f" | awk '{print $2}' >>.wrfvars
    echo -e "\n  List of variables inside $2:"
    echo ""
    var_list=$(cat .wrfvars)
    echo $var_list | sed 's/ /,  /g'
    rm .wrfvars
  fi ;;
  i)
    echo "  PostWRF Version 1.1 (Oct 2020)"
    echo "  Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>"
    ;;
  esac
done

if [[ $1 != "-h" && $1 != "-i" && $1 != "-f" && $1 != "-d" && $1 != "-p" ]]; then
  export wrfout=$1
  export extractonoff=$(cat namelist.wrf | grep Extract_On-Off | awk '{print $3}')
  export contour_onoff=$(cat namelist.wrf | grep CONTOUR_ON_OFF | awk '{print $3}')
  export crossonoff=$(cat namelist.wrf | grep CROSSSECTION_ON-OFF | awk '{print $3}')
  export roseonoff=$(cat namelist.wrf | grep windrose_On-Off | awk '{print $3}')
  export skewtonoff=$(cat namelist.wrf | grep skewT_On-Off | awk '{print $3}')
  export domainonoff=$(cat namelist.wrf | grep Domain_On-Off | awk '{print $3}')
  export statisticalonoff=$(cat namelist.wrf | grep STATISTICAL_DIAGRAMS_ON_OFF | awk '{print $3}')
  export GEOTIFF_ONOFF=$(cat namelist.wrf | grep Geotiff_ON_OFF | awk '{print $3}')
  export rttov_onoff=$(cat namelist.wrf | grep RTTOV_On-Off | awk '{print $3}')
  sumopts=$((extractonoff + contour_onoff + crossonoff + roseonoff + skewtonoff + domainonoff + GEOTIFF_ONOFF + statisticalonoff + rttov_onoff))
  if [[ $sumopts -gt 1 ]]; then
    echo ""
    echo "  More than one section is activated"
    echo "  Select only one section in namelist.wrf and run again"
    echo ""

  elif [[ $sumopts -eq 0 ]]; then
    echo ""
    echo "  No section is activated"
    echo "  Select one section in namelist.wrf and run again"
    echo ""

  else
    if [[ $GEOTIFF_ONOFF -eq 1 ]]; then
      if ! hash gdal_translate 2>/dev/null; then
        echo ""
        echo "  gdal program which is necessary for the Geotiff conversion is missing"
        echo "  Install gdal and run again"
        echo ""
        exit
      fi
    fi
    ./modules/main.sh
    rm eqname equnit 2>/dev/null
    cd $postwrf_dir/modules
    rm wrfout_d0* eq* *.txt .AllWRFVariables 2>/dev/null
  fi
fi