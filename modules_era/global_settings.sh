#!/bin/bash
#Global settigns. To be added to main_era.sh
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
