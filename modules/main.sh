#!/bin/bash
#PostWRF Version 1.0 (May 2018)
#Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

  echo ""
  echo "*****************  PostWRF (Version 1.0)  *********************"
  echo "************* Run './postwrf.sh -h' to get help ***************"
  echo "** In case of problems, please contact <ah.nikfal@gmail.com> **"
  echo "***************************************************************"

totlines=`grep = namelist.wrf | grep -v %% | wc -l` #Total lines of namelist.wrf

curdir=`pwd`
trap 'my_exit; exit' SIGINT SIGQUIT
count=0
my_exit()
{
curdir2=`pwd`
rm timestep_file 2> /dev/null
rm .AllWRFVariables 2> /dev/null
if [[ $curdir != $curdir2 ]]; then

wrflist2=`ls wrfout*`
totnom=`echo $wrflist2 | wc -w`
rmcounter=1
while [ $rmcounter -le $totnom ]; do
file=`echo $wrflist2 | cut -d' ' -f$rmcounter`
 if [[ -L "$file" ]]; then
 rm $file 2> /dev/null
 fi
rmcounter=$((rmcounter+1))
done

unset rmcounter
fi
}

function countline {
numlinevars=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | awk -F',' '{ print NF }'`
ifendcomma=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | rev | cut -c1`
if [[ $ifendcomma == "," ]]; then
numlinevars=$((numlinevars-1))
fi
}

counter=0

while [  $counter -lt $totlines ]; do

###################################################################################################
###############   1st LINE OF namelist.wrf   ####################################################
###################################################################################################

