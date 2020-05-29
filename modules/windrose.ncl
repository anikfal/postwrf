;PostWRF Version 1.1 (Apr 2020)
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
  print("The two notes below can be ignored")
  uvm10 = wrf_user_getvar(f,"uvmet10",-1)
  u10 = uvm10(0,:,:,:)
  v10 = uvm10(1,:,:,:)
  nclwndbnd = stringtointeger(getenv("sh_wndbnd"))
  nclimgtype = getenv("imgfmt")
  nclfilename = getenv("outname")
  sh_lats=stringtofloat(getenv("roselat"))
  sh_lons=stringtofloat(getenv("roselon"))
  NCLspinup = tointeger(getenv("spinup"))
  NCLaverage_onoff = tointeger(getenv("average_onoff"))
  NCLaverage_time = tointeger(getenv("averagetime"))
  NCLtitle = tointeger(getenv("titile_option"))
  panel_onoff = tointeger(getenv("panelplot"))
  NCLpanelrows = tointeger(getenv("panelrows"))
  NCLpanelcolumns = tointeger(getenv("panelcolumns"))
  stat = getenv("rosevar")
  all_steps=f->XTIME
  hourstep = (all_steps(1) - all_steps(0))/60
  if (NCLspinup.ge.hourstep) then
    start_timestep = tointeger(NCLspinup/hourstep)
    else
    start_timestep = 0
  end if
  totstepsminus = dimsizes(times)-1
  loc = wrf_user_ll_to_ij(f, sh_lons, sh_lats, True)
  cr = inttochar(10)
  wks = gsn_open_wks(nclimgtype,nclfilename)
  mx = loc(0) - 1
  ny = loc(1) - 1
  lat1  = f->XLAT(0,ny,mx)
  lon1  = f->XLONG(0,ny,mx)
  res               = True
  res@tiMainOffsetYF = 0.04
  res@tiMainPosition = "Center"
  res@gsnFrame      = False         ; do not advance the frame
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
  colorBounds       = (/ "blue", "green", "yellow", "red" /)
  lbres                    = True          ; labelbar only resources
  lbres@lbAutoManage       = False         ; Necessary to control sizes
  lbres@vpWidthF           = 0.05          ; labelbar width
  lbres@vpHeightF          = 0.15          ; labelbar height
  lbres@vpXF               = 0.83          ; labelbar position in x direction 
  lbres@vpYF               = 0.58          ; labelbar position in y direction
  lbres@lbBoxMajorExtentF  = 0.80          ; puts space between color boxes
  lbres@lbFillColors       = colorBounds   ; labelbar colors        
  lbres@lbMonoFillPattern  = True          ; Solid fill pattern
  lbres@lbLabelFontHeightF = 0.016         ; font height. default is small
  lbres@lbPerimOn          = False
  lbres@lbTitleString      ="Wind Speed (m/s)" 
  lbres@lbTitleFontHeightF = 0.013

if (NCLaverage_onoff.ne.1) then ;code average122
  if (NCLtitle .eq. 1) then
      tstart := str_split(times(start_timestep), ":")
      tend := str_split(times(dimtime-1), ":")
      res@tiMainString  = "WindRose from " + tstart + " to " + tend + "~C~" \
  + "~Z75~          Location on the nearest grid point: " + stat + " (" + lon1 + ", " + lat1 + ")"
  end if
  wspd1= ndtooned( sqrt(u10(start_timestep:,ny,mx)^2 + v10(start_timestep:,ny,mx)^2) )
  wdir1= ndtooned( atan2(u10(start_timestep:,ny,mx),v10(start_timestep:,ny,mx))/0.01745329 +180. )
  plot = WindRoseColor (wks,wspd1,wdir1,numPetals,circFr,spdBounds,colorBounds,res)
  nbar   = dimsizes(spdBounds)
  labels = new(nbar,string)
  labels(0) = 0 + "-" + spdBounds(0)
  do i=1,nbar-1
     labels(i) = spdBounds(i-1) + "-" +spdBounds(i)
  end do
  lbid = gsn_create_labelbar(wks,nbar,labels,lbres)
  draw(lbid)
  frame(wks)

  else ;code average122
  if (panel_onoff.ne.1 .or. (NCLpanelrows.eq.1 .and. NCLpanelcolumns.eq.1)) then
    paneloption = False
    else ;;Panelplot
    paneloption = True
    arrayplots = new (totstepsminus+1, graphic)
    pnlres                            = True
    pnlres@gsnPanelFigureStrings = (/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","AB","AC","AD","AE","AF","AG","AH"/)
    pnlres@gsnPanelFigureStringsJust = "topleft"
    pnlres@gsnPanelYWhiteSpacePercent = 5      
    pnlres@gsnPanelLabelBar           = False    ; Turn on common labelbar
    pnlres@lbLabelAutoStride          = True    ; Spacing of lbar labels.
    pnlres@lbBoxMinorExtentF          = 0.13
  end if

  ncltstep = tointeger(NCLaverage_time/hourstep)
  totstepsminus = totstepsminus - start_timestep
  ntimes = totstepsminus - mod(totstepsminus, ncltstep) - ncltstep
  kk = 0
  do it = start_timestep,ntimes-1,ncltstep
      tstart := str_split(times(it), ":")
      tend := str_split(times(it+ncltstep), ":")
      print("WindRose from " + tstart(0) + " to " + tend(0))
      if (NCLtitle .eq. 1) then
        res@tiMainString  = "WindRose from " + tstart(0) + " to " + tend(0) + "~C~" \
        + "~Z75~          Location on the nearest grid point: " + stat + " (" + lon1 + ", " + lat1 + ")"
      end if
      wspd1 := ndtooned( sqrt(u10(it:(it+ncltstep),ny,mx)^2 + v10(it:(it+ncltstep),ny,mx)^2) )
      wdir1 := ndtooned( atan2(u10(it:(it+ncltstep),ny,mx),v10(it:(it+ncltstep),ny,mx))/0.01745329 +180. )
    if (.not.paneloption) then
      plot := WindRoseColor (wks,wspd1,wdir1,numPetals,circFr,spdBounds,colorBounds,res)
      nbar   = dimsizes(spdBounds)
      labels = new(nbar,string)
      labels(0) = 0 + "-" + spdBounds(0)
      do i=1,nbar-1
        labels(i) = spdBounds(i-1) + "-" +spdBounds(i)
      end do
      lbid = gsn_create_labelbar(wks,nbar,labels,lbres)
      draw(lbid)
      frame(wks)
    else ;panel plot
      res@gsnDraw = False
      res@gsnFrame = False
      arrayplots(kk) = WindRoseColor (wks,wspd1,wdir1,numPetals,circFr,spdBounds,colorBounds,res)
    end if
    kk = kk + 1
  end do
  
    if (paneloption) then
    rowcol = NCLpanelrows*NCLpanelcolumns - 1
    tot_elements_minus = (ntimes - start_timestep)/ncltstep
    if (NCLtitle .eq. 1) then
      pnlres@gsnPanelMainString      = stat  + " (" + lat1 + ", " + lon1 + ") " + "SkewT diagrams"
    end if
    i = 0
    do i = 0, tot_elements_minus
      if ((i+rowcol+1).gt.tot_elements_minus) then
        rowcol = mod(tot_elements_minus, (rowcol+1))
      end if
      gsn_panel(wks,(/arrayplots(i:(i+rowcol))/),(/NCLpanelrows,NCLpanelcolumns/),pnlres)
      i = i + rowcol
    end do
  end if

end if ;code average122

end
