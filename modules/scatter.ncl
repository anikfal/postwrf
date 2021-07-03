begin

pairnum = tointeger(getenv("pairnumber"))
scatter_value = new(pairnum,"string")
scatter_observation = scatter_value
ii=0
do while(ii.lt.pairnum)
 scatter_value(ii) = getenv("scatter_valfile"+ii)
 scatter_observation(ii) = getenv("scatter_obsfile"+ii)
 ii=ii+1
end do
delete(ii)

jj=0
do while(jj.lt.pairnum)
  data_tot := asciiread(scatter_value(jj),-1,"string")
  data_main := data_tot(4:)
  varname := str_get_field(data_tot(1), 2, "(")
  varname := str_get_field(varname, 1, ")")
  unit := str_squeeze(str_get_field(data_tot(1), 3, ":"))
  totrecords := dimsizes(data_main)
  totcolumns_wrf := str_fields_count(data_main(0), " ") - 1 ;time column is subtracted
  data_tot_obv := asciiread(scatter_observation(jj),-1,"string")
  data_main_obv := data_tot_obv(4:)
  totcolumns_obv := str_fields_count(data_main_obv(0), " ") - 1 ;time column is subtracted
  if (totcolumns_wrf .ne. totcolumns_obv) then
    print("Number of data columns in simulation and observation files must be equal.")
    print("Correct the data files and run again.")
    exit()
  end if
  res                     = True                   ; plot mods desired
  res@gsnDraw             = False                   ; don't draw
  res@gsnFrame            = False
  res@gsnMaximize         = True                   ; maximize plot in frame
  res@xyMarkLineModes     = (/"Markers","Lines"/)  ; choose which have markers
  res@xyMarkers           = 16                     ; choose type of marker 
  res@xyMarkerColor       = "red"                  ; Marker color
  res@xyMarkerSizeF       = 0.005                  ; Marker size (default 0.01)
  res@xyDashPatterns      = 1                      ; solid line 
  res@xyLineThicknesses   = (/1,2/)                ; set second line to 2

  data := new ( (/2,dimsizes(str_get_field(data_main, 2, " "))/), "float")
  do ii = 0, totcolumns_wrf-1
    ts := tofloat(str_get_field(data_main, ii+2, " "))
    city_name := str_get_field(data_tot(3), ii+2, " ")
    city_shortname = str_get_field(city_name, 1, "_")
    data(0,:) = ts
    x := tofloat(str_get_field(data_main_obv, ii+2, " "))
    x@long_name = "Observation: " + varname + " (" + unit + ")"
    rc = regline(x,ts)
    r = escorc(x,ts)
    rmse_value = dim_rmsd(x,ts)
    data(1,:) = rc*x + rc@yintercept
    data@long_name = "Simulation: " + varname + " (" + unit + ")"
    myname = "scatterplot_"+varname
    wks = gsn_open_wks(getenv("imgfmt"),"scatterplot_"+varname+"_"+city_shortname)
    res@tiMainString = city_name ;str_get_field(data_tot(3), ii+2, " ")  ;varname + " (" + unit + ")"

    plot  = gsn_csm_xy (wks,x,data,res)        ; create plot

    txres               = True                      ; text mods desired
    txres@txFontHeightF = 0.025
    txres@txJust             = "CenterLeft"
    reg_equation = "Y = " + tostring(sprintf("%4.3f", rc)) + "X " + "+ " + tostring(sprintf("%5.2f", rc@yintercept))
    deltalength = (max(ts)-min(ts))/10
    yypoint = avg(ts)
    xxpoint = (max(x)+min(x))/2 ;avg(x)+avg(x)/20
    dum1 = gsn_add_text(wks, plot, reg_equation, xxpoint, yypoint, txres)
    r2 = "r~S~2~N~ = " + tostring(sprintf("%4.3f", r))
    dum2 = gsn_add_text(wks, plot, r2, xxpoint, yypoint-deltalength, txres)
    RMSE = "RMSE = " + tostring(sprintf("%4.3f", rmse_value))
    dum3 = gsn_add_text(wks, plot, RMSE, xxpoint, yypoint-deltalength*2, txres)

    draw(plot)
    frame(wks)
  end do
  jj=jj+1
end do

end