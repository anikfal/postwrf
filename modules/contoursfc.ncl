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
  cnmode = getenv("contvar")
 
  cnmin = getenv("Min")
  cnmax = getenv("Max")
  cnintv = getenv("Intv")
  cnvar = getenv("contourselect")
  contourcolorpal = getenv("colpal")
  ncltstep2 = getenv("tstep")
  ncltstep = tointeger(ncltstep2)
  ncl_shape_onoff = getenv("shape_onoff")
  ncl_shape_path = getenv("shape_path")

nullchar = inttochar(0) 
var = str_match(myfile,"/" )

if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if

filename = getenv("outname")
fr = getenv("imgfmt")
   if (fr .eq. "animated_gif") then
    fr = "png"
   end if
wks = gsn_open_wks(fr,filename)
print("")
print("NCL is processing, please wait ... (1/4)")
times = wrf_user_getvar(a,"times",-1)
slp2 = wrf_user_getvar(a,cnvar,-1)

   if (cnvar .eq. "cape_surface") then
   slp3 = wrf_user_getvar(a,"cape_2d",-1)
   slp3@_FillValue=-1
   slp3@description = "CAPE"
   slp3@units = "J/kg"
   slp = slp3(0,:,:,:)
  else if (cnvar .eq. "cin_surface") then
   slp3 = wrf_user_getvar(a,"cape_2d",-1)
   slp3@_FillValue=-1
   slp3@description = "CIN"
   slp3@units = "J/kg"
   slp = slp3(1,:,:,:)
  else if (cnvar .eq. "cin_3d") then
     slp3  = wrf_user_getvar(a,"cape_3d",-1)
     slp3@_FillValue=-1
     slp3@description = "CIN"
     slp3@units = "J/kg"
     slp = slp3(1,:,:,:,:)
  else if (cnvar .eq. "cape_3d") then
     delete(slp2)
     slp3 = wrf_user_getvar(a,"cape_3d",-1)
     slp3@_FillValue=-1
     slp3@description = "CIN"
     slp3@units = "J/kg"
     slp = slp3(0,:,:,:,:)
     delete(slp3)
 else if (cnvar .eq. "lcl") then
     slp3  = wrf_user_getvar(a,"cape_2d",-1)
     slp3@description = "Lifting Condensation Level"
     slp3@units = "m"
     slp = slp3(2,:,:,:)
 else if (cnvar .eq. "lfc") then
     slp3 = wrf_user_getvar(a,"cape_2d",-1)
     slp3@description = "Level of Free Convection"
     slp3@units = "m"
     slp = slp3(2,:,:,:)
 end if
 end if
 end if
 end if
 end if
 end if


varcnsize = dimsizes(dimsizes(slp2))

   nostdvar = False
 if (varcnsize.eq.4)
   slp = slp2(:,0,:,:)
 else if (varcnsize.eq.3)
   slp = slp2
 else
 nostdvar = True
 end if
 end if


if (nostdvar .eq. True)
   print("PostWRF: " + cnvar + " is not a standard 3D or 4D variable. Contour map not possible.")
else 


 if(cnmode .eq. "Manual") then  ; code abc123
Nullcnmin = new(1,"logical")
Nullcnmax = new(1,"logical")
if ((cnmin .eq. "NULL") .or. (cnmax .eq. "NULL") .or. (cnintv .eq. "NULL")) then
stats = new(2,"float")
perc_limit = (/0.0833,0.9166/)
tc_planeone = ndtooned(slp)
var_percentile = get_percentiles(tc_planeone,perc_limit)
stats(0) = var_percentile(0)
stats(1) = var_percentile(1)
delete((tc_planeone))
end if

if (cnmin .eq. "NULL") then
MANcnmin = new(1,"float")
Nullcnmin = True
MANcnmin = stats(0)
end if

if (cnmax .eq. "NULL") then
MANcnmax = new(1,"float")
Nullcnmax = True
MANcnmax = stats(1)
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

