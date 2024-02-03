load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"

load "read_wrfouts.ncl"

ncl_smooth = tointeger(getenv("smooth_onoff"))
NCLspinup = tointeger(getenv("spinup"))
NCLaverage_onoff = tointeger(getenv("average_onoff"))
NCLaverage_time = tointeger(getenv("averagetime"))
tiffresol = tointeger(getenv("tiffresol"))
all_steps = wrf_user_getvar(a,"XTIME",-1)
hourstep = (all_steps(1) - all_steps(0))/60
if (NCLspinup.ge.hourstep) then
 start_timestep = tointeger(NCLspinup/hourstep)
else
 start_timestep = 0
end if

   filename = getenv("outname")

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
 
        NCLvarnames = asciiread("variablesCN3.txt", -1, "string")
        totvarsnum = dimsizes(NCLvarnames) - 1

        ncl_CNLEV3_num = tointeger(getenv("GTIFFPLEV_num"))
        NCLPLEV3 = new(ncl_CNLEV3_num, "integer")
        i = 0
        do while(i.lt.ncl_CNLEV3_num)
          NCLPLEV3(i) = tointeger(getenv("GTIFFPLEVS"+i))
          i=i+1
        end do
        oneP1 = False
        asciiwrite (homedir+"/modules/geo_eq_ok.txt" , True)
        if (ncl_CNLEV3_num.eq.(totvarsnum+1)) then
          NCLPLEV3 = new(ncl_CNLEV3_num, "integer")
          i = 0
          do while(i.lt.ncl_CNLEV3_num)
            NCLPLEV3(i) = tointeger(getenv("GTIFFPLEVS"+i))
            i=i+1
          end do
        else
          if (ncl_CNLEV3_num.eq.1) then
            delete(NCLPLEV3)
            NCLPLEV3 = new((totvarsnum+1), "integer")
            NCLPLEV3 = tointeger(getenv("GTIFFPLEVS0"))
            oneP1 = True
          else
            print("Error: Number of pressure levels do not match the number of variables in < "\
             + asciiread(homedir+"/modules/totalequation0.txt", -1, "string")  + " >" )
            print("       You could put only one pressure for all the variables in the polynomial")
            asciiwrite (homedir+"/modules/geo_eq_ok.txt" , False)
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
              ListAppend(varlist2,wrf_user_getvar(a, "DUST_1", -1) + wrf_user_getvar(a, "DUST_2", -1) + wrf_user_getvar(a, "DUST_3", -1) + wrf_user_getvar(a, "DUST_4", -1) + wrf_user_getvar(a, "DUST_5", -1))
              varlist2[ii]@description = "Total dust concentration"
              varlist2[ii]@units = "Micro_gram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm2.5") then
              ListAppend(varlist2,wrf_user_getvar(a, "DUST_1", -1) + 0.3125*wrf_user_getvar(a, "DUST_2", -1))
              varlist2[ii]@description = "Dust equal to PM2.5 concentration"
              varlist2[ii]@units = "Micro_gram/kg_dry_air"

          else if (NCLvarnames(ii) .eq. "dust_pm10") then
              ListAppend(varlist2,wrf_user_getvar(a, "DUST_1", -1) + wrf_user_getvar(a, "DUST_2", -1) + wrf_user_getvar(a, "DUST_3", -1) + 0.87*wrf_user_getvar(a, "DUST_4", -1))
              varlist2[ii]@description = "Dust equal to PM10 concentration"
              varlist2[ii]@units = "Micro_gram/kg_dry_air"

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
rh = varlist[0]  ;;;added_new_line_by_sed333
delete(varlist)
delete(varlist2)

  ;equation from namelist.wrf333
tc_plane3 = rh/100  ;;;added_new_line_by_sed333

if (ncl_smooth.eq.1) then
  wrf_smooth_2d(tc_plane3,3)
end if

