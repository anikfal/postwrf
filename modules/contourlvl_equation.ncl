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

 myfile = getenv("wrfout")
 var = str_match(myfile,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if

 NCLCNVAR3 = getenv("CNVAR3") ;NCLcontours11
 NCLCNVAR1 = getenv("CNVAR1") ;NCLcontours22
 NCLCNVAR2 = getenv("CNVAR2") ;NCLcontours33
 NCLwindonoff = tointeger(getenv("wind_onoff"))
 NCL1VARONOFF = tointeger(getenv("FIRSTVAR_ONOFF")) ;NCLsecondvaronoffF
 NCL2VARONOFF = tointeger(getenv("SECONDVAR_ONOFF")) ;NCLthirdvaronoffF
 NCL3VARONOFF = tointeger(getenv("THIRDVAR_ONOFF"))
 ncl_province_onoff = getenv("province_onoff")
 ncl_province_num  = tointeger(getenv("province_num"))
 NCLprovince_name = new(ncl_province_num,"string")
 ncl_shape_onoff = tointeger(getenv("shape_onoff"))
 ncl_shape_path = getenv("shape_path")
 ncl_smooth = tointeger(getenv("smooth_onoff"))
 nclborder = getenv("border_color")
 nclborder_thick = tofloat(getenv("borderthick"))

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
 NCLspinup = tointeger(getenv("spinup"))
 NCLaverage_onoff = tointeger(getenv("average_onoff"))
 NCLaverage_time = tointeger(getenv("averagetime"))

 NCLtitle = tointeger(getenv("titile_option"))
 panel_onoff = tointeger(getenv("panelplot"))
 NCLpanelrows = tointeger(getenv("panelrows"))
 NCLpanelcolumns = tointeger(getenv("panelcolumns"))
 all_steps=a->XTIME
hourstep = (all_steps(1) - all_steps(0))/60
if (NCLspinup.ge.hourstep) then
 start_timestep = tointeger(NCLspinup/hourstep)
else
 start_timestep = 0
end if

i=0
do while(i.le.(ncl_province_num-1))
 NCLprovince_name(i) = getenv("ncl_province_names"+i)
 i=i+1
end do
NCLprovince_name_lower = str_lower(NCLprovince_name)

  optfirst = True
  optfirst@FontHeightF = 0.013
  if (panel_onoff.eq.1) then
    optfirst@FontHeightF = 0.007
  end if
  optfirst@Footer = False
  opt_notitle = True
  opt_notitle@NoHeaderFooter = True
  opt_notitle@InitTime = False
  opt_notitle@ValidTime = False

   filename = getenv("outname")
  type = getenv("imgfmt")
   if (type .eq. "animated_gif") then
    type = "png"
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

  if (NCL3VARONOFF .eq. 1) then ; code ifvar3on

    cnmode = getenv("contvar")
    cnmin = getenv("Min")
    cnmax = getenv("Max")
    cnintv = getenv("Intv")
    contourcolorpal = getenv("colpal")

    if_polynom3 = polynoms_status(2)
      if (if_polynom3.eq."False")  ;;code ifpoly3
        NCLPLEV3 = tointeger(getenv("CNLEV30")) ;pressure_levelsS

        if (NCLCNVAR3 .eq. "cape_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CAPE"
        slp1@units = "J/kg"
        myvar = slp1(0,:,:,:)
        else if (NCLCNVAR3 .eq. "cin_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CIN"
        slp1@units = "J/kg"
        myvar = slp1(1,:,:,:)
        else if (NCLCNVAR3 .eq. "cin_3d") then
          slp1  = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CIN"
          slp1@units = "J/kg"
          myvar = slp1(1,:,:,:,:)
        else if (NCLCNVAR3 .eq. "cape_3d") then
          slp1 = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CAPE"
          slp1@units = "J/kg"
          myvar = slp1(0,:,:,:,:)
          delete(slp1)
        else if (NCLCNVAR3 .eq. "lcl") then
            slp1  = wrf_user_getvar(a,"cape_2d",-1)
            slp1@description = "Lifting Condensation Level"
            slp1@units = "m"
            myvar = slp1(2,:,:,:)
        else if (NCLCNVAR3 .eq. "lfc") then
            slp1 = wrf_user_getvar(a,"cape_2d",-1)
            slp1@description = "Level of Free Convection"
            slp1@units = "m"
            myvar = slp1(2,:,:,:)

        else if (NCLCNVAR3 .eq. "dust_total") then
            myvar  = a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
            myvar@description = "Total dust concentration"
            myvar@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR3 .eq. "dust_pm2.5") then
            myvar  = a->DUST_1+0.3125*a->DUST_2
            myvar@description = "Dust_PM2.5 concentration"
            myvar@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR3 .eq. "dust_pm10") then
            myvar  = a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
            myvar@description = "Dust_PM10 concentration"
            myvar@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR3 .eq. "wind_s") then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
            myvar = wind_speed(uu10,vv10)
            myvar@description = "10m wind speed"
            myvar@units = "m s-1"

        else if (NCLCNVAR3 .eq. "wind_d") then
          if (.not.isdefined("uu10")) then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
          end if
            myvar = wind_direction(uu10,vv10,0)
            myvar@description = "10m wind direction"
            myvar@units = "Degrees from north"

        else
        myvar = wrf_user_getvar(a,NCLCNVAR3,-1)        ; T in C

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

        mydim3 = dimsizes(dimsizes(myvar))
        if (mydim3.eq.3) then
          tc_plane3 = myvar
          tc_plane3@PlotLevelID = "surface"
          else ;if dimsize equals 4
          if (NCLPLEV3.eq.0) then ;surface pressure
              tc_plane3 = myvar(:,0,:,:)
              tc_plane3@PlotLevelID = "surface"
            else
          if (.not.isdefined("p")) then
            p  = wrf_user_getvar(a, "pressure",-1)
          end if
              tc_plane3 := wrf_user_intrp3d(myvar,p,"h",NCLPLEV3,0.,False)
          end if
        end if

      else  ;;code ifpoly3

        NCLvarnames = asciiread("variablesCN3.txt", -1, "string")
        totvarsnum = dimsizes(NCLvarnames) - 1

        ncl_CNLEV3_num = tointeger(getenv("CNLEV3_num"))
        NCLPLEV3 = new(ncl_CNLEV3_num, "integer")
        i = 0
        do while(i.lt.ncl_CNLEV3_num)
          NCLPLEV3(i) = tointeger(getenv("CNLEV3"+i))
          i=i+1
        end do
        oneP1 = False
        if (ncl_CNLEV3_num.eq.(totvarsnum+1)) then
          NCLPLEV3 = new(ncl_CNLEV3_num, "integer")
          i = 0
          do while(i.lt.ncl_CNLEV3_num)
            NCLPLEV3(i) = tointeger(getenv("CNLEV3"+i))
            i=i+1
          end do
        else
          if (ncl_CNLEV3_num.eq.1) then
            delete(NCLPLEV3)
            NCLPLEV3 = new((totvarsnum+1), "integer")
            NCLPLEV3 = tointeger(getenv("CNLEV30"))
            oneP1 = True
          else
            print("Error: Number of pressure levels do not match the number of variables in < "\
             + asciiread(homedir+"/modules/totalequationCN30.txt", -1, "string")  + " >" )
            print("       You could put only one pressure for all the variables in the polynomial")
            ;print("Correct the number of pressure levels and try again")
            exit()
          end if
        end if


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
              varlist2[ii]@description = "Total dust concentration"
              varlist2[ii]@units = "Microgram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
              ListAppend(varlist2,a->DUST_1+0.3125*a->DUST_2)
              varlist2[ii]@description = "Dust_PM2.5 concentration"
              varlist2[ii]@units = "Microgram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm10") then
              ListAppend(varlist2,a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4)
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
        if (dimsizes(dimsizes(varlist2[ii])).eq.3) then
            ListAppend(varlist,varlist2[ii])
          else ;if dimsize equals 4
            if (NCLPLEV3(ii).eq.0) then ;surface pressure
                ListAppend(varlist,varlist2[ii](:,0,:,:))
              else
                p  = wrf_user_getvar(a, "pressure",-1) ; pressure is our vertical coordinate
                ListAppend(varlist,wrf_user_intrp3d(varlist2[ii],p,"h",NCLPLEV3(ii),0.,False))
            end if
        end if
        end do ;;code docheck22

        ;;shell script333
