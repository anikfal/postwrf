;PostWRF Version 1.1 (Apr 2020)
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
 nullchar = inttochar(0)
 var = str_match(myfile,"/" )

if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if

 NCLCNVAR3 = getenv("xCNVAR3") ;NCLcontours11
 NCLCNVAR1 = getenv("xCNVAR1") ;NCLcontours22
 NCLCNVAR2 = getenv("xCNVAR2") ;NCLcontours33
 varonoff_check = 0
 NCL1VARONOFF = tointeger(getenv("xFIRSTVAR_ONOFF")) ;NCLsecondvaronoffF
 if (NCL1VARONOFF .eq. 1) then
   varonoff_check = 1
 end if
 NCL2VARONOFF = tointeger(getenv("xSECONDVAR_ONOFF")) ;NCLthirdvaronoffF
 if (NCL2VARONOFF .eq. 1) then
   varonoff_check = varonoff_check + 2
 end if
 NCL3VARONOFF = tointeger(getenv("xTHIRDVAR_ONOFF"))
 if (NCL3VARONOFF .eq. 1) then
   varonoff_check = varonoff_check + 4
 end if
 
 ncl_smooth = tointeger(getenv("smooth_onoff"))
 NCLgridline_onoff = tointeger(getenv("gridline_onoff"))
 NCLspinup = tointeger(getenv("spinup"))
 NCLaverage_onoff = tointeger(getenv("average_onoff"))
 NCLaverage_time = tointeger(getenv("averagetime"))
 NCLtitle = tointeger(getenv("titile_option"))
 panel_onoff = tointeger(getenv("panelplot"))
 NCLpanelrows = tointeger(getenv("panelrows"))
 NCLpanelcolumns = tointeger(getenv("panelcolumns"))
 cross_path_onoff = tointeger(getenv("xcrosspath_ONOFF"))
 type = getenv("imgfmt")
 if (type .eq. "animated_gif") then
  type = "png"
 end if

  rescross                      = True
  rescross@lbLabelFontHeightF   = 0.01
  rescross@tmXBLabelFontHeightF = 0.01
  rescross@tmXBLabelAngleF      = 45.
  rescross@gsnDraw              = False             ; do not draw 
  rescross@gsnFrame             = False             ; do not advance the frame
  rescross@cnMissingValPerimOn = True
  rescross@cnMissingValPerimThicknessF = 4
  rescross@tmXBLabelFontHeightF = 0.015
  rescross@tiYAxisOn = True
  rescross@tiYAxisString = "Height (m)"

 optcross = True
 optcross@latlon      = True
 optcross@linecoords  = True
 optcross@file_handle = a

  nclcrosshght = stringtofloat(getenv("nclcrosshgt"))
  crossname = getenv("outname")

  all_steps=a->XTIME
  hourstep = (all_steps(1) - all_steps(0))/60
  if (NCLspinup.ge.hourstep) then
    start_timestep = tointeger(NCLspinup/hourstep)
    else
    start_timestep = 0
  end if
  times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
  totstepsminus = dimsizes(times)-1
  if (NCLaverage_onoff.ne.1) then
    ncltstep = tointeger(getenv("tstep"))
    ntimes = totstepsminus
    else
    ncltstep = tointeger(NCLaverage_time/hourstep)
    totstepsminus = totstepsminus - start_timestep
    ntimes = totstepsminus - mod(totstepsminus, ncltstep) - ncltstep
  end if
    homedir = getenv("postwrf_dir")
    polynoms_status = asciiread(homedir+"/modules/polynom_status.txt", -1, "string")

   z_press    = wrf_user_getvar(a, "z",-1)

  if (getenv("crossmode") .eq. "Two-points") then
  nclslat = stringtofloat(getenv("slat"))
  nclslon = stringtofloat(getenv("slon"))
  nclelat = stringtofloat(getenv("elat"))
  nclelon = stringtofloat(getenv("elon"))
  else
  nclplat = stringtofloat(getenv("plat"))
  nclplon = stringtofloat(getenv("plon"))
  optcross@use_pivot = True
  optcross@angle = stringtofloat(getenv("crossdir"))
 end if

if (NCL3VARONOFF .eq. 1) then ; code pprggvar1 var333
        cnmode = getenv("contvar")
        cnmin = getenv("Min")
        cnmax = getenv("Max")
        cnintv = getenv("Intv")
        contourcolorpal = getenv("colpal")
        
      if_polynom3 = polynoms_status(2)
            if (if_polynom3.eq."False")  ;;code ifpoly3

        if (NCLCNVAR3 .eq. "cape_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CAPE"
        slp1@units = "J/kg"
        tc = slp1(0,:,:,:)
        else if (NCLCNVAR3 .eq. "cin_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CIN"
        slp1@units = "J/kg"
        tc = slp1(1,:,:,:)
        else if (NCLCNVAR3 .eq. "cin_3d") then
          slp1  = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CIN"
          slp1@units = "J/kg"
          tc = slp1(1,:,:,:,:)
        else if (NCLCNVAR3 .eq. "cape_3d") then
          slp1 = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CAPE"
          slp1@units = "J/kg"
          tc = slp1(0,:,:,:,:)
          delete(slp1)
      else if (NCLCNVAR3 .eq. "lcl") then
          slp1  = wrf_user_getvar(a,"cape_2d",-1)
          slp1@description = "Lifting Condensation Level"
          slp1@units = "m"
          tc = slp1(2,:,:,:)
      else if (NCLCNVAR3 .eq. "lfc") then
          slp1 = wrf_user_getvar(a,"cape_2d",-1)
          slp1@description = "Level of Free Convection"
          slp1@units = "m"
          tc = slp1(2,:,:,:)

      else if (NCLCNVAR3 .eq. "dust_total") then
          tc  = a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
          copy_VarCoords(a->DUST_1,tc)
          tc@description = "Total dust concentration"
          tc@units = "Microgram/kg_dry_air"

      else if (NCLCNVAR3 .eq. "dust_pm2.5") then
          tc  = a->DUST_1+0.3125*a->DUST_2
          copy_VarCoords(a->DUST_1,tc)
          tc@description = "Dust_PM2.5 concentration"
          tc@units = "Microgram/kg_dry_air"

      else if (NCLCNVAR3 .eq. "dust_pm10") then
          tc  = a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
          copy_VarCoords(a->DUST_1,tc)
          tc@description = "Dust_PM10 concentration"
          tc@units = "Microgram/kg_dry_air"

      else if (NCLCNVAR3 .eq. "wind_s") then
          uu10  = wrf_user_getvar(a,"U10",-1)
          vv10  = wrf_user_getvar(a,"V10",-1)
          tc = wind_speed(uu10,vv10)
          tc@description = "10m wind speed"
          tc@units = "m s-1"

      else if (NCLCNVAR3 .eq. "wind_d") then
        if (.not.isdefined("uu10")) then
          uu10  = wrf_user_getvar(a,"U10",-1)
          vv10  = wrf_user_getvar(a,"V10",-1)
        end if
          tc = wind_direction(uu10,vv10,0)
          tc@description = "10m wind direction"
          tc@units = "Degrees from north"

      else
      tc = wrf_user_getvar(a,NCLCNVAR3,-1)        ; T in C

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

      mydim1 = dimsizes(dimsizes(tc))

      if (mydim1.lt.4) then
      print("The variable is wrong. It must have a bottom-top dimension. Exitting ...")
      exit()

        else ;if dimsize equals 4

        if (getenv("crossmode") .eq. "Two-points") then
        tc_plane3 = wrf_user_vert_cross(tc,z_press,(/nclslon,nclslat,nclelon,nclelat/),optcross)
        else
        tc_plane3 = wrf_user_vert_cross(tc,z_press,(/nclplon,nclplat/),optcross)
        end if

      end if

        else  ;;code ifpoly3

                NCLvarnames = asciiread("variablesCN3.txt", -1, "string")
              totvarsnum = dimsizes(NCLvarnames) - 1
          
              varlist2 = NewList("lifo")

              do ii = 0, totvarsnum ;;code do_poly3
                if (NCLvarnames(ii) .eq. "cape_surface") then
                tc3  = wrf_user_getvar(a,"cape_2d",-1)
                tc3@_FillValue=-1
                tc3@description = "CAPE"
                tc3@units = "J/kg"
                ListAppend(varlist2,tc3(0,:,:,:))

                else if (NCLvarnames(ii) .eq. "cin_surface") then
                  tc3  = wrf_user_getvar(a,"cape_2d",-1)
                  tc3@_FillValue=-1
                  tc3@description = "CIN"
                  tc3@units = "J/kg"
                  ListAppend(varlist2,tc3(1,:,:,:))

                else if (NCLvarnames(ii) .eq. "cin_3d") then
                    tc3  = wrf_user_getvar(a,"cape_3d",-1)
                    tc3@_FillValue=-1
                    tc3@description = "CIN"
                    tc3@units = "J/kg"
                    ListAppend(varlist2,tc3(1,:,:,:,:))

                else if (NCLvarnames(ii) .eq. "cape_3d") then
                    tc3  = wrf_user_getvar(a,"cape_3d",-1)
                    tc3@_FillValue=-1
                    tc3@description = "CAPE"
                    tc3@units = "J/kg"
                    ListAppend(varlist2,tc3(0,:,:,:,:))

                else if (NCLvarnames(ii) .eq. "lcl") then
                    tc3  = wrf_user_getvar(a,"cape_2d",-1)
                    tc3@description = "Lifting Condensation Level"
                    tc3@units = "m"
                    ListAppend(varlist2,tc3(2,:,:,:))

                else if (NCLvarnames(ii) .eq. "lfc") then
                    tc3  := wrf_user_getvar(a,"cape_2d",-1)
                    tc3@description = "Level of Free Convection"
                    tc3@units = "m"
                    ListAppend(varlist2,tc3(3,:,:,:))

                else if (NCLvarnames(ii) .eq. "dust_total") then
                    ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Total dust concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
                    ListAppend(varlist2,a->DUST_1+0.3125*a->DUST_2)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Dust_PM2.5 concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "dust_pm10") then
                    ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Dust_PM10 concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "wind_s") then
                    uu10  = wrf_user_getvar(a,"U10",-1)
                    vv10  = wrf_user_getvar(a,"V10",-1)
                    ListAppend(varlist2,wind_speed(uu10,vv10))
                    varlist2[ii]@description = "10m wind speed"
                    varlist2[ii]@units = "m s-1"

                else if (NCLvarnames(ii) .eq. "wind_d") then
                  if (.not.isdefined("uu10")) then
                    uu10  = wrf_user_getvar(a,"U10",-1)
                    vv10  = wrf_user_getvar(a,"V10",-1)
                  end if
                    ListAppend(varlist2,wind_direction(uu10,vv10,0))
                    varlist2[ii]@description = "10m wind direction"
                    varlist2[ii]@units = "Degrees from north"

                  else

                  ListAppend(varlist2,wrf_user_getvar(a,NCLvarnames(ii),-1))

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
              end do ;;code do_poly3
              delete(NCLvarnames)

              varlist = NewList("lifo") ;;main list and checking the dims
              do ii = 0, totvarsnum ;;code docheck22

      mydim1 = dimsizes(dimsizes(varlist2[ii]))

      if (mydim1.lt.4) then
      print("The variable is wrong. It must have a bottom-top dimension. Exitting ...")
      exit()

        else ;if dimsize equals 4

        if (getenv("crossmode") .eq. "Two-points") then
        ListAppend(varlist,wrf_user_vert_cross(varlist2[ii],z_press,(/nclslon,nclslat,nclelon,nclelat/),optcross))
        else
        ListAppend(varlist,wrf_user_vert_cross(varlist2[ii],z_press,(/nclplon,nclplat/),optcross))
        end if

      end if

      end do ;;code docheck22


              ;;shell script333
