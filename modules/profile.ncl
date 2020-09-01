;PostWRF Version 1.1 (Apr 2020)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
begin
  NCLaverage_onoff = tointeger(getenv("average_onoff"))
  NCLaverage_time = tointeger(getenv("averagetime"))
  NCLtitle = tointeger(getenv("titile_option"))
  panel_onoff = tointeger(getenv("panelplot"))
  NCLpanelrows = tointeger(getenv("panelrows"))
  NCLpanelcolumns = tointeger(getenv("panelcolumns"))
  NCLspinup = tointeger(getenv("spinup"))
  myfile = getenv("wrfout")
  if (ismissing(str_match(myfile,"/"))) then
    dir = systemfunc("pwd")
    f = addfile(dir + "/" + myfile,"r")
  else
    f = addfile(myfile,"r")
  end if
  all_steps=f->XTIME
  hourstep = (all_steps(1) - all_steps(0))/60
  if (NCLspinup.ge.hourstep) then
  start_timestep = tointeger(NCLspinup/hourstep)
  else
  start_timestep = 0
  end if
  ;;------------------------------------------------------------------
  times  = wrf_user_getvar(f,"times",-1)
  totstepsminus = dimsizes(times)-1
  if (NCLaverage_onoff.ne.1) then
    ncltstep = tointeger(getenv("tstep"))
    ntimes = totstepsminus
    else
    ncltstep = tointeger(NCLaverage_time/hourstep)
    totstepsminus = totstepsminus - start_timestep
    ntimes = totstepsminus - mod(totstepsminus, ncltstep) - ncltstep
  end if
  ;;------------------------------------------------------------------
  myvar = getenv("nclwrfvar0")
  ;;------------------------------------------------------------------
  linesmain = tointeger(getenv("ncllocs"))
  locnames = new(linesmain,"string")
  i=0
  do while(i.le.(linesmain-1))
  locnames(i) = getenv("ncllocnames"+i)
  i=i+1
  end do
  totlocs=dimsizes(locnames)
  ;;------------------------------------------------------------------
  lines = tointeger(getenv("ncllats"))
  lats = new(lines,"float")
  i=0
  do while(i.le.(lines-1))
  lats(i) = stringtofloat(getenv("nclloclats"+i))
  i=i+1
  end do
 delete(lines)
  ;;------------------------------------------------------------------
  lines = tointeger(getenv("ncllons"))
  lons = new(lines,"float")
  i=0
  do while(i.le.(lines-1))
  lons(i) = stringtofloat(getenv("nclloclons"+i))
  i=i+1
  end do
  delete(lines)
  delete(i)

  yy  = asciiread(".AllWRFVariables", -1, "string")

varplus = str_match(myvar,"+")
varminus = str_match(myvar,"-")
varmult = str_match(myvar,"*")
vardiv = str_match(myvar,"/")
varexp = str_match(myvar,"^")
varopenp = str_match(myvar,"(")
varclosep = str_match(myvar,")")
if( ismissing(varplus) .and. ismissing(varminus) .and. ismissing(varmult) .and. ismissing(vardiv)\
 .and. ismissing(varexp) .and. ismissing(varopenp) .and. ismissing(varclosep) ) then  ;sssif