dust_pm10 = varlist[0]  ;;;added_new_line_by_sed333
delete(varlist)
delete(varlist2)

  ;equation from namelist.wrf333
tc_plane3 = dust_pm10*2  ;;;added_new_line_by_sed333

if (dimsizes(NCLPLEV3).eq.1) then
  if (NCLPLEV3.eq.0) then
    tc_plane3@PlotLevelID = "surface"
  else
    tc_plane3@PlotLevelID = NCLPLEV3
  end if
else
  tc_plane3@PlotLevelID = "multi atmospheric levels"
end if

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


              opt1 = optfirst
              opt1@lbLabelFontHeightF = 0.02
              opt1@lbTitleFontHeightF = 0.025
              ;opt1@lbTopMarginF = 0.5
              opt1@lbBottomMarginF = -0.15

              if (NCLtitle.ne.1) then
              opt1 = opt_notitle
              end if
              
            if(contourcolorpal .eq. "BlueRed1") then
              opt1@cnFillColors = BlueRed2
            end if
            if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
              opt1@cnFillColors = WhiteYellowOrangeRed2
            end if
            if(contourcolorpal .eq. "WhBlGrYeRe1") then
              opt1@cnFillColors = WhBlGrYeRe2
            end if
            if(contourcolorpal .eq. "MPL_gist_rainbow1") then
              opt1@cnFillColors = MPL_gist_rainbow2
            end if
            if(contourcolorpal .eq. "rainbow1") then
              opt1@cnFillColors = rainbow2
            end if
            if(contourcolorpal .eq. "WhiteGreen1") then
              opt1@cnFillColors = WhiteGreen2
            end if
            if(contourcolorpal .eq. "MPL_Reds1") then
              opt1@cnFillColors = MPL_Reds2
            end if
            if(contourcolorpal .eq. "WandB") then
              opt1@cnFillColors = WandB2
            end if
            if(contourcolorpal .eq. "WhiteBlue1") then
              opt1@cnFillColors = WhiteBlue2
            end if
            if(contourcolorpal .eq. "BandW") then
              opt1@cnFillColors = BandW2
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
              ;opt1@cnMaxLevelCount = 12
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "WhiteYellowOrangeRed1") then
            ; opt1@cnMaxLevelCount = 12
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "WhBlGrYeRe1") then
            ; opt1@cnMaxLevelCount = 12
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "MPL_gist_rainbow1") then
            ;  opt1@cnMaxLevelCount = 12
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "rainbow1") then
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "WhiteGreen1") then
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "MPL_Reds1") then
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "WandB") then
              opt1@cnMaxLevelCount = 9
            end if
            if(contourcolorpal .eq. "WhiteBlue1") then
              opt1@cnMaxLevelCount = 11
            end if
            if(contourcolorpal .eq. "BandW") then
              opt1@cnMaxLevelCount = 9
            end if
      end if
              ; Plotting options for T                
              opt1@cnFillOn = True
        
            if(cnmode .eq. "Manual") then
            opt1@cnLevelSelectionMode = "ManualLevels"
              if (cnmin .eq. "NULL") then
              opt1@cnMinLevelValF = MANcnmin
              else
              ;if (cnmin .ne. "NULL") then
              cnmin3  = stringtofloat(cnmin)
              opt1@cnMinLevelValF = cnmin3
              end if
              if (cnmax .eq. "NULL") then
              ;opt1@cnMaxLevelValF = MANcnmax(level)
              opt1@cnMaxLevelValF = MANcnmax
              else
              cnmax3  = stringtofloat(cnmax)
              opt1@cnMaxLevelValF = cnmax3
              end if
              if (cnintv .eq. "NULL") then
              ;opt1@cnLevelSpacingF = MANcnintv(level)
              opt1@cnLevelSpacingF = MANcnintv
              else
              cnintv3  = stringtofloat(cnintv)
              opt1@cnLevelSpacingF = cnintv3
              end if
            end if

              opt1@cnLineLabelDensityF = 1
              opt1@cnLineLabelInterval = 1
              opt1@cnInfoLabelOrthogonalPosF = 0.07  ; offset second label information
              opt1@gsnContourLineThicknessesScale = 2.0
              opt1@gsnContourLineThicknessesScale = 3.0
              opt1@cnLineLabelFontHeightF = 0.025
              opt1@cnHighLabelFontHeightF   = 0.03

  end if ;code ifvar3on

