load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

  input_file = addfile("new.nc","r")

   var = short2flt(input_file->blh)
   uu = short2flt(input_file->u10)
   vv = short2flt(input_file->v10)

  wks = gsn_open_wks("x11", "boundary_layer_may")

  time=input_file->time
 i = 0 ;Chenge to 0
   do while(i .le. dimsizes(time)-1)

  gsn_merge_colormaps(wks,"rainbow", "lightgray")

  myplot = new(2,graphic)

  time@units = "hours since 1900-01-01 00:00:0.0"
  utc_date = cd_calendar(time(i), 0)
  year   = tointeger(utc_date(:,0))    ; Convert to integer for
  month  = tointeger(utc_date(:,1))    ; use sprinti 
  day    = tointeger(utc_date(:,2))
  hour   = tointeger(utc_date(:,3))

  res                   = True
  res@gsnDraw           = False  ; do not draw plot yet (need False for paneling)
  res@gsnFrame          = False  ; do not frame plot yet (need False for paneling)
  res@gsnMaximize       = True   ; make plots as big as possible
  res@gsnSpreadColors   = True   ; use all of the colormap
  res@gsnSpreadColorEnd = 189    ; but only up color #189 (right before gray)
  res@cnFillOn          = True   ; fill contours
  res@cnLinesOn         = False
  res@gsnLeftString     = var@long_name
  res@tiMainString      = year + "-" + sprinti("%0.2i",month) + "-" + sprinti("%0.2i",day) + "_" + sprinti("%0.2i",hour)
  res@tiMainFontHeightF = 0.018
  res@tiMainFontThicknessF = 0.2
  res@cnLevelSpacingF   = 40     ; change the contour spacing to be 60 m
  res@lbLabelStride     = 2      ; only print value for every other contour in label bar
  res@cnLineLabelDensityF = 1.5
  res@mpOceanFillColor = "deepskyblue"
  res@mpLandFillColor = (/1,1,1/) ; for lesser versions of ncl 6.4 set to (0,0,0)
  res@mpInlandWaterFillColor = "deepskyblue"
  res@gsnLeftStringFontHeightF = 0.017
  res@gsnRightStringFontHeightF = 0.017
  res@cnLineThicknessF = 5
  res@cnLineLabelPlacementMode = "Constant"
  res@cnLineDashSegLenF = 0.2
  res@cnLineLabelInterval = 1
  res@mpShapeMode  = "FreeAspect"
  res@vpWidthF      = 0.5
  res@vpHeightF     = 0.5
  res@cnLineLabelBackgroundColor = "Transparent"
  res@cnLineLabelFontHeightF = 0.019
  res@mpMinLatF         = 20
  res@mpMaxLatF         = 45
  res@mpMinLonF         = 31
  res@mpMaxLonF         = 62
  res@gsnAddCyclic = False
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF = 100
  res@cnMaxLevelValF = 3100
  res@cnLevelSpacingF = 100
  res@mpOutlineBoundarySets = "AllBoundaries"
  res@mpGeophysicalLineThicknessF = 3
  res@mpNationalLineThicknessF = 2
  ;res@mpNationalLineColor = "white"
  res@mpGeophysicalLineColor = "white"
  


; Create the vector plot we want to go on top of the geopotential base plot:
  resuv                   = True
  resuv@gsnDraw           = False  ; do not draw plot yet (need False for paneling)
  resuv@gsnFrame          = False  ; do not frame plot yet (need False for paneling)
  resuv@gsnMaximize       = True   ; make plots as big as possible
  resuv@vcRefMagnitudeF   = 5    ; vector reference set to 10 m/s
  resuv@vcRefAnnoString1 = "5 m/s"
  resuv@vcRefLengthF      = 0.01   ; setting for nicely sized vectors
  resuv@vcMinDistanceF    = 0.024  ; vector density
  resuv@gsnLeftString     = ""     ; turn off left string
  resuv@gsnRightString    = ""     ; turn off right string
  resuv@vcRefAnnoOrthogonalPosF = -0.45         ; Moves reference vector box inside the plot
  resuv@vcRefAnnoOn       = True  ; turn off vector annotation

  plot_base = gsn_csm_contour_map(wks,var(i,:,:),res)

  plot_wind = gsn_csm_vector(wks, uu(i,:,:), vv(i,:,:), resuv)

  overlay(plot_base, plot_wind)

  shpres = True
  ;shpres@gsLineColor = "white"
  shpres@gsLineThicknessF = 2
  shapefile_path = "/home/ah/postwrf/modules/iran_provinces/khuzestan.shp"
  myprov = gsn_add_shapefile_polylines(wks, plot_base, shapefile_path, shpres)
  city_lat = 31.318
  city_lon = 48.671
  city_name = "Ahvaz"
  pmres = True
  ;pmres@gsMarkerColor = "white"
  pmres@gsMarkerIndex = 16
  dum1 = gsn_add_polymarker(wks, plot_base, city_lon, city_lat, pmres)
  tres       =  True
  tres@txFontHeightF = 15
  ;tres@txFontColor = "white"
  dum2 = gsn_add_text(wks,plot_base,city_name,city_lon,city_lat+1,tres)
  draw(plot_base)
  frame(wks)

  print("time: " + res@tiMainString)

 i=i+1
   end do

end