pvo = varlist[0]  ;;;added_new_line_by_sed333


                  ;equation from namelist.wrf333
tc_plane3 = pvo*1  ;;;added_new_line_by_sed333


            copy_VarCoords(varlist[0],tc_plane3)
            copy_VarAtts(varlist[0],tc_plane3)
            delete(varlist)
            delete(varlist2)

            system("cd $postwrf_dir/modules && ./contourlvl_getinput3.sh")
            system("ln -sf $postwrf_dir/modules/eqname $postwrf_dir")
            eqname3 = asciiread("eqname", -1, "string")
            system("ln -sf $postwrf_dir/modules/equnit $postwrf_dir")
            equnit3 = asciiread("equnit", -1, "string")
            tc_plane3@description = eqname3
            tc_plane3@units = equnit3

                end if ;;code ifpoly3

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

                    opt33 = rescross
                    opt33@cnFillOn             = True     ; turn on contour fill
                    opt33@cnLinesOn            = False    ; turn off contour lines
                    opt33@cnLineLabelsOn       = False    ; turn off line labels
                    opt33@lbLabelFontHeightF = 0.02
                    opt33@lbTitleFontHeightF = 0.025

                  if(contourcolorpal .eq. "BlueRed1") then
                    opt33@cnFillColors = BlueRed2
                  end if
                  if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
                    opt33@cnFillColors = WhiteYellowOrangeRed2
                  end if
                  if(contourcolorpal .eq. "WhBlGrYeRe1") then
                    opt33@cnFillColors = WhBlGrYeRe2
                  end if
                  if(contourcolorpal .eq. "MPL_gist_rainbow1") then
                    opt33@cnFillColors = MPL_gist_rainbow2
                  end if
                  if(contourcolorpal .eq. "rainbow1") then
                    opt33@cnFillColors = rainbow2
                  end if
                  if(contourcolorpal .eq. "WhiteGreen1") then
                    opt33@cnFillColors = WhiteGreen2
                  end if
                  if(contourcolorpal .eq. "MPL_Reds1") then
                    opt33@cnFillColors = MPL_Reds2
                  end if
                  if(contourcolorpal .eq. "WandB") then
                    opt33@cnFillColors = WandB2
                  end if
                  if(contourcolorpal .eq. "WhiteBlue1") then
                    opt33@cnFillColors = WhiteBlue2
                  end if
                  if(contourcolorpal .eq. "BandW") then
                    opt33@cnFillColors = BandW2
                  end if

            if(cnmode .eq. "Manual") then  ; code abc123
            Nullcnmin = new(1,"logical")
            Nullcnmax = new(1,"logical")
            if ((cnmin .eq. "NULL") .or. (cnmax .eq. "NULL") .or. (cnintv .eq. "NULL")) then
            stats = new(2,"float")
            perc_limit = (/0.0833,0.9166/)

            tc_planeone = ndtooned(tc_plane3)
            var_percentile = get_percentiles(tc_planeone,perc_limit)
            stats(0) = var_percentile(0)
            stats(1) = var_percentile(1)
            delete((tc_planeone))
            end if

              if (ncl_smooth.eq.1) then
                wrf_smooth_2d(tc_plane3,3)
              end if

            if (cnmin .eq. "NULL") then
            Nullcnmin = True
            MANcnmin = stats(0)
            end if

            if (cnmax .eq. "NULL") then
            Nullcnmax = True
            MANcnmax = stats(1)
            end if

            if (cnintv .eq. "NULL") then ; code abcnull
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
            end if ; code abcnull

            end if ; if for code abc123

            if(cnmode .eq. "Automatic") then  ; code abc123
                  if(contourcolorpal .eq. "BlueRed1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "WhBlGrYeRe1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "MPL_gist_rainbow1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "rainbow1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "WhiteGreen1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "MPL_Reds1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "WandB") then
                    opt33@cnMaxLevelCount = 9
                  end if
                  if(contourcolorpal .eq. "WhiteBlue1") then
                    opt33@cnMaxLevelCount = 11
                  end if
                  if(contourcolorpal .eq. "BandW") then
                    opt33@cnMaxLevelCount = 9
                  end if
            end if
              
                  if(cnmode .eq. "Manual") then
                  opt33@cnLevelSelectionMode = "ManualLevels"
                    if (cnmin .eq. "NULL") then
                    opt33@cnMinLevelValF = MANcnmin
                    else
                    cnmin3  = stringtofloat(cnmin)
                    opt33@cnMinLevelValF = cnmin3
                    end if
                    if (cnmax .eq. "NULL") then
                    opt33@cnMaxLevelValF = MANcnmax
                    else
                    cnmax3  = stringtofloat(cnmax)
                    opt33@cnMaxLevelValF = cnmax3
                    end if
                    if (cnintv .eq. "NULL") then
                    opt33@cnLevelSpacingF = MANcnintv
                    else
                    cnintv3  = stringtofloat(cnintv)
                    opt33@cnLevelSpacingF = cnintv3
                    end if
                  end if

                    opt33@cnLineLabelDensityF = 1
                    opt33@cnLineLabelInterval = 1
                    opt33@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
                    opt33@gsnContourLineThicknessesScale = 2.0
                    opt33@gsnContourLineThicknessesScale = 3.0
                    opt33@cnLineLabelFontHeightF = 0.025
                    opt33@cnHighLabelFontHeightF   = 0.03
