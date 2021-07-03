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

load "read_wrfouts.ncl"
wrffile = a[0]
lat0 = wrffile->XLAT
long0 = wrffile->XLONG
lat2d = lat0(0, :, :)
copy_VarAtts(lat0, lat2d)
lon2d = long0(0, :, :)
AllLines = asciiread(getenv("radiation_file"), -1, "string")
lat_count =  dimsizes(lat2d(:,0))-1   ;95 - 1
long_count_plus = dimsizes(lon2d(0,:))   ;117 - 1
long_count = long_count_plus - 1
allbands = dimsizes(str_split(AllLines(0), " ")) - 1
rttovvar = new( (/allbands+1 ,lat_count+1, long_count+1/), "float")
rttovvar!1 = "south_north"                      ; assign named dimensions
rttovvar!2 = "west_east"
ncfile = getenv("ncfilename")
cnmode = getenv("contvar")
cnmin = getenv("Min")
cnmax = getenv("Max")
; cnintv = getenv("Intv")
contourcolorpal = getenv("colpal")
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

WhiteYellowOrangeRed2 = (/ "(/1, 1, 1/)", "(/1, 1, 0.75/)", "(/1, 1, 0.55/)", \
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

res                = True
if(contourcolorpal .eq. "BlueRed1") then
res@cnFillColors = BlueRed2
end if
if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
res@cnFillColors = WhiteYellowOrangeRed2
end if
if(contourcolorpal .eq. "WhBlGrYeRe1") then
res@cnFillColors = WhBlGrYeRe2
end if
if(contourcolorpal .eq. "MPL_gist_rainbow1") then
res@cnFillColors = MPL_gist_rainbow2
end if
if(contourcolorpal .eq. "rainbow1") then
res@cnFillColors = rainbow2
end if
if(contourcolorpal .eq. "WhiteGreen1") then
res@cnFillColors = WhiteGreen2
end if
if(contourcolorpal .eq. "MPL_Reds1") then
res@cnFillColors = MPL_Reds2
end if
if(contourcolorpal .eq. "WandB") then
res@cnFillColors = WandB2
end if
if(contourcolorpal .eq. "WhiteBlue1") then
res@cnFillColors = WhiteBlue2
end if
if(contourcolorpal .eq. "BandW") then
res@cnFillColors = BandW2
end if

do bandnum=0, allbands ;each band
    do jjlat=0, lat_count
        do iilong=0, long_count
            kkline = jjlat*long_count_plus + iilong
            myband = tofloat(str_split(AllLines(kkline), " "))
            rttovvar(bandnum, jjlat, iilong) = myband(bandnum)
        end do
    end do
end do

if(cnmode .eq. "Manual") then  ; code abc123
    Nullcnmin = new(1,"logical")
    Nullcnmax = new(1,"logical")
    if ((cnmin .eq. "NULL") .or. (cnmax .eq. "NULL") ) then
    stats = new(2,"float")
    perc_limit = (/0.0833,0.9166/)
    tc_planeone = ndtooned(rttovvar)
    var_percentile = get_percentiles(tc_planeone, perc_limit)
    stats(0) = var_percentile(0)
    stats(1) = var_percentile(1)
    delete((tc_planeone))
    end if
    ; if (ncl_smooth.eq.1) then
    ;     wrf_smooth_2d(tc_plane33,3)
    ; end if
    if (cnmin .eq. "NULL") then
    Nullcnmin = True
    MANcnmin = stats(0)
    end if
    if (cnmax .eq. "NULL") then
    Nullcnmax = True
    MANcnmax = stats(1)
    end if
    ; if (cnintv .eq. "NULL") then ; code abcnull
    if ((.not. ismissing(Nullcnmin)) .and. ismissing(Nullcnmax))
    cnmax2  = stringtofloat(cnmax)
    MANcnintv = (cnmax2-MANcnmin/10)
    else if (ismissing(Nullcnmin) .and. (.not. ismissing(Nullcnmax)))
    cnmin2  = stringtofloat(cnmin)
    MANcnintv = (MANcnmax-cnmin2)/10
    else if (ismissing(Nullcnmin) .and. ismissing(Nullcnmax))
    cnmax2  = stringtofloat(cnmax)
    cnmin2  = stringtofloat(cnmin)
        if((contourcolorpal .eq. "WandB") .or. (contourcolorpal .eq. "BandW")) then
        MANcnintv = (cnmax2-cnmin2)/9
        else
        MANcnintv = (cnmax2-cnmin2)/10
        end if
    else
        if((contourcolorpal .eq. "WandB") .or. (contourcolorpal .eq. "BandW")) then
        MANcnintv = (MANcnmax-MANcnmin)/9
        else
        MANcnintv = (MANcnmax-MANcnmin)/10
        end if
    end if
    end if
    end if
    ; end if ; code abcnull

    res@cnLevelSelectionMode = "ManualLevels"
    if (cnmin .eq. "NULL") then
    res@cnMinLevelValF = MANcnmin
    else
    cnmin3  = stringtofloat(cnmin)
    res@cnMinLevelValF = cnmin3
    end if
    if (cnmax .eq. "NULL") then
    res@cnMaxLevelValF = MANcnmax
    else
    cnmax3  = stringtofloat(cnmax)
    res@cnMaxLevelValF = cnmax3
    end if
    ; if (cnintv .eq. "NULL") then
    res@cnLevelSpacingF = MANcnintv
    ; else
    ; cnintv3  = stringtofloat(cnintv)
    ; res@cnLevelSpacingF = cnintv3
    ; end if
end if ; if for code abc123

do bandnum=0, allbands ;each band
    ; do jjlat=0, lat_count
    ;     do iilong=0, long_count
    ;         kkline = jjlat*long_count_plus + iilong
    ;         myband = tofloat(str_split(AllLines(kkline), " "))
    ;         rttovvar(bandnum, jjlat, iilong) = myband(bandnum)
    ;     end do
    ; end do
    mynum = bandnum+1
    band_name = "band"+mynum
    mylat  = lat2d
    mylon  = lon2d
    mydim = dimsizes(mylat) - 1
    wks = gsn_open_wks("png",band_name+"_"+ncfile)
    res@gsnMaximize    = True     ; maximize plot in frame
    res@cnFillOn       = True     ; turn on contour fill
    res@cnLinesOn      = False    ; turn off contour lines
    res@cnLineLabelsOn = False    ; turn off contour line labels
    ; res@cnFillPalette = "rainbow"
    ; res@cnLevelSelectionMode = "ManualLevels"
    ; res@cnMinLevelValF = 195
    ; res@cnMaxLevelValF = 330
    ; res@cnLevelSpacingF = 5
    res@tfDoNDCOverlay    = True              ; REQUIRED for plotting on native grid  
    ; res@tfDoNDCOverlay    = "NDCViewport"     ; NCL V6.5.0 or later
    res@mpLimitMode       = "Corners"         ; choose range of map
    res@mpLeftCornerLatF  = max( mylat(mydim(0), 0) )
    res@mpLeftCornerLonF  = min(mylon(mydim(0), 0) )
    res@mpRightCornerLatF = min(mylat(0, mydim(1)) )
    res@mpRightCornerLonF = max(mylon(0, mydim(1)) )
    res@mpProjection        = "LambertConformal"
    res@mpLambertMeridianF  = wrffile@CEN_LON
    res@mpLambertParallel1F = wrffile@TRUELAT1
    res@mpLambertParallel2F = wrffile@TRUELAT2
    res@pmTickMarkDisplayMode = "Always"    ; better map tickmarks
    ; res@tiMainString   = "Plotting data on its native grid"
    res@mpDataBaseVersion = "MediumRes"
    res@mpGeophysicalLineThicknessF = 2
    plot = gsn_csm_contour_map(wks, rttovvar(bandnum, :, :), res)
    ; print(" " + band_name + ": Converting to NetCDF ...")
end do