; ;;;;;####################################################################
; ;;;;;####################################################################
;processing VAR1
if (NCL1VARONOFF.eq.1) then  ;processing VAR1
  ;NCLPLEV1 = tointeger(getenv("CNLEV1")) ;pressure_level11
  ;NCLPLEV1 = (/0, 500, 300/)
  NCLINTV1 = tofloat(getenv("CNINTV1")) ;NCLintv22
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
  
  opt2 = optfirst
  
   if (NCLtitle.ne.1) then
     opt2 = opt_notitle
   end if
  opt2@cnFillOn = False
  opt2@cnLineColor = NCLCOLOR1
  opt2@cnLineThicknessF  = NCLTHICK1
  opt2@cnLineLabelFontHeightF = NCLLABEL1
  opt2@cnLineLabelInterval = 1
  opt2@cnLineLabelPlacementMode = "Constant"

      if_polynom1 = polynoms_status(0)
      if (if_polynom1.eq."False")  ;;code ifpoly1
      NCLPLEV1 = tointeger(getenv("CNLEV10")) ;pressure_level11

        if (NCLCNVAR1 .eq. "cape_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CAPE"
        slp1@units = "J/kg"
        tc_plane1 = slp1(0,:,:,:)
        else if (NCLCNVAR1 .eq. "cin_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CIN"
        slp1@units = "J/kg"
        tc_plane1 = slp1(1,:,:,:)
        else if (NCLCNVAR1 .eq. "cin_3d") then
          slp1  = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CIN"
          slp1@units = "J/kg"
          tc_plane1 = slp1(1,:,:,:,:)
        else if (NCLCNVAR1 .eq. "cape_3d") then
          slp1 = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CAPE"
          slp1@units = "J/kg"
          tc_plane1 = slp1(0,:,:,:,:)
          delete(slp1)
        else if (NCLCNVAR1 .eq. "lcl") then
            slp1  = wrf_user_getvar(a,"cape_2d",-1)
            slp1@description = "Lifting Condensation Level"
            slp1@units = "m"
            tc_plane1 = slp1(2,:,:,:)
        else if (NCLCNVAR1 .eq. "lfc") then
            slp1 = wrf_user_getvar(a,"cape_2d",-1)
            slp1@description = "Level of Free Convection"
            slp1@units = "m"
            tc_plane1 = slp1(2,:,:,:)

        else if (NCLCNVAR1 .eq. "dust_total") then
            tc_plane1  = a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
            tc_plane1@description = "Total dust concentration"
            tc_plane1@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR1 .eq. "dust_pm2.5") then
            tc_plane1  = a->DUST_1+0.3125*a->DUST_2
            tc_plane1@description = "Dust_PM2.5 concentration"
            tc_plane1@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR1 .eq. "dust_pm10") then
            tc_plane1  = a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
            tc_plane1@description = "Dust_PM10 concentration"
            tc_plane1@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR1 .eq. "wind_s") then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
            tc_plane1 = wind_speed(uu10,vv10)
            tc_plane1@description = "10m wind speed"
            tc_plane1@units = "m s-1"

        else if (NCLCNVAR1 .eq. "wind_d") then
          if (.not.isdefined("uu10")) then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
          end if
            tc_plane1 = wind_direction(uu10,vv10,0)
            tc_plane1@description = "10m wind direction"
            tc_plane1@units = "Degrees from north"

        else
        tc_plane1 = wrf_user_getvar(a,NCLCNVAR1,-1)        ; T in C

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

        mydim1 = dimsizes(dimsizes(tc_plane1))
        if (mydim1.eq.3) then
          tc_plane1@PlotLevelID = "surface"
          else ;if dimsize equals 4
          if (NCLPLEV1.eq.0) then ;surface pressure
              tc_plane1 := tc_plane1(:,0,:,:)
              tc_plane1@PlotLevelID = "surface"
            else

          if (.not.isdefined("p")) then
            p  = wrf_user_getvar(a, "pressure",-1)
          end if
              tc_plane1 := wrf_user_intrp3d(tc_plane1,p,"h",NCLPLEV1,0.,False)
          end if
        end if

      else  ;;code ifpoly1

        NCLvarnames = asciiread("variablesCN1.txt", -1, "string")
        totvarsnum = dimsizes(NCLvarnames) - 1

        ncl_CNLEV1_num = tointeger(getenv("CNLEV1_num"))
        NCLPLEV1 = new(ncl_CNLEV1_num, "integer")
        i = 0
        do while(i.lt.ncl_CNLEV1_num)
          NCLPLEV1(i) = tointeger(getenv("CNLEV1"+i))
          i=i+1
        end do
        
        oneP1 = False
        if (ncl_CNLEV1_num.eq.(totvarsnum+1)) then
          NCLPLEV1 = new(ncl_CNLEV1_num, "integer")
          i = 0
          do while(i.lt.ncl_CNLEV1_num)
            NCLPLEV1(i) = tointeger(getenv("CNLEV1"+i))
            i=i+1
          end do
        else
          if (ncl_CNLEV1_num.eq.1) then
            delete(NCLPLEV1)
            NCLPLEV1 = new((totvarsnum+1), "integer")
            NCLPLEV1 = tointeger(getenv("CNLEV10"))
            oneP1 = True
          else
            print("Error: Number of pressure levels do not match the number of variables in < "\
             + asciiread(homedir+"/modules/totalequationCN10.txt", -1, "string")  + " >" )
            print("       You could put only one pressure for all the variables in the polynomial")
            exit()
          end if
        end if

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
              ListAppend(varlist2,f->DUST_1+f->DUST_2+f->DUST_3+f->DUST_4+f->DUST_5)
              varlist2[ii]@description = "Total dust concentration"
              varlist2[ii]@units = "Microgram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
              ListAppend(varlist2,f->DUST_1+0.3125*f->DUST_2)
              varlist2[ii]@description = "Dust_PM2.5 concentration"
              varlist2[ii]@units = "Microgram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm10") then
              ListAppend(varlist2,f->DUST_1+f->DUST_2+f->DUST_3+0.87*f->DUST_4)
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
        end do ;;code do_poly1
        delete(NCLvarnames)

        varlist = NewList("lifo") ;;main list and checking the dims
        do ii = 0, totvarsnum ;;code docheck22
        if (dimsizes(dimsizes(varlist2[ii])).eq.3) then
            ListAppend(varlist,varlist2[ii])
            varlist[ii]@PlotLevelID = "surface"
          else ;if dimsize equals 4
            if (NCLPLEV1(ii).eq.0) then ;surface pressure
                ListAppend(varlist,varlist2[ii](:,0,:,:))
                varlist[ii]@PlotLevelID = "surface"
              else
                p  = wrf_user_getvar(a, "pressure",-1) ; pressure is our vertical coordinate
                ListAppend(varlist,wrf_user_intrp3d(varlist2[ii],p,"h",NCLPLEV1(ii),0.,False))
            end if
        end if
        end do ;;code docheck22

        ;;shell script111