system("cd $postwrf_dir/modules && ./geotiff_getinput.sh")
system("ln -sf $postwrf_dir/modules/eqname $postwrf_dir")
eqname = asciiread("eqname", -1, "string")
system("ln -sf $postwrf_dir/modules/equnit $postwrf_dir")
equnit = asciiread("equnit", -1, "string")
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Time Loop
    jjprov = 0
    jj = 0
    totstepsminus = dimsizes(times)-1
    ntimes = totstepsminus
    lat2d = wrf_user_getvar(a, "XLAT",-1)
    lon2d = wrf_user_getvar(a, "XLONG",-1)
    if (tiffresol.eq.0) then
      delY = a[0]@DY/1000
      delX = a[0]@DX/1000
    else
      delY = tiffresol
      delX = tiffresol
    end if
    avg_lat = a[0]@CEN_LAT
    deg2km = 6371 * cos((3.1416/180)*avg_lat) * 2 * 3.1416 / 360
    Yratio = deg2km/delY
    Xratio = deg2km/delX
    minlat2d = min(lat2d)
    maxlat2d = max(lat2d)
    intvlat2d = tointeger(ceil((maxlat2d - minlat2d)*Yratio*1.18))
    minlon2d = min(lon2d)
    maxlon2d = max(lon2d)
    intvlon2d = tointeger(ceil((maxlat2d - minlat2d)*Xratio*1.18)) + 1
    lat = fspan(minlat2d, maxlat2d, intvlat2d)
    lon = fspan(minlon2d, maxlon2d, intvlon2d)
    tc_plane33_rectilinear  = rcm2rgrid(lat2d(0,:,:),lon2d(0,:,:),tc_plane3,lat,lon,0)
    tc_plane33_rectilinear!0         = "time"
    tc_plane33_rectilinear!1         = "latitude"                      ; assign named dimensions
    tc_plane33_rectilinear!2         = "longitude"
    tc_plane33_rectilinear&latitude  = lat
    tc_plane33_rectilinear&longitude  = lon
    tc_plane33_rectilinear@long_name  = eqname
    tc_plane33_rectilinear@unit  = equnit
    
    if (ncl_CNLEV3_num.eq.1) then
      Plevel = NCLPLEV3(0)+"hpa_"
      else
      Plevel = "multi_levels_"
    end if
    if (NCLaverage_onoff.ne.1) then ;code timeif122
    ncltstep = tointeger(getenv("tstep"))
    do it = start_timestep, ntimes, ncltstep
      print("Working on time: " + times(it))
      tstart_arr = str_split(times(it), ":")
      tstart = tstart_arr(0)
      ncdf = addfile(eqname+"_"+Plevel+tstart+".nc" ,"c")
      ncdf@Conventions   = "None"
      varname = "myvar"
      ncdf->varname = tc_plane33_rectilinear(it,:,:)
      ncdf->latitude = lat
      ncdf->longitude = lon
    end do        ; END OF TIME LOOP
 
  else ;;Averaging code timeif122
    ncltstep = tointeger(NCLaverage_time/hourstep)
    totstepsminus = totstepsminus - start_timestep
    ntimes = totstepsminus - mod(totstepsminus, ncltstep) - ncltstep
    do it = start_timestep, ntimes, ncltstep
      print("Working on time range (average): " + times(it) + " to " + times(it+ncltstep) )
      tstart_arr = str_split(times(it), ":")
      tstart = tstart_arr(0)
      tend_arr = str_split(times(it+ncltstep), ":")
      tend = tend_arr(0)
      ncdf = addfile(eqname+"_"+Plevel+tstart+"_to_"+tend+".nc" ,"c")
      ncdf@Conventions   = "None"
      varname = "myvar"
      ncdf->varname = dim_avg_n_Wrap(tc_plane33_rectilinear(it:(it+ncltstep),:,:),0)
      ncdf->latitude = lat
      ncdf->longitude = lon
    end do        ; END OF TIME LOOP

  end if ;code timeif122