end if ;code pprggvar1 var333

;;;;;####################################################################
;processing var111
if (NCL1VARONOFF.eq.1) then  ;processing var111
        NCLINTV1 = tofloat(getenv("xCNINTV1"))
        NCLCOLOR1 = getenv("xCNCOLOR1") ;NCLcolor2
        NCLTHICK1 = tofloat(getenv("xCNTHICK1")) ;NCLthick22
        if (NCLTHICK1.le.1 .and. NCLTHICK1.ge.0) then
          NCLTHICK1 = 1 + NCLTHICK1*3
        else
          NCLTHICK1 = 2
        end if

        NCLLABEL1 = tofloat(getenv("xCNLABEL1")) ;NCLlabel22
        if (NCLLABEL1.le.1 .and. NCLLABEL1.ge.0) then
          NCLLABEL1 = 0.01 + NCLLABEL1*0.02
        else
          NCLLABEL1 = 0.02
        end if

          opt11 = rescross
        
        opt11@cnFillOn = False
        opt11@cnLineColor = NCLCOLOR1
        opt11@cnLineLabelFontColor = NCLCOLOR1
        opt11@gsnLeftStringFontColor = NCLCOLOR1
        opt11@gsnRightStringFontColor = NCLCOLOR1
        opt11@cnLineThicknessF  = NCLTHICK1
        opt11@cnLineLabelFontHeightF = NCLLABEL1
        opt11@cnLineLabelInterval = 1
        opt11@cnLineLabelPlacementMode = "Constant"
        opt11@gsnContourNegLineDashPattern = 0
        opt11@gsnContourPosLineDashPattern = 0
        cnvar = NCLCNVAR1

      if_polynom1 = polynoms_status(0)
      if (if_polynom1.eq."False")  ;;code ifpoly1
        if (cnvar .eq. "cape_surface") then
        slp2 = wrf_user_getvar(a,"cape_2d",-1)
        slp2@_FillValue=-1
        slp2@description = "CAPE"
        slp2@units = "J/kg"
        tc11 = slp2(0,:,:,:)
        else if (cnvar .eq. "cin_surface") then
        slp2 = wrf_user_getvar(a,"cape_2d",-1)
        slp2@_FillValue=-1
        slp2@description = "CIN"
        slp2@units = "J/kg"
        tc11 = slp2(1,:,:,:)
        else if (cnvar .eq. "cin_3d") then
          slp2  = wrf_user_getvar(a,"cape_3d",-1)
          slp2@_FillValue=-1
          slp2@description = "CIN"
          slp2@units = "J/kg"
          tc11 = slp2(1,:,:,:,:)
        else if (cnvar .eq. "cape_3d") then
          slp2 = wrf_user_getvar(a,"cape_3d",-1)
          slp2@_FillValue=-1
          slp2@description = "CAPE"
          slp2@units = "J/kg"
          tc11 = slp2(0,:,:,:,:)
          delete(slp2)
        else if (cnvar .eq. "lcl") then
          slp2  = wrf_user_getvar(a,"cape_2d",-1)
          slp2@description = "Lifting Condensation Level"
          slp2@units = "m"
          tc11 = slp2(2,:,:,:)
        else if (cnvar .eq. "lfc") then
          slp2 = wrf_user_getvar(a,"cape_2d",-1)
          slp2@description = "Level of Free Convection"
          slp2@units = "m"
          tc11 = slp2(2,:,:,:)

        else if (cnvar .eq. "dust_total") then
          tc11  = a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
          copy_VarCoords(a->DUST_1,tc11)
          tc11@description = "Total dust concentration"
          tc11@units = "Microgram/kg_dry_air"

        else if (cnvar .eq. "dust_pm2.5") then
          tc11  = a->DUST_1+0.3125*a->DUST_2
          copy_VarCoords(a->DUST_1,tc11)
          tc11@description = "Dust_PM2.5 concentration"
          tc11@units = "Microgram/kg_dry_air"

        else if (cnvar .eq. "dust_pm10") then
          tc11  = a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
          copy_VarCoords(a->DUST_1,tc11)
          tc11@description = "Dust_PM10 concentration"
          tc11@units = "Microgram/kg_dry_air"

        else if (cnvar .eq. "wind_s") then
          uu10  = wrf_user_getvar(a,"U10",-1)
          vv10  = wrf_user_getvar(a,"V10",-1)
          tc11 = wind_speed(uu10,vv10)
          tc11@description = "10m wind speed"
          tc11@units = "m s-1"

        else if (cnvar .eq. "wind_d") then
          if (.not.isdefined("uu10")) then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
          end if
            tc11 = wind_direction(uu10,vv10,0)
            tc11@description = "10m wind direction"
            tc11@units = "Degrees from north"

        else
        tc11 = wrf_user_getvar(a,cnvar,-1)        ; T in C

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

        mydim2 = dimsizes(dimsizes(tc11))  
      if (mydim2.lt.4) then
        print("The variable is wrong. It must have a bottom-top dimension. Exitting ...")
        exit()

        else ;if dimsize equals 4

        if (getenv("crossmode") .eq. "Two-points") then
          tc_plane1 = wrf_user_vert_cross(tc11,z_press,(/nclslon,nclslat,nclelon,nclelat/),optcross)
          else
          tc_plane1 = wrf_user_vert_cross(tc11,z_press,(/nclplon,nclplat/),optcross)
        end if
      
      end if

      else ;;code ifpoly1

        NCLvarnames = asciiread("variablesCN1.txt", -1, "string")
        totvarsnum = dimsizes(NCLvarnames) - 1

                varlist2 = NewList("lifo")

              do ii = 0, totvarsnum ;;code do_poly1
                if (NCLvarnames(ii) .eq. "cape_surface") then
                tc3  = wrf_user_getvar(a,"cape_2d",-1)
                tc3@_FillValue=-1
                tc3@description = "CAPE"
                tc3@units = "J/kg"
                ListAppend(varlist2,tc3(0,:,:,:))

                else if (NCLvarnames(ii) .eq. "cin_surface") then
                  tc3  = wrf_user_getvar(a,"cape_2d",-1)
                  tc3@_FillValue=-1
                  tc3@description = "CIN"
                  tc3@units = "J/kg"
                  ListAppend(varlist2,tc3(1,:,:,:))

                else if (NCLvarnames(ii) .eq. "cin_3d") then
                    tc3  = wrf_user_getvar(a,"cape_3d",-1)
                    tc3@_FillValue=-1
                    tc3@description = "CIN"
                    tc3@units = "J/kg"
                    ListAppend(varlist2,tc3(1,:,:,:,:))

                else if (NCLvarnames(ii) .eq. "cape_3d") then
                    tc3  = wrf_user_getvar(a,"cape_3d",-1)
                    tc3@_FillValue=-1
                    tc3@description = "CAPE"
                    tc3@units = "J/kg"
                    ListAppend(varlist2,tc3(0,:,:,:,:))

                else if (NCLvarnames(ii) .eq. "lcl") then
                    tc3  = wrf_user_getvar(a,"cape_2d",-1)
                    tc3@description = "Lifting Condensation Level"
                    tc3@units = "m"
                    ListAppend(varlist2,tc3(2,:,:,:))

                else if (NCLvarnames(ii) .eq. "lfc") then
                    tc3  := wrf_user_getvar(a,"cape_2d",-1)
                    tc3@description = "Level of Free Convection"
                    tc3@units = "m"
                    ListAppend(varlist2,tc3(3,:,:,:))

                else if (NCLvarnames(ii) .eq. "dust_total") then
                    ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Total dust concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
                    ListAppend(varlist2,a->DUST_1+0.3125*a->DUST_2)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Dust_PM2.5 concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "dust_pm10") then
                    ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Dust_PM10 concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "wind_s") then
                    uu10  = wrf_user_getvar(a,"U10",-1)
                    vv10  = wrf_user_getvar(a,"V10",-1)
                    ListAppend(varlist2,wind_speed(uu10,vv10))
                    varlist2[ii]@description = "10m wind speed"
                    varlist2[ii]@units = "m s-1"

                else if (NCLvarnames(ii) .eq. "wind_d") then
                  if (.not.isdefined("uu10")) then
                    uu10  = wrf_user_getvar(a,"U10",-1)
                    vv10  = wrf_user_getvar(a,"V10",-1)
                  end if
                    ListAppend(varlist2,wind_direction(uu10,vv10,0))
                    varlist2[ii]@description = "10m wind direction"
                    varlist2[ii]@units = "Degrees from north"

                  else

                  ListAppend(varlist2,wrf_user_getvar(a,NCLvarnames(ii),-1))

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
              end do ;;code do_poly3
              delete(NCLvarnames)

              varlist = NewList("lifo") ;;main list and checking the dims
              do ii = 0, totvarsnum ;;code docheck22

      mydim1 = dimsizes(dimsizes(varlist2[ii]))

      if (mydim1.lt.4) then
      print("The variable is wrong. It must have a bottom-top dimension. Exitting ...")
      exit()

        else ;if dimsize equals 4

        if (getenv("crossmode") .eq. "Two-points") then
        ListAppend(varlist,wrf_user_vert_cross(varlist2[ii],z_press,(/nclslon,nclslat,nclelon,nclelat/),optcross))
        else
        ListAppend(varlist,wrf_user_vert_cross(varlist2[ii],z_press,(/nclplon,nclplat/),optcross))
        end if

      end if
      end do ;;code docheck22

              ;;shell script111
