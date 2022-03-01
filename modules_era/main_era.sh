#PostWRF Version 1.3 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

echo ""
echo "=================  PostWRF (Version 1.3)  ====================="
echo "              Run './postwrf.sh -h' to get help                "
echo "   In case of problems, please contact <ah.nikfal@gmail.com>   "
echo "==============================================================="

curdir=$(pwd)
trap 'my_exit; exit' SIGINT SIGQUIT
count=0
my_exit() {
  curdir2=$(pwd)
  rm timestep_file 2>/dev/null
  rm .AllWRFVariables postwrf_era_* 2>/dev/null
  if [[ $curdir != $curdir2 ]]; then
    wrflist2=$(ls *.nc)
    totnom=$(echo $wrflist2 | wc -w)
    rmcounter=1
    while [ $rmcounter -le $totnom ]; do
      file=$(echo $wrflist2 | cut -d' ' -f$rmcounter)
      if [[ -L "$file" ]]; then
        rm $file 2>/dev/null
      fi
      rmcounter=$((rmcounter + 1))
    done
    unset rmcounter
  fi
}

function countline() {
  numlinevars=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | awk -F',' '{ print NF }')
  ifendcomma=$(sed -n "/$myvar/p" namelist.wrf | rev | cut -c1)
  if [[ $ifendcomma == "," ]]; then
    numlinevars=$((numlinevars - 1))
  fi
}

#Reading the variables of the section General settings
source $postwrf_dir/modules_era/global_settings.sh

