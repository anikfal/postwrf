;;PostWRF Version 1.2 (May 2021)
;;Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

load "read_wrfouts.ncl"
wrffile = a[0]
lat0 = wrffile->XLAT
long0 = wrffile->XLONG
lat2d = lat0(0, :, :)
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

if (fileexists(ncfile+".nc")) then ;;check if the same NetCDF file exists to remove it
    system("rm " + ncfile+".nc")
end if
brightness_nc = addfile(ncfile+".nc", "c")
copy_VarAtts(wrffile, brightness_nc)
do bandnum=0, allbands ;each band
    do jjlat=0, lat_count
        do iilong=0, long_count
            kkline = jjlat*long_count_plus + iilong
            myband = tofloat(str_split(AllLines(kkline), " "))
            rttovvar(bandnum, jjlat, iilong) = myband(bandnum)
        end do
    end do
    mynum = bandnum+1
    band_name = "band"+mynum
    print(" " + band_name + ": Converting to NetCDF ...")
    brightness_nc->$band_name$ = rttovvar(bandnum, :, :)
end do
brightness_nc->latitude = lat2d
brightness_nc->longitude = lon2d

if (getenv("imgfmt").eq."GeoTIFF") then  ;;Creating rectilinear
    minlat2d = min(lat2d)
    maxlat2d = max(lat2d)
    intvlat2d = tointeger(ceil((maxlat2d - minlat2d)*10))
    minlon2d = min(lon2d)
    maxlon2d = max(lon2d)
    intvlon2d = tointeger(ceil((maxlon2d - minlon2d)*10))
    lat = fspan(minlat2d, maxlat2d, intvlat2d)
    lon = fspan(minlon2d, maxlon2d, intvlon2d)
    do bandnum=0, allbands ;each band
        mynum = bandnum+1
        band_name = "band"+mynum
        print(" " + band_name + ": Regridding to reclininear ...")
        brightness_rectilinear := addfile(band_name+"_"+ncfile+".nc", "c")
        copy_VarAtts(wrffile, brightness_rectilinear)
        myvar = rcm2rgrid(lat2d, lon2d, rttovvar(bandnum, :, :), lat, lon, 0)
        myvar!0         = "latitude"
        myvar!1         = "longitude"
        myvar&latitude  = lat
        myvar&longitude = lon
        brightness_rectilinear->$band_name$ = myvar
    end do
end if