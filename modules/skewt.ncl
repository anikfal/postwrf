;PostWRF Version 1.0 (May 2018)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

myfile = getenv("wrfout")
 var = str_match(myfile,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  a = addfile(dir + "/" + myfile,"r")
else
  a = addfile(myfile,"r")
end if
nclimgtype = getenv("imgfmt")
nclfilename = getenv("outname")
  type = nclimgtype
  wks = gsn_open_wks(type,nclfilename)
  gsn_define_colormap(wks,"WhViBlGrYeOrReWh")

;Second Line
lines2 = getenv("ncllocs")
linesmain = tointeger(lines2)
NCLlocnames = new(linesmain,"string")
i=0
do while(i.le.(linesmain-1))
 NCLlocnames(i) = getenv("ncllocnames"+i)
 i=i+1
end do
totlocs=dimsizes(NCLlocnames)
delete(lines2)

;Third Line
lines2 = getenv("ncllats")
lines = tointeger(lines2)
NCLloclats2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLloclats2(i) = getenv("nclloclats"+i)
 i=i+1
end do
NCLloclats=stringtofloat(NCLloclats2)
delete(lines2)
delete(lines)

;Fourth Line
lines2 = getenv("ncllons")
lines = tointeger(lines2)
NCLloclons2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLloclons2(i) = getenv("nclloclons"+i)
 i=i+1
end do
NCLloclons=stringtofloat(NCLloclons2)
delete(lines2)
delete(lines)
delete(i)

  ncltstep2 = getenv("tstep")
  ncltstep = tointeger(ncltstep2)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Get some dimension info - so we can check to make sure
; the sounding locations are inside the model domain
  mdims = getfilevardimsizes(a,"P")
  nd = dimsizes(mdims)
  dimX = mdims(nd-1)
  dimY = mdims(nd-2)

; List of stations, and their lat/lon locations we are interested in

stat = NCLlocnames
lats = NCLloclats
lons = NCLloclons

; Get ij points in model domain for all above locations
; loc(1,:) is south-north (y) and loc(0,:) is west-east (x)
  locs = wrf_user_ll_to_ij(a, lons, lats, True)

; Remove the data points outside our model domain
  num_st = dimsizes(stat)
  do ip = 0, num_st-1
    if ( locs(0,ip) .lt. 1 .or. locs(0,ip) .gt. dimX .or. locs(1,ip) .lt. 1 .or. locs(1,ip) .gt. dimY )
      print("Station - " + stat(ip) + " at location: "+ lats(ip) +" ; "+ lons(ip) + " is outside model domain" )
      locs(:,ip) = -999
      stat(ip) = " "
    end if
  end do

  stat@_FillValue = " "
  inds = ind(.not. ismissing(stat))
  ip_locs = stat(inds)

  loc1D = ndtooned(locs)
  indloc = ind(.not. ismissing(loc1D))
  loc1D_new = loc1D(indloc)
  num_st = num(.not. ismissing(locs))/2
  loc = new( (/2,num_st/), typeof(locs) )
  loc = onedtond(loc1D_new,dimsizes(loc))
  loc = loc - 1    ; location in NCL space to use as array indeses

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; What times and how many time steps are in the data set?
  times  = wrf_user_getvar(a,"times",-1) ; get times in the file
  ntimes = dimsizes(times)         ; number of times in the file
  do it = 0,ntimes-1,ncltstep        ; TIME LOOP

    print("Working on time: " + times(it) )

    tc  = wrf_user_getvar(a,"tc",it)         ; T in C
    td  = wrf_user_getvar(a,"td",it)         ; dew point temperature
    p   = wrf_user_getvar(a, "pressure",it)  ; grid point pressure
    z   = wrf_user_getvar(a, "z",it)         ; grid point height
    uvm = wrf_user_getvar(a,"uvmet",it)      ; umet and vmet averaged to mass points
					     ; This is a 4D array where
					     ; uvm(0,:,:,:) is umet, and
					     ; uvm(1,:,:,:) is vmet, and
					     ; This function rotate winds to earth coord.
  ; extract u and v from uvm array, and turn wind into kts
    u   = uvm(0,:,:,:)*1.94386 
    v   = uvm(1,:,:,:)*1.94386

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   nip = dimsizes(ip_locs)  
   do ip = 0, nip-1         ; LOOP through all stations in model domain


  ;      Define a few skew-T plotting options
         skewtOpts          = True
         skewtOpts@DrawHeightScale   = True    ; plot height scale on side
         skewtOpts@DrawHeightScaleFt = False   ; plot height scale in km
         skewtOpts@DrawStandardAtm   = True    ; draw standard atm on plot
         skewtOpts@vpXF              = 0.12    ; controls off-set from left
         skewtOpts@vpYF              = 0.87    ; controls off-set from top
         skewtOpts@vpWidthF          = 0.75    ; controls size of plot
         skewtOpts@vpHeightF         = 0.75    ; controls size of plot
         skewtOpts@DrawFahrenheit    = False   ; use deg C scale
         skewtOpts@tiMainFontHeightF = 0.015   ; change height of main title
        ;skewtOpts@DrawColLine       = False   ; draw lines in black
         skewtOpts@DrawColAreaFill   = True    ; color on background plot
        ;skewtOpts@DrawColAreaColor  = "Green" ; final color may depend on the color table used
         skewtOpts@DrawColAreaColor  = 53      ; Light Green for WhViBlGrYeOrReWh color table
         skewtOpts@PrintOpts         = False   ; do not print options out


  ;      Get the skew-T background
         skewtOpts@tiMainString = ip_locs(ip)  + " at " + times(it)
         skewt_bkgd             = skewT_BackGround (wks, skewtOpts)
         draw (skewt_bkgd)


  ;      Draw the skew-T plot
         dataOpts           = True
         dataOpts@Parcel    = 1
         dataOpts@WspdWdir  = False  ; wind speed and dir [else: u,v]
         dataOpts@HspdHdir  = True   ; wind speed and dir [else: u,v]
         dataOpts@PlotWindH = False  ; plot wind barbs at h lvls [pibal; special]
         skewT_data = skewT_PlotData(wks, skewt_bkgd, p(:,loc(1,ip),loc(0,ip)), \
                                                     tc(:,loc(1,ip),loc(0,ip)), \
                                                     td(:,loc(1,ip),loc(0,ip)), \
                                                      z(:,loc(1,ip),loc(0,ip)), \
                                                      u(:,loc(1,ip),loc(0,ip)), \
                                                      v(:,loc(1,ip),loc(0,ip)), \
                                                      dataOpts)

  ;      Close the frame
         frame(wks)

         delete(skewtOpts)
         delete(dataOpts)
         delete(skewT_data)
         delete(skewt_bkgd)


   end do     ; END OF LOCATIONS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  end do        ; END OF TIME LOOP

end