tk = varlist[0]  ;;;added_new_line_by_sed111


        ;equation from namelist.wrf111
tc_plane1 = tk*1  ;;;added_new_line_by_sed111

copy_VarCoords(varlist[0],tc_plane1)
copy_VarAtts(varlist[0],tc_plane1)
delete(varlist)
delete(varlist2)


system("cd $postwrf_dir/modules && ./contourlvl_getinput1.sh")
system("ln -sf $postwrf_dir/modules/eqname $postwrf_dir")
eqname1 = asciiread("eqname", -1, "string")
system("ln -sf $postwrf_dir/modules/equnit $postwrf_dir")
equnit1 = asciiread("equnit", -1, "string")
tc_plane1@description = eqname1
tc_plane1@units = equnit1

end if ;;code ifpoly1

  if (ncl_smooth.eq.1) then
    wrf_smooth_2d(tc_plane1,3)
  end if
  
  stats1 = stat_dispersion(tc_plane1, False)
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
  opt11@cnLevelSelectionMode = "ManualLevels"
  if (NCLINTV1.eq.0 .or. NCLINTV1.gt.intv_range2) then
    opt11@cnLevelSpacingF = intv_range2/10
  else
    opt11@cnLevelSpacingF = NCLINTV1
  end if
  opt11@cnMaxLevelValF = upper_bound1
  opt11@cnMinLevelValF = lower_bound1
  opt11@cnMaxLevelCount = 255

end if ;end of var111

;;;;;####################################################################
;;;;;####################################################################
;processing var222
if (NCL2VARONOFF.eq.1) then  ;processing var222
      NCLINTV2 = tofloat(getenv("xCNINTV2")) ;NCLintv33
      NCLCOLOR2 = getenv("xCNCOLOR2") ;NCLcolor33
      NCLTHICK2 = tofloat(getenv("xCNTHICK2")) ;NCLthick33
      NCLBROKEN2 = tointeger(getenv("xCNBROKEN2")) ;NCLbroken33

      if (NCLTHICK2.le.1 .and. NCLTHICK2.ge.0) then
        NCLTHICK2 = 1 + NCLTHICK2*3
      else
        NCLTHICK2 = 2
      end if

      NCLLABEL2 = tofloat(getenv("xCNLABEL2")) ;NCLlabel33
      if (NCLLABEL2.le.1 .and. NCLLABEL2.ge.0) then
        NCLLABEL2 = 0.01 + NCLLABEL2*0.02
      else
        NCLLABEL2 = 0.02
      end if

      opt22 = rescross
      opt22@cnFillOn = False
      opt22@cnLineColor = NCLCOLOR2
      opt22@cnLineLabelFontColor = NCLCOLOR2
      opt22@gsnLeftStringFontColor = NCLCOLOR2
      opt22@gsnRightStringFontColor = NCLCOLOR2
      opt22@cnLineThicknessF  = NCLTHICK2
      opt22@cnLineLabelFontHeightF = NCLLABEL2
      opt22@gsnContourNegLineDashPattern = NCLBROKEN2
      opt22@gsnContourPosLineDashPattern = NCLBROKEN2
      opt22@cnLineLabelInterval = 1
      opt22@cnLineLabelPlacementMode = "Constant"
      cnvar = NCLCNVAR2

      if_polynom2 = polynoms_status(1)
      if (if_polynom2.eq."False")  ;;code ifpoly2

      if (cnvar .eq. "cape_surface") then
      slp3 = wrf_user_getvar(a,"cape_2d",-1)
      slp3@_FillValue=-1
      slp3@description = "CAPE"
      slp3@units = "J/kg"
      tc22 = slp3(0,:,:,:)
      else if (cnvar .eq. "cin_surface") then
      slp3 = wrf_user_getvar(a,"cape_2d",-1)
      slp3@_FillValue=-1
      slp3@description = "CIN"
      slp3@units = "J/kg"
      tc22 = slp3(1,:,:,:)
      else if (cnvar .eq. "cin_3d") then
        slp3  = wrf_user_getvar(a,"cape_3d",-1)
        slp3@_FillValue=-1
        slp3@description = "CIN"
        slp3@units = "J/kg"
        tc22 = slp3(1,:,:,:,:)
      else if (cnvar .eq. "cape_3d") then
        slp3 = wrf_user_getvar(a,"cape_3d",-1)
        slp3@_FillValue=-1
        slp3@description = "CAPE"
        slp3@units = "J/kg"
        tc22 = slp3(0,:,:,:,:)
        delete(slp3)
      else if (cnvar .eq. "lcl") then
        slp3  = wrf_user_getvar(a,"cape_2d",-1)
        slp3@description = "Lifting Condensation Level"
        slp3@units = "m"
        tc22 = slp3(2,:,:,:)
      else if (cnvar .eq. "lfc") then
        slp3 = wrf_user_getvar(a,"cape_2d",-1)
        slp3@description = "Level of Free Convection"
        slp3@units = "m"
        tc22 = slp3(2,:,:,:)

      else if (cnvar .eq. "dust_total") then
        tc22  = a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
        copy_VarCoords(a->DUST_1,tc22)
        tc22@description = "Total dust concentration"
        tc22@units = "Microgram/kg_dry_air"

      else if (cnvar .eq. "dust_pm2.5") then
        tc22  = a->DUST_1+0.3125*a->DUST_2
        copy_VarCoords(a->DUST_1,tc22)
        tc22@description = "Dust_PM2.5 concentration"
        tc22@units = "Microgram/kg_dry_air"

      else if (cnvar .eq. "dust_pm10") then
        tc22  = a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
        copy_VarCoords(a->DUST_1,tc22)
        tc22@description = "Dust_PM10 concentration"
        tc22@units = "Microgram/kg_dry_air"

        else if (cnvar .eq. "wind_s") then
        uu10  = wrf_user_getvar(a,"U10",-1)
        vv10  = wrf_user_getvar(a,"V10",-1)
        tc22 = wind_speed(uu10,vv10)
        tc22@description = "10m wind speed"
        tc22@units = "m s-1"

      else if (cnvar .eq. "wind_d") then
        if (.not.isdefined("uu10")) then
          uu10  = wrf_user_getvar(f,"U10",-1)
          vv10  = wrf_user_getvar(f,"V10",-1)
        end if
          tc22 = wind_direction(uu10,vv10,0)
          tc22@description = "10m wind direction"
          tc22@units = "Degrees from north"

      else
      tc22 = wrf_user_getvar(a,cnvar,-1)        ; T in C

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

      mydim3 = dimsizes(dimsizes(tc22))  
    if (mydim3.eq.3) then
      print("The variable is wrong. It must have a bottom-top dimension. Exitting ...")
      exit()
      else ;if dimsize equals 4
      if (getenv("crossmode") .eq. "Two-points") then
        tc_plane2 = wrf_user_vert_cross(tc22,z_press,(/nclslon,nclslat,nclelon,nclelat/),optcross)
        else
        tc_plane2 = wrf_user_vert_cross(tc22,z_press,(/nclplon,nclplat/),optcross)
      end if
      end if
      
  else ;;code ifpoly2

        NCLvarnames = asciiread("variablesCN2.txt", -1, "string")
        totvarsnum = dimsizes(NCLvarnames) - 1
                        varlist2 = NewList("lifo")

              do ii = 0, totvarsnum ;;code do_poly2
                if (NCLvarnames(ii) .eq. "cape_surface") then
                tc3  = wrf_user_getvar(a,"cape_2d",-1)
                tc3@_FillValue=-1
                tc3@description = "CAPE"
                tc3@units = "J/kg"
                ListAppend(varlist2,tc3(0,:,:,:))

                else if (NCLvarnames(ii) .eq. "cin_surface") then
                  tc3  = wrf_user_getvar(a,"cape_2d",-1)
                  tc3@_FillValue=-1
                  tc3@description = "CIN"
                  tc3@units = "J/kg"
                  ListAppend(varlist2,tc3(1,:,:,:))

                else if (NCLvarnames(ii) .eq. "cin_3d") then
                    tc3  = wrf_user_getvar(a,"cape_3d",-1)
                    tc3@_FillValue=-1
                    tc3@description = "CIN"
                    tc3@units = "J/kg"
                    ListAppend(varlist2,tc3(1,:,:,:,:))

                else if (NCLvarnames(ii) .eq. "cape_3d") then
                    tc3  = wrf_user_getvar(a,"cape_3d",-1)
                    tc3@_FillValue=-1
                    tc3@description = "CAPE"
                    tc3@units = "J/kg"
                    ListAppend(varlist2,tc3(0,:,:,:,:))

                else if (NCLvarnames(ii) .eq. "lcl") then
                    tc3  = wrf_user_getvar(a,"cape_2d",-1)
                    tc3@description = "Lifting Condensation Level"
                    tc3@units = "m"
                    ListAppend(varlist2,tc3(2,:,:,:))

                else if (NCLvarnames(ii) .eq. "lfc") then
                    tc3  := wrf_user_getvar(a,"cape_2d",-1)
                    tc3@description = "Level of Free Convection"
                    tc3@units = "m"
                    ListAppend(varlist2,tc3(3,:,:,:))

                else if (NCLvarnames(ii) .eq. "dust_total") then
                    ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Total dust concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
                    ListAppend(varlist2,a->DUST_1+0.3125*a->DUST_2)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Dust_PM2.5 concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "dust_pm10") then
                    ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4)
                    copy_VarCoords(a->DUST_1,varlist2[ii])
                    varlist2[ii]@description = "Dust_PM10 concentration"
                    varlist2[ii]@units = "Microgram/kg_dry_air"

                else if (NCLvarnames(ii) .eq. "wind_s") then
                    uu10  = wrf_user_getvar(a,"U10",-1)
                    vv10  = wrf_user_getvar(a,"V10",-1)
                    ListAppend(varlist2,wind_speed(uu10,vv10))
                    varlist2[ii]@description = "10m wind speed"
                    varlist2[ii]@units = "m s-1"

                else if (NCLvarnames(ii) .eq. "wind_d") then
                  if (.not.isdefined("uu10")) then
                    uu10  = wrf_user_getvar(a,"U10",-1)
                    vv10  = wrf_user_getvar(a,"V10",-1)
                  end if
                    ListAppend(varlist2,wind_direction(uu10,vv10,0))
                    varlist2[ii]@description = "10m wind direction"
                    varlist2[ii]@units = "Degrees from north"

                  else

                  ListAppend(varlist2,wrf_user_getvar(a,NCLvarnames(ii),-1))

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
              end do ;;code do_poly2
              delete(NCLvarnames)

              varlist = NewList("lifo") ;;main list and checking the dims
              do ii = 0, totvarsnum ;;code docheck22

      mydim1 = dimsizes(dimsizes(varlist2[ii]))

      if (mydim1.lt.4) then
      print("The variable is wrong. It must have a bottom-top dimension. Exitting ...")
      exit()

        else ;if dimsize equals 4

        if (getenv("crossmode") .eq. "Two-points") then
        ListAppend(varlist,wrf_user_vert_cross(varlist2[ii],z_press,(/nclslon,nclslat,nclelon,nclelat/),optcross))
        else
        ListAppend(varlist,wrf_user_vert_cross(varlist2[ii],z_press,(/nclplon,nclplat/),optcross))
        end if
      end if
      end do ;;code docheck22

              ;;shell script222
