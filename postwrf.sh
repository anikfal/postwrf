#!/bin/bash
#PostWRF Version 1.0 (May 2018)
#Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

trap 'my_exit; exit' SIGINT SIGQUIT
count=0
my_exit()
{
echo -e "\n Ctrl-C, exiting ..."
 rm .wrfvars 2> /dev/null
 rm .listfile 2> /dev/null
 rm .AllWRFVariables 2> /dev/null
}

while getopts hidf: option; do
  case $option in
	h) echo -e "  Some options are as follows:";
           echo "    -d,  print the choosable diagnostic variables which are not inside the WRF file";
	   echo "    -f,  print the choosable variables inside the WRF file (need WRF file as argument)"
	   echo "    -i,  PostWRF version and basic informations"; 
           echo "    -h,  display this help";;
        d) cat modules/readme;;
	f) if [[ `echo $2 | rev | cut -c -3 | rev` == ".nc" ]]; then
           ncl_filedump $2 | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' > .wrfvars
           ncl_filedump $2 | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >> .wrfvars
           ncl_filedump $2 | grep "( Time, south_north, west_east" | awk '{print $2}' >> .wrfvars
	   ncl_filedump $2 | grep "Variable" | grep -v "f" | awk '{print $2}' >> .wrfvars
	   echo -e "\n  List of choosable variables inside $2:"
	   echo ""
	   var_list=`cat .wrfvars`
	   echo $var_list | sed 's/ /,  /g'
	   rm .wrfvars
          else
           ncl_filedump "$2.nc" | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' > .wrfvars
           ncl_filedump "$2.nc" | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >> .wrfvars
           ncl_filedump "$2.nc" | grep "( Time, south_north, west_east" | awk '{print $2}' >> .wrfvars
	   ncl_filedump "$2.nc" | grep "Variable" | grep -v "f" | awk '{print $2}' >> .wrfvars
	   echo -e "\n  List of choosable variables inside $2:"
	   echo ""
	   var_list=`cat .wrfvars`
	   echo $var_list | sed 's/ /,  /g'
	   rm .wrfvars
          fi;;
	i) echo "  PostWRF Version 1.0 (May 2018)";
           echo "  Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>" ;;
  esac
done

if [[ $1 != "-h" && $1 != "-i" && $1 != "-f" && $1 != "-d" ]]; then
   export wrfout=$1
 ./modules/main.sh
fi