tk = varlist[0]  ;;;added_new_line_by_sed111
delete(varlist)
delete(varlist2)

  ;equation from namelist.wrf111
tc_plane1 = tk-273  ;;;added_new_line_by_sed111


if (dimsizes(NCLPLEV1).eq.1) then
  if (NCLPLEV1.eq.0) then
    tc_plane1@PlotLevelID = "surface"
  else
    tc_plane1@PlotLevelID = NCLPLEV1
  end if
else
  if (oneP1) then
    tc_plane1@PlotLevelID = tointeger(getenv("CNLEV10"))
  else
    tc_plane1@PlotLevelID = "multi atmospheric levels"
  end if
end if

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
  if (upper_bound1 .gt. max1) then ;checking the whiskers of box plot
    upper_bound1 = max1
  end if
  if (lower_bound1 .lt. min1) then ;checking the whiskers of box plot
    lower_bound1 = min1
  end if
  intv_range1 = upper_bound1 - lower_bound1
  opt2@cnLevelSelectionMode = "ManualLevels"
  if (NCLINTV1.eq.0 .or. NCLINTV1.gt.intv_range1) then
    opt2@cnLevelSpacingF = intv_range1/10
  else
    opt2@cnLevelSpacingF = NCLINTV1
  end if
   opt2@cnMaxLevelValF = upper_bound1
   opt2@cnMinLevelValF = lower_bound1
   opt2@cnMaxLevelCount = 255