if ( any(yy.eq.myvar) ) then ;abcdif
  if (myvar .eq. "cape_surface") then
     profilevar2  = wrf_user_getvar(f,"cape_2d",-1)
     profilevar2@_FillValue=-1
     profilevar2@description = "CAPE"
     profilevar2@units = "J/kg"
     profilevar = profilevar2(0,:,:,:)

 else if (myvar .eq. "cin_surface") then
     profilevar2  = wrf_user_getvar(f,"cape_2d",-1)
     profilevar2@_FillValue=-1
     profilevar2@description = "CIN"
     profilevar2@units = "J/kg"
     profilevar = profilevar2(1,:,:,:)

 else if (myvar .eq. "cin_3d") then
     profilevar2  = wrf_user_getvar(f,"cape_3d",-1)
     profilevar2@_FillValue=-1
     profilevar2@description = "CIN"
     profilevar2@units = "J/kg"
     profilevar = profilevar2(1,:,:,:,:)

 else if (myvar .eq. "cape_3d") then
     profilevar2  = wrf_user_getvar(f,"cape_3d",-1)
     profilevar2@_FillValue=-1
     profilevar2@description = "CIN"
     profilevar2@units = "J/kg"
     profilevar = profilevar2(0,:,:,:,:)

 else if (myvar .eq. "lcl") then
     profilevar2  = wrf_user_getvar(f,"cape_2d",-1)
     profilevar2@description = "Lifting Condensation Level"
     profilevar2@units = "m"
     profilevar = profilevar2(2,:,:,:)

 else if (myvar .eq. "lfc") then
     profilevar2  = wrf_user_getvar(f,"cape_2d",-1)
     profilevar2@description = "Level of Free Convection"
     profilevar2@units = "m"
     profilevar = profilevar2(2,:,:,:)

 else if (myvar .eq. "dust_total") then
     profilevar  = f->DUST_1+f->DUST_2+f->DUST_3+f->DUST_4+f->DUST_5
     profilevar@description = "Total dust concentration"
     profilevar@units = "Micro_gram/kg_dry_air"
     copy_VarCoords(f->DUST_4,profilevar)

 else if (myvar .eq. "dust_pm2.5") then
     profilevar  = f->DUST_1+0.3125*f->DUST_2
     profilevar@description = "Dust equal to PM2.5 concentration"
     profilevar@units = "Micro_gram/kg_dry_air"
     copy_VarCoords(f->DUST_4,profilevar)

 else if (myvar .eq. "dust_pm10") then
     profilevar  = f->DUST_1+f->DUST_2+f->DUST_3+0.87*f->DUST_4
     profilevar@description = "Dust equal to PM10 concentration"
     profilevar@units = "Micro_gram/kg_dry_air"
     copy_VarCoords(f->DUST_4,profilevar)

else if (myvar .eq. "wind_s") then
     uu10  = wrf_user_getvar(f,"U10",-1)
     vv10  = wrf_user_getvar(f,"V10",-1)
     profilevar = wind_speed(uu10,vv10)
     profilevar@description = "10m wind speed"
     profilevar@units = "m s-1"

 else if (myvar .eq. "wind_d") then
  if (.not.isdefined("uu10")) then
     uu10  = wrf_user_getvar(f,"U10",-1)
     vv10  = wrf_user_getvar(f,"V10",-1)
  end if
     profilevar = wind_direction(uu10,vv10,0)
     profilevar@description = "10m wind direction"
     profilevar@units = "Degrees from north"
  else

  profilevar = wrf_user_getvar(f, myvar,-1)

