;PostWRF Version 1.0 (May 2018)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

;   Plot data on a cross section
;   This script will plot data at a set angle through a specified point

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
 nullchar = inttochar(0)
 var = str_match(myfile,"/" )

if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if
 NCLimgfm = getenv("imgfmt")
 contourcolorpal = getenv("colpal")
 nclcrossvar = getenv("crossselect")
 nclcrossdir2 = getenv("crossdir")
 nclcrossdir = stringtofloat(nclcrossdir2)
 delete(nclcrossdir2)

 nclplat2 = getenv("plat")
 nclplat = stringtofloat(nclplat2)
 delete(nclplat2)
 nclplon2 = getenv("plon")
 nclplon = stringtofloat(nclplon2)
 delete(nclplon2)
 nclcrosshght2 = getenv("crossheight")
 nclcrosshght = stringtofloat(nclcrosshght2)
 delete(nclcrosshght2)

 cnmode = getenv("contvar")
 cnmin = getenv("Min")
 cnmax = getenv("Max")
 cnintv = getenv("Intv")
 crossname = getenv("outname")
 ncltstep2 = getenv("tstep")
 ncltstep = tointeger(ncltstep2)

; We generate plots, but what kind do we prefer?
  type = NCLimgfm
  if (type .eq. "animated_gif") then
   type = "png"
  end if
  wks = gsn_open_wks(type,crossname)


; Set some basic resources
  res = True
  res@MainTitle = "REAL-TIME WRF"
  res@Footer = False
  
  pltres = True


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  FirstTime = True
  FirstTimeMap = True
 print("NCL is processing, please wait ... (1/3)")
  times  = wrf_user_getvar(a,"times",-1) ; get times in the file
  ntimes = dimsizes(times)         ; number of times in the file

  mdims = getfilevardimsizes(a,"P") ; get some dimension sizes for the file
  nd = dimsizes(mdims)

  xlat = wrf_user_getvar(a, "XLAT",0)
  xlon = wrf_user_getvar(a, "XLONG",0)
  ter = wrf_user_getvar(a, "HGT",0)

;---------------------------------------------------------------

if (nclcrossvar .eq. "cape_surface") then
   rh2 = wrf_user_getvar(a,"cape_2d",-1)
   rh2@_FillValue=-1
   rh2@description = "CAPE"
   rh2@units = "J/kg"
   rh3 = rh2(0,:,:,:)
     delete(rh2)
  else if (nclcrossvar .eq. "cin_surface") then
   rh2 = wrf_user_getvar(a,"cape_2d",-1)
   rh2@_FillValue=-1
   rh2@description = "CIN"
   rh2@units = "J/kg"
   rh3 = rh2(1,:,:,:)
     delete(rh2)
  else if (nclcrossvar .eq. "cin_3d") then
     rh2  = wrf_user_getvar(a,"cape_3d",-1)
     rh2@_FillValue=-1
     rh2@description = "CIN"
     rh2@units = "J/kg"
     rh3 = rh2(1,:,:,:,:)
     delete(rh2)
  else if (nclcrossvar .eq. "cape_3d") then
  print("For computing CAPE, it takes several minutes. Be patient ...")
     rh2 = wrf_user_getvar(a,"cape_3d",-1)
  print("NCL is processing, please wait ...")
     rh2@_FillValue=-1
     rh2@description = "CIN"
     rh2@units = "J/kg"
     rh3 = rh2(0,:,:,:,:)
     delete(rh2)
 else if (nclcrossvar .eq. "lcl") then
     rh2  = wrf_user_getvar(a,"cape_2d",-1)
     rh2@description = "Lifting Condensation Level"
     rh2@units = "m"
     rh3 = rh2(2,:,:,:)
     delete(rh2)
 else if (nclcrossvar .eq. "lfc") then
     rh2 = wrf_user_getvar(a,"cape_2d",-1)
     rh2@description = "Level of Free Convection"
     rh2@units = "m"
     rh3 = rh2(2,:,:,:)
     delete(rh2)
 else
   ; rh   = wrf_user_getvar(a,nclcrossvar,it)      ; relative humidity
    rh3   = wrf_user_getvar(a,nclcrossvar,-1)      ; relative humidity
 end if
 end if
 end if
 end if
 end if
 end if

 print("NCL is processing, please wait ... (2/3)")
    tc2   = wrf_user_getvar(a,"tc",-1)      ; T in C
    z2    = wrf_user_getvar(a, "z",-1)      ; grid point height

   BandW2 = (/"(/0.1, 0.1, 0.1/)","(/0.2, 0.2, 0.2/)","(/0.3, 0.3, 0.3/)","(/0.4, 0.4, 0.4/)","(/0.5, 0.5, 0.5/)","(/0.6, 0.6, 0.6/)",\
           "(/0.7, 0.7, 0.7/)","(/0.8, 0.8, 0.8/)", "(/0.85,0.85,0.85/)", "(/0.9, 0.9, 0.9/)", "(/0.95,0.95,0.95/)", "(/1, 1, 1/)"/)

   WandB2 = (/"(/1, 1, 1/)", "(/0.95,0.95,0.95/)", "(/0.9, 0.9, 0.9/)", "(/0.85, 0.85, 0.85/)", "(/0.8, 0.8, 0.8/)", "(/0.7, 0.7, 0.7/)", \
                       "(/0.6, 0.6, 0.6/)", "(/0.5, 0.5, 0.5/)", "(/0.4, 0.4, 0.4/)", "(/0.3, 0.3, 0.3/)", "(/0.2, 0.2, 0.2/)", \
                       "(/0.1, 0.1, 0.1/)"/)

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

