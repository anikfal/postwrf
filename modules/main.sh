#!/bin/bash
#PostWRF Version 1.1 (Apr 2020)
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
echo ""
echo "=================  PostWRF (Version 1.1)  ====================="
echo "              Run './postwrf.sh -h' to get help                "
echo "   In case of problems, please contact <ah.nikfal@gmail.com>   "
echo "==============================================================="

curdir=$(pwd)
trap 'my_exit; exit' SIGINT SIGQUIT
count=0
my_exit() {
  curdir2=$(pwd)
  rm timestep_file 2>/dev/null
  rm .AllWRFVariables 2>/dev/null
  if [[ $curdir != $curdir2 ]]; then

    wrflist2=$(ls wrfout*)
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
  ifendcomma=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | rev | cut -c1)
  if [[ $ifendcomma == "," ]]; then
    numlinevars=$((numlinevars - 1))
  fi
}

###################################################################################################
##################################   GLOBAL SETTINGS   ############################################
###################################################################################################
myvar="spin-up_time"
spinup=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export spinup=$(echo $spinup)                                                     #Remove spaces
unset myvar

myvar="averaging_on_off"
average_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
export average_onoff=$(echo ${average_onoff}) #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="average_time"
averagetime=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export averagetime=$(echo $averagetime)                                                #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="smooth_maps_on_off"
smooth_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
smooth_onoff=$(echo ${smooth_onoff}) #Remove spaces
export smooth_onoff
unset myvar

##------------------------------------------------------------------------------------------------
myvar="map_filled_ocean_on_off"
oceanfill_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
export oceanfill_onoff=$(echo ${oceanfill_onoff}) #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="map_borderline_color"
border_color=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export border_color=$(echo $border_color)                                               #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="map_borderline_thickness"
borderthick=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export borderthick=$(echo $borderthick)                                                #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="map_gridlines_on_off"
gridline_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
export gridline_onoff=$(echo ${gridline_onoff}) #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="plot_titles_on_off"
titile_option=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
export titile_option=$(echo ${titile_option}) #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="panel_plot__on_off"
panelplot=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
export panelplot=$(echo ${panelplot}) #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="panel_plot__rows_number"
panelrows=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export panelrows=$(echo $panelrows)                                                  #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="panel_plot__columns_number"
panelcolumns=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export panelcolumns=$(echo $panelcolumns)                                               #Remove spaces
unset myvar

##------------------------------------------------------------------------------------------------
myvar="Variable_name_to_Geotiff"
GTIFFVAR=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
export GTIFFVAR=$(echo "${GTIFFVAR// /}")
unset myvar