td = varlist[1]  ;;;added_new_line_by_sed222
rh = varlist[0]  ;;;added_new_line_by_sed222


        ;equation from namelist.wrf222
tc_plane2 = (rh*td/10)^2  ;;;added_new_line_by_sed222


      copy_VarCoords(varlist[0],tc_plane2)
      copy_VarAtts(varlist[0],tc_plane2)
      delete(varlist)
      delete(varlist2)


      system("cd $postwrf_dir/modules && ./contourlvl_getinput2.sh")
      system("ln -sf $postwrf_dir/modules/eqname $postwrf_dir")
      eqname2 = asciiread("eqname", -1, "string")
      system("ln -sf $postwrf_dir/modules/equnit $postwrf_dir")
      equnit2 = asciiread("equnit", -1, "string")
      tc_plane2@description = eqname2
      tc_plane2@units = equnit2

  end if ;;code ifpoly2

      if (ncl_smooth.eq.1) then
        wrf_smooth_2d(tc_plane2,3)
      end if
        
      stats2 = stat_dispersion(tc_plane2, False)
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
      opt22@cnLevelSelectionMode = "ManualLevels"

      if (NCLINTV2.eq.0 .or. NCLINTV2.gt.intv_range3) then
        opt22@cnLevelSpacingF = intv_range3/10
      else
        opt22@cnLevelSpacingF = NCLINTV2
      end if
      opt22@cnMaxLevelValF = upper_bound2
      opt22@cnMinLevelValF = lower_bound2
      opt22@cnMaxLevelCount = 255

end if ;end of var222

