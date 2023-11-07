load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

domnum = tointeger(getenv("dom_number"))
nclimgtype = getenv("imgfmt")
nclfilename = getenv("outname")
bordercolor = getenv("border_color")
nclborder_thick = tofloat(getenv("borderthick"))
if (nclborder_thick.le.1 .and. nclborder_thick.ge.0) then
  nclborder_thick = 1 + nclborder_thick*3
else
  nclborder_thick = 2
end if
nclborderonoff = getenv("border_onoff")
ocean_onoff = tointeger(getenv("oceanfill_onoff"))
gridline_onoff = tointeger(getenv("gridline_onoff"))
NCLtitle = tointeger(getenv("titile_option"))
color = getenv("boxcolor")
wks = gsn_open_wks(nclimgtype, nclfilename)

  d1 = addfile(getenv("domfile1"), "r")
  var1 = wrf_user_getvar(d1,"HGT_M",0)
  lat1 = wrf_user_getvar(d1,"XLAT",0)
  lon1 = wrf_user_getvar(d1,"XLONG",0)
  var1@lat2d = lat1
  var1@lon2d = lon1
  dom_dims = dimsizes(var1)
  dom_rank = dimsizes(dom_dims)
  nx1 = dom_dims(dom_rank - 1) - 1
  ny1 = dom_dims(dom_rank - 2) - 1

  res                 = True
  res@cnFillOn        = True
  res@cnLinesOn       = False
  res@cnLineLabelsOn  = False
  res@cnInfoLabelOn   = False
  res@gsnSpreadColors = True
  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMaxLevelValF  =  3500
  res@cnMinLevelValF  =  50
  res@cnLevelSpacingF  = 250
  cmap = read_colormap_file("topo_15lev")
  res@cnFillColors = cmap
  res@gsnLeftString = ""
  res@gsnRightString = ""
  res@gsnDraw         = False
  res@gsnFrame        = False
res2 = res
  if (NCLtitle.eq.1) then
    res@tiMainString                = " WPS Domain Configuration  "
  end if
  res@mpOutlineBoundarySets = "AllBoundaries"
  if (nclborderonoff.eq.0) then
    res@mpOutlineBoundarySets = "NoBoundaries"
  end if
  res@mpGeophysicalLineThicknessF = nclborder_thick
  res@mpNationalLineThicknessF    = nclborder_thick
  res@mpUSStateLineThicknessF   = nclborder_thick
  res@mpGeophysicalLineColor      = bordercolor
  res@mpNationalLineColor         = bordercolor
  res@mpPerimLineColor            = bordercolor
  res@mpUSStateLineColor          = bordercolor
  res@mpDataBaseVersion     = "MediumRes"          ; Default is LowRes
  res@mpOutlineDrawOrder    = "PostDraw"           ; Draw map outlines last
  res@pmTickMarkDisplayMode = "Always"             ; Turn on map tickmarks
  res = set_mp_wrf_map_resources(d1,res)
  res@mpLimitMode        = "Corners"               ; Portion of map to zoom
  res@mpLeftCornerLatF   = lat1(0,0)
  res@mpLeftCornerLonF   = lon1(0,0)
  res@mpRightCornerLatF  = lat1(ny1,nx1)
  res@mpRightCornerLonF  = lon1(ny1,nx1)
  res@lbTitleString    = "Terrain Height (m)"
  res@lbTitleFontHeightF= .02
  res@lbTitleOffsetF = -0.2
  res@lbLabelAutoStride = True
  res@gsnMaximize     = True
  res@mpGridAndLimbOn = True
  if (gridline_onoff.eq.0) then
    res@mpGridAndLimbOn = False
  end if
  res@mpGridLatSpacingF = 5
  res@mpGridLonSpacingF = 5
  res@pmLabelBarHeightF     = 0.08
  res2@lbLabelBarOn = False
  res2@gsnMaximize  = False
  map = gsn_csm_contour_map(wks, var1, res)
  delete(res)

if (domnum .gt. 1) then
  kk = 0
  do while(kk .lt. (domnum-1))
    plot = new(domnum, graphic)
    mm = kk + 2 ;for the name of file
    dd = addfile(getenv("domfile"+mm), "r")
    var := wrf_user_getvar(dd,"HGT_M",0)
    lat := wrf_user_getvar(dd,"XLAT",0)
    lon := wrf_user_getvar(dd,"XLONG",0)
    var@lat2d = lat
    var@lon2d = lon
    dom_dims = dimsizes(var)
    dom_rank = dimsizes(dom_dims)
    nx = dom_dims(dom_rank - 1) - 1
    ny = dom_dims(dom_rank - 2) - 1
    xbox_out = new(5,float)
    ybox_out = new(5,float)
    xbox = (/lon(0,0),lon(0,nx),lon(ny,nx),lon(ny,0),lon(0,0)/)
    ybox = (/lat(0,0),lat(0,nx),lat(ny,nx),lat(ny,0),lat(0,0)/)
    lnres = True
    lnres@gsLineColor = color
    lnres@gsLineThicknessF  = 5
    plot(kk) = gsn_csm_contour(wks, var, res2)
    overlay (map, plot(kk))
     kk = kk + 1
  end do
  draw(map)

    kk = 0
  do while(kk .lt. (domnum-1))
    mm = kk + 2 ;for the name of file
    dd = addfile(getenv("domfile"+mm), "r")
    var := wrf_user_getvar(dd,"HGT_M",0)
    lat := wrf_user_getvar(dd,"XLAT",0)
    lon := wrf_user_getvar(dd,"XLONG",0)
    var@lat2d = lat
    var@lon2d = lon
    dom_dims = dimsizes(var)
    dom_rank = dimsizes(dom_dims)
    nx = dom_dims(dom_rank - 1) - 1
    ny = dom_dims(dom_rank - 2) - 1
    xbox_out = new(5,float)
    ybox_out = new(5,float)
    xbox = (/lon(0,0),lon(0,nx),lon(ny,nx),lon(ny,0),lon(0,0)/)
    ybox = (/lat(0,0),lat(0,nx),lat(ny,nx),lat(ny,0),lat(0,0)/)
    lnres = True
    lnres@gsLineColor = color
    lnres@gsLineThicknessF  = 5
    datatondc(map, xbox, ybox, xbox_out, ybox_out)
    gsn_polyline_ndc(wks, xbox_out, ybox_out, lnres)
    tres       =  True
    tres@txFontHeightF = 0.02
    tres@txFontColor = color
    ii = dimsizes(lat(:,0))-1
    gsn_text(wks,map,"D0"+mm,lon(0,5),lat(ii,0)+0.6,tres)
    kk = kk + 1
  end do
  
  else
    draw(map)
end if

  frame(wks)

end
