timelist = asciiread("wrf_time_list.txt", -1, "integer") - 1
load "read_wrfouts.ncl"
wrffile = a
pressure = wrf_user_getvar(wrffile, "pressure", -1)
times = wrf_user_getvar(wrffile,"times",-1)
temp = wrf_user_getvar(wrffile, "tk", -1)
totallevels = dimsizes(temp(0,:,0,0))
wvapor1 = wrf_user_getvar(wrffile, "QVAPOR", -1)
cloud_fraction = wrf_user_getvar(wrffile, "cfrac", -1)
cloud_top_pressure = new(1,"float")
cloud_top_pressure = 200
wvapor = wvapor1 / (1 + wvapor1)
t2 = wrf_user_getvar(wrffile, "T2", -1)
q2mixing = wrf_user_getvar(wrffile, "Q2", -1)
q2 = q2mixing
q2 = q2mixing / (1 + q2mixing)
p2 = wrf_user_getvar(wrffile, "PSFC", -1) / 100
u10 = wrf_user_getvar(wrffile, "U10", -1)
v10 = wrf_user_getvar(wrffile, "V10", -1)
skint = wrf_user_getvar(wrffile, "TSK", -1)
landmask = wrf_user_getvar(wrffile, "LANDMASK", -1)
landmask := where(landmask.eq.1,0,1)
latitude = wrf_user_getvar(wrffile, "XLAT", -1)
longitude = wrf_user_getvar(wrffile, "XLONG", -1)
elevation = wrf_user_getvar(wrffile, "ter", -1) / 1000

rad2deg = 180/3.141593
zenith_solar = acos( wrf_user_getvar(wrffile, "COSZEN", -1) ) * rad2deg
azimuth_solar = 0.0 ;Arbitrary (not effective for IR simulations)
beta = acos( cos(latitude/rad2deg)*cos((longitude-41.5)/rad2deg) )
zenith_sat_sin = 42164*sin(beta) / (1.8084*1e9 - 5.3725*cos(beta)*1e8)^0.5
zenith_sat := asin(zenith_sat_sin)*rad2deg
azimuth_sat = 0.0 ;Arbitrary (not effective for IR simulations)
iilon_total = dimsizes(longitude(0,0,:))
jjlat_total = dimsizes(latitude(0,:,0))
totprofnum = iilon_total*jjlat_total
tablename = getenv("tablename")
headermain = (/"!", \
            "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", \
            "! WRF File Name: " + a[0]@SIMULATION_START_DATE, \
            "! TOTAL PROFILES (Grid Points): " + totprofnum, \
            "! TOTAL LEVELS (in each profile): " + totallevels, \
            "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", \
            "!", \
            "! Specify input profiles for example_aer_file_fwd.F90.", \
            "! Multiple profiles may be described: follow the same format for each one.", \
            "! Comment lines (starting with '!') are optional.", \
            "!", \
            "! Gas units (must be same for all profiles)", \
            "! 0 => ppmv over dry air", \
            "! 1 => kg/kg over moist air", \
            "! 2 => ppmv over moist air", \
            "!"/)
hlistmain = [/headermain/]

