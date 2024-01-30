load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

 namelist_adrs = getenv("wpspath")
 lables_onoff = getenv("wpslables")
 nclimgtype = getenv("imgfmt")
 nclfilename = getenv("outname")
 nclfontsize = getenv("fontsz")
 nclfontsize = tofloat(nclfontsize)
 lables_onoff = tointeger(lables_onoff)
 nclborderonoff = getenv("border_onoff")
  type = nclimgtype
  wks = gsn_open_wks(type,nclfilename)
  ;filename = "/home/ah/WRF3.9.1/WPS/namelist.wps"
  filename = namelist_adrs
  bordercolor = getenv("border_color")
   nclborder_thick = tofloat(getenv("borderthick"))
   if (nclborder_thick.le.1 .and. nclborder_thick.ge.0) then
    nclborder_thick = 1 + nclborder_thick*3
  else
    nclborder_thick = 2
  end if
  ocean_onoff = tointeger(getenv("oceanfill_onoff"))
  gridline_onoff = tointeger(getenv("gridline_onoff"))
  NCLtitle = tointeger(getenv("titile_option"))
  domcolor = getenv("domcolor")

 ;Second Line
;i=0
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
;i=0
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

; Set some map information ; line and text information
  mpres = True
  mpres@mpOutlineBoundarySets = "AllBoundaries"
  mpres@mpDataBaseVersion = "Ncarg4_1"
  mpres@mpDataSetName = "Earth..4"
  if (nclborderonoff.eq.0) then
    mpres@mpOutlineBoundarySets = "NoBoundaries"
  end if
  if (ocean_onoff.eq.1) then
    mpres@mpFillOn = True
    mpres@mpFillColors = (/"background","DeepSkyBlue",domcolor,"DeepSkyBlue", "transparent"/)
  else
    mpres@mpFillOn = True
    mpres@mpFillColors = (/"background",domcolor,domcolor,domcolor, "transparent"/)
  end if
  mpres@mpGeophysicalLineColor      = bordercolor
  if (gridline_onoff.eq.0) then
    mpres@mpGridAndLimbOn = False
  end if
  mpres@mpGridLineColor             = "white"
  mpres@mpNationalLineColor         = bordercolor
  mpres@mpPerimLineColor            = bordercolor
  mpres@mpUSStateLineColor          = bordercolor
  if (NCLtitle.eq.1) then
    mpres@tiMainString                = " WPS Domain Configuration  "
  end if
  mpres@mpGeophysicalLineThicknessF = nclborder_thick
  mpres@mpGridLineThicknessF        = 2.0
  mpres@mpLimbLineThicknessF        = 2.0
  mpres@mpNationalLineThicknessF    = nclborder_thick
  mpres@mpUSStateLineThicknessF     = nclborder_thick

  lnres = True 
  lnres@gsLineThicknessF = 8  ;domain line thickness
  lnres@domLineColors    = (/ "white", "Red" , "Red" , "Blue" /)
  if (str_lower(domcolor) .eq. "white") then
    lnres@domLineColors    = (/ "black", "black" , "black" , "black" /)
  end if

  txres = True
  txres@txFont = "helvetica-bold"
  txres@txJust = "TopLeft"
  txres@txPerimOn = False
  txres@txFontHeightF = 0.025
   txres@txFontColor = "White"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Do not change anything between the ";;;;;" lines

  mpres@max_dom   = stringtoint  (systemfunc("grep max_dom    " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  mpres@dx        = stringtofloat(systemfunc("grep dx         " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  mpres@dy        = stringtofloat(systemfunc("grep dy         " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  mpres@ref_lat   = stringtofloat(systemfunc("grep ref_lat    " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  mpres@ref_lon   = stringtofloat(systemfunc("grep ref_lon    " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  test = systemfunc("grep truelat1 " +filename ) 
  if ( .not. ismissing(test) )
    mpres@truelat1  = stringtofloat(systemfunc("grep truelat1   " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  else
    mpres@truelat1  = 0.0
  end if
  test = systemfunc("grep truelat2 " +filename ) 
  if ( .not. ismissing(test) )
    mpres@truelat2  = stringtofloat(systemfunc("grep truelat2   " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  else
    mpres@truelat2  = 0.0
  end if
  mpres@stand_lon = stringtofloat(systemfunc("grep stand_lon  " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )

  test = systemfunc("grep lambert " +filename ) 
  if ( .not. ismissing(test) )
    mpres@map_proj          = "lambert"
  end if
  test = systemfunc("grep mercator " +filename ) 
  if ( .not. ismissing(test) )
    mpres@map_proj          = "mercator"
  end if
  test = systemfunc("grep polar " +filename ) 
  if ( .not. ismissing(test) )
    mpres@map_proj          = "polar"
  end if
  testa = systemfunc("grep 'lat-lon' " +filename ) 
  if ( .not. ismissing(testa) )
    mpres@map_proj          = "lat-lon"
    mpres@pole_lat = stringtofloat(systemfunc("grep pole_lat  " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
    mpres@pole_lon = stringtofloat(systemfunc("grep pole_lon  " +filename+ " | cut -f2 -d'=' | cut -f1 -d','" ) )
  end if

  parent_id         = new ( mpres@max_dom , integer )
  parent_grid_ratio = new ( mpres@max_dom , integer )
  i_parent_start    = new ( mpres@max_dom , integer )
  j_parent_start    = new ( mpres@max_dom , integer )
  e_we              = new ( mpres@max_dom , integer )
  e_sn              = new ( mpres@max_dom , integer )

  do n = 1, mpres@max_dom 

    n0 = n - 1
    parent_id(n0)         = stringtoint(systemfunc("grep parent_id         " +filename+ " | cut -f2 -d'=' | cut -f"+n+" -d','" ) )
    parent_grid_ratio(n0) = stringtoint(systemfunc("grep parent_grid_ratio " +filename+ " | cut -f2 -d'=' | cut -f"+n+" -d','" ) )
    i_parent_start(n0)    = stringtoint(systemfunc("grep i_parent_start    " +filename+ " | cut -f2 -d'=' | cut -f"+n+" -d','" ) )
    j_parent_start(n0)    = stringtoint(systemfunc("grep j_parent_start    " +filename+ " | cut -f2 -d'=' | cut -f"+n+" -d','" ) )
    e_we(n0)              = stringtoint(systemfunc("grep e_we              " +filename+ " | cut -f2 -d'=' | cut -f"+n+" -d','" ) )
    e_sn(n0)              = stringtoint(systemfunc("grep e_sn              " +filename+ " | cut -f2 -d'=' | cut -f"+n+" -d','" ) )
 
  end do 

  mpres@parent_id         = parent_id
  mpres@parent_grid_ratio = parent_grid_ratio
  mpres@i_parent_start    = i_parent_start
  mpres@j_parent_start    = j_parent_start
  mpres@e_we              = e_we
  mpres@e_sn              = e_sn
  
  mp = wrf_wps_dom (wks,mpres,lnres,txres)

 if ( lables_onoff .eq. 1 )
  cities = NCLlocnames 
  lat = NCLloclats
  lon = NCLloclons
  pmres = True
  pmres@gsMarkerColor = "black"
  pmres@gsMarkerIndex = 16
  pmres@gsMarkerSizeF = 0.01
  gsn_polymarker(wks,mp,lon,lat,pmres)
  tres       =  True
  tres@txFontHeightF = nclfontsize
  tres@txFontColor = "White"
  if (str_lower(domcolor) .eq. "white") then
    tres@txFontColor = "black"
  end if
  
  gsn_text(wks,mp,cities,lon,lat-0.4,tres)
 end if

  frame(wks)           ; lets frame the plot - do not delete

end
