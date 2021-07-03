allvalcount = tointeger(getenv("value_files_count"))
prow = toint(getenv("panelrows"))
pcol = toint(getenv("panelcolumns"))
ii=0
ts_value = new(allvalcount, "string")
ts_observation = ts_value
ts_outputname = ts_value
do while(ii.lt.allvalcount)
 ts_value(ii) = getenv("ts_valfile"+ii)
 ts_observation(ii) = getenv("ts_obsfile"+ii)
 ts_outputname(ii) = getenv("ts_outputname"+ii)
 ii=ii+1
end do
plot = new(allvalcount, graphic)
wks = gsn_open_wks(getenv("imgfmt"),"timeseries_panel")
do kk = 0, allvalcount-1
    data_tot := asciiread(ts_value(kk), -1, "string")
    data_main := data_tot(4:)
    varname := str_get_field(data_tot(1), 2, "(")
    varname := str_get_field(varname, 1, ")")
    unit := str_squeeze(str_get_field(data_tot(1), 3, ":"))
    alltime := str_get_field(data_tot(4:), 1, " ")
    hour_min_sec_0 = str_get_field(alltime(0), 2, "_")
    hour_min_sec_1 = str_get_field(alltime(1), 2, "_")
    hour_interval = tointeger(hour_min_sec_1) - tointeger(hour_min_sec_0)
    mydate = str_get_field(alltime(0), 1, "_")
    day_init = tointeger(str_get_field(mydate, 3, "-"))
    totrecords = dimsizes(data_main)
    totcolumns_wrf = str_fields_count(data_main(0), " ") - 1 ;time column is subtracted
    if fileexists(ts_observation(kk)) then
        data_tot_obv := asciiread(ts_observation(kk), -1, "string")
        data_main_obv := data_tot_obv(4:)
        totcolumns_obv := str_fields_count(data_main_obv(0), " ") - 1 ;time column is subtracted
        totcolumns := totcolumns_wrf + totcolumns_obv
        data := new((/totcolumns,totrecords/),float)
        xaxis_title := new(totcolumns, string)
        data@long_name = varname + " (" + unit + ")"
        do ii = 0, totcolumns_wrf-1
        data(ii,:) = tofloat(str_get_field(data_main, ii+2, " "))
        xaxis_title(ii) = str_get_field(data_tot(3), ii+2, " ")
        xaxis_title(ii) = str_get_field(xaxis_title(ii), 1, "_")
        end do
        do ii = 0, totcolumns_obv-1
        jj = ii+totcolumns_wrf
        data(jj,:) = tofloat(str_get_field(data_main_obv, ii+2, " "))
        xaxis_title(jj) = str_get_field(data_tot_obv(3), ii+2, " ")
        xaxis_title(jj) = str_get_field(xaxis_title(ii), 1, "_") + "_observed"
        end do

        else

        totcolumns = totcolumns_wrf
        data := new((/totcolumns,totrecords/),float)
        xaxis_title := new(totcolumns, string)
        data@long_name = varname + " (" + unit + ")"
        do ii = 0, totcolumns_wrf-1
        data(ii,:) = tofloat(str_get_field(data_main, ii+2, " "))
        xaxis_title(ii) = str_get_field(data_tot(3), ii+2, " ")
        xaxis_title(ii) = str_get_field(xaxis_title(ii), 1, "_")
        end do

    end if

    mytime := toint( str_get_field(data_main, 1, " ") )
    mytime@long_name = "Hours from " + alltime(0)
    mytime(0)=0
    do ii = 1, totrecords-1
    jj = ii - 1
    day = toint( str_get_field( str_get_field(alltime(ii), 1, "_"), 3, "-") )
    hour = toint( str_get_cols( str_get_field(alltime(ii), 2, "_"), 0, 1) )
    mytime(ii) = mytime(jj) + hour_interval
    end do
    
    mycolor = read_colormap_file("circular_2") ;24 colors
    color_intv = abs(24/totcolumns)
    if (color_intv .eq. 0) then
        color_intv = 1
    end if
    
    res                   = True 
    res@xyLineThicknesses = (/  2.0, 2.0, 2.0, 2.0/)          ; make second line thicker
    res@xyLineColors      :=  mycolor(::color_intv,:) ;"BkBlAqGrYeOrReViWh200" ;(/"blue","red","green","black"/)
    res@xyDashPattern  = 0                         ; Make curves all solid
    res@gsnMaximize    = True
    res@gsnDraw        = False                   ; don't draw
    res@gsnFrame       = False
    if (tointeger(getenv("timeseries_line_onoff")) .and. tointeger(getenv("timeseries_marker_onoff"))) then
        res@xyMarkLineMode = "MarkLines"
        else if (tointeger(getenv("timeseries_line_onoff")) .and. (.not. tointeger(getenv("timeseries_marker_onoff"))) ) then 
            res@xyMarkLineMode = "Lines"
        else if ( (.not. tointeger(getenv("timeseries_line_onoff"))) .and. tointeger(getenv("timeseries_marker_onoff")) ) then
            res@xyMarkLineMode = "Markers"
        else
            res@xyMarkLineMode = "Markers" 
    end if
    end if
    end if
    res@xyMarkers      = (/6,11,16, 13/)
        yaxix_max = getenv("y_axis_max")
    if (.not. ismissing(yaxix_max)) then
        res@trYMaxF  =  tofloat(yaxix_max)
    end if
    yaxix_min = getenv("y_axis_min")
    if (.not. ismissing(yaxix_min)) then
        res@trYMinF  =  tofloat(yaxix_min)
    end if
    res@xyMarkerColors := mycolor(::color_intv,:) ;(/"blue","red","green","black"/)
    res@pmLegendDisplayMode    = "Always"
    res@pmLegendSide           = "Top"                 ; Change location of 
    res@pmLegendParallelPosF   = .80                   ; move units right
    res@pmLegendOrthogonalPosF = -1                  ; more neg = down
    res@pmLegendWidthF         = 0.12                  ; Change width and
    res@pmLegendHeightF        = 0.15                  ; height of legend.
    res@lgLabelFontHeightF     = .015                   ; change font height
    res@lgPerimOn              = False                 ; no box around
    res@xyExplicitLegendLabels := xaxis_title  ;(/"20N","30N","40N","50N"/)
    plot(kk) = gsn_csm_xy (wks, mytime, data, res)

end do

plotsinframe = prow*pcol
panelframes = ceil(tofloat(allvalcount)/plotsinframe)
pnlres                            = True
pnlres@gsnPanelFigureStrings = (/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","AB","AC","AD","AE","AF","AG","AH"/)
pnlres@gsnPanelFigureStringsJust = "topleft"
pnlres@gsnPanelYWhiteSpacePercent = 5       ; Add white space b/w 
pnlres@gsnPanelLabelBar           = False    ; Turn on common labelbar
pnlres@lbLabelAutoStride          = True    ; Spacing of lbar labels.
pnlres@lbBoxMinorExtentF          = 0.13
if (allvalcount .le. plotsinframe) then
  gsn_panel(wks,plot(:(allvalcount-1)),(/prow, pcol/), pnlres)
else
  do myframe = 0, panelframes-1
    startii = myframe*plotsinframe
    endii = startii+plotsinframe-1
    if (endii .gt. (allvalcount-1)) then
      endii = allvalcount-1
    end if
    gsn_panel(wks,plot(startii:endii),(/prow, pcol/), pnlres)
  end do
end if