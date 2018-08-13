;PostWRF Version 1.0 (May 2018)
;Program to extract variables out of WRF files.
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;Import from shell
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 myfile = getenv("wrfout")
 var = str_match(myfile,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  f = addfile(dir + "/" + myfile,"r")
else
  f = addfile(myfile,"r")
end if

;First line
lines2 = getenv("nclvars")
lines = tointeger(lines2)
NCLvarnames = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLvarnames(i) = getenv("nclwrfvar"+i)
 i=i+1
end do
delete(lines2)
delete(lines)

;Second Line
lines2 = getenv("ncllocs")
linesmain = tointeger(lines2)
NCLlocnames = new(linesmain,"string")
i=0
do while(i.le.(linesmain-1))
 NCLlocnames(i) = getenv("ncllocnames"+i)
 i=i+1
end do
totlocs=dimsizes(NCLlocnames)
delete(lines2)

;Third Line
lines2 = getenv("ncllats")
lines = tointeger(lines2)
NCLloclats2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLloclats2(i) = getenv("nclloclats"+i)
 i=i+1
end do
NCLloclats=stringtofloat(NCLloclats2)
delete(lines2)
delete(lines)

;Fourth Line
lines2 = getenv("ncllons")
lines = tointeger(lines2)
NCLloclons2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLloclons2(i) = getenv("nclloclons"+i)
 i=i+1
end do
;tofloat(NCLloclons)
NCLloclons=stringtofloat(NCLloclons2)
delete(lines2)
delete(lines)
delete(i)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; Continue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  lat2d = f->XLAT(0,:,:)
  lon2d = f->XLONG(0,:,:)
  cr = inttochar(10)
  mdims = getfilevardimsizes(f,"U") ; get some dimension sizes for the file
  nd = dimsizes(mdims)
;  loc1 = wrf_user_ij_to_ll(f, 0, 0, True)
;  loc2 = wrf_user_ij_to_ll(f, mdims(nd-1), mdims(nd-2), True)
loc1=new(2,"float")
loc2=loc1
loc1(0)=min(lon2d)
loc1(1)=min(lat2d)
loc2(0)=max(lon2d)
loc2(1)=max(lat2d)
  print("")
  print("Range of Domain Latitudes (south-north): " + decimalPlaces(loc1(1),2,True) + " to " + decimalPlaces(loc2(1),2,True))
  print("Range of Domain Longitudes (west-east) : " + decimalPlaces(loc1(0),2,True) + " to " + decimalPlaces(loc2(0),2,True) + cr)

ii=0
outlocs=""
outlocs@_FillValue=""
 do while(ii.le.(totlocs-1))
  if ((NCLloclats(ii) .lt. loc1(1)) .or. (NCLloclats(ii) .gt. loc2(1)) .or. (NCLloclons(ii) .lt. loc1(0)) .or. (NCLloclons(ii) .gt. loc2(0))) then
   outlocs = outlocs + NCLlocnames(ii) + ", "
  end if
  ii = ii+1
 end do ;ii Loop

 if (.not.all(ismissing(outlocs))) then
  print("Warning: Location(s) " + outlocs + "are out of domain boundaries." )
 end if

totvars = dimsizes(NCLvarnames)
yy  = asciiread(".AllWRFVariables", -1, "string")

  times = wrf_user_getvar(f,"times",-1)
ii=0
do while(ii.le.(totvars-1))
if ( any(yy.eq.NCLvarnames(ii)) ) then


  if (NCLvarnames(ii) .eq. "cape_surface") then
     tc3  = wrf_user_getvar(f,"cape_2d",-1)
     tc3@_FillValue=-1
     tc3@description = "CAPE"
     tc3@units = "J/kg"
     tc2 = tc3(0,:,:,:)

 else if (NCLvarnames(ii) .eq. "cin_surface") then
     tc3  = wrf_user_getvar(f,"cape_2d",-1)
     tc3@_FillValue=-1
     tc3@description = "CIN"
     tc3@units = "J/kg"
     tc2 = tc3(1,:,:,:)

 else if (NCLvarnames(ii) .eq. "cin_3d") then
     tc3  = wrf_user_getvar(f,"cape_3d",-1)
     tc3@_FillValue=-1
     tc3@description = "CIN"
     tc3@units = "J/kg"
     tc2 = tc3(1,:,:,:,:)

 else if (NCLvarnames(ii) .eq. "cape_3d") then
     tc3  = wrf_user_getvar(f,"cape_3d",-1)
     tc3@_FillValue=-1
     tc3@description = "CIN"
     tc3@units = "J/kg"
     tc2 = tc3(0,:,:,:,:)

 else if (NCLvarnames(ii) .eq. "lcl") then
     tc3  = wrf_user_getvar(f,"cape_2d",-1)
     tc3@description = "Lifting Condensation Level"
     tc3@units = "m"
     tc2 = tc3(2,:,:,:)

 else if (NCLvarnames(ii) .eq. "lfc") then
     tc3  = wrf_user_getvar(f,"cape_2d",-1)
     tc3@description = "Level of Free Convection"
     tc3@units = "m"
     tc2 = tc3(2,:,:,:)

  else

  tc2  = wrf_user_getvar(f,NCLvarnames(ii),-1)    ; 3D temperature

end if
end if
end if
end if
end if
end if


  lat = NCLloclats
  lon = NCLloclons

  cityname = NCLlocnames

  nm = getind_latlon2d (lat2d,lon2d, lat, lon)
;--------------------------------------------------
; Extracting Temperature from the locations
;--------------------------------------------------
 LocNum = dimsizes(lat)

 if (dimsizes(dimsizes(tc2)) .eq. 3) then
  xTemp = new((/LocNum,dimsizes(tc2(:,0,0))/),typeof(tc2))
 else if (dimsizes(dimsizes(tc2)) .eq. 4) then
  xTemp = new((/LocNum,dimsizes(tc2(:,0,0,0))/),typeof(tc2))
end if
end if 

if (NCLvarnames(ii) .eq. "cape_surface" .or. NCLvarnames(ii) .eq. "cin_surface" .or. NCLvarnames(ii) .eq. "cin_3d" .or. NCLvarnames(ii) .eq. "cape_3d") then
xTemp@_FillValue=tc2@_FillValue
end if

 xTemp!0="Point Locations"
 xTemp!1="Times"
 xTemp = 0
 n=0
 do while(n.le.(LocNum-1))
 if (dimsizes(dimsizes(tc2)) .eq. 3) then
  xTemp(n,:) = xTemp(n,:) + tc2(:,nm(n,0),nm(n,1))
 else if (dimsizes(dimsizes(tc2)) .eq. 4) then
  xTemp(n,:) = xTemp(n,:) + tc2(:,0,nm(n,0),nm(n,1))
end if
end if
 n=n+1
end do

;------------------------------------------------------------------------------------------
; Computing maximum and minimum temperatures by averaging the extreme values of all points
; -----------------------------------------------------------------------------------------
  TimeSteps = dimsizes(times)
  header=(/"----------------------------------------------------------------------------", \
           " WRF Output Variable: " + NCLvarnames(ii) + " (" + tc2@description + ") - " +  "Units: " + tc2@units + "",\
           "----------------------------------------------------------------------------"/)
delete(tc2)
  hlist=[/header/]
 tablename="value-"+NCLvarnames(ii)
  write_table( tablename, "w", hlist, "%s" ) ; Write header on the table

timecap=times
timename=(/"Time"/)

;hnamelist = NewList("lifo")
alist = NewList("lifo")
;ListAppend(hnamelist,timename)
;ListAppend(alist,timecap)

;hnamelist=[/timename/]
;alist=[/timecap/]
nameformat="%19s"
valueformat="%19s"

 if (totlocs .eq. 1) then
city1=cityname(0)
value1=xTemp(0,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1/]
alist=[/timecap,value1/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 2) then
city1=cityname(0)
city2=cityname(1)
value1=xTemp(0,:)
value2=xTemp(1,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2/]
alist=[/timecap,value1,value2/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 3) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3/]
alist=[/timecap,value1,value2,value3/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 4) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4/]
alist=[/timecap,value1,value2,value3,value4/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if


 if (totlocs .eq. 5) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5/]