end if ;end of VAR1

; ;;;;;####################################################################
; ;;;;;####################################################################
;processing VAR2
if (NCL2VARONOFF.eq.1) then  ;processing VAR2

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

  opt3 = optfirst
  opt3@cnInfoLabelZone = 4
    ;opt3@InitTime = False
   if (NCLtitle.ne.1) then
     opt3 = opt_notitle
   end if
  opt3@cnFillOn = False
  opt3@cnLineColor = NCLCOLOR2
  opt3@cnLineThicknessF  = NCLTHICK2
  opt3@cnLineLabelFontHeightF = NCLLABEL2
  opt3@gsnContourNegLineDashPattern = NCLBROKEN2
  opt3@gsnContourPosLineDashPattern = NCLBROKEN2
  opt3@cnLineLabelInterval = 1
  opt3@cnLineLabelPlacementMode = "Constant"

  if_polynom2 = polynoms_status(1)
  if (if_polynom2.eq."False")  ;;code ifpoly2
    NCLPLEV2 = tointeger(getenv("CNLEV20"))

        if (NCLCNVAR2 .eq. "cape_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CAPE"
        slp1@units = "J/kg"
        myvar := slp1(0,:,:,:)
        else if (NCLCNVAR2 .eq. "cin_surface") then
        slp1 = wrf_user_getvar(a,"cape_2d",-1)
        slp1@_FillValue=-1
        slp1@description = "CIN"
        slp1@units = "J/kg"
        myvar := slp1(1,:,:,:)
        else if (NCLCNVAR2 .eq. "cin_3d") then
          slp1  = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CIN"
          slp1@units = "J/kg"
          myvar := slp1(1,:,:,:,:)
        else if (NCLCNVAR2 .eq. "cape_3d") then
          slp1 = wrf_user_getvar(a,"cape_3d",-1)
          slp1@_FillValue=-1
          slp1@description = "CAPE"
          slp1@units = "J/kg"
          myvar := slp1(0,:,:,:,:)
          delete(slp1)
        else if (NCLCNVAR2 .eq. "lcl") then
            slp1  = wrf_user_getvar(a,"cape_2d",-1)
            slp1@description = "Lifting Condensation Level"
            slp1@units = "m"
            myvar := slp1(2,:,:,:)
        else if (NCLCNVAR2 .eq. "lfc") then
            slp1 = wrf_user_getvar(a,"cape_2d",-1)
            slp1@description = "Level of Free Convection"
            slp1@units = "m"
            myvar := slp1(2,:,:,:)

        else if (NCLCNVAR2 .eq. "dust_total") then
            myvar  := a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
            myvar@description = "Total dust concentration"
            myvar@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR2 .eq. "dust_pm2.5") then
            myvar  := a->DUST_1+0.3125*a->DUST_2
            myvar@description = "Dust_PM2.5 concentration"
            myvar@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR2 .eq. "dust_pm10") then
            myvar  := a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
            myvar@description = "Dust_PM10 concentration"
            myvar@units = "Microgram/kg_dry_air"

        else if (NCLCNVAR2 .eq. "wind_s") then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
            myvar := wind_speed(uu10,vv10)
            myvar@description = "10m wind speed"
            myvar@units = "m s-1"

        else if (NCLCNVAR2 .eq. "wind_d") then
          if (.not.isdefined("uu10")) then
            uu10  = wrf_user_getvar(a,"U10",-1)
            vv10  = wrf_user_getvar(a,"V10",-1)
          end if
            myvar := wind_direction(uu10,vv10,0)
            myvar@description = "10m wind direction"
            myvar@units = "Degrees from north"

        else
        myvar := wrf_user_getvar(a,NCLCNVAR2,-1)        ; T in C

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

  mydim2 = dimsizes(dimsizes(myvar))  
  if (mydim2.eq.3) then
    tc_plane2 = myvar
    tc_plane2@PlotLevelID = "surface"
    else ;if dimsize equals 4
     if (NCLPLEV2.eq.0) then ;surface pressure
        tc_plane2 = myvar(:,0,:,:)
        tc_plane2@PlotLevelID = "surface"
       else

    if (.not.isdefined("p")) then
      p  = wrf_user_getvar(a, "pressure",-1)
    end if
        tc_plane2 = wrf_user_intrp3d(myvar,p,"h",NCLPLEV2,0.,False)
     end if
  end if


      else  ;;code ifpoly2

        NCLvarnames = asciiread("variablesCN2.txt", -1, "string")
        totvarsnum = dimsizes(NCLvarnames) - 1

        ncl_CNLEV2_num = tointeger(getenv("CNLEV2_num"))
        NCLPLEV2 = new(ncl_CNLEV2_num, "integer")
        i = 0
        do while(i.lt.ncl_CNLEV2_num)
          NCLPLEV2(i) = tointeger(getenv("CNLEV2"+i))
          i=i+1
        end do
        
        oneP2 = False
        if (ncl_CNLEV2_num.eq.(totvarsnum+1)) then
          NCLPLEV2 = new(ncl_CNLEV2_num, "integer")
          i = 0
          do while(i.lt.ncl_CNLEV2_num)
            NCLPLEV2(i) = tointeger(getenv("CNLEV2"+i))
            i=i+1
          end do
        else
          if (ncl_CNLEV2_num.eq.1) then
            delete(NCLPLEV2)
            NCLPLEV2 = new((totvarsnum+1), "integer")
            NCLPLEV2 = tointeger(getenv("CNLEV20"))
            oneP2 = True
          else
            print("Error: Number of pressure levels do not match the number of variables in < "\
             + asciiread(homedir+"/modules/totalequationCN20.txt", -1, "string")  + " >" )
            print("       You could put only one pressure for all the variables in the polynomial")
            exit()
          end if
        end if

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
              ListAppend(varlist2,f->DUST_1+f->DUST_2+f->DUST_3+f->DUST_4+f->DUST_5)
              varlist2[ii]@description = "Total dust concentration"
              varlist2[ii]@units = "Microgram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
              ListAppend(varlist2,f->DUST_1+0.3125*f->DUST_2)
              varlist2[ii]@description = "Dust_PM2.5 concentration"
              varlist2[ii]@units = "Microgram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm10") then
              ListAppend(varlist2,f->DUST_1+f->DUST_2+f->DUST_3+0.87*f->DUST_4)
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
        end do ;;code do_poly1

        varlist = NewList("lifo") ;;main list and checking the dims
        do ii = 0, totvarsnum ;;code docheck22
        if (dimsizes(dimsizes(varlist2[ii])).eq.3) then
            ListAppend(varlist,varlist2[ii])
            varlist[ii]@PlotLevelID = "surface"
          else ;if dimsize equals 4
            if (NCLPLEV2(ii).eq.0) then ;surface pressure
                ListAppend(varlist,varlist2[ii](:,0,:,:))
                varlist[ii]@PlotLevelID = "surface"
              else
                p  = wrf_user_getvar(a, "pressure",-1) ; pressure is our vertical coordinate
                ListAppend(varlist,wrf_user_intrp3d(varlist2[ii],p,"h",NCLPLEV2(ii),0.,False))
            end if
        end if
        end do ;;code docheck22


        ;;shell script222
