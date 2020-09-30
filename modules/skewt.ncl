;PostWRF Version 1.1 (Apr 2020)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

load "read_wrfouts.ncl"

wks = gsn_open_wks(getenv("imgfmt"),getenv("outname"))
gsn_define_colormap(wks,"WhViBlGrYeOrReWh")
stat = getenv("skewvar")
lats=stringtofloat(getenv("skewlat"))
lons=stringtofloat(getenv("skewlon"))
NCLspinup = tointeger(getenv("spinup"))
all_steps = wrf_user_getvar(a,"XTIME",-1)
hourstep = (all_steps(1) - all_steps(0))/60
if (NCLspinup.ge.hourstep) then
 start_timestep = tointeger(NCLspinup/hourstep)
else
 start_timestep = 0
end if
 NCLaverage_onoff = tointeger(getenv("average_onoff"))
 NCLaverage_time = tointeger(getenv("averagetime"))
 NCLtitle = tointeger(getenv("titile_option"))
 panel_onoff = tointeger(getenv("panelplot"))
 NCLpanelrows = tointeger(getenv("panelrows"))
 NCLpanelcolumns = tointeger(getenv("panelcolumns"))
times  = wrf_user_getvar(a,"times",-1)
totstepsminus = dimsizes(times)-1
if (NCLaverage_onoff.ne.1) then
  ncltstep = tointeger(getenv("tstep"))
  ntimes = totstepsminus
  else
  ncltstep = tointeger(NCLaverage_time/hourstep)
  totstepsminus = totstepsminus - start_timestep
  ntimes = totstepsminus - mod(totstepsminus, ncltstep) - ncltstep
end if

mdims = getfilevardimsizes(a[0],"P")
nd = dimsizes(mdims)
dimX = mdims(nd-1)
dimY = mdims(nd-2)

locs = wrf_user_ll_to_ij(a, lons, lats, True)

if ( locs(0).lt.1 .or. locs(0).gt.dimX .or. locs(1).lt.1 .or. locs(1).gt.dimY )
  print(stat + " (" + lats + ", " + lons + ")" + " is outside of the model domain")
  print("Edit namelist.wrf and run again")
  print("")
  exit()
end if

  skewtOpts          = True
  skewtOpts@DrawHeightScale   = True    ; plot height scale on side
  skewtOpts@DrawHeightScaleFt = False   ; plot height scale in km
  skewtOpts@DrawStandardAtm   = True    ; draw standard atm on plot
  skewtOpts@vpXF              = 0.12    ; controls off-set from left
  skewtOpts@vpYF              = 0.87    ; controls off-set from top
  skewtOpts@vpWidthF          = 0.75    ; controls size of plot
  skewtOpts@vpHeightF         = 0.75    ; controls size of plot
  skewtOpts@DrawFahrenheit    = False   ; use deg C scale
  skewtOpts@tiMainFontHeightF = 0.025   ; change height of main title
  skewtOpts@DrawColAreaFill   = True    ; color on background plot
  skewtOpts@DrawColAreaColor  = 53      ; Light Green for WhViBlGrYeOrReWh color table
  skewtOpts@PrintOpts         = False   ; do not print options out
  dataOpts           = True
  dataOpts@Parcel    = 1
  dataOpts@WspdWdir  = False  ; wind speed and dir [else: u,v]
  dataOpts@HspdHdir  = True   ; wind speed and dir [else: u,v]
  dataOpts@PlotWindH = False  ; plot wind barbs at h lvls [pibal; special]

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
if (NCLaverage_onoff.ne.1) then ;code timeif122
  do it = start_timestep,ntimes-1,ncltstep        ; TIME LOOP
    print("Working on time: " + times(it) )
    tc  = wrf_user_getvar(a,"tc",it)         ; T in C
    td  = wrf_user_getvar(a,"td",it)         ; dew point temperature
    p   = wrf_user_getvar(a, "pressure",it)  ; grid point pressure
    z   = wrf_user_getvar(a, "z",it)         ; grid point height
    uvm = wrf_user_getvar(a,"uvmet",it)      ; umet and vmet averaged to mass points
    u   = uvm(0,:,:,:);*1.94386 
    v   = uvm(1,:,:,:);*1.94386
    if (NCLtitle .eq. 1) then
      runtime = str_split(times(it), ":")
      skewtOpts@tiMainString := stat  + " (" + lats + ", " + lons + ") | " + runtime(0)
    end if
    
    if (.not.paneloption) then
      skewt_bkgd             := skewT_BackGround (wks, skewtOpts)
      draw (skewt_bkgd)
      skewT_data := skewT_PlotData(wks, skewt_bkgd, p(:,locs(1),locs(0)), tc(:,locs(1),locs(0)), \
                                                  td(:,locs(1),locs(0)), z(:,locs(1),locs(0)), \
                                                  u(:,locs(1),locs(0)), v(:,locs(1),locs(0)), dataOpts)
      frame(wks)
      else
      skewtOpts@DrawWind        = False   ; not possible with panel
      skewtOpts@Panel           = True    ; Default is False
      skewt_bkgd               := skewT_BackGround (wks, skewtOpts)
      arrayplots(kk) = skewT_PlotData(wks, skewt_bkgd, p(:,locs(1),locs(0)), tc(:,locs(1),locs(0)), \
                                                    td(:,locs(1),locs(0)), z(:,locs(1),locs(0)), \
                                                    u(:,locs(1),locs(0)), v(:,locs(1),locs(0)), dataOpts)
    end if
    kk = kk + 1
  end do        ; END OF TIME LOOP

  if (paneloption) then
    rowcol = NCLpanelrows*NCLpanelcolumns - 1
    tot_elements_minus = (ntimes - start_timestep)/ncltstep
    if (NCLtitle .eq. 1) then
      pnlres@gsnPanelMainString      = stat  + " (" + lats + ", " + lons + ") " + "SkewT diagrams"
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

