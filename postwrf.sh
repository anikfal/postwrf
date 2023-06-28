#!/bin/bash
#PostWRF Version 1.3 (January 2022)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

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

awk_read_onoff () {
        awk -v pat=$1 '$0~pat {print $3}' namelist.wrf
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
  f)  if [[ $(echo $2 | awk -F. '{ print $NF }') == "nc" ]]; then
        echo "  Variable names inside the file $2:"
        ncl_filedump $2 | awk '/short/ {for(i=2;i<=NF;i++) printf $i" "; print ""}'
        echo "  Variables' description:"
        ncl_filedump $2 | awk '/long_name/ {for(i=1;i<=NF;i++) printf $i" "; print ""}' | sed -n '5,$ p'
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
    echo "  PostWRF Version 1.3 (January 2022)"
    echo "  Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>"
    ;;
  esac
done

if [[ $1 != "-h" && $1 != "-i" && $1 != "-f" && $1 != "-d" && $1 != "-p" ]]; then
  export wrfout=$1
  export extractonoff=$(awk_read_onoff WRF_Extract_ON_OFF)
  export contour_onoff=$(awk_read_onoff CONTOUR_ON_OFF)
  export crossonoff=$(awk_read_onoff CROSSSECTION_ON-OFF)
  export roseonoff=$(awk_read_onoff windrose_On-Off)
  export skewtonoff=$(awk_read_onoff skewT_On-Off)
  export domainonoff=$(awk_read_onoff Domain_On-Off)
  export statisticalonoff=$(awk_read_onoff STATISTICAL_DIAGRAMS_ON_OFF)
  export GEOTIFF_ONOFF=$(awk_read_onoff Geotiff_ON_OFF)
  export rttov_onoff=$(awk_read_onoff RTTOV_On-Off)
  export era_onoff=$(awk_read_onoff ERA5_ON_OFF)
  export era_extract_onoff=$(awk_read_onoff ERA5_Extract_ON_OFF)
  sumopts=$((extractonoff + era_extract_onoff + contour_onoff + crossonoff + roseonoff + skewtonoff + domainonoff + GEOTIFF_ONOFF + statisticalonoff + rttov_onoff + era_onoff))
  if [[ $sumopts -gt 1 ]]; then
    echo ""
    echo "  More than one task is on"
    echo "  Select only one task or section in namelist.wrf and run again"
    echo ""

  elif [[ $sumopts -eq 0 ]]; then
    echo ""
    echo "  No section is activated"
    echo "  Select one task or section in namelist.wrf and run again"
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
    if [[ $era_onoff -ne 1 && $era_extract_onoff -ne 1 ]]; then
      ./modules/main.sh
      rm eqname equnit 2>/dev/null
      cd $postwrf_dir/modules
      rm wrfout_d0* eq* *.txt .AllWRFVariables 2>/dev/null
    else
      ./modules_era/main_era.sh
    fi
  fi
fi