###############   2nd Section (CONTOUR_MAP)   #######################
if [[ $era_onoff == 1 ]]; then                                                  #For the fifth line (Contour Variables)
    #Counting Variables in a line of namelist.wrf
  myvar="Location_names"
  countline
  export ncllocs=$numlinevars #Zero (0) is included in the line numbers
  #Extracting Vairables into array
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    locnames[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
    locnames[$varcount]=$(echo ${locnames[$varcount]}) #Remove spaces
    varcount=$((varcount + 1))
  done
  unset varcount

  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    declare ncllocnames$varcount=${locnames[$varcount]}
    export ncllocnames$varcount
    varcount=$((varcount + 1))
  done
  unset myvar
  ###################################################################################################
  #Counting Variables in a line of namelist.wrf
  myvar="Location_latitudes"
  countline
  export ncllats=$numlinevars #Zero (0) is included in the line numbers
  #Extracting Variables into array
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    loclats[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
    loclats[$varcount]=$(echo ${loclats[$varcount]}) #Remove spaces
    varcount=$((varcount + 1))
  done
  unset varcount

  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    declare nclloclats$varcount=${loclats[$varcount]}
    export nclloclats$varcount
    varcount=$((varcount + 1))
  done
  unset myvar
  ###################################################################################################
  #Counting Variables in a line of namelist.wrf
  myvar="Location_longitudes"
  countline
  export ncllons=$numlinevars #Zero (0) is included in the line numbers
  #Extracting Vairables into array
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    loclons[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
    loclons[$varcount]=$(echo ${loclons[$varcount]}) #Remove spaces
    varcount=$((varcount + 1))
  done
  unset varcount

  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    declare nclloclons$varcount=${loclons[$varcount]}
    export nclloclons$varcount
    varcount=$((varcount + 1))
  done
  unset myvar
    
  myvar="3rd_ERA5_Var_name"                                                         #nclcontourvars11
  CNVAR3=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export CNVAR3=$(echo "${CNVAR3// /}")                                             #Remove spaces
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="3rd_ERA5_Var_on_off"
  THIRDVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export THIRDVAR_ONOFF=$(echo ${THIRDVAR_ONOFF}) #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="3rd_ERA5_Var_pressure_level"
  countline
  export CNLEV3_num=$numlinevars #Zero (0) is included in the line numbers
  #Extracting Vairables into array
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    cnlev3arr[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
    cnlev3arr[$varcount]=$(echo ${cnlev3arr[$varcount]}) #Remove spaces
    varcount=$((varcount + 1))
  done
  unset varcount
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    declare CNLEV3$varcount=${cnlev3arr[$varcount]}
    export CNLEV3$varcount
    varcount=$((varcount + 1))
  done
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="ERA5_point_mark_on_off"
  contourpoints_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export contourpoints_onoff=$(echo ${contourpoints_onoff}) #Remove spaces
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="ERA5_labels_size"
  labelsize=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export labelsize=$(echo $labelsize)                                                  #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="ERA5_labels_color"
  labelcolor=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export labelcolor=$(echo $labelcolor)                                                 #Remove spaces
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="ERA5_labels_on_off"
  contourlabel_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export contourlabel_onoff=$(echo ${contourlabel_onoff}) #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="1st_ERA5_Var_on_off" #secondvar_onoffF
  FIRSTVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export FIRSTVAR_ONOFF=$(echo "${FIRSTVAR_ONOFF// /}")
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="2nd_ERA5_Var_on_off" #thirdvar_onofff
  SECONDVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export SECONDVAR_ONOFF=$(echo "${SECONDVAR_ONOFF// /}")
  unset myvar

  if [ $FIRSTVAR_ONOFF == 1 ]; then
    ##------------------------------------------------------------------------------------------------
    myvar="1st_ERA5_Var_name"
    CNVAR1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNVAR1=$(echo "${CNVAR1// /}")                                             #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------

    myvar="1st_ERA5_Var_pressure_level"
    countline
    export CNLEV1_num=$numlinevars #Zero (0) is included in the line numbers
    #Extracting Vairables into array
    varcount=0
    while [ $varcount -lt $numlinevars ]; do
      cnlev1arr[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
      cnlev1arr[$varcount]=$(echo ${cnlev1arr[$varcount]}) #Remove spaces
      varcount=$((varcount + 1))
    done
    unset varcount

    varcount=0
    while [ $varcount -lt $numlinevars ]; do
      declare CNLEV1$varcount=${cnlev1arr[$varcount]}
      export CNLEV1$varcount
      varcount=$((varcount + 1))
    done
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="1st_ERA5_Var_intervals"                                                     #nclintv22
    CNINTV1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNINTV1=$(echo $CNINTV1)                                                    #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_ERA5_Var_line_color"                                                     #nclcontourcolor22
    CNCOLOR1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNCOLOR1=$(echo $CNCOLOR1)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_ERA5_Var_line_thickness"                                                 #nclthickness22
    CNTHICK1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNTHICK1=$(echo $CNTHICK1)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_ERA5_Var_label_size"                                                     #ncllabel2
    CNLABEL1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNLABEL1=$(echo $CNLABEL1)                                                   #Remove spaces
    unset myvar
  fi

  if [ $SECONDVAR_ONOFF == 1 ]; then
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_name"                                                         #nclcontourvars33
    CNVAR2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNVAR2=$(echo "${CNVAR2// /}")                                             #Remove spaces
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_pressure_level"
    countline
    export CNLEV2_num=$numlinevars #Zero (0) is included in the line numbers
    #Extracting Vairables into array
    varcount=0
    while [ $varcount -lt $numlinevars ]; do
      cnlev2arr[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
      cnlev2arr[$varcount]=$(echo ${cnlev2arr[$varcount]}) #Remove spaces
      varcount=$((varcount + 1))
    done
    unset varcount

    varcount=0
    while [ $varcount -lt $numlinevars ]; do
      declare CNLEV2$varcount=${cnlev2arr[$varcount]}
      export CNLEV2$varcount
      varcount=$((varcount + 1))
    done
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_intervals"
    CNINTV2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNINTV2=$(echo $CNINTV2)                                                    #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_line_color"
    CNCOLOR2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNCOLOR2=$(echo $CNCOLOR2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_line_thickness"
    CNTHICK2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNTHICK2=$(echo $CNTHICK2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_label_size"
    CNLABEL2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNLABEL2=$(echo $CNLABEL2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_ERA5_Var_brokenline_on_off" #CNBROKEN2
    CNBROKEN2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
    export CNBROKEN2=$(echo ${CNBROKEN2}) #Remove spaces
    unset myvar
  fi

  ##------------------------------------------------------------------------------------------------
  myvar="Wind_ERA5_on_off"
  wind_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  wind_onoff=$(echo ${wind_onoff}) #Remove spaces
  export wind_onoff
  unset myvar

  if [ $wind_onoff == 1 ]; then
    myvar="Wind_ERA5_pressure_level"
    windlev=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    windlev=$(echo $windlev)                                                           #Remove spaces
    export nclwindlev=$windlev
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="Wind_ERA5_speed"
    windsize=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export windsize=$(echo $windsize)                                                   #Remove spaces
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="Wind_ERA5_density"
    winddens=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export winddens=$(echo $winddens)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="Wind_ERA5_color"
    windcolor=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export windcolor=$(echo $windcolor)                                                  #Remove spaces
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="Wind_ERA5_thickness"
    windthick=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export windthick=$(echo $windthick)                                                  #Remove spaces
    unset myvar
  fi

  ##------------------------------------------------------------------------------------------------
  myvar="ERA5_Shapefile_on_off"
  shape_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  shape_onoff=$(echo ${shape_onoff}) #Remove spaces
  export shape_onoff
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="ERA5_Shapefile_path"
  shape_path=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  shape_path=$(echo ${shape_path}) #Remove spaces
  export shape_path
  unset myvar

  myvar="ERA5_SubDomain_on_off"
  era_subdom_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  era_subdom_onoff=$(echo ${era_subdom_onoff}) #Remove spaces
  export era_subdom_onoff
  unset myvar

  myvar="Min_lat"
  era_minlat=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export era_minlat=$(echo $era_minlat)                                                   #Remove spaces
  unset myvar

  myvar="Max_lat"
  era_maxlat=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export era_maxlat=$(echo $era_maxlat)                                                   #Remove spaces
  unset myvar

  myvar="Min_lon"
  era_minlon=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export era_minlon=$(echo $era_minlon)                                                   #Remove spaces
  unset myvar

  myvar="Max_lon"
  era_maxlon=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export era_maxlon=$(echo $era_maxlon)                                                   #Remove spaces
  unset myvar

fi

  ###################################################################################################
  ###############   Specifying WRF Output File   ####################################################
  ###################################################################################################

    echo ""
    echo "---------------------------------------------------------"
    echo "      ERA5 NetCDF Plot             ERA5 NetCDF Plot"
    echo "---------------------------------------------------------"
    echo ""

  if [ -z "$wrfout" ]; then #code abc
    wrflist=$(ls *.nc 2>/dev/null)
    wrflistvar=$(echo $wrflist | wc -w)
    if [ -z "$wrflist" ]; then
      echo "      No ERA5 NetCDF files in the current directory."
      echo "      You can link or copy one or more files to the current directory."
      exit
    elif [ $wrflistvar == 1 ]; then
      selectedwrf=$wrflist
      ln $postwrf_dir/$selectedwrf $postwrf_dir/postwrf_era_$selectedwrf
      echo -e "\n"$selectedwrf" has been selected in the current directory.\n"
    else
      echo -e "There are multiple NetCDF (ERA5) files in the current directory:\n"
      COUNTER=0
      ls *.nc >.listfile
      while [ $COUNTER -lt $wrflistvar ]; do
        wrffile[$COUNTER]=$(sed -n "$((COUNTER + 1)) p" .listfile)
        COUNTER=$((COUNTER + 1))
      done
      COUNTER=0
      while [ $COUNTER -lt $wrflistvar ]; do
        echo -e "   $((COUNTER + 1))) ${wrffile[$COUNTER]}"
        COUNTER=$((COUNTER + 1))
      done
      echo ""
      unset COUNTER

      read -p "Enter the number of the favored file: " filenum
      wrfcount=$(echo $filenum | awk -F',' '{ print NF }')
      wrflastcomma=$(echo $filenum | rev | cut -c1)
      if [[ $wrflastcomma == "," ]]; then
        wrfcount=$((wrfcount - 1))
      fi

      varcount=0
      echo ""
      while [ $varcount -lt $wrfcount ]; do
        wrfnum[$varcount]=$(echo $filenum | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1))) #separating wrf number
        wrfnum[$varcount]=$(echo ${wrfnum[$varcount]})                                             #Remove spaces
        if [[ ${wrfnum[$varcount]} -gt $wrflistvar || ${wrfnum[$varcount]} -lt 1 ]] 2>/dev/null; then
          echo -e "\nError in file number:"
          echo ${wrfnum[$varcount]} is out of the range 1 to $wrflistvar
          echo Run again with correct file numbers.
          break
        fi
        wrfnum_minus=$((wrfnum[$varcount] - 1))
        selectedwrf=${wrffile[$wrfnum_minus]}
        ln $postwrf_dir/$selectedwrf $postwrf_dir/postwrf_era_$selectedwrf
        echo $selectedwrf has been selected
        varcount=$((varcount + 1))
      done
      echo ""
      unset varcount
      unset filenum
      rm -f .listfile
    fi
  fi #code abc

    ncl_filedump $selectedwrf | grep short | awk '{print $2}' >.AllWRFVariables

    ###################################################################################
    ####################                 NCL            ###############################
    ###################################################################################
    # if [[ $extractonoff == 1 ]]; then
    #   myvar="Vertical_profile_plot_on_off"
    #   verticalplotonoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
    #   export verticalplotonoff=$(echo "${verticalplotonoff// /}")
    #   unset myvar
    #   ##------------------------------------------------------------------------------------------------
    #   ./modules_era/extract.sh
    # fi

    # Contour (Level) Module==========================================================
    if [[ $era_onoff == 1 ]]; then #code rrr9
      if [[ ($THIRDVAR_ONOFF == 1 || $FIRSTVAR_ONOFF == 1 || $SECONDVAR_ONOFF == 1) ]]; then
        echo "Plotting contour maps ..."
        echo ""
        ./modules_era/contourlvl_era.sh
        cd $postwrf_dir
        unlink variablesCN1.txt 2>/dev/null
        unlink variablesCN2.txt 2>/dev/null
        unlink variablesCN3.txt 2>/dev/null
        unlink eqname 2>/dev/null
        unlink equnit 2>/dev/null
        unlink totalequation.txt 2>/dev/null
        unlink variables.txt 2>/dev/null
      else
        echo -e "\nPostWRF: No contour variable is ON in namelist.wrf ..."
      fi
      unset era_onoff
    fi #code rrr9

rm -f .wrfvars 2>/dev/null
rm -f .AllWRFVariables 2>/dev/null
rm -f postwrf_wrfout* 2>/dev/null