varcnsize = dimsizes(dimsizes(tc2))
 if (varcnsize.ne.4) ;code: aabb
   print("PostWRF: " + cnvar + " is not a standard 3D or 4D variable. Contour map not possible.")
else

angle = nclcrossdir
plane = wrf_user_ll_to_ij(a,(/nclplon/),(/nclplat/),True)
plane = plane - 1

b_res = new(ntimes, "float")
do it = 0, ntimes-1, 1
 z = z2(it,:,:,:)
 zz = wrf_user_intrp3d(z,z,"v",plane,angle,False)
 z_upindices = ind(zz(:,0) .gt. nclcrosshght*1000.)
 b_res(it) = z_upindices(0)
delete(z_upindices)
end do
b = avg(b_res)
zmax_pos = numeric2int(b,0) - 1

varsize = wrf_user_intrp3d(tc2(0,:,:,:),z2(0,:,:,:),"v",plane,angle,False)
dim2 = dimsizes(varsize(:,0))
dim3 = dimsizes(varsize(0,:))
stattotal = new((/ntimes,dim2,dim3/),"float")
do it = 0, ntimes-1, ncltstep
 z = z2(it,:,:,:)
 varplane = wrf_user_intrp3d(rh3(it,:,:,:),z,"v",plane,angle,False)
 stattotal(it,:,:) =  varplane
end do
delete(z)
delete(zz)
delete(b)
delete(varplane)


if(cnmode .eq. "Manual") then  ; code abc123
Nullcnmin = new(1,"logical")
Nullcnmax = new(1,"logical")
if ((cnmin .eq. "NULL") .or. (cnmax .eq. "NULL") .or. (cnintv .eq. "NULL")) then
tc_planeone = ndtooned(stattotal(:,0:zmax_pos,:))
perc_limit = (/0.0833,0.9166/)
var_percentile = get_percentiles(tc_planeone,perc_limit)
delete((tc_planeone))

end if

if (cnmin .eq. "NULL") then
MANcnmin = new(1,"float")
Nullcnmin = True
MANcnmin = var_percentile(0)
end if

if (cnmax .eq. "NULL") then
MANcnmax = new(1,"float")
Nullcnmax = True
MANcnmax = var_percentile(1)
end if

if (cnintv .eq. "NULL") then
divar=10
MANcnintv = new(1,"float")
  if ((.not. ismissing(Nullcnmin)) .and. ismissing(Nullcnmax))
  cnmax2  = stringtofloat(cnmax)
  MANcnintv = (cnmax2-MANcnmin)/divar
  else if (ismissing(Nullcnmin) .and. (.not. ismissing(Nullcnmax)))
  cnmin2  = stringtofloat(cnmin)
  MANcnintv = (MANcnmax-cnmin2)/divar
  else if (ismissing(Nullcnmin) .and. ismissing(Nullcnmax))
        cnmax2  = stringtofloat(cnmax)
        cnmin2  = stringtofloat(cnmin)
  MANcnintv = (cnmax2-cnmin2)/divar
  else
  MANcnintv = (MANcnmax-MANcnmin)/divar
  end if
  end if
  end if