else ;code timeif122
    tc2  = wrf_user_getvar(a,"tc",-1)
    td2  = wrf_user_getvar(a,"td",-1)
    p2   = wrf_user_getvar(a, "pressure",-1)
    z2   = wrf_user_getvar(a, "z",-1)
    uvm2 = wrf_user_getvar(a,"uvmet",-1)
  do it = start_timestep,ntimes-1,ncltstep        ; TIME LOOP
    print("Working on time range (average): " + times(it) + " to " + times(it+ncltstep))
    tc  = dim_avg_n_Wrap(tc2(it:(it+ncltstep),:,:,:),0)
    td  = dim_avg_n_Wrap(td2(it:(it+ncltstep),:,:,:),0)
    p   = dim_avg_n_Wrap(p2(it:(it+ncltstep),:,:,:),0)
    z   = dim_avg_n_Wrap(z2(it:(it+ncltstep),:,:,:),0)
    uvm = dim_avg_n_Wrap(uvm2(:,it:(it+ncltstep),:,:,:),0)
    u   = uvm(0,:,:,:);*1.94386 
    v   = uvm(1,:,:,:);*1.94386
    if (NCLtitle .eq. 1) then
    tstart = str_split(times(it), ":")
    tend = str_split(times(it+ncltstep), ":")
    skewtOpts@tiMainString := stat  + " (" + lats + ", " + lons + ")~C~" + tstart(0) + " to " + tend(0) + "~C~ "
    end if
    if (.not.paneloption) then
      skewt_bkgd             := skewT_BackGround (wks, skewtOpts)
      draw (skewt_bkgd)
      skewT_data := skewT_PlotData(wks, skewt_bkgd, p(:,locs(1),locs(0)), tc(:,locs(1),locs(0)), \
                                                  td(:,locs(1),locs(0)), z(:,locs(1),locs(0)), \
                                                  u(:,locs(1),locs(0)), v(:,locs(1),locs(0)), dataOpts)
      frame(wks)
      else
      skewtOpts@DrawWind        = False   ; not possible with panel
      skewtOpts@Panel           = True    ; Default is False
      skewt_bkgd               := skewT_BackGround (wks, skewtOpts)
      arrayplots(kk) = skewT_PlotData(wks, skewt_bkgd, p(:,locs(1),locs(0)), tc(:,locs(1),locs(0)), \
                                                    td(:,locs(1),locs(0)), z(:,locs(1),locs(0)), \
                                                    u(:,locs(1),locs(0)), v(:,locs(1),locs(0)), dataOpts)
    end if
    kk = kk + 1
  end do        ; END OF TIME LOOP

  if (paneloption) then
    rowcol = NCLpanelrows*NCLpanelcolumns - 1
    tot_elements_minus = (ntimes - start_timestep)/ncltstep
    if (NCLtitle .eq. 1) then
      tstart = str_split(times(it), ":")
      tend = str_split(times(it+ncltstep), ":")
      pnlres@gsnPanelMainString      = stat  + " (" + lats + ", " + lons + ") " + "| SkewT diagrams"
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
end if ;code timeif122

end