if (panel_onoff.ne.1 .or. (NCLpanelrows.eq.1 .and. NCLpanelcolumns.eq.1)) then
  paneloption = False

 else ;;Panelplot

  paneloption = True
  arrayplots = new (totstepsminus+1, graphic)
  pnlres                            = True
  pnlres@gsnPanelFigureStrings = (/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","AB","AC","AD","AE","AF","AG","AH"/)
  pnlres@gsnPanelFigureStringsJust = "topleft"
 pnlres@gsnPanelYWhiteSpacePercent = 5      
 pnlres@gsnPanelLabelBar           = False    ; Turn on common labelbar
 pnlres@lbLabelAutoStride          = True    ; Spacing of lbar labels.
 pnlres@lbBoxMinorExtentF          = 0.13
end if

over_plot = new (totstepsminus+1, graphic)
dum1 = new (totstepsminus+1, graphic)

wks = gsn_open_wks(type,crossname)
;; Time Loop
  kk = 0 
  cross_path_used = False
  cross_path_used11 = False
    if (NCLaverage_onoff.ne.1) then ;code timeif122

      do it = start_timestep, ntimes, ncltstep
        
        print("Working on time: " + times(it))

        pltres = True
        pltres@FontHeightF = 0.013 ;;no panl, no average

          if (NCL3VARONOFF.eq.1) then
          totxaxis_steps = dimsizes(tc_plane3(0,0,:))-1
          xvalues := ispan(0,totxaxis_steps,1)
          ll_step = tointeger(totxaxis_steps/6)+1                                       ; step interval for tickmarks
          opt33@tmXBMode          = "Explicit"
          opt33@tmXBValues        = xvalues(::ll_step)
          opt33@tmXBLabels        = sprintf("%6.2f",tc_plane3@lats(::ll_step)) + "~S~o~N~N~C~" + \
                                  sprintf("%6.2f",tc_plane3@lons(::ll_step)) + "~S~o~N~E"
           opt33@pmLabelBarHeightF     = 0.08
           opt33@tiMainString = times(it)
           opt33@lbTitleString  = tc_plane3@description + " (" + tc_plane3@units + ")"
           
           if (varonoff_check .eq. 4) then
            opt33@gsnRightString = tc_plane3@units ;+ "~C~" + " "
            opt33@gsnLeftString = tc_plane3@description ;+ "~C~" + " "
            else
            opt33@gsnRightString = tc_plane3@units + "~C~~C~~C~" + " "
            opt33@gsnLeftString = tc_plane3@description + "~C~~C~~C~" + " "
           end if
          if (NCLtitle .ne. 1) then
           opt33@gsnRightString = ""
           opt33@gsnLeftString = ""
          end if
           

            if ( cross_path_onoff .ne. 1 ) then
              contour_tc = gsn_csm_contour(wks,tc_plane3(it,:,:),opt33)
              else
              cross_path_used = True
              cross_path_used11 = True  ;use in the next (var 2) variable
              contour_tc = gsn_csm_contour(wks,tc_plane3(it,:,:),opt33)
              mpwrf_res  = True
              mpwrf_res@vpWidthF          = 0.2     ; make map much smaller
              mpwrf_res@vpHeightF         = 0.2
              mpwrf_res@gsnDraw           = False
              mpwrf_res@gsnFrame          = False

              mpwrf_res = wrf_map_resources(a,mpwrf_res)     ; Use WRF map projection
              mpwrf_res@pmTickMarkDisplayMode = "Never"     ; turns off map tickmarks and labels
              mpwrf_res@mpPerimLineColor      = "Black"     ; wrf_map_resources sets this to gray
              topovaronoff = stringtofloat(getenv("crosstopo"))
              if (topovaronoff .ne. 1) then
                mpwrf_res@mpFillColors = (/"transparent","blue","gray97","blue", "transparent"/)
                map_plot = gsn_csm_map(wks,mpwrf_res)
                else
                ter = wrf_user_getvar(a, "HGT", 0)
                ter@lat2d = a->XLAT(0,:,:)
                ter@lon2d = a->XLONG(0,:,:)
                mpwrf_res@cnFillOn = True
                cmap = read_colormap_file("OceanLakeLandSnow")
                mpwrf_res@cnFillPalette      = cmap(2:,:)
                mpwrf_res@cnLinesOn = False
                mpwrf_res@lbLabelBarOn = False
                mpwrf_res@cnInfoLabelOn      = False
                mpwrf_res@mpGeophysicalLineThicknessF = 2
                mpwrf_res@mpGeophysicalLineColor = "black"
                mpwrf_res@gsnLeftString = ""
                mpwrf_res@gsnRightString = ""
                map_plot = gsn_csm_contour_map(wks, ter, mpwrf_res)
              end if

              mkres                  = True
              mkres@gsLineColor      = "NavyBlue"
              mkres@gsLineThicknessF = 3.0
              over_plot(kk) = gsn_add_polyline(wks,map_plot,tc_plane3@lons,tc_plane3@lats,mkres)

              amres                  = True
              amres@amJust           = "TopLeft"  
              amres@amOrthogonalPosF = -0.49    
              amres@amParallelPosF   = 0.15 ;-0.49     
              anno33 = gsn_add_annotation(contour_tc, map_plot, amres)
            end if
            
          end if
          

          if (NCL1VARONOFF.eq.1) then
          totxaxis_steps = dimsizes(tc_plane1(0,0,:))-1
          xvalues := ispan(0,totxaxis_steps,1)
          ll_step = tointeger(totxaxis_steps/6)+1
          opt11@tmXBMode          = "Explicit"
          opt11@tmXBValues        = xvalues(::ll_step)
          opt11@tmXBLabels        = sprintf("%6.2f",tc_plane1@lats(::ll_step)) + "~S~o~N~N~C~" + \
                                  sprintf("%6.2f",tc_plane1@lons(::ll_step)) + "~S~o~N~E"
          if (varonoff_check .eq. 1) then
          opt11@gsnRightString = tc_plane1@units
          opt11@gsnLeftString = tc_plane1@description
          else
          opt11@gsnRightString = tc_plane1@units + "~C~" + " "
          opt11@gsnLeftString = tc_plane1@description + "~C~" + " "
          end if
          if (NCLtitle .ne. 1) then
           opt11@gsnRightString = ""
           opt11@gsnLeftString = ""
          end if
          opt11@tiMainString = times(it)
          opt11@cnInfoLabelOn = False

            if ( (cross_path_onoff .ne. 1) .or. cross_path_used ) then
              contour_tc1 = gsn_csm_contour(wks,tc_plane1(it,:,:),opt11)
              ; opt33@cnFillOn = True
              ; opt33@cnLinesOn = False
              ;contour_tc0 = gsn_csm_contour(wks,tc_plane1(it,:,:),opt33)
              else
              cross_path_used11 = True  ;use in the next (var 2) variable
              contour_tc1 = gsn_csm_contour(wks,tc_plane1(it,:,:),opt11)
              mpwrf_res  = True
              mpwrf_res@vpWidthF          = 0.2     ; make map much snaller
              mpwrf_res@vpHeightF         = 0.2
              mpwrf_res@gsnDraw           = False
              mpwrf_res@gsnFrame          = False
              mpwrf_res = wrf_map_resources(a,mpwrf_res)     ; Use WRF map projection
              mpwrf_res@pmTickMarkDisplayMode = "Never"     ; turns off map tickmarks and labels
              mpwrf_res@mpPerimLineColor      = "Black"     ; wrf_map_resources sets this to gray
              topovaronoff = stringtofloat(getenv("crosstopo"))
              if (topovaronoff .ne. 1) then
                mpwrf_res@mpFillColors = (/"transparent","blue","gray97","blue", "transparent"/)
                map_plot = gsn_csm_map(wks,mpwrf_res)
                else
                ter = wrf_user_getvar(a, "HGT", 0)
                ter@lat2d = a->XLAT(0,:,:)
                ter@lon2d = a->XLONG(0,:,:)
                mpwrf_res@cnFillOn = True
                cmap = read_colormap_file("OceanLakeLandSnow")
                mpwrf_res@cnFillPalette      = cmap(2:,:)
                mpwrf_res@cnLinesOn = False
                mpwrf_res@lbLabelBarOn = False
                mpwrf_res@cnInfoLabelOn      = False
                mpwrf_res@mpGeophysicalLineThicknessF = 2
                mpwrf_res@mpGeophysicalLineColor = "black"
                mpwrf_res@gsnLeftString = ""
                mpwrf_res@gsnRightString = ""
                map_plot = gsn_csm_contour_map(wks, ter, mpwrf_res)
              end if

              mkres                  = True
              mkres@gsLineColor      = "NavyBlue"
              mkres@gsLineThicknessF = 3.0
              over_plot(kk) = gsn_add_polyline(wks,map_plot,tc_plane1@lons,tc_plane1@lats,mkres)

              amres                  = True
              amres@amJust           = "TopLeft"  
              amres@amOrthogonalPosF = -0.49    
              amres@amParallelPosF   = 0.15 ;-0.49  
              anno11 = gsn_add_annotation(contour_tc1, map_plot, amres)
            end if

          end if


          if (NCL2VARONOFF.eq.1) then
          totxaxis_steps = dimsizes(tc_plane2(0,0,:))-1
          xvalues := ispan(0,totxaxis_steps,1)
          ll_step = tointeger(totxaxis_steps/6)+1
          opt22@tmXBMode          = "Explicit"
          opt22@tmXBValues        = xvalues(::ll_step)
          opt22@tmXBLabels        = sprintf("%6.2f",tc_plane2@lats(::ll_step)) + "~S~o~N~N~C~" + \
                                  sprintf("%6.2f",tc_plane2@lons(::ll_step)) + "~S~o~N~E"
          if (varonoff_check .eq. 2) then
           opt22@gsnRightString = tc_plane2@units ;+ "~C~" + " "
           opt22@gsnLeftString = tc_plane2@description ;+ "~C~" + " "
           else
           opt22@gsnRightString = tc_plane2@units + "~C~~C~" + " "
           opt22@gsnLeftString = tc_plane2@description + "~C~~C~" + " "
          end if
          if (NCLtitle .ne. 1) then
           opt22@gsnRightString = ""
           opt22@gsnLeftString = ""
          end if
          
          opt22@tiMainString = times(it)
          opt22@cnInfoLabelOn = False

            if ( (cross_path_onoff .ne. 1) .or. cross_path_used11 ) then ;No need to set another cross_path_used
              contour_tc2 = gsn_csm_contour(wks,tc_plane2(it,:,:),opt22)
              else
              contour_tc2 = gsn_csm_contour(wks,tc_plane2(it,:,:),opt22)
              mpwrf_res  = True
              mpwrf_res@vpWidthF          = 0.2     ; make map much snaller
              mpwrf_res@vpHeightF         = 0.2
              mpwrf_res@gsnDraw           = False
              mpwrf_res@gsnFrame          = False
              mpwrf_res = wrf_map_resources(a,mpwrf_res)     ; Use WRF map projection
              mpwrf_res@pmTickMarkDisplayMode = "Never"     ; turns off map tickmarks and labels
              mpwrf_res@mpPerimLineColor      = "Black"     ; wrf_map_resources sets this to gray
              topovaronoff = stringtofloat(getenv("crosstopo"))
              if (topovaronoff .ne. 1) then
                mpwrf_res@mpFillColors = (/"transparent","blue","gray97","blue", "transparent"/)
                map_plot = gsn_csm_map(wks,mpwrf_res)
                else
                ter = wrf_user_getvar(a, "HGT", 0)
                ter@lat2d = a->XLAT(0,:,:)
                ter@lon2d = a->XLONG(0,:,:)
                mpwrf_res@cnFillOn = True
                cmap = read_colormap_file("OceanLakeLandSnow")
                mpwrf_res@cnFillPalette      = cmap(2:,:)
                mpwrf_res@cnLinesOn = False
                mpwrf_res@lbLabelBarOn = False
                mpwrf_res@cnInfoLabelOn      = False
                mpwrf_res@mpGeophysicalLineThicknessF = 2
                mpwrf_res@mpGeophysicalLineColor = "black"
                mpwrf_res@gsnLeftString = ""
                mpwrf_res@gsnRightString = ""
                map_plot = gsn_csm_contour_map(wks, ter, mpwrf_res)
              end if

              mkres                  = True
              mkres@gsLineColor      = "NavyBlue"
              mkres@gsLineThicknessF = 3.0
              over_plot(kk) = gsn_add_polyline(wks,map_plot,tc_plane2@lons,tc_plane2@lats,mkres)

              amres                  = True
              amres@amJust           = "TopLeft"   
              amres@amOrthogonalPosF = -0.49    
              amres@amParallelPosF   = 0.15 ;-0.49       
              anno11 = gsn_add_annotation(contour_tc2, map_plot, amres)
            end if

          end if

mpres = True
          if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1) then
            overlay(contour_tc1, contour_tc2)
            overlay(contour_tc, contour_tc1)
            plot = contour_tc
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1) then
            overlay(contour_tc, contour_tc1)
            plot = contour_tc
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1) then
            overlay(contour_tc, contour_tc2)
            plot = contour_tc
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1) then
            plot = contour_tc
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1) then
            overlay(contour_tc1, contour_tc2)
            plot = contour_tc1
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1) then
            draw(contour_tc1)
            plot = contour_tc1
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1) then
            draw(contour_tc2)
            plot = contour_tc2
          end if
          end if
          end if
          end if
          end if
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
        tot_elements_minus = (ntimes - start_timestep)/ncltstep
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

        do it = start_timestep, ntimes, ncltstep
                
                print("Working on time range (average): " + times(it) + " to " + times(it+ncltstep) )

                pltres = True
                pltres@FontHeightF = 0.013 ;;no panl, no average

                  if (NCL3VARONOFF.eq.1) then
                  totxaxis_steps = dimsizes(tc_plane3(0,0,:))-1
                  xvalues := ispan(0,totxaxis_steps,1)
                  ll_step = tointeger(totxaxis_steps/6)+1                                       ; step interval for tickmarks
                  opt33@tmXBMode          = "Explicit"
                  opt33@tmXBValues        = xvalues(::ll_step)
                  opt33@tmXBLabels        = sprintf("%6.2f",tc_plane3@lats(::ll_step)) + "~S~o~N~N~C~" + \
                                          sprintf("%6.2f",tc_plane3@lons(::ll_step)) + "~S~o~N~E"
                  opt33@pmLabelBarHeightF     = 0.08
                  tstart = str_split(times(it), ":")
                  tend = str_split(times(it+ncltstep), ":")
                  opt33@tiMainString = tstart(0) + " to " + tend(0)
                  opt33@lbTitleString  = tc_plane3@description + " (" + tc_plane3@units + ")"
                  
                  if (varonoff_check .eq. 4) then
                    opt33@gsnRightString = tc_plane3@units ;+ "~C~" + " "
                    opt33@gsnLeftString = tc_plane3@description ;+ "~C~" + " "
                    else
                    opt33@gsnRightString = tc_plane3@units + "~C~~C~~C~" + " "
                    opt33@gsnLeftString = tc_plane3@description + "~C~~C~~C~" + " "
                  end if
                  if (NCLtitle .ne. 1) then
                  opt33@gsnRightString = ""
                  opt33@gsnLeftString = ""
                  end if
                  
                    if ( cross_path_onoff .ne. 1 ) then
                      contour_tc = gsn_csm_contour(wks,dim_avg_n_Wrap(tc_plane3(it:(it+ncltstep),:,:),0),opt33)

                      else
                      cross_path_used = True
                      cross_path_used11 = True  ;use in the next (var 2) variable
                      contour_tc = gsn_csm_contour(wks,dim_avg_n_Wrap(tc_plane3(it:(it+ncltstep),:,:),0),opt33)
                      mpwrf_res  = True
                      mpwrf_res@vpWidthF          = 0.2     ; make map much snaller
                      mpwrf_res@vpHeightF         = 0.2
                      mpwrf_res@gsnDraw           = False
                      mpwrf_res@gsnFrame          = False

                      mpwrf_res = wrf_map_resources(a,mpwrf_res)     ; Use WRF map projection
                      mpwrf_res@pmTickMarkDisplayMode = "Never"     ; turns off map tickmarks and labels
                      mpwrf_res@mpPerimLineColor      = "Black"     ; wrf_map_resources sets this to gray
              topovaronoff = stringtofloat(getenv("crosstopo"))
              if (topovaronoff .ne. 1) then
                mpwrf_res@mpFillColors = (/"transparent","blue","gray97","blue", "transparent"/)
                map_plot = gsn_csm_map(wks,mpwrf_res)
                else
                ter = wrf_user_getvar(a, "HGT", 0)
                ter@lat2d = a->XLAT(0,:,:)
                ter@lon2d = a->XLONG(0,:,:)
                mpwrf_res@cnFillOn = True
                cmap = read_colormap_file("OceanLakeLandSnow")
                mpwrf_res@cnFillPalette      = cmap(2:,:)
                mpwrf_res@cnLinesOn = False
                mpwrf_res@lbLabelBarOn = False
                mpwrf_res@cnInfoLabelOn      = False
                mpwrf_res@mpGeophysicalLineThicknessF = 2
                mpwrf_res@mpGeophysicalLineColor = "black"
                mpwrf_res@gsnLeftString = ""
                mpwrf_res@gsnRightString = ""
                map_plot = gsn_csm_contour_map(wks, ter, mpwrf_res)
              end if
                      mkres                  = True
                      mkres@gsLineColor      = "NavyBlue"
                      mkres@gsLineThicknessF = 3.0
                      over_plot(kk) = gsn_add_polyline(wks,map_plot,tc_plane3@lons,tc_plane3@lats,mkres)

                      amres                  = True
                      amres@amJust           = "TopLeft"    ; Corner of plot for positioning
                      amres@amOrthogonalPosF = -0.49    
                      amres@amParallelPosF   = 0.15 ;-0.49 
                      anno33 = gsn_add_annotation(contour_tc, map_plot, amres)
                    end if
                    
                  end if
                  
                  if (NCL1VARONOFF.eq.1) then
                  totxaxis_steps = dimsizes(tc_plane1(0,0,:))-1
                  xvalues := ispan(0,totxaxis_steps,1)
                  ll_step = tointeger(totxaxis_steps/6)+1
                  opt11@tmXBMode          = "Explicit"
                  opt11@tmXBValues        = xvalues(::ll_step)
                  opt11@tmXBLabels        = sprintf("%6.2f",tc_plane1@lats(::ll_step)) + "~S~o~N~N~C~" + \
                                          sprintf("%6.2f",tc_plane1@lons(::ll_step)) + "~S~o~N~E"
                  if (varonoff_check .eq. 1) then
                  opt11@gsnRightString = tc11@units
                  opt11@gsnLeftString = tc11@description
                  else
                  opt11@gsnRightString = tc11@units + "~C~" + " "
                  opt11@gsnLeftString = tc11@description + "~C~" + " "
                  end if
                  if (NCLtitle .ne. 1) then
                  opt11@gsnRightString = ""
                  opt11@gsnLeftString = ""
                  end if
                  tstart = str_split(times(it), ":")
                  tend = str_split(times(it+ncltstep), ":")
                  opt11@tiMainString = tstart(0) + " to " + tend(0)
                  opt11@cnInfoLabelOn = False

                    if ( (cross_path_onoff .ne. 1) .or. cross_path_used ) then
                      contour_tc1 = gsn_csm_contour(wks,dim_avg_n_Wrap(tc_plane1(it:(it+ncltstep),:,:),0),opt11)

                      else
                      cross_path_used11 = True  ;use in the next (var 2) variable
                      contour_tc1 = gsn_csm_contour(wks,dim_avg_n_Wrap(tc_plane1(it:(it+ncltstep),:,:),0),opt11)
                      mpwrf_res  = True
                      mpwrf_res@vpWidthF          = 0.2     ; make map much snaller
                      mpwrf_res@vpHeightF         = 0.2
                      mpwrf_res@gsnDraw           = False
                      mpwrf_res@gsnFrame          = False

                      mpwrf_res = wrf_map_resources(a,mpwrf_res)     ; Use WRF map projection
                      mpwrf_res@pmTickMarkDisplayMode = "Never"     ; turns off map tickmarks and labels
                      mpwrf_res@mpPerimLineColor      = "Black"     ; wrf_map_resources sets this to gray
              topovaronoff = stringtofloat(getenv("crosstopo"))
              if (topovaronoff .ne. 1) then
                mpwrf_res@mpFillColors = (/"transparent","blue","gray97","blue", "transparent"/)
                map_plot = gsn_csm_map(wks,mpwrf_res)
                else
                ter = wrf_user_getvar(a, "HGT", 0)
                ter@lat2d = a->XLAT(0,:,:)
                ter@lon2d = a->XLONG(0,:,:)
                mpwrf_res@cnFillOn = True
                cmap = read_colormap_file("OceanLakeLandSnow")
                mpwrf_res@cnFillPalette      = cmap(2:,:)
                mpwrf_res@cnLinesOn = False
                mpwrf_res@lbLabelBarOn = False
                mpwrf_res@cnInfoLabelOn      = False
                mpwrf_res@mpGeophysicalLineThicknessF = 2
                mpwrf_res@mpGeophysicalLineColor = "black"
                mpwrf_res@gsnLeftString = ""
                mpwrf_res@gsnRightString = ""
                map_plot = gsn_csm_contour_map(wks, ter, mpwrf_res)
              end if
                      mkres                  = True
                      mkres@gsLineColor      = "NavyBlue"
                      mkres@gsLineThicknessF = 3.0
                      over_plot(kk) = gsn_add_polyline(wks,map_plot,tc_plane1@lons,tc_plane1@lats,mkres)

                      amres                  = True
                      amres@amJust           = "TopLeft"    ; Corner of plot for positioning
                      amres@amOrthogonalPosF = -0.49    
                      amres@amParallelPosF   = 0.15 ;-0.49 
                      anno11 = gsn_add_annotation(contour_tc1, map_plot, amres)
                    end if

                  end if


                  if (NCL2VARONOFF.eq.1) then
                  totxaxis_steps = dimsizes(tc_plane2(0,0,:))-1
                  xvalues := ispan(0,totxaxis_steps,1)
                  ll_step = tointeger(totxaxis_steps/6)+1
                  opt22@tmXBMode          = "Explicit"
                  opt22@tmXBValues        = xvalues(::ll_step)
                  opt22@tmXBLabels        = sprintf("%6.2f",tc_plane2@lats(::ll_step)) + "~S~o~N~N~C~" + \
                                          sprintf("%6.2f",tc_plane2@lons(::ll_step)) + "~S~o~N~E"
                  if (varonoff_check .eq. 2) then
                  opt22@gsnRightString = tc_plane2@units ;+ "~C~" + " "
                  opt22@gsnLeftString = tc_plane2@description ;+ "~C~" + " "
                  else
                  opt22@gsnRightString = tc_plane2@units + "~C~~C~" + " "
                  opt22@gsnLeftString = tc_plane2@description + "~C~~C~" + " "
                  end if
                  if (NCLtitle .ne. 1) then
                  opt22@gsnRightString = ""
                  opt22@gsnLeftString = ""
                  end if

                  tstart = str_split(times(it), ":")
                  tend = str_split(times(it+ncltstep), ":")
                  opt22@tiMainString = tstart(0) + " to " + tend(0)
                  opt22@cnInfoLabelOn = False
                    if ( (cross_path_onoff .ne. 1) .or. cross_path_used11 ) then ;No need to set another cross_path_used
                      contour_tc2 = gsn_csm_contour(wks,dim_avg_n_Wrap(tc_plane2(it:(it+ncltstep),:,:),0),opt22)
                      else
                      contour_tc2 = gsn_csm_contour(wks,dim_avg_n_Wrap(tc_plane2(it:(it+ncltstep),:,:),0),opt22)
                      mpwrf_res  = True
                      mpwrf_res@vpWidthF          = 0.2     ; make map much snaller
                      mpwrf_res@vpHeightF         = 0.2
                      mpwrf_res@gsnDraw           = False
                      mpwrf_res@gsnFrame          = False

                      mpwrf_res = wrf_map_resources(a,mpwrf_res)     ; Use WRF map projection
                      mpwrf_res@pmTickMarkDisplayMode = "Never"     ; turns off map tickmarks and labels
                      mpwrf_res@mpPerimLineColor      = "Black"     ; wrf_map_resources sets this to gray
              topovaronoff = stringtofloat(getenv("crosstopo"))
              if (topovaronoff .ne. 1) then
                mpwrf_res@mpFillColors = (/"transparent","blue","gray97","blue", "transparent"/)
                map_plot = gsn_csm_map(wks,mpwrf_res)
                else
                ter = wrf_user_getvar(a, "HGT", 0)
                ter@lat2d = a->XLAT(0,:,:)
                ter@lon2d = a->XLONG(0,:,:)
                mpwrf_res@cnFillOn = True
                cmap = read_colormap_file("OceanLakeLandSnow")
                mpwrf_res@cnFillPalette      = cmap(2:,:)
                mpwrf_res@cnLinesOn = False
                mpwrf_res@lbLabelBarOn = False
                mpwrf_res@cnInfoLabelOn      = False
                mpwrf_res@mpGeophysicalLineThicknessF = 2
                mpwrf_res@mpGeophysicalLineColor = "black"
                mpwrf_res@gsnLeftString = ""
                mpwrf_res@gsnRightString = ""
                map_plot = gsn_csm_contour_map(wks, ter, mpwrf_res)
              end if

                      mkres                  = True
                      mkres@gsLineColor      = "NavyBlue"
                      mkres@gsLineThicknessF = 3.0
                      over_plot(kk) = gsn_add_polyline(wks,map_plot,tc_plane2@lons,tc_plane2@lats,mkres)

                      amres                  = True
                      amres@amJust           = "TopLeft"    ; Corner of plot for positioning
                      amres@amOrthogonalPosF = -0.49    
                      amres@amParallelPosF   = 0.15 ;-0.49 
                      anno11 = gsn_add_annotation(contour_tc2, map_plot, amres)
                    end if
                  end if

        mpres = True
                  if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1) then
                    overlay(contour_tc1, contour_tc2)
                    overlay(contour_tc, contour_tc1)
                    plot = contour_tc
                  else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1) then
                    overlay(contour_tc, contour_tc1)
                    plot = contour_tc
                  else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1) then
                    overlay(contour_tc, contour_tc2)
                    plot = contour_tc
                  else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1) then
                    plot = contour_tc
                  else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1) then
                    overlay(contour_tc1, contour_tc2)
                    plot = contour_tc1
                  else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1) then
                    draw(contour_tc1)
                    plot = contour_tc1
                  else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1) then
                    plot = contour_tc2
                  end if
                  end if
                  end if
                  end if
                  end if
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
                tot_elements_minus = (ntimes - start_timestep)/ncltstep
                i = 0
                do i = 0, tot_elements_minus
                  if ((i+rowcol+1).gt.tot_elements_minus) then
                    rowcol = mod(tot_elements_minus, (rowcol+1))
                  end if
                  gsn_panel(wks,(/arrayplots(i:(i+rowcol))/),(/NCLpanelrows,NCLpanelcolumns/),pnlres)
                  i = i + rowcol
                end do
              end if
end if ;;code timeif122

end ;second begin