rh = varlist[1]  ;;;added_new_line_by_sed222
T2 = varlist[0]  ;;;added_new_line_by_sed222

delete(varlist)
delete(varlist2)

  ;equation from namelist.wrf222
tc_plane2 = T2+rh  ;;;added_new_line_by_sed222

if (dimsizes(NCLPLEV2).eq.1) then
  if (NCLPLEV2.eq.0) then
    tc_plane2@PlotLevelID = "surface"
  else
    tc_plane2@PlotLevelID = NCLPLEV2
  end if
else
  if (oneP2) then
    tc_plane2@PlotLevelID = tointeger(getenv("CNLEV20"))
  else
    tc_plane2@PlotLevelID = "multi atmospheric levels"
  end if
end if

system("cd $postwrf_dir/modules && ./contourlvl_getinput2.sh")
system("ln -sf $postwrf_dir/modules/eqname $postwrf_dir")
eqname1 = asciiread("eqname", -1, "string")
system("ln -sf $postwrf_dir/modules/equnit $postwrf_dir")

equnit1 = asciiread("equnit", -1, "string")
tc_plane2@description = eqname1
tc_plane2@units = equnit1

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
  if (upper_bound2 .gt. max2) then ;checking the whiskers of box plot
    upper_bound2 = max2
  end if
  if (lower_bound2 .lt. min2) then ;checking the whiskers of box plot
    lower_bound2 = min2
  end if
  intv_range3 = upper_bound2 - lower_bound2
  opt3@cnLevelSelectionMode = "ManualLevels"
  if (NCLINTV2.eq.0 .or. NCLINTV2.gt.intv_range3) then
    opt3@cnLevelSpacingF = intv_range3/10
  else
    opt3@cnLevelSpacingF = NCLINTV2
  end if
   opt3@cnMaxLevelValF = upper_bound2
   opt3@cnMinLevelValF = lower_bound2
   opt3@cnMaxLevelCount = 255
end if ;end of VAR2


if (NCLwindonoff .eq. 1)
  NCLwindlev = tointeger(getenv("nclwindlev"))
  NCLwindsize = tointeger(getenv("windsize"))
  NCLwinddens = tofloat(getenv("winddens"))
  NCLwindcolor = getenv("windcolor")
  NCLwindthick = tofloat(getenv("windthick"))
  if (NCLwindlev.eq.0) then
    u  = wrf_user_getvar(a,"U10",-1)
    v  = wrf_user_getvar(a,"V10",-1)
    u_plane  = u
    v_plane  = v
    u_plane@PlotLevelID = "10 m"
    v_plane@PlotLevelID = "10 m"
    else
    u  = wrf_user_getvar(a,"ua",-1)        ; u averaged to mass points
    v  = wrf_user_getvar(a,"va",-1)        ; v averaged to mass points
    if (.not.isdefined("p")) then
      p  = wrf_user_getvar(a, "pressure",-1)
    end if
    u_plane  = wrf_user_intrp3d( u,p,"h",NCLwindlev,0.,False)
    v_plane  = wrf_user_intrp3d( v,p,"h",NCLwindlev,0.,False)
  end if

    opts = optfirst
     if (NCLtitle.ne.1) then
       opts = opt_notitle
     end if
    opts@vcRefMagnitudeF   = NCLwindsize
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
    opts@vcRefAnnoOrthogonalPosF = -0.24         ; Moves reference vector box inside the plot
    opts@vcRefAnnoOn       = True
    opts@vcGlyphStyle     = "CurlyVector"