alist=[/timecap,value1,value2,value3,value4,value5/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data

end if

 if (totlocs .eq. 6) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6/]
alist=[/timecap,value1,value2,value3,value4,value5, value6/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 7) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 8) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 9) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 10) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if


 if (totlocs .eq. 11) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if


 if (totlocs .eq. 12) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if





 if (totlocs .eq. 13) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 14) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

 if (totlocs .eq. 15) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%15s"
 valueformat=valueformat+"%15.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if


 if (totlocs .eq. 16) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 17) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 18) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 19) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 20) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 21) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 22) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 23) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 24) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 25) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 26) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 27) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 28) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 29) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 30) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 31) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 32) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 33) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 34) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 35) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 36) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 37) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 38) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 39) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 40) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 41) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 42) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if


 if (totlocs .eq. 43) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 44) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 45) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
city45=cityname(44)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
value45=xTemp(44,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44,city45/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44,value45/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if


 if (totlocs .eq. 46) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
city45=cityname(44)
city46=cityname(45)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
value45=xTemp(44,:)
value46=xTemp(45,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44,city45,city46/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44,value45,value46/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 47) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
city45=cityname(44)
city46=cityname(45)
city47=cityname(46)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
value45=xTemp(44,:)
value46=xTemp(45,:)
value47=xTemp(46,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44,city45,city46,city47/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44,value45,value46,value47/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 48) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
city45=cityname(44)
city46=cityname(45)
city47=cityname(46)
city48=cityname(47)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
value45=xTemp(44,:)
value46=xTemp(45,:)
value47=xTemp(46,:)
value48=xTemp(47,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44,city45,city46,city47,city48/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44,value45,value46,value47,value48/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if




 if (totlocs .eq. 49) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
city45=cityname(44)
city46=cityname(45)
city47=cityname(46)
city48=cityname(47)
city49=cityname(48)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
value45=xTemp(44,:)
value46=xTemp(45,:)
value47=xTemp(46,:)
value48=xTemp(47,:)
value49=xTemp(48,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44,city45,city46,city47,city48,city49/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44,value45,value46,value47,value48,value49/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if



 if (totlocs .eq. 50) then
city1=cityname(0)
city2=cityname(1)
city3=cityname(2)
city4=cityname(3)
city5=cityname(4)
city6=cityname(5)
city7=cityname(6)
city8=cityname(7)
city9=cityname(8)
city10=cityname(9)
city11=cityname(10)
city12=cityname(11)
city13=cityname(12)
city14=cityname(13)
city15=cityname(14)
city16=cityname(15)
city17=cityname(16)
city18=cityname(17)
city19=cityname(18)
city20=cityname(19)
city21=cityname(20)
city22=cityname(21)
city23=cityname(22)
city24=cityname(23)
city25=cityname(24)
city26=cityname(25)
city27=cityname(26)
city28=cityname(27)
city29=cityname(28)
city30=cityname(29)
city31=cityname(30)
city32=cityname(31)
city33=cityname(32)
city34=cityname(33)
city35=cityname(34)
city36=cityname(35)
city37=cityname(36)
city38=cityname(37)
city39=cityname(38)
city40=cityname(39)
city41=cityname(40)
city42=cityname(41)
city43=cityname(42)
city44=cityname(43)
city45=cityname(44)
city46=cityname(45)
city47=cityname(46)
city48=cityname(47)
city49=cityname(48)
city50=cityname(49)
value1=xTemp(0,:)
value2=xTemp(1,:)
value3=xTemp(2,:)
value4=xTemp(3,:)
value5=xTemp(4,:)
value6=xTemp(5,:)
value7=xTemp(6,:)
value8=xTemp(7,:)
value9=xTemp(8,:)
value10=xTemp(9,:)
value11=xTemp(10,:)
value12=xTemp(11,:)
value13=xTemp(12,:)
value14=xTemp(13,:)
value15=xTemp(14,:)
value16=xTemp(15,:)
value17=xTemp(16,:)
value18=xTemp(17,:)
value19=xTemp(18,:)
value20=xTemp(19,:)
value21=xTemp(20,:)
value22=xTemp(21,:)
value23=xTemp(22,:)
value24=xTemp(23,:)
value25=xTemp(24,:)
value26=xTemp(25,:)
value27=xTemp(26,:)
value28=xTemp(27,:)
value29=xTemp(28,:)
value30=xTemp(29,:)
value31=xTemp(30,:)
value32=xTemp(31,:)
value33=xTemp(32,:)
value34=xTemp(33,:)
value35=xTemp(34,:)
value36=xTemp(35,:)
value37=xTemp(36,:)
value38=xTemp(37,:)
value39=xTemp(38,:)
value40=xTemp(39,:)
value41=xTemp(40,:)
value42=xTemp(41,:)
value43=xTemp(42,:)
value44=xTemp(43,:)
value45=xTemp(44,:)
value46=xTemp(45,:)
value47=xTemp(46,:)
value48=xTemp(47,:)
value49=xTemp(48,:)
value50=xTemp(49,:)
j=0
do while(j.le.(totlocs-1))
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.2f"
j=j+1
end do
hnamelist=[/timename,city1,city2,city3,city4,city5,city6,city7,city8,city9,city10,city11,city12,city13,city14,city15,city16,city17,city18,city19,city20,city21,city22,city23,city24,city25,city26,city27,city28,city29,city30,city31,city32,city33,city34,city35,city36,city37,city38,city39,city40,city41,city42,city43,city44,city45,city46,city47,city48,city49,city50/]
alist=[/timecap,value1,value2,value3,value4,value5, value6, value7, value8, value9, value10, value11, value12, value13, value14, value15,value16,value17,value18,value19,value20,value21,value22,value23,value24,value25,value26,value27,value28,value29,value30,value31,value32,value33,value34,value35,value36,value37,value38,value39,value40,value41,value42,value43,value44,value45,value46,value47,value48,value49,value50/]
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
end if

else

;print("<" + NCLvarnames(ii) + ">" + " is not among the standard 3-dimensional and 4-dimensional variables of " + myfile)
;print(NCLvarnames(ii) + " is neither a standard 3D or 4D variable of " + myfile + " nor a diagnostic variable.")
print("PostWRF Warning: " + "<" + NCLvarnames(ii) + ">" + " is not among the output variables of " + myfile)

end if

ii = ii+1
end do ;ii Loop

end
