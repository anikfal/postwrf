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

myfilename = systemfunc("ls postwrf_era_*")
var = str_match(myfilename,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  aaa = addfile(dir + "/" + myfilename,"r")
  else
  aaa = addfile(myfilename,"r")
end if

 print("Please wait. NCL is processing ...")
 print("")
 all_steps = tointeger(cd_calendar(aaa->time, 3))
 NCLCNVAR3 = getenv("CNVAR3")
 NCLCNVAR1 = getenv("CNVAR1")
 NCLCNVAR2 = getenv("CNVAR2")
 NCLwindonoff = tointeger(getenv("wind_onoff"))
 NCL1VARONOFF = tointeger(getenv("FIRSTVAR_ONOFF"))
 NCL2VARONOFF = tointeger(getenv("SECONDVAR_ONOFF"))
 NCL3VARONOFF = tointeger(getenv("THIRDVAR_ONOFF"))
 ncl_shape_onoff = tointeger(getenv("shape_onoff"))
 ncl_shape_path = getenv("shape_path")
 ncl_smooth = tointeger(getenv("smooth_onoff"))
 nclborder = getenv("border_color")
 nclborder_thick = tofloat(getenv("borderthick"))
 time_first = tointeger(getenv("tfirst_ind")) - 1
 time_last = getenv("tlast_ind")
  if (time_last .eq. "last_index_era") then
    time_last := dimsizes(all_steps) - 1
   else
    time_last := tointeger(time_last) - 1
  end if

  if (nclborder_thick.le.1 .and. nclborder_thick.ge.0) then
    nclborder_thick = 1 + nclborder_thick*3
  else
    nclborder_thick = 2
  end if
 ocean_onoff = tointeger(getenv("oceanfill_onoff"))
 point_onoff = tointeger(getenv("contourpoints_onoff"))
 label_onoff = tointeger(getenv("contourlabel_onoff"))
 if (point_onoff .eq. 0) then
  label_onoff = 0
 end if
 NCLgridline_onoff = tointeger(getenv("gridline_onoff"))
 NCLaverage_onoff = tointeger(getenv("average_onoff"))
 NCLaverage_time = tointeger(getenv("averagetime"))
 NCLtitle = tointeger(getenv("titile_option"))
 panel_onoff = tointeger(getenv("panelplot"))
 NCLpanelrows = tointeger(getenv("panelrows"))
 NCLpanelcolumns = tointeger(getenv("panelcolumns"))

opt_notitle = True
opt_notitle@NoHeaderFooter = True
opt_notitle@InitTime = False
opt_notitle@ValidTime = False

filename = getenv("outname")
type = getenv("imgfmt")
if (type .eq. "animated_gif") then
type = "png"
end if

totstepsminus = dimsizes(all_steps)-1
if (NCLaverage_onoff.eq.1) then
  hourstep = all_steps(1) - all_steps(0)
  ncltstep = tointeger(NCLaverage_time/hourstep)
  totstepsminus = totstepsminus - time_first
end if

yy  = asciiread(".AllWRFVariables", -1, "string")

if_polynom  = False
if_polynom3 = False
if_polynom2 = False
if_polynom1 = False
if_valid   = True

if ( NCL3VARONOFF.ne.1 ) then
  NCLCNVAR3=yy(0)
  else
  varplus = str_match(NCLCNVAR3,"+")
  varminus = str_match(NCLCNVAR3,"-")
  varmult = str_match(NCLCNVAR3,"*")
  vardiv = str_match(NCLCNVAR3,"/")
  varexp = str_match(NCLCNVAR3,"^")
  varopenp = str_match(NCLCNVAR3,"(")
  varclosep = str_match(NCLCNVAR3,")")
  if( .not.ismissing(varplus) .or. .not.ismissing(varminus) .or. .not.ismissing(varmult) \
    .or. .not.ismissing(vardiv) .or. .not.ismissing(varexp) .or. .not.ismissing(varopenp) \
    .or. .not.ismissing(varclosep) ) then ;;if one is filled
    if_polynom = True
    if_polynom3 = if_polynom
    homedir = getenv("postwrf_dir")
    asciiwrite (homedir+"/modules_era/totalequation.txt" , NCLCNVAR3)
    asciiwrite (homedir+"/modules_era/totalequationCN3.txt" , NCLCNVAR3)
    system("cd $postwrf_dir/modules_era && ./separation.sh") ;;variable.txt
    system("ln -sf $postwrf_dir/modules_era/variables.txt .")
    system("ln -sf $postwrf_dir/modules_era/totalequation.txt .")
    polynom3 = asciiread("variables.txt", -1, "string")
    asciiwrite (homedir+"/modules_era/variablesCN3.txt" , polynom3)
    system("ln -sf $postwrf_dir/modules_era/variablesCN3.txt .")
    vardims = dimsizes(polynom3)
    do ii = 0, vardims-1 ;;check if polynomial variables are valid
      if ( all(yy.ne.polynom3(ii)) ) then
        print("Found invalid variable name")
        delete(NCLCNVAR3)
        NCLCNVAR3 = ""
        NCL1VARONOFF = 0 ;;No need for the next var (VAR1)
        NCL2VARONOFF = 0
        if_valid = False
        break
      end if
    end do
  end if
end if

if ( NCL1VARONOFF.ne.1 ) then ;if is off, then no need to test the validity of variable
  NCLCNVAR1=yy(0)
  else
  varplus = str_match(NCLCNVAR1,"+")
  varminus = str_match(NCLCNVAR1,"-")
  varmult = str_match(NCLCNVAR1,"*")
  vardiv = str_match(NCLCNVAR1,"/")
  varexp = str_match(NCLCNVAR1,"^")
  varopenp = str_match(NCLCNVAR1,"(")
  varclosep = str_match(NCLCNVAR1,")")
  if( .not.ismissing(varplus) .or. .not.ismissing(varminus) .or. .not.ismissing(varmult) \
    .or. .not.ismissing(vardiv) .or. .not.ismissing(varexp) .or. .not.ismissing(varopenp) \
    .or. .not.ismissing(varclosep) ) then ;;if one is filled
    if_polynom = True
    if_polynom1 = if_polynom
    homedir = getenv("postwrf_dir")
    asciiwrite (homedir+"/modules_era/totalequation.txt" , NCLCNVAR1)
    asciiwrite (homedir+"/modules_era/totalequationCN1.txt" , NCLCNVAR1)
    system("cd $postwrf_dir/modules_era && ./separation.sh") ;;variable.txt
    system("ln -sf $postwrf_dir/modules_era/variables.txt .")
    system("ln -sf $postwrf_dir/modules_era/totalequation.txt .")
    polynom1 = asciiread("variables.txt", -1, "string")
    asciiwrite (homedir+"/modules_era/variablesCN1.txt" , polynom1)
    system("ln -sf $postwrf_dir/modules_era/variablesCN1.txt .")
    vardims = dimsizes(polynom1)
    do ii = 0, vardims-1 ;;check if polynomial variables are valid
      if ( all(yy.ne.polynom1(ii)) ) then
        print("Found invalid variable name")
        delete(NCLCNVAR1)
        NCLCNVAR1 = ""
        NCL2VARONOFF = 0  ;;var3 is passed, so no need for setting its value
        if_valid = False
        break
      end if
    end do
  end if
end if

if ( NCL2VARONOFF.ne.1 ) then
  NCLCNVAR2=yy(0)
  else
  varplus = str_match(NCLCNVAR2,"+")
  varminus = str_match(NCLCNVAR2,"-")
  varmult = str_match(NCLCNVAR2,"*")
  vardiv = str_match(NCLCNVAR2,"/")
  varexp = str_match(NCLCNVAR2,"^")
  varopenp = str_match(NCLCNVAR2,"(")
  varclosep = str_match(NCLCNVAR2,")")
  if( .not.ismissing(varplus) .or. .not.ismissing(varminus) .or. .not.ismissing(varmult) \
    .or. .not.ismissing(vardiv) .or. .not.ismissing(varexp) .or. .not.ismissing(varopenp) \
    .or. .not.ismissing(varclosep) ) then ;;if one is filled
    if_polynom = True
    if_polynom2 = if_polynom
    homedir = getenv("postwrf_dir")
    asciiwrite (homedir+"/modules_era/totalequation.txt" , NCLCNVAR2)
    asciiwrite (homedir+"/modules_era/totalequationCN2.txt" , NCLCNVAR2)
    system("cd $postwrf_dir/modules_era && ./separation.sh") ;;variable.txt
    system("ln -sf $postwrf_dir/modules_era/variables.txt .")
    system("ln -sf $postwrf_dir/modules_era/totalequation.txt .")
    polynom2 = asciiread("variables.txt", -1, "string")
    asciiwrite (homedir+"/modules_era/variablesCN2.txt" , polynom2)
    system("ln -sf $postwrf_dir/modules_era/variablesCN2.txt .")
    vardims = dimsizes(polynom2)
    do ii = 0, vardims-1 ;;check if polynomial variables are valid
      if ( all(yy.ne.polynom2(ii)) ) then
        print("Found invalid variable name")
        delete(NCLCNVAR2)
        NCLCNVAR2 = ""
        NCL2VARONOFF = 0  ;;var3 is passed, so no need for setting its value
        if_valid = False
        break
      end if
    end do
  end if
end if

if (if_polynom .and. if_valid) then ;;if not valid, do not exit, showing message of not valid
  poly_var = (/if_polynom1, if_polynom2, if_polynom3/)
  asciiwrite (homedir+"/modules_era/polynom_status.txt", poly_var)
  if (if_polynom3) then
    print("Please wait. NCL is processing ...")
    print("")
    system("cd $postwrf_dir/modules_era && ./contourlvl_sed3.sh") ;;sed
  end if
  if (if_polynom2) then
    print("Please wait. NCL is processing ...")
    print("")
    system("cd $postwrf_dir/modules_era && ./contourlvl_sed2.sh") ;;sed
  end if
  if (if_polynom1) then
    print("Please wait. NCL is processing ...")
    print("")
    system("cd $postwrf_dir/modules_era && ./contourlvl_sed1.sh") ;;sed
  end if
  system("cd $postwrf_dir/modules_era && ncl -Q contourlvl_era_equation.ncl")
  exit()
end if
if ( any(yy.eq.NCLCNVAR3) .and. any(yy.eq.NCLCNVAR1) .and. any(yy.eq.NCLCNVAR2) ) then  ;code att2
      if (isfilevar(aaa, "level")) then
        levs = aaa->level
        levdim = dimsizes(levs)-1
        highestPressureLev = levs(0)
        lowestPressureLev = levs(levdim)
      end if
      if (tointeger(getenv("era_subdom_onoff")) .ne. 1) then
        mylat = aaa->latitude
        mylon = aaa->longitude
        min_lat = min(mylat)
        max_lat = max(mylat)
        min_lon = min(mylon)
        max_lon = max(mylon)
        else
        min_lat = tointeger(getenv("era_minlat"))
        max_lat = tointeger(getenv("era_maxlat"))
        min_lon = tointeger(getenv("era_minlon"))
        max_lon = tointeger(getenv("era_maxlon"))
      end if
      
      if (NCL3VARONOFF .eq. 1) then ; code pprggvar1
        NCLPLEV3 = tointeger(getenv("CNLEV30")) ;pressure_levelsS
        cnmode = getenv("contvar")
        cnmin = getenv("Min")
        cnmax = getenv("Max")
        contourcolorpal = getenv("colpal")
       
          if (NCLCNVAR3 .eq. "wind_s") then
            if (isfilevar(aaa, "level")) then
              uu10  = short2flt(aaa->u)
              vv10  = short2flt(aaa->v)
              else
              uu10  = short2flt(aaa->u10)
              vv10  = short2flt(aaa->v10)
            end if
              tc3 = wind_speed(uu10, vv10)
              tc3@description = "wind speed"
              tc3@units = "m s-1"
           else if (NCLCNVAR3 .eq. "wind_d") then
            if (isfilevar(aaa, "level")) then
              uu10  := short2flt(aaa->u)
              vv10  := short2flt(aaa->v)
              else
              uu10  := short2flt(aaa->u10)
              vv10  := short2flt(aaa->v10)
            end if
              tc3 = wind_direction(uu10, vv10, 0)
              tc3@description = "wind direction"
              tc3@units = "Degrees from north"
           else if (NCLCNVAR3 .eq. "z") then
              print("Note:")
              print("z (geopotential - unit: m**2 s**-2) has been converted to geopotential-height (unit: decameter)")
              print("you can put z in polynomials which is treated as its original variable with unit: m**2 s**-2")
              print("")
              tc0 = short2flt(aaa->z)
              tc3 = tc0/98.1 ;convert to hectopascal
              copy_VarCoords(tc0, tc3)
              copy_VarAtts(tc0, tc3)
              delete(tc0)
              tc3@units = "Decameter"
            else
            tc3 = short2flt(aaa->$NCLCNVAR3$)
          end if
          end if
          end if

        mydim1 = dimsizes(dimsizes(tc3))

        if (mydim1.eq.3) then
            tc_plane33 = tc3
            tc_plane33@PlotLevelID = "surface"
          else ;if dimsize equals 4
            if (NCLPLEV3.eq.0) then ;surface pressure
                NCLPLEV3 = lowestPressureLev
                tc_plane33 = tc3(:, {NCLPLEV3}, :, :)
              else
                if (NCLPLEV3 .lt. highestPressureLev) then
                  print("Pressure level has been set to " + highestPressureLev)
                  NCLPLEV3 = highestPressureLev
                  else if (NCLPLEV3 .gt. lowestPressureLev) then
                    print("Pressure level has been set to " + lowestPressureLev)
                    NCLPLEV3 = lowestPressureLev
                  end if
                end if
                tc_plane33 = tc3(:, {NCLPLEV3}, :, :)
            end if
        end if
        if (isfilevar(aaa, "level")) then
          tc3@long_name := tc3@long_name + " at " + tc_plane33@level + " hpa"
        end if
        opt333                   = True
        opt333@gsnDraw           = False  ; do not draw plot yet (need False for paneling)
        opt333@gsnFrame          = False  ; do not frame plot yet (need False for paneling)
        opt333@cnFillOn          = True   ; fill contours
        opt333@cnFillPalette     = contourcolorpal ;"WhBlGrYeRe"
        opt333@cnFillDrawOrder   = "PreDraw"
        opt333@cnLinesOn         = False
        opt333@gsnLeftString     = ""
        opt333@gsnRightString    = ""
        opt333@tiMainFontHeightF = 0.018
        opt333@tiMainFontThicknessF = 0.2
        opt333@lbLabelStride     = 2      ; only print value for every other contour in label bar
        opt333@cnLineLabelDensityF = 1.5
        opt333@mpLandFillColor      = "transparent"
        opt333@mpShapeMode  = "FreeAspect"        
        if (ocean_onoff .eq. 1) then
          opt333@mpFillOn             = True
          opt333@mpOceanFillColor = "deepskyblue"
          opt333@mpInlandWaterFillColor = "deepskyblue"
          opt333@mpFillDrawOrder      = "draw" ;"PostDraw"          
        end if
        if (NCLgridline_onoff .eq. 1) then
          opt333@mpGridAndLimbOn = True
        end if
        opt333@cnLineThicknessF = 5
        opt333@cnLineLabelPlacementMode = "Constant"
        opt333@cnLineDashSegLenF = 0.2
        opt333@cnLineLabelInterval = 1
        opt333@vpWidthF      = 0.5
        opt333@vpHeightF     = 0.5
        opt333@cnLineLabelBackgroundColor = "Transparent"
        opt333@cnLineLabelFontHeightF = 0.019
        opt333@mpMinLatF         = min_lat
        opt333@mpMaxLatF         = max_lat
        opt333@mpMinLonF         = min_lon
        opt333@mpMaxLonF         = max_lon
        opt333@gsnAddCyclic = False
        opt333@mpOutlineBoundarySets = "AllBoundaries"
        opt333@mpGeophysicalLineThicknessF = nclborder_thick
        opt333@mpNationalLineThicknessF = nclborder_thick
        opt333@mpGeophysicalLineColor = nclborder
        opt333@mpNationalLineColor = nclborder

        ; Plotting options for T                
        opt333@cnFillOn = True
        if(cnmode .eq. "Manual") then  ; code abc123
          Nullcnmin = new(1,"logical")
          Nullcnmax = new(1,"logical")
          if ((cnmin .eq. "NULL") .or. (cnmax .eq. "NULL")) then
            stats = new(2,"float")
            perc_limit = (/0.0833,0.9166/)

            tc_planeone = ndtooned(tc_plane33)
            var_percentile = get_percentiles(tc_planeone,perc_limit)
            stats(0) = var_percentile(0)
            stats(1) = var_percentile(1)
            delete((tc_planeone))
          end if

          if (ncl_smooth.eq.1) then
            tc_plane33 := smth9_Wrap(tc_plane33, 0.5, -0.25, False)
          end if

          if (cnmin .eq. "NULL") then
          Nullcnmin = True
          MANcnmin = stats(0)
          end if

          if (cnmax .eq. "NULL") then
          Nullcnmax = True
          MANcnmax = stats(1)
          end if

          opt333@cnLevelSelectionMode = "ManualLevels"
          if (cnmin .eq. "NULL") then
            opt333@cnMinLevelValF = MANcnmin
            else
            cnmin3  = stringtofloat(cnmin)
            opt333@cnMinLevelValF = cnmin3
          end if
          if (cnmax .eq. "NULL") then
            opt333@cnMaxLevelValF = MANcnmax
            else
            cnmax3  = stringtofloat(cnmax)
            opt333@cnMaxLevelValF = cnmax3
          end if
        end if ; if for code abc123
      end if ;code pprggvar1

      ;;;;;####################################################################
      ;processing VAR1
      if (NCL1VARONOFF.eq.1) then  ;processing VAR2
        NCLPLEV1 = tointeger(getenv("CNLEV10")) ;pressure_level22
        NCLINTV1 = tofloat(getenv("CNINTV1"))
        NCLCOLOR1 = getenv("CNCOLOR1") ;NCLcolor22
        NCLTHICK1 = tofloat(getenv("CNTHICK1")) ;NCLthick22
        if (NCLTHICK1.le.1 .and. NCLTHICK1.ge.0) then
          NCLTHICK1 = 1 + NCLTHICK1*3
        else
          NCLTHICK1 = 2
        end if

        NCLLABEL1 = tofloat(getenv("CNLABEL1")) ;NCLlabel22
        if (NCLLABEL1.le.1 .and. NCLLABEL1.ge.0) then
          NCLLABEL1 = 0.01 + NCLLABEL1*0.02
        else
          NCLLABEL1 = 0.02
        end if
        
        if (NCLCNVAR1 .eq. "wind_s") then
          if (isfilevar(aaa, "level")) then
            uu10  = short2flt(aaa->u)
            vv10  = short2flt(aaa->v)
            else
            uu10  = short2flt(aaa->u10)
            vv10  = short2flt(aaa->v10)
          end if
            tc1 = wind_speed(uu10, vv10)
            tc1@description = "wind speed"
            tc1@units = "m s-1"
          else if (NCLCNVAR1 .eq. "wind_d") then
          if (isfilevar(aaa, "level")) then
            uu10  := short2flt(aaa->u)
            vv10  := short2flt(aaa->v)
            else
            uu10  := short2flt(aaa->u10)
            vv10  := short2flt(aaa->v10)
          end if
            tc1 = wind_direction(uu10, vv10, 0)
            tc1@description = "wind direction"
            tc1@units = "Degrees from north"
          else if (NCLCNVAR1 .eq. "z") then
            print("Note:")
            print("z (geopotential - unit: m**2 s**-2) has been converted to geopotential-height (unit: decameter)")
            print("you can put z in polynomials which is treated as its original variable with unit: m**2 s**-2")
            print("")
            tc0 = short2flt(aaa->z)
            tc1 = tc0/98.1 ;convert to hectopascal
            copy_VarCoords(tc0, tc1)
            copy_VarAtts(tc0, tc1)
            delete(tc0)
            tc1@units = "Decameter"
          else
          tc1 = short2flt(aaa->$NCLCNVAR1$)
          end if
          end if
        end if

        opt111                   = True
        opt111@gsnDraw           = False  ; do not draw plot yet (need False for paneling)
        opt111@gsnFrame          = False  ; do not frame plot yet (need False for paneling)
        opt111@cnFillOn          = False   ; fill contours
        opt111@cnLinesOn         = True
        opt111@gsnLeftStringFontColor = NCLCOLOR1
        opt111@gsnRightStringFontColor = NCLCOLOR1
        opt111@tiMainFontHeightF = 0.018
        opt111@tiMainFontThicknessF = 0.2
        opt111@lbLabelStride     = 2      ; only print value for every other contour in label bar
        opt111@cnLineLabelDensityF = 1.5
        opt111@mpLandFillColor        = "transparent"
        if (ocean_onoff .eq. 1) then
          opt111@mpFillOn               = True
          opt111@mpOceanFillColor       = "deepskyblue"
          opt111@mpInlandWaterFillColor = "deepskyblue"
          opt111@mpFillDrawOrder        =  "PreDraw" ;"PostDraw"          
        end if
        if (NCLgridline_onoff .eq. 1) then
          opt111@mpGridAndLimbOn = True
        end if
        opt111@gsnLeftStringFontHeightF = 0.017
        opt111@gsnRightStringFontHeightF = 0.017
        opt111@cnLineLabelPlacementMode = "Constant"
        opt111@cnLineDashSegLenF = 0.2
        opt111@cnLineLabelInterval = 1
        opt111@mpShapeMode  = "FreeAspect"
        opt111@vpWidthF      = 0.5
        opt111@vpHeightF     = 0.5
        opt111@cnLineLabelBackgroundColor = "Transparent"
        opt111@mpMinLatF         = min_lat
        opt111@mpMaxLatF         = max_lat
        opt111@mpMinLonF         = min_lon
        opt111@mpMaxLonF         = max_lon
        opt111@gsnAddCyclic = False
        opt111@mpOutlineOn = True
        opt111@mpOutlineBoundarySets = "AllBoundaries"
        opt111@mpGeophysicalLineThicknessF = nclborder_thick
        opt111@mpNationalLineThicknessF = nclborder_thick
        opt111@mpGeophysicalLineColor = nclborder
        opt111@mpNationalLineColor = nclborder
        opt111@cnLineColor = NCLCOLOR1
        opt111@cnLineThicknessF  = NCLTHICK1
        opt111@cnLineLabelFontHeightF = NCLLABEL1
        opt111@gsnContourNegLineDashPattern = 0
        opt111@gsnContourPosLineDashPattern = 0
        opt111@cnInfoLabelOn   = False
        if (NCL3VARONOFF.eq.1) then
          delete(opt111@mpShapeMode)
          delete(opt111@mpMinLatF)
          delete(opt111@mpMaxLatF)
          delete(opt111@mpMinLonF)
          delete(opt111@mpMaxLonF)
          delete(opt111@mpOutlineBoundarySets)
          delete(opt111@mpGeophysicalLineThicknessF)
          delete(opt111@mpNationalLineThicknessF)
          delete(opt111@mpGeophysicalLineColor)
          delete(opt111@mpNationalLineColor)
          delete(opt111@mpOutlineOn)
          delete(opt111@mpLandFillColor)
          if (ocean_onoff .eq. 1) then
            delete(opt111@mpFillOn)
            delete(opt111@mpOceanFillColor)
            delete(opt111@mpInlandWaterFillColor)
            delete(opt111@mpFillDrawOrder)
          end if
          if (NCLgridline_onoff .eq. 1) then
            delete(opt111@mpGridAndLimbOn)
          end if
        end if
        mydim2 = dimsizes(dimsizes(tc1))  
        if (mydim2.eq.3) then
          tc_plane11 = tc1
          tc_plane11@PlotLevelID = "surface"
          else ;if dimsize equals 4
          if (NCLPLEV1.eq.0) then ;surface pressure
                NCLPLEV1 = lowestPressureLev
                tc_plane11 = tc1(:, {NCLPLEV1}, :, :)
            else
              if (NCLPLEV1 .lt. highestPressureLev) then
                print("Pressure level has been set to " + highestPressureLev)
                NCLPLEV1 = highestPressureLev
                else if (NCLPLEV1 .gt. lowestPressureLev) then
                  print("Pressure level has been set to " + lowestPressureLev)
                  NCLPLEV1 = lowestPressureLev
                end if
              end if
              tc_plane11 = tc1(:, {NCLPLEV1}, :, :)
          end if
        end if
        if (isfilevar(aaa, "level")) then
          tc1@long_name := tc1@long_name + " at " + tc_plane11@level + " hpa"
        end if
        opt111@gsnLeftString = tc1@long_name

        if (ncl_smooth.eq.1) then
          tc_plane11 := smth9_Wrap(tc_plane11, 0.5, -0.25, False)
        end if
        
        stats1 = stat_dispersion(tc_plane11, False)
        max1 = stats1(14)
        min1 = stats1(2)
        high_quatile1 = stats1(10)
        low_quatile1 = stats1(6)
        iqr1 = high_quatile1 - low_quatile1
        upper_bound1 = high_quatile1 + 1.5*iqr1
        lower_bound1 = low_quatile1 - 1.5*iqr1
        if (upper_bound1 .gt. max1) then ;checking the whiskers of box 
          upper_bound1 = max1
        end if
        if (lower_bound1 .lt. min1) then ;checking the whiskers of box 
          lower_bound1 = min1
        end if
        intv_range2 = upper_bound1 - lower_bound1
        opt111@cnLevelSelectionMode = "ManualLevels"
        if (NCLINTV1.eq.0 .or. NCLINTV1.gt.intv_range2) then
          opt111@cnLevelSpacingF = intv_range2/10
        else
          opt111@cnLevelSpacingF = NCLINTV1
        end if
        opt111@cnMaxLevelValF = upper_bound1
        opt111@cnMinLevelValF = lower_bound1
        opt111@cnMaxLevelCount = 255
      end if ;end of VAR1

      ;;;;;####################################################################
      ;processing VAR2
      if (NCL2VARONOFF.eq.1) then  ;processing VAR3
        NCLPLEV2 = tointeger(getenv("CNLEV20")) ;pressure_level33
        NCLINTV2 = tofloat(getenv("CNINTV2")) ;NCLintv33
        NCLCOLOR2 = getenv("CNCOLOR2") ;NCLcolor33
        NCLTHICK2 = tofloat(getenv("CNTHICK2")) ;NCLthick33
        NCLBROKEN2 = tointeger(getenv("CNBROKEN2")) ;NCLbroken33

        if (NCLTHICK2.le.1 .and. NCLTHICK2.ge.0) then
          NCLTHICK2 = 1 + NCLTHICK2*3
        else
          NCLTHICK2 = 2
        end if

        NCLLABEL2 = tofloat(getenv("CNLABEL2")) ;NCLlabel33
        if (NCLLABEL2.le.1 .and. NCLLABEL2.ge.0) then
          NCLLABEL2 = 0.01 + NCLLABEL2*0.02
        else
          NCLLABEL2 = 0.02
        end if

        if (NCLCNVAR2 .eq. "wind_s") then
          if (isfilevar(aaa, "level")) then
            uu10  = short2flt(aaa->u)
            vv10  = short2flt(aaa->v)
            else
            uu10  = short2flt(aaa->u10)
            vv10  = short2flt(aaa->v10)
          end if
            tc2 = wind_speed(uu10, vv10)
            tc2@description = "wind speed"
            tc2@units = "m s-1"
          else if (NCLCNVAR2 .eq. "wind_d") then
          if (isfilevar(aaa, "level")) then
            uu10  := short2flt(aaa->u)
            vv10  := short2flt(aaa->v)
            else
            uu10  := short2flt(aaa->u10)
            vv10  := short2flt(aaa->v10)
          end if
            tc2 = wind_direction(uu10, vv10, 0)
            tc2@description = "wind direction"
            tc2@units = "Degrees from north"
          else if (NCLCNVAR2 .eq. "z") then
            print("Note:")
            print("z (geopotential - unit: m**2 s**-2) has been converted to geopotential-height (unit: decameter)")
            print("you can put z in polynomials which is treated as its original variable with unit: m**2 s**-2")
            print("")
            tc0 := short2flt(aaa->z)
            tc2 = tc0/98.1 ;convert to decameter
            copy_VarCoords(tc0, tc2)
            copy_VarAtts(tc0, tc2)
            delete(tc0)
            tc2@units = "Decameter"
          else
          tc2 = short2flt(aaa->$NCLCNVAR2$)
          end if
          end if
        end if

        opt222                   = True
        opt222@gsnDraw           = False  ; do not draw plot yet (need False for paneling)
        opt222@gsnFrame          = False  ; do not frame plot yet (need False for paneling)
        opt222@cnFillOn          = False   ; fill contours
        opt222@cnLinesOn         = True
        opt222@gsnLeftStringFontColor = NCLCOLOR2
        opt222@gsnRightStringFontColor = NCLCOLOR2
        opt222@tiMainFontHeightF = 0.018
        opt222@tiMainFontThicknessF = 0.2
        opt222@cnLineColor = NCLCOLOR2
        opt222@cnLineThicknessF  = NCLTHICK2
        opt222@cnLineLabelFontHeightF = NCLLABEL2
        opt222@gsnContourNegLineDashPattern = NCLBROKEN2
        opt222@gsnContourPosLineDashPattern = NCLBROKEN2
        opt222@cnInfoLabelOn   = False
        opt222@lbLabelStride     = 2      ; only print value for every other contour in label bar
        opt222@cnLineLabelDensityF = 1.5
        opt222@mpLandFillColor        = "transparent"
        if (ocean_onoff .eq. 1) then
          opt222@mpFillOn               = True
          opt222@mpOceanFillColor       = "deepskyblue"
          opt222@mpInlandWaterFillColor = "deepskyblue"
          opt222@mpFillDrawOrder        = "PreDraw" ;"PostDraw"          
        end if
        if (NCLgridline_onoff .eq. 1) then
          opt222@mpGridAndLimbOn = True
        end if
        opt222@gsnLeftStringFontHeightF = 0.017
        opt222@gsnRightStringFontHeightF = 0.017
        opt222@cnLineLabelPlacementMode = "Constant"
        opt222@cnLineDashSegLenF = 0.2
        opt222@cnLineLabelInterval = 1
        opt222@mpShapeMode  = "FreeAspect"
        opt222@vpWidthF      = 0.5
        opt222@vpHeightF     = 0.5
        opt222@cnLineLabelBackgroundColor = "Transparent"
        opt222@mpMinLatF         = min_lat
        opt222@mpMaxLatF         = max_lat
        opt222@mpMinLonF         = min_lon
        opt222@mpMaxLonF         = max_lon
        opt222@gsnAddCyclic = False
        opt222@mpOutlineOn = True
        opt222@mpOutlineBoundarySets = "AllBoundaries"
        opt222@mpGeophysicalLineThicknessF = nclborder_thick
        opt222@mpNationalLineThicknessF = nclborder_thick
        opt222@mpGeophysicalLineColor = nclborder
        opt222@mpNationalLineColor = nclborder
        if (NCL3VARONOFF.eq.1 .or. NCL1VARONOFF.eq.1) then
          delete(opt222@mpShapeMode)
          delete(opt222@mpMinLatF)
          delete(opt222@mpMaxLatF)
          delete(opt222@mpMinLonF)
          delete(opt222@mpMaxLonF)
          delete(opt222@mpOutlineBoundarySets)
          delete(opt222@mpGeophysicalLineThicknessF)
          delete(opt222@mpNationalLineThicknessF)
          delete(opt222@mpGeophysicalLineColor)
          delete(opt222@mpNationalLineColor)
          delete(opt222@mpOutlineOn)
          delete(opt222@mpLandFillColor)
          if (ocean_onoff .eq. 1) then
            delete(opt222@mpFillOn)
            delete(opt222@mpOceanFillColor)
            delete(opt222@mpInlandWaterFillColor)
            delete(opt222@mpFillDrawOrder)
          end if
          if (NCLgridline_onoff .eq. 1) then
            delete(opt222@mpGridAndLimbOn)
          end if
        end if
        mydim3 = dimsizes(dimsizes(tc2))  
        if (mydim3.eq.3) then
          tc_plane22 = tc2
          tc_plane22@PlotLevelID = "surface"
          else ;if dimsize equals 4
          if (NCLPLEV2.eq.0) then ;surface pressure
              NCLPLEV2 = lowestPressureLev
              tc_plane22 = tc2(:, {NCLPLEV2}, :, :)              
            else
              if (NCLPLEV2 .lt. highestPressureLev) then
                print("Pressure level has been set to " + highestPressureLev)
                NCLPLEV2 = highestPressureLev
                else if (NCLPLEV2 .gt. lowestPressureLev) then
                  print("Pressure level has been set to " + lowestPressureLev)
                  NCLPLEV2 = lowestPressureLev
                end if
              end if
              tc_plane22 = tc2(:, {NCLPLEV2}, :, :)
          end if
        end if
        if (isfilevar(aaa, "level")) then
          tc2@long_name := tc2@long_name + " at " + tc_plane22@level + " hpa"
        end if
        opt222@gsnLeftString = tc2@long_name

        if (ncl_smooth.eq.1) then
          tc_plane22 := smth9_Wrap(tc_plane22, 0.5, -0.25, False)
        end if
          
        stats2 = stat_dispersion(tc_plane22, False)
        max2 = stats2(14)
        min2 = stats2(2)
        high_quatile2 = stats2(10)
        low_quatile2 = stats2(6)
        iqr2 = high_quatile2 - low_quatile2
        upper_bound2 = high_quatile2 + 1.5*iqr2
        lower_bound2 = low_quatile2 - 1.5*iqr2
        if (upper_bound2 .gt. max2) then ;checking the whiskers of box 
          upper_bound2 = max2
        end if
        if (lower_bound2 .lt. min2) then ;checking the whiskers of box 
          lower_bound2 = min2
        end if
        intv_range3 = upper_bound2 - lower_bound2
        opt222@cnLevelSelectionMode = "ManualLevels"
        if (NCLINTV2.eq.0 .or. NCLINTV2.gt.intv_range3) then
          opt222@cnLevelSpacingF = intv_range3/10
        else
          opt222@cnLevelSpacingF = NCLINTV2
        end if
        opt222@cnMaxLevelValF = upper_bound2
        opt222@cnMinLevelValF = lower_bound2
        opt222@cnMaxLevelCount = 255
      end if ;end of VAR3

      if (NCLwindonoff .eq. 1)
        NCLwindlev = tointeger(getenv("nclwindlev"))
        NCLwindsize = tointeger(getenv("windsize"))
        NCLwinddens = tofloat(getenv("winddens"))
        NCLwindcolor = getenv("windcolor")
        NCLwindthick = tofloat(getenv("windthick"))
        windbarb = tointeger(getenv("windbarb_era"))
        opts = True
        if (isfilevar(aaa, "level")) then
          uu  = short2flt(aaa->u)
          vv  = short2flt(aaa->v)
          if (NCLwindlev.eq.0) then
            NCLwindlev = lowestPressureLev
            u_plane = uu(:, {NCLwindlev}, :, :)
            v_plane = vv(:, {NCLwindlev}, :, :)
            else
                if (NCLwindlev .lt. highestPressureLev) then
                  print("Pressure level has been set to " + highestPressureLev)
                  NCLwindlev = highestPressureLev
                  else if (NCLwindlev .gt. lowestPressureLev) then
                    print("Pressure level has been set to " + lowestPressureLev)
                    NCLwindlev = lowestPressureLev
                  end if
                end if
                u_plane = uu(:, {NCLwindlev}, :, :)
                v_plane = vv(:, {NCLwindlev}, :, :)
                opts@vcRefAnnoString2 = "at " + u_plane@level + " hpa"
          end if
          else
          u_plane = short2flt(aaa->u10)
          v_plane = short2flt(aaa->v10)
          opts@vcRefAnnoString2 = "at 10m"
        end if
        u_plane@long_name = "Wind speed"
        opts@vcRefMagnitudeF = NCLwindsize
        opts@gsnDraw = False
        opts@gsnFrame = False
        opts@gsnLeftString = ""
        opts@gsnRightString = ""
        opts@vcRefAnnoString1 = opts@vcRefMagnitudeF + " m/s"
        opts@vcRefLengthF      = 0.01   ; setting for nicely sized vectors
        opts@vcLineArrowColor = NCLwindcolor
        if (NCLwindthick.le.1 .and. NCLwindthick.ge.0) then
          opts@vcLineArrowThicknessF = 0.5 + 3*NCLwindthick ;; No need to else, cuase its default value is 1
        end if
        if (NCLwinddens.le.1 .and. NCLwinddens.ge.0) then
          opts@vcMinDistanceF = (1-NCLwinddens)*0.1 + 0.01
         else
          opts@vcMinDistanceF = 0.03
        end if
          opts@vcRefAnnoOn       = True
          if (windbarb.eq.1) then
            opts@vcGlyphStyle     = "WindBarb"
            opts@vcWindBarbColor  = NCLwindcolor
            opts@vcWindBarbScaleFactorF = 2
            if (NCLwindthick.le.1 .and. NCLwindthick.ge.0) then
              opts@vcWindBarbLineThicknessF = 0.5 + 4*NCLwindthick ;; No need to else, cuase its default value is 1
            end if
            opts@vcRefLengthF     = 0.03
          else
            opts@vcGlyphStyle     = "CurlyVector"
            if (NCLwindthick.le.1 .and. NCLwindthick.ge.0) then
              opts@vcLineArrowThicknessF = 0.5 + 4*NCLwindthick ;; No need to else, cuase its default value is 1
            end if
          end if
      end if

      if (ncl_shape_onoff.eq.1 .or. point_onoff.eq.1) then ;code iigg

        if (point_onoff.eq.1) then
          NCLlabelsize = tofloat(getenv("labelsize"))
          if (NCLlabelsize.le.1 .and. NCLlabelsize.ge.0) then
            NCLlabelsize = 0.005 + 0.025*NCLlabelsize
            else
            NCLlabelsize = 0.01
          end if
          NCLlabelcolor = getenv("labelcolor")
          pmres = True
          pmres@gsMarkerColor = NCLlabelcolor
          pmres@tfPolyDrawOrder = "PostDraw"
          if (panel_onoff.ne.1) then
            pmres@gsMarkerSizeF = NCLlabelsize
            else
            pmres@gsMarkerSizeF = NCLlabelsize/2
          end if
          pmres@gsMarkerIndex = 16
          tres       =  True
          tres@txFontHeightF = 2*NCLlabelsize
          tres@txFontColor = NCLlabelcolor
          totlocs = tointeger(getenv("ncllocs"))
          NCLlocnames = new(totlocs,"string")
          i=0
          do while(i.le.(totlocs-1))
          NCLlocnames(i) = getenv("ncllocnames"+i)
          i=i+1
          end do
          lines = tointeger(getenv("ncllats"))
          NCLloclats = new(lines,"float")
          i=0
          do while(i.le.(lines-1))
          NCLloclats(i) = tofloat(getenv("nclloclats"+i))
          i=i+1
          end do
          delete(lines)
          lines = tointeger(getenv("ncllons"))
          NCLloclons = new(lines,"float")
          i=0
          do while(i.le.(lines-1))
          NCLloclons(i) = tofloat(getenv("nclloclons"+i))
          i=i+1
          end do
        end if

        shpres = True
        shpres@gsLineColor = nclborder
        shpres@gsLineThicknessF = nclborder_thick
      end if ;code iigg

      if (panel_onoff.ne.1 .or. (NCLpanelrows.eq.1 .and. NCLpanelcolumns.eq.1)) then
        paneloption = False

        else ;;Panel 
        
        paneloption = True
        arrayplots = new (totstepsminus+1, graphic)
        pnlres                            = True
        pnlres@gsnPanelFigureStrings = (/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","AB","AC","AD","AE","AF","AG","AH"/)
        pnlres@gsnPanelFigureStringsJust = "topleft"
        pnlres@gsnPanelYWhiteSpacePercent = 5       ; Add white space b/w 
        pnlres@gsnPanelLabelBar           = False    ; Turn on common labelbar
        pnlres@lbLabelAutoStride          = True    ; Spacing of lbar labels.
        pnlres@lbBoxMinorExtentF          = 0.13
        pnlres@txString                   = tc3@long_name + " (" + tc3@units + " )"

        if (NCL3VARONOFF.eq.1 .and. cnmode.eq."Manual") then
          pnlres@gsnPanelLabelBar = True
          opt333@lbLabelBarOn = False
        end if

      end if

      over_plot = new (totstepsminus+1, graphic)
      dum1 = new (totstepsminus+1, graphic)

      ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
      ;; Time Loop
        kk = 0 ;for looping panel 
        jjprov = 0
        jj = 0
        wks = gsn_open_wks(type,filename)
        if (NCLaverage_onoff.ne.1) then ;code timeif122

          do it = time_first, time_last
            
            print("Working on time: " + all_steps(it))

              if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString    = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.48  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                opt111@gsnLeftString = tc1@long_name + "~C~" + " "
                opt111@gsnRightString = tc1@units + "~C~" + " "
                contour_tc1 = gsn_csm_contour(wks, tc_plane11(it,:,:), opt111)
                contour_tc2 = gsn_csm_contour(wks, tc_plane22(it,:,:), opt222)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc3, contour_tc1)
                overlay(contour_tc3, contour_tc2)
                overlay(contour_tc3, vector)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                opt111@gsnLeftString = tc1@long_name + "~C~" + " "
                opt111@gsnRightString = tc1@units + "~C~" + " "
                contour_tc1 = gsn_csm_contour(wks, tc_plane11(it,:,:), opt111)
                contour_tc2 = gsn_csm_contour(wks, tc_plane22(it,:,:), opt222)
                overlay(contour_tc3, contour_tc1)
                overlay(contour_tc3, contour_tc2)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.465  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                contour_tc1 = gsn_csm_contour(wks, tc_plane11(it,:,:), opt111)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc3, contour_tc1)
                overlay(contour_tc3, vector)
                plot = contour_tc3       
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                contour_tc1 = gsn_csm_contour(wks, tc_plane11(it,:,:), opt111)
                overlay(contour_tc3, contour_tc1)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .017
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.485  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                contour_tc2 = gsn_csm_contour(wks, tc_plane22(it,:,:), opt222)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc3, contour_tc2)
                overlay(contour_tc3, vector)
                plot = contour_tc3 
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                contour_tc2 = gsn_csm_contour(wks, tc_plane22(it,:,:), opt222)
                overlay(contour_tc3, contour_tc2)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opt333@gsnMaximize = True
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.48  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc3, vector)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
                opt333@gsnMaximize = True
                opt333@tiMainString = all_steps(it)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                ; opt333@lbTitleString = tc_plane33@long_name + " (" + tc_plane33@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                plot = gsn_csm_contour_map(wks, tc_plane33(it,:,:), opt333)
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt111@tiMainString = all_steps(it)
                opts@vcRefAnnoOrthogonalPosF = -0.1  ; 2 titles
                opt111@gsnMaximize = True
                contour_tc1 = gsn_csm_contour_map(wks, tc_plane11(it,:,:), opt111)
                contour_tc2 = gsn_csm_contour(wks, tc_plane22(it,:,:), opt222)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc1, contour_tc2)
                overlay(contour_tc1, vector)
                plot = contour_tc1
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt111@tiMainString = all_steps(it)
                opt111@gsnMaximize = True
                contour_tc1 = gsn_csm_contour_map(wks,tc_plane11(it,:,:),opt111)
                contour_tc2 = gsn_csm_contour(wks, tc_plane22(it,:,:), opt222)
                overlay(contour_tc1, contour_tc2)
                plot = contour_tc1
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opt111@tiMainString = all_steps(it)
                opts@vcRefAnnoOrthogonalPosF = -0.1  ; 1 titles
                opt111@gsnMaximize = True
                contour_tc1 = gsn_csm_contour_map(wks, tc_plane11(it,:,:), opt111)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc1, vector)
                plot = contour_tc1
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
                opt111@tiMainString = all_steps(it)
                opt111@gsnMaximize = True
                plot = gsn_csm_contour_map(wks, tc_plane11(it,:,:), opt111)
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt222@tiMainString = all_steps(it)
                opts@vcRefAnnoOrthogonalPosF = -0.1  ; 1 titles
                opt222@gsnMaximize = True
                contour_tc2 = gsn_csm_contour_map(wks, tc_plane22(it,:,:), opt222)
                vector = gsn_csm_vector(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
                overlay(contour_tc2, vector)
                plot = contour_tc2
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt222@tiMainString = all_steps(it)
                opt222@gsnMaximize = True
                plot = gsn_csm_contour_map(wks, tc_plane22(it,:,:), opt222)
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opts@tiMainString = all_steps(it)
                opts@vcRefAnnoOrthogonalPosF = -0.19
                opts@gsnMaximize = True
                opts@mpMinLatF         = min_lat
                opts@mpMaxLatF         = max_lat
                opts@mpMinLonF         = min_lon
                opts@mpMaxLonF         = max_lon
                opts@gsnAddCyclic = False
                opts@mpOutlineBoundarySets = "AllBoundaries"
                opts@mpGeophysicalLineThicknessF = nclborder_thick
                opts@mpNationalLineThicknessF = nclborder_thick
                opts@mpGeophysicalLineColor = nclborder
                opts@mpNationalLineColor = nclborder
                opts@mpLandFillColor = "transparent"
                opts@mpShapeMode = "FreeAspect"
                opts@vcRefAnnoOrthogonalPosF = -0.14
                if (ocean_onoff .eq. 1) then
                  opts@mpFillOn               = True
                  opts@mpOceanFillColor       = "deepskyblue"
                  opts@mpInlandWaterFillColor = "deepskyblue"
                  opts@mpFillDrawOrder        = "PreDraw"
                end if
                plot = gsn_csm_vector_map(wks, u_plane(it,:,:), v_plane(it,:,:), opts)
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if

              if (ncl_shape_onoff.eq.1 .or. point_onoff.eq.1) then
                if (point_onoff.eq.1) then
                  dum1(kk) = gsn_add_polymarker(wks, plot, NCLloclons, NCLloclats, pmres)
                end if
                if (label_onoff.eq.1) then
                  dum2 = gsn_add_text(wks,plot,NCLlocnames,NCLloclons,NCLloclats-(80*NCLlabelsize),tres)
                end if
                if (ncl_shape_onoff.eq.1) then
                  over_plot(kk) = gsn_add_shapefile_polylines(wks, plot, ncl_shape_path, shpres)
                end if
              end if

              if (.not.paneloption) then
                draw(plot)
                frame(wks)
              else
                arrayplots(kk) = plot
                delete(plot)
              end if
                
              kk = kk + 1
          end do        ; END OF TIME LOOP

          if (paneloption) then
            rowcol = NCLpanelrows*NCLpanelcolumns - 1
            tot_elements_minus = time_last - time_first
            i = 0
            do i = 0, tot_elements_minus
              if ((i+rowcol+1).gt.tot_elements_minus) then
                rowcol = mod(tot_elements_minus, (rowcol+1))
              end if
              gsn_panel(wks,(/arrayplots(i:(i+rowcol))/),(/NCLpanelrows,NCLpanelcolumns/),pnlres)
              i = i + rowcol
            end do
          end if

          else ;;Averaging code timeif122
          ; pnlres@txString                   = "Average " + tc3@long_name + " (" + tc3@units + " )"

            do it = time_first, time_last, ncltstep
              if ((it+ncltstep) .gt. time_last) then
                break
              end if
              print("Working on time range (average): " + all_steps(it) + " to " + all_steps(it+ncltstep) )
              if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString    = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.48  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep), :, :), 0), opt333)
                opt111@gsnLeftString = tc1@long_name + "~C~" + " "
                opt111@gsnRightString = tc1@units + "~C~" + " "
                contour_tc1 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep), :, :), 0), opt111)
                contour_tc2 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep), :, :), 0), opt222)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep), :, :), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep), :, :), 0), opts)
                overlay(contour_tc3, contour_tc1)
                overlay(contour_tc3, contour_tc2)
                overlay(contour_tc3, vector)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
                opt111@gsnLeftString = tc1@long_name + "~C~" + " "
                opt111@gsnRightString = tc1@units + "~C~" + " "
                contour_tc1 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0), opt111)
                contour_tc2 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
                overlay(contour_tc3, contour_tc1)
                overlay(contour_tc3, contour_tc2)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.465  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
                contour_tc1 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0), opt111)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:), 0), opts)
                overlay(contour_tc3, contour_tc1)
                overlay(contour_tc3, vector)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
                contour_tc1 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0), opt111)
                overlay(contour_tc3, contour_tc1)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .017
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.485  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
                contour_tc2 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep), :, :), 0), opts)
                overlay(contour_tc3, contour_tc2)
                overlay(contour_tc3, vector)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
                contour_tc2 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
                overlay(contour_tc3, contour_tc2)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opt333@gsnMaximize = True
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                opts@vcRefAnnoOrthogonalPosF = -0.48  ; 2 titles
                contour_tc3 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:), 0), opts)
                overlay(contour_tc3, vector)
                plot = contour_tc3
              else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
                opt333@gsnMaximize = True
                opt333@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt333@lbTitleString = tc3@long_name + " (" + tc3@units + ")"
                opt333@lbTitleFontHeightF = .015
                opt333@lbTopMarginF = 0.1
                opt333@lbTopMarginF = 0.2
                opt333@lbBottomMarginF = 0.4
                plot = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane33(it:(it+ncltstep),:,:), 0), opt333)
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt111@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opts@vcRefAnnoOrthogonalPosF = -0.1  ; 2 titles
                opt111@gsnMaximize = True
                contour_tc1 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0), opt111)
                contour_tc2 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:), 0), opts)
                overlay(contour_tc1, contour_tc2)
                overlay(contour_tc1, vector)
                plot = contour_tc1
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt111@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt111@gsnMaximize = True
                contour_tc1 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0),opt111)
                contour_tc2 = gsn_csm_contour(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
                overlay(contour_tc1, contour_tc2)
                plot = contour_tc1
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opt111@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opts@vcRefAnnoOrthogonalPosF = -0.1  ; 1 titles
                opt111@gsnMaximize = True
                contour_tc1 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0), opt111)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:), 0), opts)
                overlay(contour_tc1, vector)
                plot = contour_tc1
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
                opt111@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt111@gsnMaximize = True
                plot = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane11(it:(it+ncltstep),:,:), 0), opt111)
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
                opt222@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opts@vcRefAnnoOrthogonalPosF = -0.1  ; 1 titles
                opt222@gsnMaximize = True
                contour_tc2 = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
                vector = gsn_csm_vector(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:), 0), opts)
                overlay(contour_tc2, vector)
                plot = contour_tc2
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
                opt222@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opt222@gsnMaximize = True
                plot = gsn_csm_contour_map(wks, dim_avg_n_Wrap(tc_plane22(it:(it+ncltstep),:,:), 0), opt222)
              else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
                opts@tiMainString = "Average from " + all_steps(it) + " to " + all_steps(it+ncltstep)
                opts@vcRefAnnoOrthogonalPosF = -0.19
                opts@gsnMaximize = True
                opts@mpMinLatF         = min_lat
                opts@mpMaxLatF         = max_lat
                opts@mpMinLonF         = min_lon
                opts@mpMaxLonF         = max_lon
                opts@gsnAddCyclic = False
                opts@mpOutlineBoundarySets = "AllBoundaries"
                opts@mpGeophysicalLineThicknessF = nclborder_thick
                opts@mpNationalLineThicknessF = nclborder_thick
                opts@mpGeophysicalLineColor = nclborder
                opts@mpNationalLineColor = nclborder
                opts@mpLandFillColor = "transparent"
                opts@mpShapeMode = "FreeAspect"
                opts@vcRefAnnoOrthogonalPosF = -0.14
                if (ocean_onoff .eq. 1) then
                  opts@mpFillOn               = True
                  opts@mpOceanFillColor       = "deepskyblue"
                  opts@mpInlandWaterFillColor = "deepskyblue"
                  opts@mpFillDrawOrder        = "PreDraw"     
                end if
                plot = gsn_csm_vector_map(wks, dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:), 0), dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:), 0), opts)
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              end if
              if (ncl_shape_onoff.eq.1 .or. point_onoff.eq.1) then
                if (point_onoff.eq.1) then
                  dum1(kk) = gsn_add_polymarker(wks, plot, NCLloclons, NCLloclats, pmres)
                end if
                if (label_onoff.eq.1) then
                  dum2 = gsn_add_text(wks,plot,NCLlocnames,NCLloclons,NCLloclats-(80*NCLlabelsize),tres)
                end if
                if (ncl_shape_onoff.eq.1) then
                  over_plot(kk) = gsn_add_shapefile_polylines(wks,plot,ncl_shape_path,shpres)
                end if
              end if
              if (.not.paneloption) then
                draw(plot)
                frame(wks)
                else
                arrayplots(kk) = plot
                delete(plot)
              end if
              kk = kk + 1
            end do        ; END OF TIME LOOP

            if (paneloption) then
              rowcol = NCLpanelrows*NCLpanelcolumns - 1
              tot_elements_minus = (time_last - time_first)/ncltstep
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

      else
      print("")
      print("Error: one or more contour variables in namelist.wrf are not valid for " + myfilename)

end if ; code att2 

end