end if

end if ; if for ;code abc123


  do it = 0,ntimes-1, ncltstep             ; TIME LOOP

    print("Working on time: " + times(it) )
    res@TimeLabel = times(it)   ; Set Valid time to use on plots

    rh = rh3(it,:,:,:)
    tc = tc2(it,:,:,:)
     z =  z2(it,:,:,:)

    if ( FirstTime ) then                ; get height info for labels
      zmin = 0.
      zmax = nclcrosshght                 ; We are only interested in the first 6km
      nz   = floattoint(zmax + 1)
    end if


;---------------------------------------------------------------

        opts = False

     ;  angle = nclcrossdir
        if(angle .lt. 45) then
          X_desc = "latitude"
          X_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
        else if ((angle .ge. 45) .and. (angle .lt. 90))
          X_desc = "longitude"
          X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
        else if ((angle .ge. 90) .and. (angle .lt. 135))
          X_desc = "longitude"
          X_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
        else if ((angle .ge. 135) .and. (angle .le. 180))
          X_desc = "latitude"
          X_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
        end if
        end if
        end if
        end if


        rh_plane = wrf_user_intrp3d(rh,z,"v",plane,angle,opts)
        tc_plane = wrf_user_intrp3d(tc,z,"v",plane,angle,opts)


      ; Find the index where 6km is - only need to do this once
        if ( FirstTime ) then
          zz = wrf_user_intrp3d(z,z,"v",plane,angle,opts)
          b = ind(zz(:,0) .gt. zmax*1000. )
          zmax_pos = b(0) - 1
          if ( abs(zz(zmax_pos,0)-zmax*1000.) .lt. abs(zz(zmax_pos+1,0)-zmax*1000.) ) then
            zspan = b(0) - 1
          else
            zspan = b(0)
          end if
          delete(zz)
          delete(b)
          FirstTime = False
        end if

      ; X-axis lables
      dimsX = dimsizes(X_plane)
      xmin  = X_plane(0)
      xmax  = X_plane(dimsX(0)-1)
      xspan = dimsX(0)-1
 ;     nx    = floattoint( (xmax-xmin)/2 + 1)
      nx    = 10
      ;---------------------------------------------------------------
        
      ; Options for XY Plots
        opts_xy                         = res
        opts_xy@tiXAxisString           = X_desc
        opts_xy@tiYAxisString           = "Height (km)"
        opts_xy@cnMissingValPerimOn     = True
        opts_xy@cnMissingValFillColor   = 0
        opts_xy@cnMissingValFillPattern = 11
        opts_xy@tmXTOn                  = False
        opts_xy@tmYROn                  = False
        opts_xy@tmXBMode                = "Explicit"
        opts_xy@tmXBValues              = fspan(0,xspan,nx)                    ; Create tick marks
        opts_xy@tmXBLabels              = sprintf("%.1f",fspan(xmin,xmax,nx))  ; Create labels
        opts_xy@tmXBLabelFontHeightF    = 0.015
        opts_xy@tmYLMode                = "Explicit"
        opts_xy@tmYLValues              = fspan(0,zspan,nz)                    ; Create tick marks
        opts_xy@tmYLLabels              = sprintf("%.1f",fspan(zmin,zmax,nz))  ; Create labels
        opts_xy@tiXAxisFontHeightF      = 0.020
        opts_xy@tiYAxisFontHeightF      = 0.020
        opts_xy@tmXBMajorLengthF        = 0.02
        opts_xy@tmYLMajorLengthF        = 0.02
        opts_xy@tmYLLabelFontHeightF    = 0.015
        opts_xy@PlotOrientation         = tc_plane@Orientation