end if
  pltres = True
  pltres@FontHeightF = 0.013 ;;no panel, no average
  mpres = True
  
  if (ocean_onoff.eq.1) then
  mpres@mpFillOn = True
  mpres@mpFillColors = (/"transparent","LightSkyBlue1","transparent","LightSkyBlue1", "transparent"/) ;background LightSkyBlue
  end if
  
  if (NCLgridline_onoff.eq.0) then
  mpres@mpGridAndLimbOn = False
  end if
  mpres@mpOutlineBoundarySets = "National"
  mpres@mpGeophysicalLineColor      = nclborder 
  mpres@mpNationalLineColor         = nclborder
  mpres@mpUSStateLineColor          = nclborder
  mpres@mpGridLineColor             = "Black"
  mpres@mpLimbLineColor             = "Black"
  mpres@mpPerimLineColor            = "Black"
  mpres@mpGeophysicalLineThicknessF = nclborder_thick
  mpres@mpGridLineThicknessF        = 2.0
  mpres@mpLimbLineThicknessF        = 2.0
  mpres@mpNationalLineThicknessF    = nclborder_thick
  mpres@mpUSStateLineThicknessF     = nclborder_thick
if (ncl_shape_onoff.eq.1 .or. ncl_province_onoff.eq.1 .or. point_onoff.eq.1) then

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

 myprov = new(ncl_province_num*(totstepsminus+1),graphic)
 shpres = True
 shpres@gsLineColor = nclborder
 shpres@gsLineThicknessF = nclborder_thick
end if

 if (NCLtitle.ne.1) then
  pltres@CommonTitle = True
  pltres@FontHeightF = 0.025
  pltres@NoTitles = True
 end if
pltres@PanelPlot= True
pltres@gsnFrame = False

if (panel_onoff.ne.1 .or. (NCLpanelrows.eq.1 .and. NCLpanelcolumns.eq.1)) then
  paneloption = False

 else ;;Panel plot

  if (NCLtitle.ne.1) then
   pltres@CommonTitle = True
   pltres@FontHeightF = 0.0145
   pltres@NoTitles = True
   else
   pltres@FontHeightF = 0.007
  end if
  pltres@FontHeightF = pltres@FontHeightF * (6/tofloat(NCLpanelrows*NCLpanelcolumns))^0.3
  
  if (NCLaverage_onoff.eq.1) then
  end if

  paneloption = True
  arrayplots = new (totstepsminus+1, graphic)
  pnlres                            = True
  pnlres@gsnPanelFigureStrings = (/"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","AB","AC","AD","AE","AF","AG","AH"/)
  pnlres@gsnPanelFigureStringsJust = "topleft"
 pnlres@gsnPanelYWhiteSpacePercent = 5       ; Add white space b/w plots.
 pnlres@gsnPanelLabelBar           = False    ; Turn on common labelbar
 pnlres@lbLabelAutoStride          = True    ; Spacing of lbar labels.
 pnlres@lbBoxMinorExtentF          = 0.13

  if (NCL3VARONOFF.eq.1 .and. cnmode.eq."Manual") then
    pnlres@txString                   = "colored contours: " + myvar@description + " (" + myvar@units + " )"
    pnlres@gsnPanelLabelBar = True
    opt1@lbLabelBarOn = False
  end if

end if

over_plot = new (totstepsminus+1, graphic)
dum1 = new (totstepsminus+1, graphic)

  wks = gsn_open_wks(type,filename)
  if (type .eq. "x11") then