timedim = dimsizes(timelist) - 1
do tt=0, timedim
    ttstep = timelist(tt)
    if (timelist(tt).ge.dimsizes(times)) then
      print(timelist(tt) + " is greater than total number of times (" + dimsizes(times) + ")")
      break
    end if
    print("  Making profiles for time slot " + (ttstep+1) + ": " + times(ttstep) + " ...")
    time_suffix := str_split(times(ttstep), ":")
    table_directory = tablename + "_" +  time_suffix(0) + ".dat"
    write_table(table_directory, "w", hlistmain, "%s")
    gas_unit = 1
    alist = [/gas_unit/]
    write_table(table_directory, "a", alist, "%d")

    do jjlatitude=0, jjlat_total-1
        jjlat_title = jjlatitude+1
        kk = jjlatitude * iilon_total
        do iilongitude=0, iilon_total-1
            iilon_title = iilongitude+1
            profnumber = kk + iilon_title
            header = "! --- Start of profile (lat, lon):"
            prof_num = profnumber + " (" + jjlat_title + ", " + iilon_title + ") out of (" + jjlat_total + ", " + iilon_total + ")"
            hlist = [/header, prof_num/]
            write_table(table_directory, "a", hlist, "%s%s")
            delete(header)

            plevels = pressure(ttstep,::-1,jjlatitude,iilongitude)
            delete(alist)
            alist = [/plevels/]
            write_table(table_directory, "a", alist, "%f")

            header = (/"!",\
            "! Temperature profile (K)",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            tlevels = temp(ttstep,::-1,jjlatitude,iilongitude)
            delete(alist)
            alist = [/tlevels/]
            write_table(table_directory, "a", alist, "%f")

            header = (/"!",\
            "! Water vapour profile (kg/kg)",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            qlevels = wvapor(ttstep,::-1,jjlatitude,iilongitude)
            delete(alist)
            alist = [/qlevels/]
            write_table(table_directory, "a", alist, "%1.12f")

            header = (/"!",\
            "! Ozone profile (ppmv) - currently not read in",\
            "! Ozone data ..."/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            delete(header)
            header = (/"!",\
            "! Near-surface variables:",\
            "! 2m T (K)    2m q (kg/kg) 2m p (hPa) 10m wind u (m/s)  10m wind v (m/s)  wind fetch (m)",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            t2_sfc = t2(ttstep,jjlatitude,iilongitude)
            q2_sfc = q2(ttstep,jjlatitude,iilongitude)
            p2_sfc = p2(ttstep,jjlatitude,iilongitude)
            u10_sfc = u10(ttstep,jjlatitude,iilongitude)
            v10_sfc = v10(ttstep,jjlatitude,iilongitude)
            wind_fetch = 100000
            delete(alist)
            alist = [/t2_sfc, q2_sfc, p2_sfc, u10_sfc, v10_sfc, wind_fetch/]
            write_table(table_directory, "a", alist, "%2.2f%f%2.2f%2.2f%2.2f%i")

            header = (/"!",\
            "! Skin variables:",\
            "! Skin T (K)  Salinity  FASTEM parameters for land surfaces (not needed for this app; ignored)",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            skintemp = skint(ttstep,jjlatitude,iilongitude)
            delete(alist)
            slanitity = 35.0
            fastem1 = 3.0
            fastem2 = 5.0
            fastem3 = 15.0
            fastem4 = 0.1
            fastem5 = 0.3
            alist = [/skintemp, slanitity, fastem1, fastem2, fastem3, fastem4, fastem5/]
            write_table(table_directory, "a", alist, "%2.2f%2.2f%2.2f%2.2f%2.2f%2.2f%2.2f")

            delete(header)
            header = (/"!",\
            "! Surface type (0=land, 1=sea, 2=sea-ice) and water type (0=fresh, 1=ocean) - water types for all cases are assumed to be ocean",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            surface_type = landmask(ttstep,jjlatitude,iilongitude)
            water_type = 1 ;set to ocean for all grid points
            delete(alist)
            alist = [/surface_type, water_type/]
            write_table(table_directory, "a", alist, "%i%i")

            delete(header)
            header = (/"!",\
            "! Elevation (km), latitude and longitude (degrees)",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            myelev = elevation(ttstep,jjlatitude,iilongitude)
            mylat = latitude(ttstep,jjlatitude,iilongitude)
            mylong = longitude(ttstep,jjlatitude,iilongitude)
            delete(alist)
            alist = [/myelev, mylat, mylong/]
            write_table(table_directory, "a", alist, "%2.2f%2.2f%2.2f")

            delete(header)
            header = (/"!",\
            "! Sat. zenith and azimuth angles, solar zenith and azimuth angles (degrees); azimuth angles have been ignored",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            sat_zenith = zenith_sat(ttstep,jjlatitude,iilongitude)
            sat_azimuth = azimuth_sat
            solar_zenith = zenith_solar(ttstep,jjlatitude,iilongitude)
            solar_azimuth = azimuth_solar
            delete(alist)
            alist = [/sat_zenith, sat_azimuth, solar_zenith, solar_azimuth/]
            write_table(table_directory, "a", alist, "%2.2f%2.2f%2.2f%2.2f")

            delete(header)
            header = (/"!",\
            "! Cloud top pressure (hPa) and cloud fraction for simple cloud scheme",\
            "!"/)
            hlist = [/header/]
            write_table(table_directory, "a", hlist, "%s")

            delete(alist)
            cloud_fraction_total = max( (/ cloud_fraction(0,ttstep,jjlatitude,iilongitude), cloud_fraction(1,ttstep,jjlatitude,iilongitude), cloud_fraction(2,ttstep,jjlatitude,iilongitude) /) )
            alist = [/cloud_top_pressure, cloud_fraction_total/]
            write_table(table_directory, "a", alist, "%2.2f%2.2f")

            delete(header)
            header = (/"! --- End of profile (lat, lon):"/)
            hlist = [/header,prof_num/]
            write_table(table_directory, "a", hlist, "%s%s")
            delete(prof_num)
        
        end do ;ii
    end do ;jj
end do ;ttstep