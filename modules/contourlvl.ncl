;PostWRF Version 1.0 (May 2018)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"

undef ( "get_percentiles" )
function get_percentiles( \
  i_data           : numeric, \
  i_percentiles : numeric  \
)
local None
begin
  retVal = new( dimsizes(i_percentiles), float )
  data1d = ndtooned( i_data )
  notMissing = data1d( ind(.not.ismissing(data1d) ) )
  qsort(notMissing)
  do p = 0, dimsizes(i_percentiles)-1
    pInd = round( i_percentiles(p) * dimsizes(notMissing), 3 ) -1
    retVal(p) = notMissing(pInd)
  end do
 return(retVal)
end

begin

 myfile = getenv("wrfout")
 var = str_match(myfile,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if

;5th Line
;i=0
lines2 = getenv("nclcontournum")
lines = tointeger(lines2)
NCLcontours = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLcontours(i) = getenv("nclcontourvars"+i)
 i=i+1
end do
delete(lines2)
delete(lines)


;6th Line
lines2 = getenv("nclcnlevelnum")
lines = tointeger(lines2)
NCLcnlevs2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLcnlevs2(i) = getenv("contourlevs"+i)
 i=i+1
end do
NCLcnlevs = tointeger(NCLcnlevs2)
delete(lines2)
delete(lines)
delete(i)

ncl_shape_onoff = getenv("shape_onoff")
  ncl_shape_path = getenv("shape_path")
totcnvars = dimsizes(NCLcontours)

yy  = asciiread(".AllWRFVariables", -1, "string")

ii=0
do while(ii.le.(totcnvars-1))

if ( any(yy.eq.NCLcontours(ii)) ) then  ;code att2

  cnmode = getenv("contvar")
  cnmin = getenv("Min")
  cnmax = getenv("Max")
  cnintv = getenv("Intv")
  filename = getenv("outname")
  type = getenv("imgfmt")
   if (type .eq. "animated_gif") then
    type = "png"
   end if
  cnvar = getenv("contourselect")
  contourcolorpal = getenv("colpal")
  ncltstep2 = getenv("tstep")
  ncltstep = tointeger(ncltstep2)

; We generate plots, but what kind do we prefer?
  wks = gsn_open_wks(type,filename)


; Set some Basic Plot options
  res = True
  res@MainTitle                   = "REAL-TIME WRF"
  res@Footer = False

  pltres = True
  mpres = True
  mpres@mpOutlineBoundarySets = "National"
  mpres@mpGeophysicalLineColor      = "(/0.90, 0.90, 0.9/)"
  mpres@mpNationalLineColor         = "(/0.8, 0.8, 0.8/)"
  mpres@mpUSStateLineColor          = "Black"
  mpres@mpGridLineColor             = "Black"
  mpres@mpLimbLineColor             = "Black"
  mpres@mpPerimLineColor            = "Black"
  mpres@mpGeophysicalLineThicknessF = 3.0
  mpres@mpGridLineThicknessF        = 2.0
  mpres@mpLimbLineThicknessF        = 2.0
  mpres@mpNationalLineThicknessF    = 3.0
  mpres@mpUSStateLineThicknessF     = 2.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; What times and how many time steps are in the data set?
  times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
  ntimes = dimsizes(times)         ; number of times in the file

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; First get the variables we will need        

timelps   = systemfunc("date")

print("")
print("NCL is processing, please wait ... (1/6)")
    u  = wrf_user_getvar(a,"ua",-1)        ; u averaged to mass points
    v  = wrf_user_getvar(a,"va",-1)        ; v averaged to mass points
 print("NCL is processing, please wait ... (2/6)")
    p  = wrf_user_getvar(a, "pressure",-1) ; pressure is our vertical coordinate
 print("NCL is processing, please wait ... (3/6)")
    z  = wrf_user_getvar(a, "z",-1)        ; grid point height
 print("NCL is processing, please wait ... (4/6)")
    rh = wrf_user_getvar(a,"rh",-1)        ; relative humidity

; The specific pressure levels that we want the data interpolated to.
; Interpolate to these levels
;  pressure_levels = (/ 850., 500. /)   ; pressure levels to plot
  pressure_levels2 = NCLcnlevs   ; pressure levels to plot
  pressure_levels = tointeger(pressure_levels2)

 print("NCL is processing, please wait ... (5/6)")
 print("")

  nlevels         = dimsizes(pressure_levels)     ; number of pressure levels

  z_plane  = wrf_user_intrp3d( z,p,"h",pressure_levels,0.,False)
  rh_plane = wrf_user_intrp3d(rh,p,"h",pressure_levels,0.,False)
  u_plane  = wrf_user_intrp3d( u,p,"h",pressure_levels,0.,False)
  v_plane  = wrf_user_intrp3d( v,p,"h",pressure_levels,0.,False)


  spd     = (u_plane*u_plane + v_plane*v_plane)^(0.5) ; m/sec
    spd@description = "Wind Speed"
    spd@units = "m/s"
  u_plane = u_plane*1.94386     ; kts
  v_plane = v_plane*1.94386     ; kts
    u_plane@units = "kts"
    v_plane@units = "kts"


tc = wrf_user_getvar(a,cnvar,-1)        ; T in C
tc_plane = wrf_user_intrp3d(tc,p,"h",pressure_levels,0.,False)


BandW2 = (/"(/0, 0, 0/)","(/0.1, 0.1, 0.1/)","(/0.2, 0.2, 0.2/)","(/0.3, 0.3, 0.3/)","(/0.4, 0.4, 0.4/)","(/0.5, 0.5, 0.5/)","(/0.6, 0.6, 0.6/)",\
           "(/0.7, 0.7, 0.7/)","(/0.8, 0.8, 0.8/)","(/0.9, 0.9, 0.9/)","(/1, 1, 1/)"/)

   WandB2 = (/"(/1, 1, 1/)", "(/0.9, 0.9, 0.9/)", "(/0.8, 0.8, 0.8/)", "(/0.7, 0.7, 0.7/)", \
                       "(/0.6, 0.6, 0.6/)", "(/0.5, 0.5, 0.5/)", "(/0.4, 0.4, 0.4/)", "(/0.3, 0.3, 0.3/)", "(/0.2, 0.2, 0.2/)", \
                       "(/0.1, 0.1, 0.1/)", "(/0, 0, 0/)"/)

   MPL_Reds2 = (/"(/1.00, 1.00, 1.00/)", "(/1, 0.9, 0.9/)", "(/1, 0.8, 0.8/)", "(/1, 0.7, 0.7/)", \
                       "(/1, 0.6, 0.6/)", "(/1, 0.5, 0.5/)", "(/1, 0.4, 0.4/)", "(/1, 0.3, 0.3/)", "(/1, 0.2, 0.2/)", \
                       "(/1, 0.1, 0.1/)", "(/1, 0, 0/)", "(/0.9, 0, 0/)"/)

   WhiteBlue2 = (/"(/1.00, 1.00, 1.00/)", "(/0.9, 0.9, 1/)", "(/0.8, 0.8, 1/)", "(/0.7, 0.7, 1/)", \
                       "(/0.6, 0.6, 1/)", "(/0.5, 0.5, 1/)", "(/0.4, 0.4, 1/)", "(/0.3, 0.3, 1/)", "(/0.2, 0.2, 1/)", \
                       "(/0.1, 0.1, 1/)", "(/0, 0, 1/)", "(/0, 0, 0.9/)"/)

   WhiteYellowOrangeRed2 = (/ "(/1, 1, 0.9/)", "(/1, 1, 0.7/)", "(/1, 1, 0.55/)", \
                       "(/1, 1, 0.4/)", "(/1, 1, 0.25/)", "(/1, 1, 0.1/)", "(/1, 0.8, 0/)", "(/1, 0.65, 0/)", \
                       "(/1, 0.5, 0/)", "(/1, 0.35, 0/)", "(/1, 0.2, 0/)", "(/1, 0.05, 0/)"/)

   BlueRed2 = (/ "(/0.15, 0.15, 1/)", "(/0.3, 0.3, 1/)", "(/0.45, 0.45, 1/)", \
                       "(/0.6, 0.6, 1/)", "(/0.75, 0.75, 1/)", "(/0.9, 0.9, 1/)", "(/1, 0.9, 0.9/)", "(/1, 0.75, 0.75/)", \
                       "(/1, 0.6, 0.6/)", "(/1, 0.45, 0.45/)", "(/1, 0.3, 0.3/)", "(/1, 0.15, 0.15/)"/)

   WhBlGrYeRe2 = (/"(/1, 1, 1/)", "(/0.51, 0, 0.86/)", "(/0.12, 0.24, 1/)", "(/0, 0.63, 1/)", \
                        "(/0, 0.82, 0.55/)", "(/0, 0.86, 0/)", "(/0.63, 0.90, 0.20/)", "(/0.90, 0.86, 0.2/)", \
                       "(/0.90, 0.69, 0.18/)", "(/0.94, 0.51, 0.16/)", "(/0.98, 0.24, 0.24/)", "(/0.94, 0, 0.51/)"/)

   MPL_gist_rainbow2 = (/"(/0.94, 0, 0.51/)","(/0.98, 0.24, 0.24/)","(/0.94, 0.51, 0.16/)","(/0.90, 0.69, 0.18/)",\
                       "(/0.90, 0.86, 0.2/)", "(/0.63, 0.90, 0.20/)","(/0, 0.86, 0/)","(/0, 0.82, 0.55/)","(/0, 0.78, 0.78/)",\
                       "(/0.12, 0.24, 1/)","(/0.51, 0, 0.86/)","(/0.63, 0, 0.78/)"/)

   rainbow2 = (/"(/0.6, 0, 1/)", "(/0.2, 0.2, 1/)", "(/0.5, 0.5, 1/)", \
                       "(/0, 0.78, 0.78/)", "(/0, 0.82, 0.55/)", "(/0, 0.86, 0/)", "(/0.63, 0.90, 0.20/)", "(/0.90, 0.86, 0.2/)", \
                       "(/0.90, 0.69, 0.18/)", "(/0.94, 0.51, 0.16/)", "(/0.98, 0.24, 0.24/)", "(/0.94, 0, 0.51/)"/)

 WhiteGreen2 = (/"(/1.00, 1.00, 1.00/)", "(/0.9, 1, 0.9/)", "(/0.8, 1, 0.8/)", "(/0.7, 1, 0.7/)", \
                       "(/0.6, 1, 0.6/)", "(/0.5, 1, 0.5/)", "(/0.4, 1, 0.4/)", "(/0.3, 1, 0.3/)", "(/0.2, 1, 0.2/)", \
                       "(/0.1, 1, 0.1/)", "(/0, 1, 0/)", "(/0, 0.9, 0/)"/)

        cnopts = res                          
      if(contourcolorpal .eq. "BlueRed1") then
        cnopts@cnFillColors = BlueRed2
      end if
      if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
        cnopts@cnFillColors = WhiteYellowOrangeRed2
      end if
      if(contourcolorpal .eq. "WhBlGrYeRe1") then
        cnopts@cnFillColors = WhBlGrYeRe2
      end if
      if(contourcolorpal .eq. "MPL_gist_rainbow1") then
        cnopts@cnFillColors = MPL_gist_rainbow2
      end if
      if(contourcolorpal .eq. "rainbow1") then
        cnopts@cnFillColors = rainbow2
      end if
      if(contourcolorpal .eq. "WhiteGreen1") then
        cnopts@cnFillColors = WhiteGreen2
      end if
      if(contourcolorpal .eq. "MPL_Reds1") then
        cnopts@cnFillColors = MPL_Reds2
      end if
      if(contourcolorpal .eq. "WandB") then
        cnopts@cnFillColors = WandB2
      end if
      if(contourcolorpal .eq. "WhiteBlue1") then
        cnopts@cnFillColors = WhiteBlue2
      end if
      if(contourcolorpal .eq. "BandW") then
        cnopts@cnFillColors = BandW2
      end if


 if(cnmode .eq. "Manual") then  ; code abc123
Nullcnmin = new(1,"logical")
Nullcnmax = new(1,"logical")
if ((cnmin .eq. "NULL") .or. (cnmax .eq. "NULL") .or. (cnintv .eq. "NULL")) then
stats = new((/nlevels,2/),"float")
perc_limit = (/0.0833,0.9166/)

do level = 0,nlevels-1
if (nlevels .le. 1) then
tc_planeone = ndtooned(tc_plane(:,:,:))
else
tc_planeone = ndtooned(tc_plane(:,level,:,:))
end if
var_percentile = get_percentiles(tc_planeone,perc_limit)
stats(level,0) = var_percentile(0)
stats(level,1) = var_percentile(1)
delete((tc_planeone))
end do
delete(level)
end if

if (cnmin .eq. "NULL") then
MANcnmin = new(nlevels,"float")
Nullcnmin = True
 do level = 0,nlevels-1
 MANcnmin(level) = stats(level,0)
 end do
delete(level)
end if


if (cnmax .eq. "NULL") then
MANcnmax = new(nlevels,"float")
Nullcnmax = True
 do level = 0,nlevels-1
MANcnmax(level) = stats(level,1)
 end do
delete(level)
end if

if (cnintv .eq. "NULL") then ; code abcnull
MANcnintv = new(nlevels,"float")
 do level = 0,nlevels-1
  if ((.not. ismissing(Nullcnmin)) .and. ismissing(Nullcnmax))
  cnmax2  = stringtofloat(cnmax)
  MANcnintv(level) = (cnmax2-MANcnmin(level))/10
  else if (ismissing(Nullcnmin) .and. (.not. ismissing(Nullcnmax)))
  cnmin2  = stringtofloat(cnmin)
  MANcnintv(level) = (MANcnmax(level)-cnmin2)/10
  else if (ismissing(Nullcnmin) .and. ismissing(Nullcnmax))
        cnmax2  = stringtofloat(cnmax)
        cnmin2  = stringtofloat(cnmin)

 if((contourcolorpal .eq. "WandB") .or. (contourcolorpal .eq. "BandW")) then
  MANcnintv(level) = (cnmax2-cnmin2)/9
 else
  MANcnintv(level) = (cnmax2-cnmin2)/10
 end if

  else

 if((contourcolorpal .eq. "WandB") .or. (contourcolorpal .eq. "BandW")) then
  MANcnintv(level) = (MANcnmax(level)-MANcnmin(level))/9
 else
  MANcnintv(level) = (MANcnmax(level)-MANcnmin(level))/10
 end if
  end if
  end if
  end if
 end do
end if ; code abcnull

end if ; if for code abc123

 if(cnmode .eq. "Automatic") then  ; code abc123
      if(contourcolorpal .eq. "BlueRed1") then
        ;cnopts@cnMaxLevelCount = 12
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
       ; cnopts@cnMaxLevelCount = 12
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhBlGrYeRe1") then
       ; cnopts@cnMaxLevelCount = 12
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "MPL_gist_rainbow1") then
      ;  cnopts@cnMaxLevelCount = 12
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "rainbow1") then
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhiteGreen1") then
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "MPL_Reds1") then
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WandB") then
        cnopts@cnMaxLevelCount = 9
      end if
      if(contourcolorpal .eq. "WhiteBlue1") then
        cnopts@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "BandW") then
        cnopts@cnMaxLevelCount = 9
      end if