province_dir_path = "modules/iran_provinces/"
else
province_dir_path = "../modules/iran_provinces/"
end if

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Time Loop
  kk = 0 ;for looping panel plots
  jjprov = 0
  jj = 0
    if (NCLaverage_onoff.ne.1) then ;code timeif122

      do it = start_timestep, ntimes, ncltstep
        
        print("Working on time: " + times(it))

        if (NCLtitle.ne.1) then
          pltres@PlotTitle   = times(it)
        end if

          if (NCL3VARONOFF.eq.1) then
            opt1@TimeLabel = times(it)
            contour_tc = wrf_contour(a,wks,tc_plane3(it,:,:),opt1)
          end if
          
          if (NCL1VARONOFF.eq.1) then
            opt2@TimeLabel = times(it)
            contour_tc2 = wrf_contour(a,wks,tc_plane1(it,:,:),opt2)
          end if

          if (NCL2VARONOFF.eq.1) then
            opt3@TimeLabel = times(it)
            contour_tc3 = wrf_contour(a,wks,tc_plane2(it,:,:),opt3)
          end if

          if (NCLwindonoff .eq. 1)
            opts@FieldTitle = "Wind Velocity"
            vector = wrf_vector(a,wks,u_plane(it,:,:),v_plane(it,:,:),opts)
          end if

          if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2,contour_tc3,vector/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2,contour_tc3/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2,vector/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc3,vector/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc3/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc,vector/),pltres,mpres)
          else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc2,contour_tc3,vector/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc2,contour_tc3/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc2,vector/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc2/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc3,vector/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
            plot = wrf_map_overlays(a,wks,(/contour_tc3/),pltres,mpres)
          else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
            plot = wrf_map_overlays(a,wks,(/vector/),pltres,mpres)
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

          if (ncl_shape_onoff.eq.1 .or. ncl_province_onoff.eq.1 .or. point_onoff.eq.1) then
            if (point_onoff.eq.1) then
              dum1(kk) = gsn_add_polymarker(wks, plot, NCLloclons, NCLloclats, pmres)
            end if
            
            if (label_onoff.eq.1) then
              dum2 = gsn_add_text(wks,plot,NCLlocnames,NCLloclons,NCLloclats-(80*NCLlabelsize),tres)
            end if
              
            if (ncl_shape_onoff.eq.1) then
              over_plot(kk) = gsn_add_shapefile_polylines(wks,plot,ncl_shape_path,shpres)
            end if

            if (ncl_province_onoff.eq.1) then
                jj=0
              do while(jj.lt.ncl_province_num)
                myprov(jjprov) = gsn_add_shapefile_polylines(wks,plot,province_dir_path+NCLprovince_name_lower(jj)+".shp",shpres)
                jjprov = jjprov + 1
                jj=jj+1
              end do
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

     if (NCLtitle.ne.1) then
      pltres@CommonTitle = True
      pltres@PlotTitle   = times(it) + " to " + times(it+ncltstep)
      if (panel_onoff.eq.1) then
        tstart = str_split(times(it), ":")
        tend = str_split(times(it+ncltstep), ":")
        pltres@PlotTitle = tstart(0) + " to " + tend(0)
      end if
     end if
     

      if (NCL3VARONOFF.eq.1) then
        opt1@TimeLabel = times(it) + " to " + times(it+ncltstep)
        contour_tc = wrf_contour(a,wks,dim_avg_n_Wrap(tc_plane3(it:(it+ncltstep),:,:),0),opt1)
      end if
      
      if (NCL1VARONOFF.eq.1) then
        opt2@TimeLabel = times(it) + " to " + times(it+ncltstep)
        contour_tc2 = wrf_contour(a,wks,dim_avg_n_Wrap(tc_plane1(it:(it+ncltstep),:,:),0),opt2)
      end if

      if (NCL2VARONOFF.eq.1) then
        opt3@TimeLabel = times(it) + " to " + times(it+ncltstep)
        contour_tc3 = wrf_contour(a,wks,dim_avg_n_Wrap(tc_plane2(it:(it+ncltstep),:,:),0),opt3)
      end if

      if (NCLwindonoff .eq. 1)
        opts@FieldTitle = "Wind Velocity"
        vector = wrf_vector(a,wks,dim_avg_n_Wrap(u_plane(it:(it+ncltstep),:,:),0),dim_avg_n_Wrap(v_plane(it:(it+ncltstep),:,:),0),opts)
      end if

      if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2,contour_tc3,vector/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2,contour_tc3/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2,vector/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc2/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc3,vector/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,contour_tc3/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc,vector/),pltres,mpres)
      else if (NCL3VARONOFF.eq.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc2,contour_tc3,vector/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc2,contour_tc3/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc2,vector/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.eq.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc2/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc3,vector/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.eq.1 .and. NCLwindonoff.ne.1) then
        plot = wrf_map_overlays(a,wks,(/contour_tc3/),pltres,mpres)
      else if (NCL3VARONOFF.ne.1 .and. NCL1VARONOFF.ne.1 .and. NCL2VARONOFF.ne.1 .and. NCLwindonoff.eq.1) then
        plot = wrf_map_overlays(a,wks,(/vector/),pltres,mpres)
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

      if (ncl_shape_onoff.eq.1 .or. ncl_province_onoff.eq.1 .or. point_onoff.eq.1) then
        
        if (point_onoff.eq.1) then
          dum1(kk) = gsn_add_polymarker(wks, plot, NCLloclons, NCLloclats, pmres)
        end if
        
        if (label_onoff.eq.1) then
          dum2 = gsn_add_text(wks,plot,NCLlocnames,NCLloclons,NCLloclats-(80*NCLlabelsize),tres)
        end if
          
        if (ncl_shape_onoff.eq.1) then
          over_plot(kk) = gsn_add_shapefile_polylines(wks,plot,ncl_shape_path,shpres)
        end if

        if (ncl_province_onoff.eq.1) then
          jj=0
          do while(jj.lt.ncl_province_num)
            myprov(jjprov) = gsn_add_shapefile_polylines(wks,plot,province_dir_path+NCLprovince_name_lower(jj)+".shp",shpres)
            jjprov = jjprov + 1
            jj=jj+1
          end do
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
  end if ;code timeif122