if [ $counter == 0 ]; then #For the first line (Variables)
#Counting Variables in a line of namelist.wrf
countline
export nclvars=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Vairables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  wrfvars[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  wrfvars[$varcount]=`echo ${wrfvars[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

 varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare nclwrfvar$varcount=${wrfvars[$varcount]}
export nclwrfvar$varcount
  varcount=$((varcount+1))
	done

###################################################################################################
###############   2nd LINE OF namelist.wrf   ###################################################
###################################################################################################

elif [ $counter == 1 ]; then #For the second line (Locations)
#Counting Variables in a line of namelist.wrf
countline
export ncllocs=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Vairables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  locnames[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  locnames[$varcount]=`echo ${locnames[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare ncllocnames$varcount=${locnames[$varcount]}
export ncllocnames$varcount
  varcount=$((varcount+1))
 done

###################################################################################################
###############   3rd LINE OF namelist.wrf   ####################################################
###################################################################################################

elif [ $counter == 2 ]; then #For the third line (Latitudes)
#Counting Variables in a line of namelist.wrf
countline
export ncllats=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Variables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  loclats[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  loclats[$varcount]=`echo ${loclats[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare nclloclats$varcount=${loclats[$varcount]}
export nclloclats$varcount
  varcount=$((varcount+1))
 done

###################################################################################################
###############   4th LINE OF namelist.wrf   ####################################################
###################################################################################################

elif [ $counter == 3 ]; then #For the forth line (Longitudes)
#Counting Variables in a line of namelist.wrf
countline
export ncllons=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Vairables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  loclons[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  loclons[$varcount]=`echo ${loclons[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare nclloclons$varcount=${loclons[$varcount]}
export nclloclons$varcount
  varcount=$((varcount+1))
 done

###################################################################################################
###############   5th LINE OF namelist.wrf (Contour variable (on levels))   #######################
###################################################################################################

elif [ $counter == 4 ]; then #For the fifth line (Contour Variables)
#Counting Variables in a line of namelist.wrf
numlinevars=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | awk -F',' '{ print NF }'`
nocnvars=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p"`
nocnvarscharnum=`echo $nocnvars | wc -m`
ifendcomma=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | rev | cut -c1`
if [[ $ifendcomma == "," ]]; then
numlinevars=$((numlinevars-1))
fi
export nclcontournum=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Variables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  contourvars[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  contourvars[$varcount]=`echo ${contourvars[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare nclcontourvars$varcount=${contourvars[$varcount]}
export nclcontourvars$varcount
  varcount=$((varcount+1))
 done

###################################################################################################
###############   6th LINE OF namelist.wrf (Contour Levels)   #####################################
###################################################################################################

elif [ $counter == 5 ]; then #For the 6th line (Contour_Levels)
#Counting Variables in a line of namelist.wrf
countline
export nclcnlevelnum=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Vairables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  contourlevs[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  contourlevs[$varcount]=`echo ${contourlevs[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare contourlevs$varcount=${contourlevs[$varcount]}
export contourlevs$varcount
  varcount=$((varcount+1))
 done
unset varcount

###################################################################################################
###############   7th LINE OF namelist.wrf (Contour variable (surface))   #########################
###################################################################################################

elif [ $counter == 6 ]; then #For the 7th line (Contour Variables (2D))
#Counting Variables in a line of namelist.wrf
numlinevars=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | awk -F',' '{ print NF }'`
nocnsfcvar=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p"`
nocnsfcvarcharnum=`echo $nocnsfcvar | wc -m`
ifendcomma=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | rev | cut -c1`
if [[ $ifendcomma == "," ]]; then
numlinevars=$((numlinevars-1))
fi
export nclcontournumsfc=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Variables into array
varcount=0
 while [  $varcount -lt $numlinevars ]; do
  contoursfc[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  contoursfc[$varcount]=`echo ${contoursfc[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [  $varcount -lt $numlinevars ]; do
declare nclcontourvarssfc$varcount=${contoursfc[$varcount]}
export nclcontourvarssfc$varcount
  varcount=$((varcount+1))
 done
unset varcount

###################################################################################################
##################   8th LINE OF namelist.wrf (Shapefile On Off)  ########################
###################################################################################################

elif [ $counter == 7 ]; then 
#Extracting Variables into array
  shape_onoff=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p"`
  shape_onoff=`echo ${shape_onoff}` #Remove spaces
export shape_onoff

###################################################################################################
#######################   9th LINE OF namelist.wrf (Shapefile Path)   #############################
###################################################################################################
elif [ $counter == 8 ]; then 
#Extracting Path Address
  shape_path=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p"`
  shape_path=`echo ${shape_path}` #Remove spaces
export shape_path

###################################################################################################
##################   10th LINE OF namelist.wrf (Cross Section variables)   #########################
###################################################################################################

elif [ $counter == 9 ]; then #For the third line (Latitudes)
#Counting Variables in a line of namelist.wrf
countline
export nclcrossnum=$numlinevars  #Zero (0) is included in the line numbers
#Extracting Variables into array
varcount=0
 while [ $varcount -lt $numlinevars ]; do
  crossvar[$varcount]=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p" | cut -d, -f$((varcount+1))`
  crossvar[$varcount]=`echo ${crossvar[$varcount]}` #Remove spaces
  varcount=$((varcount+1))
 done
unset varcount

varcount=0
 while [ $varcount -lt $numlinevars ]; do
declare nclcrossvar$varcount=${crossvar[$varcount]}
export nclcrossvar$varcount
  varcount=$((varcount+1))
 done

###################################################################################################
##################   11th LINE OF namelist.wrf (Domain Path)   #########################
###################################################################################################

elif [ $counter == 10 ]; then #For the third line (Latitudes)
#Extracting Path Address
  wpspath=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p"`
  wpspath=`echo ${wpspath}` #Remove spaces
export wpspath

###################################################################################################
##################   12th LINE OF namelist.wrf (Locations' Labels On Off)  ########################
###################################################################################################

elif [ $counter == 11 ]; then #For the third line (Latitudes)
#Extracting Variables into array
  wpslables=`grep = namelist.wrf | grep -v %% | awk -F"=" '{print $NF}' | sed -n "$((counter+1)) p"`
  wpslables=`echo ${wpslables}` #Remove spaces
export wpslables


fi #for the first line variable

counter=$((counter+1))

done
 nofile=False
 extractonoff=`cat namelist.wrf | grep Extract_On-Off | awk '{print $3}'`
 contouronoff=`cat namelist.wrf | grep Contour_On-Off | awk '{print $3}'`
 crossonoff=`cat namelist.wrf | grep CrossSection_On-Off | awk '{print $3}'`
 roseonoff=`cat namelist.wrf | grep windrose_On-Off | awk '{print $3}'`
 skewtonoff=`cat namelist.wrf | grep skewT_On-Off | awk '{print $3}'`
 domainonoff=`cat namelist.wrf | grep Domain_On-Off | awk '{print $3}'`
 if [[ $extractonoff == 1 || $contouronoff == 1 || $crossonoff == 1 || $roseonoff == 1 || $skewtonoff == 1 ]]; then #code QQWW
###################################################################################################
###############   Specifying WRF Output File   ####################################################
###################################################################################################

  if [ -z "$wrfout" ]; then  #code abc
   wrflist=`ls wrfout* 2> /dev/null`
   wrflistvar=`echo $wrflist | wc -w`
   if [ -z "$wrflist" ]; then
    echo "      No WRF output files in the current directory."
    echo "      You can link or copy one or more files to the current directory."
    nofile=True
   elif [ $wrflistvar == 1 ]; then
    wrfout=$wrflist
    echo -e "\n"$wrfout" has been selected in the current directory.\n"
   else
    echo -e "\nThere are multiple wrf-files in the current directory:\n"
    COUNTER=0
    ls wrfout* > .listfile
         while [  $COUNTER -lt $wrflistvar ]; do
             wrffile[$COUNTER]=`sed -n "$((COUNTER+1)) p" .listfile`
            COUNTER=$((COUNTER+1))
         done
     COUNTER=0
     while [  $COUNTER -lt $wrflistvar ]; do
      echo -e "   $((COUNTER+1))) ${wrffile[$COUNTER]}"
      COUNTER=$((COUNTER+1))
     done
     echo ""
     unset COUNTER
varrr=True
     while [  $varrr == True ]; do
    read -p "Enter the number of the favored file: " filenum
     if [[ $filenum -le $wrflistvar && $filenum -ge 1 ]] 2> /dev/null; then
     wrfout=${wrffile[$((filenum-1))]}
      break
     fi
    echo " Not valid. Select an integer between 1 to" $wrflistvar "..."
    done
     echo -e "\n"$wrfout" has been selected"
     echo "."
     echo "."
     echo "."
     unset filenum
    rm -f .listfile
   fi
  fi #code abc

  if [[ $nofile == False ]]; then
	  diagvars=("ua" "va" "wa" "tc" "tk" "td" "td2" "th" "theta" "tv" "twb" "eth" "slp" "p" "pres" "pressure" "geopotential" "geopt" "rh" \
"rh2" "z" "height" "ter" "pvo" "pw" "avo" "cape_surface" "cin_surface" "cape_3d" "cin_3d" "ctt" "dbz" "mdbz" "helicity" \
"omg" "updraft_helicity")

if [ `echo $wrfout | rev | cut -c -3 | rev` == ".nc" ]; then
ncl_filedump $wrfout | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' > .wrfvars
ncl_filedump $wrfout | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >> .wrfvars
ncl_filedump $wrfout | grep "( Time, south_north, west_east" | awk '{print $2}' >> .wrfvars
ncl_filedump $wrfout | grep float | awk '{print $2}' > .AllWRFVariables
ncl_filedump $wrfout | grep "Variable" | grep -v "f" | awk '{print $2}' >> .AllWRFVariables
else
ncl_filedump "$wrfout.nc" | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' > .wrfvars
ncl_filedump "$wrfout.nc" | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >> .wrfvars
ncl_filedump "$wrfout.nc" | grep "( Time, south_north, west_east" | awk '{print $2}' >> .wrfvars
ncl_filedump "$wrfout.nc" | grep float | awk '{print $2}' > .AllWRFVariables
ncl_filedump "$wrfout.nc" | grep "Variable" | grep -v "f" | awk '{print $2}' >> .AllWRFVariables
fi
varcount=0
 while [  $varcount -lt 34 ]; do
  echo ${diagvars[$varcount]} >> .AllWRFVariables
  varcount=$((varcount+1))
 done
 unset varcount
 export wrfout
 wrfout2=`echo $wrfout | awk -F/ '{print $NF}'`  #For naming, NCL must be run by wrfout, not wrfout2
###################################################################################
####################                 NCL            ###############################
###################################################################################
 if [[ $extractonoff == 1 ]]; then
 echo -e "\nPostWRF: Extracting variables ...\n"
 mkdir -p outputs_$wrfout2
 cd outputs_$wrfout2
 ln -s ../wrfout* .
 ln -s ../.AllWRFVariables .
 ncl ../modules/extract.ncl
 rm wrfout*
 echo -e "\nPostWRF: Extracting variables finished.\n"
 fi

 # Contour (Level) Module==========================================================
 if [[ $contouronoff == 1 ]]; then #code rrr9
  if [[ $extractonoff == 1 ]]; then
   cd ..
  fi
  echo "PostWRF: Drawing contour maps on levels ..."
 if [ $nocnvarscharnum -gt 1 ]; then #code qq123
 varcount=0
 while [  $varcount -lt $nclcontournum ]; do
 contourselect=nclcontourvars$varcount
 declare contourselect=${contourvars[$varcount]}
 export contourselect
 ./modules/contourlvl.sh
 unset contourselect
 varcount=$((varcount+1))
 done
 unset varcount
 else
  if [ -z $nocnvars ]; then  #If there is no variable set in namelist.wrf
   echo -e "\nPostWRF: No variable found for contour map on levels. skipping ..."
  else
 varcount=0
 while [ $varcount -lt $nclcontournum ]; do
 contourselect=nclcontourvars$varcount 
 declare contourselect=${contourvars[$varcount]}
 export contourselect
 ./modules/contourlvl.sh
 unset contourselect
 varcount=$((varcount+1))
 done
 unset varcount
  fi #If there is no variable set in namelist.wrf
 fi #code qq123

  # Contour (Surface) Module==========================================================
 echo -e "\nPostWRF: Drawing contour maps on surface ..."
if [ $nocnsfcvarcharnum -gt 1 ]; then #code ww45
 if [[ $extractonoff == 1 ]]; then
   cd ..
 fi
 varcount=0
 while [ $varcount -lt $nclcontournumsfc ]; do
 contourselect=nclcontourvarssfc$varcount
 declare contourselect=${contoursfc[$varcount]}
 export contourselect
 ./modules/contoursfc.sh
 unset contourselect
 varcount=$((varcount+1))
 done
 unset varcount
else
  if [ -z $nocnsfcvar ]; then #If there is no variable set in namelist.wrf
   echo -e "\nPostWRF: No variable found for surface contour map on levels. skipping ..."
  else
 varcount=0
 while [ $varcount -lt $nclcontournumsfc ]; do
 contourselect=nclcontourvarssfc$varcount
 declare contourselect=${contoursfc[$varcount]}
 export contourselect
 ./modules/contoursfc.sh
 unset contourselect
 varcount=$((varcount+1))
 done
 unset varcount
  fi #If there is no variable set in namelist.wrf
 fi #code ww45
fi  #code rrr9
unset contouronoff

# CrossSection Module===================================================================
 if [[ $crossonoff == 1 ]]; then
  if [[ $extractonoff == 1 ]]; then
   cd ..
  fi
 varcount=0
 while [ $varcount -lt $nclcrossnum ]; do
 crossselect=nclcrossvar$varcount
 declare crossselect=${crossvar[$varcount]}
 export crossselect
 ./modules/cross.sh
 unset crossselect
 varcount=$((varcount+1))
 done
 unset varcount
 echo -e "\nPostWRF: Cross-section maps finished.\n"
 fi
 unset crossonoff

# WindRose Module===================================================================
 if [[ $roseonoff == 1 ]]; then
  if [[ $extractonoff == 1 ]]; then
   cd ..
  fi
   echo -e "\n Drawing the WindRose on the locations ..."
  ./modules/windrose.sh
 fi
 unset roseonoff

# SkewT Module===================================================================
 if [[ $skewtonoff == 1 ]]; then
  if [[ $extractonoff == 1 ]]; then
   cd ..
  fi
   echo -e "\n Drawing the SkewT diagram on the locations ...\n"
  ./modules/skewt.sh
 fi

fi # code QQWW
fi # first if
#Out of loop for all of the previous tasks 
# Domain Module===================================================================
#domainonoff=`cat namelist.wrf | grep Domain_On-Off | awk '{print $3}'`
 if [[ $domainonoff == 1 ]]; then
  if [[ $extractonoff == 1 ]]; then
   cd ..
  fi
 echo -e "\nPostWRF: Drawing the map of the model domain ...\n"
 ./modules/domain.sh
 echo -e "\nPostWRF: Drawing the map of domain finished.\n"
 fi

 rm -f .wrfvars 2> /dev/null
 rm -f .AllWRFVariables 2> /dev/null