end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
  do it = 0,ntimes-1,ncltstep            ; TIME LOOP

    print("Working on time: " + times(it) + " for the variable: " + NCLcontours(ii)  )
    res@TimeLabel = times(it)   ; Set Valid time to use on plots

    do level = 0,nlevels-1                 ; LOOP OVER LEVELS



      pressure = pressure_levels(level)

      ; Add some level info to the plot
        res@PlotLevelID = pressure + " hPa"
          


      ; Plotting options for T                
  ;      cnopts = res                          
        cnopts@cnFillOn = True
  
       if(cnmode .eq. "Manual") then
       cnopts@cnLevelSelectionMode = "ManualLevels"
        if (cnmin .eq. "NULL") then
        cnopts@cnMinLevelValF = MANcnmin(level)
        else
        cnmin3  = stringtofloat(cnmin)
        cnopts@cnMinLevelValF = cnmin3
        end if
        if (cnmax .eq. "NULL") then
        cnopts@cnMaxLevelValF = MANcnmax(level)
        else
        cnmax3  = stringtofloat(cnmax)
        cnopts@cnMaxLevelValF = cnmax3
        end if
        if (cnintv .eq. "NULL") then
        cnopts@cnLevelSpacingF = MANcnintv(level)
        else
        cnintv3  = stringtofloat(cnintv)
        cnopts@cnLevelSpacingF = cnintv3
        end if
       end if

        cnopts@cnLineLabelDensityF = 1

        cnopts@cnLineLabelInterval = 1
        cnopts@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
        cnopts@gsnContourLineThicknessesScale = 2.0
        cnopts@gsnContourLineThicknessesScale = 3.0
        cnopts@cnLineLabelFontHeightF = 0.025
        cnopts@cnHighLabelFontHeightF   = 0.03
      if (nlevels .le. 1) then
        contour_tc = wrf_contour(a,wks,tc_plane(it,:,:),cnopts)
      else
        contour_tc = wrf_contour(a,wks,tc_plane(it,level,:,:),cnopts)
      end if

      ; Plotting options for Wind Speed                
        opts = res                         
        opts@cnLineColor = "MediumSeaGreen"
        opts@ContourParameters = (/ 10. /)
        opts@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
        opts@gsnContourLineThicknessesScale = 3.0
     if (nlevels .le. 1) then
        contour_spd = wrf_contour(a,wks,spd(it,:,:),opts)
     else
        contour_spd = wrf_contour(a,wks,spd(it,level,:,:),opts)
     end if
        delete(opts)

      ; Plotting options for Wind Vectors                 
        opts = res          
        opts@FieldTitle = "Wind"   ; overwrite Field Title
        opts@vcGlyphStyle     = "CurlyVector"
        opts@NumVectors = 25       ; wind barb density
      
        opts_z = res                         
        if((contourcolorpal .eq. "BandW") .or. (contourcolorpal .eq. "WandB")) then
       opts_z@cnLineColor = "Blue"
       opts@vcFillArrowsOn = True
       opts@vcMonoFillArrowFillColor = True
       opts@vcLineArrowColor  = "Red"
      else
        opts_z@cnLineColor = "Black"
      end if

      if (nlevels .le. 1) then
        vector = wrf_vector(a,wks,u_plane(it,:,:),v_plane(it,:,:),opts)
      else
        vector = wrf_vector(a,wks,u_plane(it,level,:,:),v_plane(it,level,:,:),opts)
      end if
        opts@NumVectors = 35       ; wind barb density
      if (nlevels .le. 1) then
        vector850 = wrf_vector(a,wks,u_plane(it,:,:),v_plane(it,:,:),opts)
      else
        vector850 = wrf_vector(a,wks,u_plane(it,level,:,:),v_plane(it,level,:,:),opts)
      end if
        delete(opts)


      ; Plotting options for Geopotential Height
       ; opts_z = res                         
        opts_z@cnFillOn = False
     ;   opts_z@cnLineColor = "Blue"
        opts_z@gsnContourLineThicknessesScale = 3.0
        opts_z@cnLineLabelInterval = 1
     ;   opts_z@cnLineLabelDensityF = 1
        opts_z@cnLineLabelFontHeightF = 0.025


      ; MAKE PLOTS                                       
     if ( (pressure .le. 1000) .and. (pressure .ge. 925) )
          opts_z@ContourParameters = (/ 10.0 /)
         if (nlevels .le. 1) then
          contour_height = wrf_contour(a,wks,z_plane(it,:,:),opts_z)
         else
          contour_height = wrf_contour(a,wks,z_plane(it,level,:,:),opts_z)
         end if
         if ( ncl_shape_onoff .ne. 1 )
          plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         else
          pltres@PanelPlot= True
          pltres@NoTitles = False
          over_id = wrf_map_overlays(a, wks,(/contour_tc,contour_height,vector/),pltres,mpres)
          shpres = True
          shpres@gsLineThicknessF = 2
          shpres@gsLineColor = "white"
          dum2 = gsn_add_shapefile_polylines(wks,over_id,ncl_shape_path,shpres)
          draw(over_id)
          frame(wks)
         end if



        else if ( (pressure .lt. 925) .and. (pressure .ge. 850) ) 
          opts_z@ContourParameters = (/ 20.0 /)
        if (nlevels .le. 1) then
          contour_height = wrf_contour(a,wks,z_plane(it,:,:),opts_z)
        else
          contour_height = wrf_contour(a,wks,z_plane(it,level,:,:),opts_z)
        end if
   ;;       plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         if ( ncl_shape_onoff .ne. 1 )
          plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         else
          pltres@PanelPlot= True
          pltres@NoTitles = False
          over_id = wrf_map_overlays(a, wks,(/contour_tc,contour_height,vector/),pltres,mpres)
          shpres = True
          shpres@gsLineThicknessF = 2
          shpres@gsLineColor = "white"
          dum2 = gsn_add_shapefile_polylines(wks,over_id,ncl_shape_path,shpres)
          draw(over_id)
          frame(wks)
         end if



        else if ( (pressure .lt. 850) .and. (pressure .ge. 400) )
          opts_z@ContourParameters = (/ 40.0 /)
       if (nlevels .le. 1) then
          contour_height = wrf_contour(a,wks,z_plane(it,:,:),opts_z)
       else
          contour_height = wrf_contour(a,wks,z_plane(it,level,:,:),opts_z)
       end if
  ;;        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
          if ( ncl_shape_onoff .ne. 1 )
          plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         else
          pltres@PanelPlot= True
          pltres@NoTitles = False
          over_id = wrf_map_overlays(a, wks,(/contour_tc,contour_height,vector/),pltres,mpres)
          shpres = True
          shpres@gsLineThicknessF = 2
          shpres@gsLineColor = "white"
          dum2 = gsn_add_shapefile_polylines(wks,over_id,ncl_shape_path,shpres)
          draw(over_id)
          frame(wks)
         end if






        else if ( (pressure .lt. 400) .and. (pressure .ge. 200) )
          opts_z@ContourParameters = (/ 80.0 /)
        if (nlevels .le. 1) then
          contour_height = wrf_contour(a,wks,z_plane(it,:,:),opts_z)
        else
          contour_height = wrf_contour(a,wks,z_plane(it,level,:,:),opts_z)
        end if
      ;;    plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         if ( ncl_shape_onoff .ne. 1 )
          plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         else
          pltres@PanelPlot= True
          pltres@NoTitles = False
          over_id = wrf_map_overlays(a, wks,(/contour_tc,contour_height,vector/),pltres,mpres)
          shpres = True
          shpres@gsLineThicknessF = 2
          shpres@gsLineColor = "white"
          dum2 = gsn_add_shapefile_polylines(wks,over_id,ncl_shape_path,shpres)
          draw(over_id)
          frame(wks)
         end if



        else if ( (pressure .lt. 200) .and. (pressure .ge. 50) )
          opts_z@ContourParameters = (/ 120.0 /)
       if (nlevels .le. 1) then
          contour_height = wrf_contour(a,wks,z_plane(it,:,:),opts_z)
       else
          contour_height = wrf_contour(a,wks,z_plane(it,level,:,:),opts_z)
       end if
       ;;   plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         if ( ncl_shape_onoff .ne. 1 )
          plot = wrf_map_overlays(a,wks,(/contour_tc,contour_height,vector/),pltres,mpres)
         else
          pltres@PanelPlot= True
          pltres@NoTitles = False
          over_id = wrf_map_overlays(a, wks,(/contour_tc,contour_height,vector/),pltres,mpres)
          shpres = True
          shpres@gsLineThicknessF = 2
          shpres@gsLineColor = "white"
          dum2 = gsn_add_shapefile_polylines(wks,over_id,ncl_shape_path,shpres)
          draw(over_id)
          frame(wks)
         end if



        else
          print("pressure level is out of range (50 hpa to 1000 hpa)")
        end if
        end if
        end if
        end if
        end if

        delete(opts_z)

    end do      ; END OF LEVEL LOOP

  end do        ; END OF TIME LOOP

delete(tc)
delete(tc_plane)

else

print("PostWRF Warning: " + "<" + NCLcontours(ii) + ">" + " is not among the output variables of " + myfile)

end if ; code att2
ii = ii +1
end do


end