end if
end if
end if
end if
end if
end if
end if
end if
end if
end if
end if

  zz = wrf_user_getvar(f, "z",-1)
  times = wrf_user_getvar(f,"times",-1)
  pp  = wrf_user_getvar(f, "pressure",-1)
  locs = wrf_user_ll_to_ij(f,lons,lats,True)
  loccount = dimsizes(locnames)
  res                   = True
  res@trYReverse        = True                       ; reverse Y-axis
  res@gsnFrame          = False                      ; don't advance frame yet
  if (loccount .le. 6) then
    res@xyLineColors = read_colormap_file("cyclic")
    elseif ((loccount .gt. 6) .and. (loccount .le. 12)) then
    res@xyLineColors = read_colormap_file("circular_1")
    else
    res@xyLineColors = read_colormap_file("so4_21")
  end if
  res@xyLineThicknessF = 4
  res@xyDashPattern = "SolidLine"
  res@tmXBMode = "Manual"
  res@pmLegendDisplayMode    = "Always"              ; turn on legend
  res@pmLegendSide           = "Top"                 ; Change location of 
  res@pmLegendParallelPosF   = .90                   ; move units right
  res@pmLegendOrthogonalPosF = -0.8                  ; more neg = down
  res@pmLegendWidthF         = 0.12                  ; Change width and
  res@pmLegendHeightF        = 0.25                  ; height of legend.
  res@lgLabelFontHeightF     = .02                   ; change font height
  res@lgPerimOn              = False                 ; no box around
  res@xyExplicitLegendLabels = locnames
  plane = new((/loccount,4/), typeof(locs))
  data_plane = new((/loccount, 100, 2/), "float")
  pressure_plane = data_plane
  minval = getenv("Min")
  maxval = getenv("Max")
  if ((minval .eq. "NULL") .or. (maxval .eq. "NULL")) then
    allvalue = wrf_user_vert_cross(profilevar,pp,(/locs(0,0),locs(1,0),locs(0,0)+1,locs(1,0)+1/),True)
  end if
  if ((minval .ne. "NULL")) then
    startval = stringtofloat(minval)
    else
    startval = min(allvalue)
  end if
  if ((maxval .ne. "NULL")) then
    endval = stringtofloat(maxval)
    else
    endval = max(allvalue)
  end if
  res@trXMaxF = endval
  res@trXMinF = startval
  res@tmXBTickStartF = startval
  res@tmXBTickEndF = endval
  res@tmXBTickSpacingF=  (endval-startval)/7
  res@tmXBPrecision = tointeger(getenv("verticaldecimal"))
  wks = gsn_open_wks(getenv("imgfmt"),getenv("outname"))

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
  kk = 0
  if (NCLaverage_onoff .ne. 1) then ;code average467
    do it = start_timestep, ntimes,ncltstep
      if (NCLtitle .eq. 1) then
        res@tiMainString      = times(it)
      end if
      print("time: " + times(it))
      do mm=0, dimsizes(locnames)-1
        plane(mm,:) = (/locs(0,mm),locs(1,mm),locs(0,mm)+1,locs(1,mm)+1/)
        data_plane(mm,:,:) = wrf_user_vert_cross(profilevar(it,:,:,:),pp(it,:,:,:),plane(mm,:),True)
        pressure_plane(mm,:,:) = wrf_user_vert_cross(pp(it,:,:,:),pp(it,:,:,:),plane(mm,:),True)
        pressure_plane@description="Pressure (hpa)"
        data_plane@description = profilevar@description + " (" + profilevar@units + ")"
      end do
      if (.not.paneloption) then
        plot  = gsn_csm_xy (wks,data_plane(:,:,0),pressure_plane(:,:,0),res)
        frame(wks)
        else
        res@gsnDraw = False
        res@gsnFrame = False
        arrayplots(kk) = gsn_csm_xy (wks,data_plane(:,:,0),pressure_plane(:,:,0),res)
      end if
      kk = kk + 1
    end do
    if (paneloption) then
      rowcol = NCLpanelrows*NCLpanelcolumns - 1
      tot_elements_minus = (ntimes - start_timestep)/ncltstep
      if (NCLtitle .eq. 1) then
        pnlres@gsnPanelMainString      = "Vertical profiles of " + data_plane@description
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

  else ;code average467

    do it = start_timestep, ntimes-1,ncltstep
      if (NCLtitle .eq. 1) then
        tstart = str_split(times(it), ":")
        tend = str_split(times(it+ncltstep), ":")
        res@tiMainString      = "Average: " + tstart + " to " + tend
      end if
      print("Average from " + times(it) + " to " + times(it+ncltstep))
      do mm=0, dimsizes(locnames)-1
        plane(mm,:) = (/locs(0,mm),locs(1,mm),locs(0,mm)+1,locs(1,mm)+1/)
        data_plane(mm,:,:) = dim_avg_n_Wrap(wrf_user_vert_cross(profilevar(it:(it+ncltstep),:,:,:),pp(it:(it+ncltstep),:,:,:),plane(mm,:),True),0)
        pressure_plane(mm,:,:) = dim_avg_n_Wrap(wrf_user_vert_cross(pp(it:(it+ncltstep),:,:,:),pp(it:(it+ncltstep),:,:,:),plane(mm,:),True),0)
        pressure_plane@description="Pressure (hpa)"
        data_plane@description = profilevar@description + " (" + profilevar@units + ")"
      end do
      if (.not.paneloption) then
        plot  = gsn_csm_xy (wks,data_plane(:,:,0),pressure_plane(:,:,0),res)
        frame(wks)
        else
        res@gsnDraw = False
        res@gsnFrame = False
        arrayplots(kk) = gsn_csm_xy (wks,data_plane(:,:,0),pressure_plane(:,:,0),res)
      end if
      kk = kk + 1
    end do
    if (paneloption) then
      rowcol = NCLpanelrows*NCLpanelcolumns - 1
      tot_elements_minus = (ntimes - start_timestep)/ncltstep
      if (NCLtitle .eq. 1) then
        pnlres@gsnPanelMainString      = "Average vertical profiles of " + data_plane@description
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

  end if ;code average467
else ;abcdif

print("PostWRF Warning: " + "<" + myvar + ">" + " is not among the output variables of " + myfile)

end if ;abcdif

else ;sssif

 homedir = getenv("postwrf_dir")
 asciiwrite (homedir+"/modules/totalequation.txt" , myvar)
 system("cd $postwrf_dir/modules && ./separation.sh") ;;variable.txt
 system("cd $postwrf_dir/modules && ./extract_equation.sh") ;;sed
 system("ln -sf $postwrf_dir/modules/profile_equation.ncl .")
 system("ln -sf $postwrf_dir/modules/variables.txt .")
 system("ln -sf $postwrf_dir/modules/totalequation.txt .")
 system("ncl -Q profile_equation.ncl")

end if ;sssif

end