##------------------------------------------------------------------------------------------------
myvar="Geotiff_pressure_level"
countline
export GTIFFPLEV_num=$numlinevars #Zero (0) is included in the line numbers
#Extracting Vairables into array
varcount=0
while [ $varcount -lt $numlinevars ]; do
  gtiffP_array[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
  gtiffP_array[$varcount]=$(echo ${gtiffP_array[$varcount]}) #Remove spaces
  varcount=$((varcount + 1))
done
unset varcount
varcount=0
while [ $varcount -lt $numlinevars ]; do
  declare GTIFFPLEVS$varcount=${gtiffP_array[$varcount]}
  export GTIFFPLEVS$varcount
  varcount=$((varcount + 1))
done
unset myvar

###################################################################################################
###############   1st Section (DATA_EXTRACT)   ####################################################
###################################################################################################

if [[ $extractonoff == 1 || $contour_onoff == 1 || $domainonoff == 1 || $roseonoff == 1 || $skewtonoff == 1 ]]; then #For the first line (Variables)
  #Counting Variables in a line of namelist.wrf
  myvar="WRF_variable_name"
  countline
  export nclvars=$numlinevars #Zero (0) is included in the line numbers
  #Extracting Vairables into array
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    wrfvars[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
    wrfvars[$varcount]=$(echo -n "${wrfvars[$varcount]//[[:space:]]/}") #Remove spaces
    varcount=$((varcount + 1))
  done
  unset varcount

  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    declare nclwrfvar$varcount=${wrfvars[$varcount]}
    export nclwrfvar$varcount
    varcount=$((varcount + 1))
  done
  unset myvar
  ###################################################################################################
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
fi
###################################################################################################
###############   2nd Section (CONTOUR_MAP)   #######################
###################################################################################################
if [[ $contour_onoff == 1 ]]; then                                                  #For the fifth line (Contour Variables)
  myvar="3rd_Variable_name"                                                         #nclcontourvars11
  CNVAR3=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  # export CNVAR3=$(echo $CNVAR3)                                                     #Remove spaces
  export CNVAR3=$(echo "${CNVAR3// /}") #Remove spaces
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="3rd_Variable_on_off"
  THIRDVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export THIRDVAR_ONOFF=$(echo ${THIRDVAR_ONOFF}) #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="3rd_Variable_pressure_level"
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
  myvar="Location_point_mark_on_off"
  contourpoints_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export contourpoints_onoff=$(echo ${contourpoints_onoff}) #Remove spaces
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="Location_labels_size"
  labelsize=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export labelsize=$(echo $labelsize)                                                  #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="Location_labels_color"
  labelcolor=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export labelcolor=$(echo $labelcolor)                                                 #Remove spaces
  unset myvar

  #------------------------------------------------------------------------------------------------
  myvar="Location_labels_on_off"
  contourlabel_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export contourlabel_onoff=$(echo ${contourlabel_onoff}) #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="1st_Variable_on_off" #secondvar_onoffF
  FIRSTVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export FIRSTVAR_ONOFF=$(echo "${FIRSTVAR_ONOFF// /}")
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="2nd_Variable_on_off" #thirdvar_onofff
  SECONDVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export SECONDVAR_ONOFF=$(echo "${SECONDVAR_ONOFF// /}")
  unset myvar

  if [ $FIRSTVAR_ONOFF == 1 ]; then
    ##------------------------------------------------------------------------------------------------
    myvar="1st_Variable_name"
    CNVAR1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNVAR1=$(echo "${CNVAR1// /}") #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------

    myvar="1st_Variable_pressure_level"
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
    myvar="1st_Variable_intervals"                                                     #nclintv22
    CNINTV1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNINTV1=$(echo $CNINTV1)                                                    #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_Variable_line_color"                                                     #nclcontourcolor22
    CNCOLOR1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNCOLOR1=$(echo $CNCOLOR1)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_Variable_line_thickness"                                                 #nclthickness22
    CNTHICK1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNTHICK1=$(echo $CNTHICK1)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_Variable_label_size"                                                     #ncllabel2
    CNLABEL1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNLABEL1=$(echo $CNLABEL1)                                                   #Remove spaces
    unset myvar
  fi

  if [ $SECONDVAR_ONOFF == 1 ]; then
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_Variable_name"                                                         #nclcontourvars33
    CNVAR2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    # export CNVAR2=$(echo $CNVAR2)                                                     #Remove spaces
    export CNVAR2=$(echo "${CNVAR2// /}") #Remove spaces
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="2nd_Variable_pressure_level"
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
    myvar="2nd_Variable_intervals"
    CNINTV2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNINTV2=$(echo $CNINTV2)                                                    #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_Variable_line_color"
    CNCOLOR2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNCOLOR2=$(echo $CNCOLOR2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_Variable_line_thickness"
    CNTHICK2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNTHICK2=$(echo $CNTHICK2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_Variable_label_size"
    CNLABEL2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export CNLABEL2=$(echo $CNLABEL2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_Variable_brokenline_on_off" #CNBROKEN2
    CNBROKEN2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
    export CNBROKEN2=$(echo ${CNBROKEN2}) #Remove spaces
    unset myvar
  fi

  ##------------------------------------------------------------------------------------------------
  myvar="Wind_Vectors_on_off"
  wind_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  wind_onoff=$(echo ${wind_onoff}) #Remove spaces
  export wind_onoff
  unset myvar

  if [ $wind_onoff == 1 ]; then
    myvar="Wind_Vectors_pressure_level"
    windlev=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    windlev=$(echo $windlev)                                                           #Remove spaces
    export nclwindlev=$windlev
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="Wind_Vectors_speed"
    windsize=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export windsize=$(echo $windsize)                                                   #Remove spaces
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="Wind_Vectors_density"
    winddens=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export winddens=$(echo $winddens)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="Wind_Vectors_color"
    windcolor=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export windcolor=$(echo $windcolor)                                                  #Remove spaces
    unset myvar

    ##------------------------------------------------------------------------------------------------
    myvar="Wind_Vectors_thickness"
    windthick=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export windthick=$(echo $windthick)                                                  #Remove spaces
    unset myvar
  fi

  ##------------------------------------------------------------------------------------------------
  myvar="Shapefile_on-off"
  shape_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  shape_onoff=$(echo ${shape_onoff}) #Remove spaces
  export shape_onoff
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="Shapefile_path"
  shape_path=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  shape_path=$(echo ${shape_path}) #Remove spaces
  export shape_path
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="Province_on-off"
  province_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  province_onoff=$(echo ${province_onoff}) #Remove spaces
  export province_onoff
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="Province_name"
  countline
  export province_num=$numlinevars #Zero (0) is included in the line numbers
  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    province_names[$varcount]=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f$((varcount + 1)))
    province_names[$varcount]=$(echo ${province_names[$varcount]}) #Remove spaces
    varcount=$((varcount + 1))
  done
  unset varcount

  varcount=0
  while [ $varcount -lt $numlinevars ]; do
    declare ncl_province_names$varcount=${province_names[$varcount]}
    export ncl_province_names$varcount
    varcount=$((varcount + 1))
  done
  unset myvar
fi

###################################################################################################
##################################   CrossSection Map   ###########################################
###################################################################################################

if [[ $crossonoff == 1 ]]; then                                                      #For the fifth line (Contour Variables)
  myvar="3rd_var_name"                                                               #nclcontourvars11
  xCNVAR3=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  # export xCNVAR3=$(echo $xCNVAR3)                                                    #Remove spaces
  export xCNVAR3=$(echo "${xCNVAR3// /}") #Remove spaces
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="CrossSection_path_on_off" #secondvar_onoffF
  xcrosspath_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export xcrosspath_ONOFF=$(echo "${xcrosspath_ONOFF// /}")
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="Topographic_map_on_off" #secondvar_onoffF
  crosstopo=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export crosstopo=$(echo "${crosstopo// /}")
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="3rd_var_on_off"
  xTHIRDVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export xTHIRDVAR_ONOFF=$(echo ${xTHIRDVAR_ONOFF}) #Remove spaces
  unset myvar
  ##------------------------------------------------------------------------------------------------
  myvar="1st_var_on_off" #secondvar_onoffF
  xFIRSTVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export xFIRSTVAR_ONOFF=$(echo "${xFIRSTVAR_ONOFF// /}")
  unset myvar

  ##------------------------------------------------------------------------------------------------
  myvar="2nd_var_on_off" #thirdvar_onofff
  xSECONDVAR_ONOFF=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export xSECONDVAR_ONOFF=$(echo "${xSECONDVAR_ONOFF// /}")
  unset myvar

  if [[ $xFIRSTVAR_ONOFF == 1 ]]; then
    ##------------------------------------------------------------------------------------------------
    myvar="1st_var_name"                                                               #contourvars22 #nclcontourvars22
    xCNVAR1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNVAR1=$(echo "${xCNVAR1// /}")                                            #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_var_intervals"                                                           #nclintv22
    xCNINTV1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNINTV1=$(echo $xCNINTV1)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_var_line_color"                                                           #nclcontourcolor22
    xCNCOLOR1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNCOLOR1=$(echo $xCNCOLOR1)                                                  #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_var_line_thickness"                                                       #nclthickness22
    xCNTHICK1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNTHICK1=$(echo $xCNTHICK1)                                                  #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="1st_var_label_size"                                                           #ncllabel2
    xCNLABEL1=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNLABEL1=$(echo $xCNLABEL1)                                                  #Remove spaces
    unset myvar
  fi

  if [[ $xSECONDVAR_ONOFF == 1 ]]; then
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_var_name"                                                               #nclcontourvars33
    xCNVAR2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    # export xCNVAR2=$(echo $xCNVAR2)                                                    #Remove spaces
    export xCNVAR2=$(echo "${xCNVAR2// /}")
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_var_intervals"
    xCNINTV2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNINTV2=$(echo $xCNINTV2)                                                   #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_var_line_color"
    xCNCOLOR2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNCOLOR2=$(echo $xCNCOLOR2)                                                  #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_var_line_thickness"
    xCNTHICK2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNTHICK2=$(echo $xCNTHICK2)                                                  #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_var_label_size"
    xCNLABEL2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
    export xCNLABEL2=$(echo $xCNLABEL2)                                                  #Remove spaces
    unset myvar
    ##------------------------------------------------------------------------------------------------
    myvar="2nd_var_brokenline_on_off" #CNBROKEN2
    xCNBROKEN2=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
    export xCNBROKEN2=$(echo ${xCNBROKEN2}) #Remove spaces
    unset myvar
  fi

fi

###################################################################################################
##################   4th Section (DOMAIN_MAP)   #########################
###################################################################################################

if [ $domainonoff == 1 ]; then #For the third line (Latitudes)
  #Extracting Path Address
  myvar="namelist.wps_path"
  wpspath=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  wpspath=$(echo ${wpspath}) #Remove spaces
  export wpspath
  unset myvar

  myvar="background_color"
  domcolor=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export domcolor=$(echo $domcolor)                                                   #Remove spaces
  unset myvar

  myvar="Domain_on_off (topography)" # TOPOGRAPHY
  domtopo_onoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  export domtopo_onoff=$(echo "${domtopo_onoff// /}")
  unset myvar

  myvar="number_of_domains"
  dom_number=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export dom_number=$(echo $dom_number)                                                 #Remove spaces
  unset myvar

  myvar="box_color"
  boxcolor=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
  export boxcolor=$(echo $boxcolor)                                                   #Remove spaces
  unset myvar

  ###################################################################################################
  #Extracting Variables into array
  myvar="lables_On-Off"
  wpslables=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
  wpslables=$(echo ${wpslables}) #Remove spaces
  export wpslables
  unset myvar
  echo -e "\nPostWRF: Drawing the map of the model domain ...\n"
  cd $postwrf_dir
  ./modules/domain.sh
  echo -e "\nPostWRF: Drawing the map of domain finished.\n"

fi

nofile=False
if [[ $extractonoff == 1 || $GEOTIFF_ONOFF == 1 || $contour_onoff == 1 || $crossonoff == 1 || $roseonoff == 1 || $skewtonoff == 1 ]]; then #code QQWW
  ###################################################################################################
  ###############   Specifying WRF Output File   ####################################################
  ###################################################################################################

  if [ $extractonoff == 1 ]; then
    echo ""
    echo "---------------------------------------------------------"
    echo "      EXTRACT VARIABLE             EXTRACT VARIABLE"
    echo "---------------------------------------------------------"
    echo ""
  elif [ $GEOTIFF_ONOFF == 1 ]; then
    echo ""
    echo "---------------------------------------------------------"
    echo "      CONVERT TO GEOTIFF          CONVERT TO GEOTIFF"
    echo "---------------------------------------------------------"
    echo ""
  elif [ $contour_onoff == 1 ]; then
    echo ""
    echo "---------------------------------------------------------"
    echo "       CONTOUR PLOT                CONTOUR PLOT"
    echo "---------------------------------------------------------"
    echo ""
  elif [ $crossonoff == 1 ]; then
    echo ""
    echo "---------------------------------------------------------"
    echo "      CROSS SECTION PLOT           CROSS SECTION PLOT"
    echo "---------------------------------------------------------"
    echo ""
  elif [ $roseonoff == 1 ]; then
    echo ""
    echo "---------------------------------------------------------"
    echo "      WIND ROSE DIAGRAM            WIND ROSE DIAGRAM"
    echo "---------------------------------------------------------"
    echo ""
  elif [ $skewtonoff == 1 ]; then
    echo ""
    echo "---------------------------------------------------------"
    echo "      SKEWT DIAGRAM                SKEWT DIAGRAM"
    echo "---------------------------------------------------------"
    echo ""
  fi

  if [ -z "$wrfout" ]; then #code abc
    wrflist=$(ls wrfout_d* 2>/dev/null)
    wrflistvar=$(echo $wrflist | wc -w)
    if [ -z "$wrflist" ]; then
      echo "      No WRF output files in the current directory."
      echo "      You can link or copy one or more files to the current directory."
      nofile=True
    elif [ $wrflistvar == 1 ]; then
      wrfout=$wrflist
      echo -e "\n"$wrfout" has been selected in the current directory.\n"
    else
      echo -e "There are multiple wrf-files in the current directory:\n"
      COUNTER=0
      ls wrfout* >.listfile
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
      varrr=True
      while [ $varrr == True ]; do
        read -p "Enter the number of the favored file: " filenum
        if [[ $filenum -le $wrflistvar && $filenum -ge 1 ]] 2>/dev/null; then
          wrfout=${wrffile[$((filenum - 1))]}
          break
        fi
        echo " Not valid. Select an integer between 1 to" $wrflistvar "..."
      done
      echo -e "\n"$wrfout" has been selected\n"
      unset filenum
      rm -f .listfile
    fi
  fi #code abc

  if [[ $nofile == False ]]; then
    diagvars=("ua" "va" "wa" "tc" "tk" "td" "td2" "th" "theta" "tv" "twb" "eth" "slp" "p" "pres" "pressure" "geopotential" "geopt" "rh"
      "rh2" "z" "height" "ter" "pvo" "pw" "avo" "cape_surface" "cin_surface" "cape_3d" "cin_3d" "ctt" "dbz" "mdbz" "helicity"
      "omg" "updraft_helicity" "dust_total" "dust_pm10" "dust_pm2.5" "wind_s" "wind_d" "lcl" "lfc")

    if [ $(echo $wrfout | rev | cut -c -3 | rev) == ".nc" ]; then
      ncl_filedump $wrfout | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' >.wrfvars
      ncl_filedump $wrfout | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >>.wrfvars
      ncl_filedump $wrfout | grep "( Time, south_north, west_east" | awk '{print $2}' >>.wrfvars
      ncl_filedump $wrfout | grep float | awk '{print $2}' >.AllWRFVariables
      ncl_filedump $wrfout | grep "Variable" | grep -v "f" | awk '{print $2}' >>.AllWRFVariables
    else
      ncl_filedump "$wrfout.nc" | grep "( Time, bottom_top, south_north, west_east" | awk '{print $2}' >.wrfvars
      ncl_filedump "$wrfout.nc" | grep "( Time, bottom_top, south_north_stag, west_east )" | awk '{print $2}' >>.wrfvars
      ncl_filedump "$wrfout.nc" | grep "( Time, south_north, west_east" | awk '{print $2}' >>.wrfvars
      ncl_filedump "$wrfout.nc" | grep float | awk '{print $2}' >.AllWRFVariables
      ncl_filedump "$wrfout.nc" | grep "Variable" | grep -v "f" | awk '{print $2}' >>.AllWRFVariables
    fi
    varcount=0
    diagcount=${#diagvars[@]}
    while [ $varcount -lt $diagcount ]; do
      echo ${diagvars[$varcount]} >>.AllWRFVariables
      varcount=$((varcount + 1))
    done
    unset varcount
    export wrfout
    wrfout2=$(echo $wrfout | awk -F/ '{print $NF}') #Just for naming. NCL uses wrfout, not wrfout2
    ln -sf $postwrf_dir/$wrfout $postwrf_dir/modules
    ###################################################################################
    ####################                 NCL            ###############################
    ###################################################################################
    if [[ $extractonoff == 1 ]]; then
      myvar="Vertical_profile_plot_on_off"
      verticalplotonoff=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}')
      export verticalplotonoff=$(echo "${verticalplotonoff// /}")
      unset myvar
      ##------------------------------------------------------------------------------------------------
      ./modules/extract.sh
    fi

    if [[ $GEOTIFF_ONOFF == 1 ]]; then
      ./modules/geotiff.sh
    fi

    # Contour (Level) Module==========================================================
    if [[ $contour_onoff == 1 ]]; then #code rrr9
      if [[ ($THIRDVAR_ONOFF == 1 || $FIRSTVAR_ONOFF == 1 || $SECONDVAR_ONOFF == 1) ]]; then
        echo "Plotting  contour maps ..."
        echo ""
        ./modules/contourlvl.sh
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
      unset contour_onoff
    fi #code rrr9

    # CrossSection Module===================================================================
    if [[ $crossonoff == 1 ]]; then #code rrr9
      if [[ ($xTHIRDVAR_ONOFF == 1 || $xFIRSTVAR_ONOFF == 1 || $xSECONDVAR_ONOFF == 1) ]]; then
        echo "Plotting  cross-section maps ..."
        echo ""
        ./modules/cross.sh
        cd $postwrf_dir
        unlink variablesCN1.txt 2>/dev/null
        unlink variablesCN2.txt 2>/dev/null
        unlink variablesCN3.txt 2>/dev/null
        unlink eqname 2>/dev/null
        unlink equnit 2>/dev/null
        unlink totalequation.txt 2>/dev/null
        unlink variables.txt 2>/dev/null
      else
        echo -e "\nPostWRF: No cross-section variable is ON in namelist.wrf ..."
      fi
      unset crossonoff
    fi #code rrr9

    # WindRose Module===================================================================
    if [[ $roseonoff == 1 ]]; then
      echo -e "\n Drawing the WindRose on the locations ..."
      ##------------------------------------------------------------------------------------------------
      myvar="wind_location_name"
      rosevar=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
      export rosevar=$(echo "${rosevar// /}")                                            #Remove spaces
      unset myvar
      ##------------------------------------------------------------------------------------------------
      myvar="wind_location_latitude"
      roselat=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
      export roselat=$(echo $roselat)                                                    #Remove spaces
      unset myvar
      ##------------------------------------------------------------------------------------------------
      myvar="wind_location_longitude"
      roselon=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
      export roselon=$(echo $roselon)                                                    #Remove spaces
      unset myvar
      ./modules/windrose.sh
    fi
    unset roseonoff

    # SkewT Module===================================================================
    if [[ $skewtonoff == 1 ]]; then
      echo -e "\n Drawing the SkewT diagram on the locations ...\n"
      ##------------------------------------------------------------------------------------------------
      myvar="skewt_location_name"
      skewvar=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
      export skewvar=$(echo "${skewvar// /}")                                            #Remove spaces
      unset myvar
      ##------------------------------------------------------------------------------------------------
      myvar="skewt_location_latitude"
      skewlat=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
      export skewlat=$(echo $skewlat)                                                    #Remove spaces
      unset myvar
      ##------------------------------------------------------------------------------------------------
      myvar="skewt_location_longitude"
      skewlon=$(sed -n "/$myvar/p" namelist.wrf | awk -F"=" '{print $NF}' | cut -d, -f1) #only one var is read
      export skewlon=$(echo $skewlon)                                                    #Remove spaces
      unset myvar
      ./modules/skewt.sh
    fi

  fi # code QQWW

fi #if nofile is false
rm -f .wrfvars 2>/dev/null
rm -f .AllWRFVariables 2>/dev/null