end if ; if for code abc123


  wrf_smooth_2d( slp, 3 )        ; smooth slp
  resp = True
  resp@cnLineColor = "NavyBlue"
 resp@UnitLabel = " "
  resp@cnInfoLabelOn        = True
  resp@cnFillOn                 = True
  resp@lbTitleOn        = True
  resp@lbTitleString    = slp@description



   BandW2 = (/"(/0, 0, 0/)","(/0.05,0.05,0.05/)","(/0.1, 0.1, 0.1/)","(/0.2, 0.2, 0.2/)","(/0.3, 0.3, 0.3/)","(/0.4, 0.4, 0.4/)","(/0.5, 0.5, 0.5/)","(/0.6, 0.6, 0.6/)",\
           "(/0.7, 0.7, 0.7/)","(/0.8, 0.8, 0.8/)","(/0.9, 0.9, 0.9/)","(/1, 1, 1/)"/)

   WandB2 = (/"(/1, 1, 1/)", "(/0.95,0.95,0.95/)", "(/0.9, 0.9, 0.9/)", "(/0.8, 0.8, 0.8/)", "(/0.7, 0.7, 0.7/)", \
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

      if(contourcolorpal .eq. "BlueRed1") then
        resp@cnFillColors = BlueRed2
      end if
      if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
        resp@cnFillColors = WhiteYellowOrangeRed2
      end if
      if(contourcolorpal .eq. "WhBlGrYeRe1") then
        resp@cnFillColors = WhBlGrYeRe2
      end if
      if(contourcolorpal .eq. "MPL_gist_rainbow1") then
        resp@cnFillColors = MPL_gist_rainbow2
      end if
      if(contourcolorpal .eq. "rainbow1") then
        resp@cnFillColors = rainbow2
      end if
      if(contourcolorpal .eq. "WhiteGreen1") then
        resp@cnFillColors = WhiteGreen2
      end if
      if(contourcolorpal .eq. "MPL_Reds1") then
        resp@cnFillColors = MPL_Reds2
      end if
      if(contourcolorpal .eq. "WandB") then
        resp@cnFillColors = WandB2
      end if
      if(contourcolorpal .eq. "WhiteBlue1") then
        resp@cnFillColors = WhiteBlue2
      end if
      if(contourcolorpal .eq. "BandW") then
        resp@cnFillColors = BandW2
      end if


      if(cnmode .eq. "Manual") then
        resp@cnLevelSelectionMode = "ManualLevels"
        if (cnmin .eq. "NULL") then
        resp@cnMinLevelValF = MANcnmin
        else
        cnmin3  = stringtofloat(cnmin)
        resp@cnMinLevelValF = cnmin3
        end if
        if (cnmax .eq. "NULL") then
        resp@cnMaxLevelValF = MANcnmax
        else
        cnmax3  = stringtofloat(cnmax)
        resp@cnMaxLevelValF = cnmax3
        end if
        if (cnintv .eq. "NULL") then
        resp@cnLevelSpacingF = MANcnintv
        else
        cnintv3  = stringtofloat(cnintv)
        resp@cnLevelSpacingF = cnintv3
        end if
       else
       
      if(contourcolorpal .eq. "BlueRed1") then
        resp@cnMaxLevelCount = 12
      end if
      if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
        resp@cnMaxLevelCount = 12
      end if
      if(contourcolorpal .eq. "WhBlGrYeRe1") then
        resp@cnMaxLevelCount = 12
      end if
      if(contourcolorpal .eq. "MPL_gist_rainbow1") then
        resp@cnMaxLevelCount = 12
      end if
      if(contourcolorpal .eq. "rainbow1") then
        resp@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WhiteGreen1") then
        resp@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "MPL_Reds1") then
        resp@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "WandB") then
        resp@cnMaxLevelCount = 9
      end if
      if(contourcolorpal .eq. "WhiteBlue1") then
        resp@cnMaxLevelCount = 11
      end if
      if(contourcolorpal .eq. "BandW") then
        resp@cnMaxLevelCount = 9
      end if
       end if


  u10 = wrf_user_getvar(a,"U10",-1)  ; u at 10 m
  v10 = wrf_user_getvar(a,"V10",-1)  ; v at 10 m

print("NCL is processing, please wait ... (2/4)")
  sealp = wrf_user_getvar(a,"slp",-1)    ; slp
  wrf_smooth_2d( sealp, 3 )            ; smooth slp
      opts = True        
      resw = True
      resw@vcGlyphStyle            = "CurlyVector"     ; turn on curley vectors
      if((contourcolorpal .eq. "BandW") .or. (contourcolorpal .eq. "WandB")) then
       opts@cnLineColor = "Blue"
       resw@vcFillArrowsOn = True
       resw@vcMonoFillArrowFillColor = True
      ; resw@vcWindBarbColor = "Blue"
       resw@vcLineArrowColor  = "Red"
      else
       opts@cnLineColor = "Black"
      end if
 
      ;opts@cnLineColor = "Black"
      opts@cnLineLabelInterval = 1
      opts@cnLineLabelFontHeightF = 0.025
      opts@cnHighLabelsOn = True
      opts@cnLowLabelsOn = True
      opts@ContourParameters = (/ 900., 1100., 4. /)
      opts@cnLineLabelBackgroundColor = -1
      opts@gsnContourLineThicknessesScale = 2.0


print("NCL is processing, please wait ... (3/4)")

 i = 0
   do while(i.le.(dimsizes(times)-1))
  print("Working on time: " + times(i) )

  contour_p = wrf_contour(a,wks,slp(i,:,:),resp)

  contour_psl = wrf_contour(a,wks,sealp(i,:,:),opts)

  vector = wrf_vector(a,wks,u10(i,:,:),v10(i,:,:),resw)

  mpres = True
  mpres@mpOutlineBoundarySets = "National"
 
  mpres@mpNationalLineThicknessF = 3.0
  mpres@mpGeophysicalLineThicknessF = 3.0
  mpres@mpNationalLineColor = "(/1, 1, 1/)"
  mpres@mpGeophysicalLineColor = "(/1, 1, 1/)"
   mpres@tiMainString =   times(i)
if ( ncl_shape_onoff .ne. 1 )
  over_id = wrf_map_overlays(a, wks,(/contour_p,contour_psl,vector/),True,mpres)
else
 pltres = True
 pltres@PanelPlot= True
 pltres@NoTitles = False
 over_id = wrf_map_overlays(a, wks,(/contour_p,contour_psl,vector/),pltres,mpres)
 shpres = True
 shpres@gsLineThicknessF = 2
 shpres@gsLineColor = "white"
 dum2 = gsn_add_shapefile_polylines(wks,over_id,ncl_shape_path,shpres)
 draw(over_id)
 frame(wks)
end if

i=i+ncltstep
   end do

end if

end
