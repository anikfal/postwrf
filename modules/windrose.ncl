;PostWRF Version 1.0 (May 2018)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/wind_rose.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin
  myfile = getenv("wrfout")
 nullchar = inttochar(0)
 var = str_match(myfile,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  f = addfile(dir + "/" + myfile,"r")
else
  f = addfile(myfile,"r")
end if
  times = wrf_user_getvar(f,"times",-1)
  dimtime = dimsizes(times)
  uvm10 = wrf_user_getvar(f,"uvmet10",-1) 
  u10 = uvm10(0,:,:,:)
  v10 = uvm10(1,:,:,:)
  
  nclwndbnd = getenv("sh_wndbnd")
  nclwndbnd = stringtointeger(nclwndbnd)
  nclimgtype = getenv("imgfmt")
  nclfilename = getenv("outname")

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
NCLloclons=stringtofloat(NCLloclons2)
delete(lines2)
delete(lines)
delete(i)
 
  sh_lats = NCLloclats
  sh_lons = NCLloclons
 
; Pick one grid point

  loc = wrf_user_ll_to_ij(f, sh_lons, sh_lats, True)
 cr = inttochar(10)
 ; loc = wrf_user_ll_to_ij(f, 50, 32, True)
wks = gsn_open_wks(nclimgtype,nclfilename)
jj = 0
;do while(jj.le.(linesmain-1)) ;loop on locations
do jj = 0, linesmain-1

  mx = loc(0,jj) - 1
  ny = loc(1,jj) - 1

  lat1  = f->XLAT(0,ny,mx)
  lon1  = f->XLONG(0,ny,mx)
  res               = True
res@tiMainOffsetYF = 0.04
res@tiMainPosition = "Center"
res@tiMainString  = "WindRose from " + times(0) + " to " + times(dimtime-1) + "~C~" + "~Z75~          Location on the nearest grid point: " + NCLlocnames(jj) + " (" + lon1 + ", " + lat1 + ")"
  wspd1= ndtooned( sqrt(u10(:,ny,mx)^2 + v10(:,ny,mx)^2) )
  wdir1= ndtooned( atan2(u10(:,ny,mx),v10(:,ny,mx))/0.01745329 +180. )

  numPetals =  16   
  circFr    = 10. 
  spdBounds1 = (/ 10., 20., 30., 40. /)
  spdBounds2 = (/ 5., 10., 15., 20. /)
  spdBounds3 = (/ 2.5, 5., 7.5, 10./)
  if (nclwndbnd .eq. 1)
    spdBounds = spdBounds1
  else if (nclwndbnd .eq. 2)
    spdBounds = spdBounds2
  else if (nclwndbnd .eq. 3)
    spdBounds = spdBounds3
  end if
  end if
  end if
 ; spdBounds = spdBounds2
  colorBounds       = (/ "blue", "green", "yellow", "red" /)

  res@gsnFrame      = False         ; do not advance the frame
  plot = WindRoseColor (wks,wspd1,wdir1,numPetals,circFr,spdBounds,colorBounds,res)


; Set up resources for the labelbar.
   
  lbres                    = True          ; labelbar only resources
  lbres@lbAutoManage       = False         ; Necessary to control sizes
  lbres@vpWidthF           = 0.05          ; labelbar width
  lbres@vpHeightF          = 0.15          ; labelbar height
  ;lbres@vpXF               = 0.78          ; labelbar position in x direction 
  lbres@vpXF               = 0.83          ; labelbar position in x direction 
  lbres@vpYF               = 0.58          ; labelbar position in y direction
  lbres@lbBoxMajorExtentF  = 0.80          ; puts space between color boxes
  lbres@lbFillColors       = colorBounds   ; labelbar colors        
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
  lbres@lbLabelFontHeightF = 0.016         ; font height. default is small
  lbres@lbPerimOn          = False
  lbres@lbTitleString      ="Wind Speed (m/s)" 
  lbres@lbTitleFontHeightF = 0.013

; Create labels

  nbar   = dimsizes(spdBounds)
  labels = new(nbar,string)
  labels(0) = 0 + "-" + spdBounds(0)
  do i=1,nbar-1
     labels(i) = spdBounds(i-1) + "-" +spdBounds(i)
  end do

  lbid = gsn_create_labelbar(wks,nbar,labels,lbres)
 
  draw(lbid)
  frame(wks)

end do
end
