;PostWRF Version 1.1 (Apr 2020)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/time_axis_labels.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/ut_string.ncl"

begin
 myfile = getenv("wrfout")
 var = str_match(myfile,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if

 print("")
 geotiffvar = getenv("GTIFFVAR")
 NCLspinup = tointeger(getenv("spinup"))
 NCLaverage_onoff = tointeger(getenv("average_onoff"))
 NCLaverage_time = tointeger(getenv("averagetime"))
 ncl_smooth = tointeger(getenv("smooth_onoff"))

 all_steps=a->XTIME
hourstep = (all_steps(1) - all_steps(0))/60
if (NCLspinup.ge.hourstep) then
 start_timestep = tointeger(NCLspinup/hourstep)
else
 start_timestep = 0
end if
homedir = getenv("postwrf_dir")
asciiwrite (homedir+"/modules/geo_eq_ok.txt" , True)

  times = wrf_user_getvar(a,"times",-1)  ; get all times in the file
  yy  = asciiread(".AllWRFVariables", -1, "string")
  if_polynom = False
  if_valid   = True
  varplus = str_match(geotiffvar,"+")
  varminus = str_match(geotiffvar,"-")
  varmult = str_match(geotiffvar,"*")
  vardiv = str_match(geotiffvar,"/")
  varexp = str_match(geotiffvar,"^")
  varopenp = str_match(geotiffvar,"(")
  varclosep = str_match(geotiffvar,")")
  if( .not.ismissing(varplus) .or. .not.ismissing(varminus) .or. .not.ismissing(varmult) \
    .or. .not.ismissing(vardiv) .or. .not.ismissing(varexp) .or. .not.ismissing(varopenp) \
    .or. .not.ismissing(varclosep) ) then ;;if one is filled
    if_polynom = True
    ; homedir = getenv("postwrf_dir")
    ; asciiwrite (homedir+"/modules/geo_eq_ok.txt" , True)
    asciiwrite (homedir+"/modules/totalequation.txt" , geotiffvar)
    system("cd $postwrf_dir/modules && ./separation.sh") ;;variable.txt
    system("ln -sf $postwrf_dir/modules/variables.txt .")
    system("ln -sf $postwrf_dir/modules/totalequation.txt .")
    polynom3 = asciiread("variables.txt", -1, "string")
    asciiwrite (homedir+"/modules/variablesCN3.txt" , polynom3)
    system("ln -sf $postwrf_dir/modules/variablesCN3.txt .")
    vardims = dimsizes(polynom3)
    do ii = 0, vardims-1 ;;check if polynomial variables are valid
      if ( all(yy.ne.polynom3(ii)) ) then
        print("Found invalid variable name")
        delete(geotiffvar)
        geotiffvar = ""
        if_valid = False
        break
      end if
    end do
  end if

if (if_polynom .and. if_valid) then ;;if not valid, do not exit, showing message of not valid
  asciiwrite (homedir+"/modules/polynom_status.txt", if_polynom)
  print("Please wait. NCL is processing ...")
  print("")
  system("cd $postwrf_dir/modules && ./geotiff_sed.sh") ;;sed
  system("cd $postwrf_dir/modules && ncl -Q geotiff_equation.ncl")
  exit()
end if

 if ( any(yy.eq.geotiffvar) ) then  ;code att2

  NCLPLEV3 = tointeger(getenv("GTIFFPLEVS0")) ;pressure_levelsS
  if (geotiffvar .eq. "cape_surface") then
   slp1 = wrf_user_getvar(a,"cape_2d",-1)
   slp1@_FillValue=-1
   slp1@description = "CAPE"
   slp1@units = "J/kg"
   tc = slp1(0,:,:,:)
  else if (geotiffvar .eq. "cin_surface") then
   slp1 = wrf_user_getvar(a,"cape_2d",-1)
   slp1@_FillValue=-1
   slp1@description = "CIN"
   slp1@units = "J/kg"
   tc = slp1(1,:,:,:)
  else if (geotiffvar .eq. "cin_3d") then
     slp1  = wrf_user_getvar(a,"cape_3d",-1)
     slp1@_FillValue=-1
     slp1@description = "CIN"
     slp1@units = "J/kg"
     tc = slp1(1,:,:,:,:)
  else if (geotiffvar .eq. "cape_3d") then
     slp1 = wrf_user_getvar(a,"cape_3d",-1)
     slp1@_FillValue=-1
     slp1@description = "CAPE"
     slp1@units = "J/kg"
     tc = slp1(0,:,:,:,:)
     delete(slp1)
 else if (geotiffvar .eq. "lcl") then
     slp1  = wrf_user_getvar(a,"cape_2d",-1)
     slp1@description = "Lifting Condensation Level"
     slp1@units = "m"
     tc = slp1(2,:,:,:)
else if (geotiffvar .eq. "lfc") then
     slp1 = wrf_user_getvar(a,"cape_2d",-1)
     slp1@description = "Level of Free Convection"
     slp1@units = "m"
     tc = slp1(2,:,:,:)

else if (geotiffvar .eq. "dust_total") then
     tc  = a->DUST_1+a->DUST_2+a->DUST_3+a->DUST_4+a->DUST_5
     tc@description = "Total dust concentration"
     tc@units = "Micro_gram/kg_dry_air"

 else if (geotiffvar .eq. "dust_pm2.5") then
     tc  = a->DUST_1+0.3125*a->DUST_2
     tc@description = "Dust equal to PM2.5 concentration"
     tc@units = "Micro_gram/kg_dry_air"

 else if (geotiffvar .eq. "dust_pm10") then
     tc  = a->DUST_1+a->DUST_2+a->DUST_3+0.87*a->DUST_4
     tc@description = "Dust equal to PM10 concentration"
     tc@units = "Micro_gram/kg_dry_air"

 else if (geotiffvar .eq. "wind_s") then
     uu10  = wrf_user_getvar(a,"U10",-1)
     vv10  = wrf_user_getvar(a,"V10",-1)
     tc = wind_speed(uu10,vv10)
     tc@description = "10m wind speed"
     tc@units = "m s-1"

 else if (geotiffvar .eq. "wind_d") then
  if (.not.isdefined("uu10")) then
     uu10  = wrf_user_getvar(a,"U10",-1)
     vv10  = wrf_user_getvar(a,"V10",-1)
  end if
     tc = wind_direction(uu10,vv10,0)
     tc@description = "10m wind direction"
     tc@units = "Degrees from north"

 else
 tc = wrf_user_getvar(a,geotiffvar,-1)        ; T in C

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

 if (mydim1.eq.3) then
    tc_plane33 = tc
    tc_plane33@PlotLevelID = "surface"
  else ;if dimsize equals 4
     if (NCLPLEV3.eq.0) then ;surface pressure
        tc_plane33 = tc(:,0,:,:)
        tc_plane33@PlotLevelID = "surface"
       else
        p  = wrf_user_getvar(a, "pressure",-1) ; pressure is our vertical coordinate
        tc_plane33 = wrf_user_intrp3d(tc,p,"h",NCLPLEV3,0.,False)
     end if
end if
  if (ncl_smooth.eq.1) then
    wrf_smooth_2d(tc_plane33,3)
  end if
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Time Loop
  jjprov = 0
  jj = 0
  totstepsminus = dimsizes(times)-1
  ntimes = totstepsminus
  lat2d = a->XLAT
  lon2d = a->XLONG
  minlat2d = min(lat2d)
  maxlat2d = max(lat2d)
  intvlat2d = tointeger(ceil((maxlat2d - minlat2d)*10))
  minlon2d = min(lon2d)
  maxlon2d = max(lon2d)
  intvlon2d = tointeger(ceil((maxlon2d - minlon2d)*10))
  lat = fspan(minlat2d, maxlat2d, intvlat2d)
  lon = fspan(minlon2d, maxlon2d, intvlon2d)
  tc_plane33_rectilinear  = rcm2rgrid(lat2d(0,:,:),lon2d(0,:,:),tc_plane33,lat,lon,0)
  tc_plane33_rectilinear!0         = "time"
  tc_plane33_rectilinear!1         = "latitude"                      ; assign named dimensions
  tc_plane33_rectilinear!2         = "longitude"
  tc_plane33_rectilinear&latitude  = lat
  tc_plane33_rectilinear&longitude  = lon
  if (NCLaverage_onoff.ne.1) then ;code timeif122
    ncltstep = tointeger(getenv("tstep"))
    do it = start_timestep, ntimes, ncltstep
      print("Working on time: " + times(it))
      tstart_arr = str_split(times(it), ":")
      tstart = tstart_arr(0)
      ncdf = addfile(geotiffvar+"_"+NCLPLEV3+"hpa_"+tstart+".nc" ,"c")
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
      ncdf = addfile(geotiffvar+"_"+NCLPLEV3+"hpa_"+"avg_"+tstart+"_to_"+tend+".nc" ,"c")
      ncdf@Conventions   = "None"
      varname = "myvar"
      ncdf->varname = dim_avg_n_Wrap(tc_plane33_rectilinear(it:(it+ncltstep),:,:),0)
      ncdf->latitude = lat
      ncdf->longitude = lon
    end do        ; END OF TIME LOOP
  end if ;code timeif122

else
print("")
print("Error: one or more contour variables in namelist.wrf are not valid for " + myfile)

end if ; code att2 


end