opts_rh = opts_xy

      if(contourcolorpal .eq. "BlueRed1") then
        opts_rh@cnFillColors = BlueRed2
      end if
      if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
        opts_rh@cnFillColors = WhiteYellowOrangeRed2
      end if
      if(contourcolorpal .eq. "WhBlGrYeRe1") then
        opts_rh@cnFillColors = WhBlGrYeRe2
      end if
      if(contourcolorpal .eq. "MPL_gist_rainbow1") then
        opts_rh@cnFillColors = MPL_gist_rainbow2
      end if
      if(contourcolorpal .eq. "rainbow1") then
        opts_rh@cnFillColors = rainbow2
      end if
      if(contourcolorpal .eq. "WhiteGreen1") then
        opts_rh@cnFillColors = WhiteGreen2
      end if
      if(contourcolorpal .eq. "MPL_Reds1") then
        opts_rh@cnFillColors = MPL_Reds2
      end if
      if(contourcolorpal .eq. "WandB") then
        opts_rh@cnFillColors = WandB2
      end if
      if(contourcolorpal .eq. "WhiteBlue1") then
        opts_rh@cnFillColors = WhiteBlue2
      end if
      if(contourcolorpal .eq. "BandW") then
        opts_rh@cnFillColors = BandW2
      end if

if(cnmode .eq. "Manual") then
        opts_rh@cnLevelSelectionMode = "ManualLevels"
        if (cnmin .eq. "NULL") then
        opts_rh@cnMinLevelValF = MANcnmin
        else
        cnmin3  = stringtofloat(cnmin)
        opts_rh@cnMinLevelValF = cnmin3
        end if
        if (cnmax .eq. "NULL") then
        opts_rh@cnMaxLevelValF = MANcnmax
        else
        cnmax3  = stringtofloat(cnmax)
        opts_rh@cnMaxLevelValF = cnmax3
        end if
        if (cnintv .eq. "NULL") then
        opts_rh@cnLevelSpacingF = MANcnintv
        else
        cnintv3  = stringtofloat(cnintv)
        opts_rh@cnLevelSpacingF = cnintv3
        end if
       else

      if(contourcolorpal .eq. "BlueRed1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhBlGrYeRe1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "MPL_gist_rainbow1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "rainbow1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhiteGreen1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "MPL_Reds1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WandB") then
        opts_rh@cnMaxLevelCount = 9
      end if
      if(contourcolorpal .eq. "WhiteBlue1") then
        opts_rh@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "BandW") then
        opts_rh@cnMaxLevelCount = 9
      end if
       end if

        opts_rh@pmLabelBarOrthogonalPosF = -0.1 
        opts_rh@cnFillOn                = True

      ; Plotting options for Temperature
        opts_tc = opts_xy
        opts_tc@cnInfoLabelZone = 1
        opts_tc@cnInfoLabelSide = "Top"
        opts_tc@cnInfoLabelPerimOn = True
        opts_tc@cnInfoLabelOrthogonalPosF = -0.00005
        opts_tc@ContourParameters  = (/ 5. /)


      ; Get the contour info for the rh and temp
        contour_tc = wrf_contour(a,wks,tc_plane(0:zmax_pos,:),opts_tc)
        contour_rh = wrf_contour(a,wks,rh_plane(0:zmax_pos,:),opts_rh)

      ;---------------------------------------------------------------

  ; MAKE PLOTS         

        if (FirstTimeMap) then
          lat_plane = wrf_user_intrp2d(xlat,plane,angle,opts)
          lon_plane = wrf_user_intrp2d(xlon,plane,angle,opts)
          mpres = True
          pltres = True
          pltres@FramePlot = False
          optsM = res
          optsM@NoHeaderFooter = True
          optsM@cnFillOn = True
          optsM@lbTitleOn = False
          contour  = wrf_contour(a,wks,ter,optsM)
          plot = wrf_map_overlays(a,wks,(/contour/),pltres,mpres)
          lnres = True
          lnres@gsLineThicknessF = 3.0
          lnres@gsLineColor = "Red"
          do ii = 0,dimsX(0)-2
            gsn_polyline(wks,plot,(/lon_plane(ii),lon_plane(ii+1)/),(/lat_plane(ii),lat_plane(ii+1)/),lnres)
          end do
          frame(wks)
          delete(lon_plane)
          delete(lat_plane)
          pltres@FramePlot = True
       end if

       plot = wrf_overlays(a,wks,(/contour_rh,contour_tc/),pltres)    ; plot x-section

  ; Delete options and fields, so we don't have carry over
        delete(opts_xy)
        delete(opts_tc)
        delete(opts_rh)
        delete(tc_plane)
        delete(rh_plane)
        delete(X_plane)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    FirstTimeMap = False
  end do        ; END OF TIME LOOP


end if ;code aabb

end
