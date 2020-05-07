;PostWRF Version 1.1 (Apr 2020)
;Programmed by Amirhossein Nikfal <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

  myfile = getenv("wrfout")

  var = str_match(myfile,"/" )
  if (ismissing(var)) then
    dir = systemfunc("pwd")
    a = addfile(dir + "/" + myfile,"r")
  else
    a = addfile(myfile,"r")
  end if

  cr = inttochar(10)

  mdims = getfilevardimsizes(a,"U") ; get some dimension sizes for the file
  nd = dimsizes(mdims)

  loc1 = wrf_user_ij_to_ll(a, 0, 0, True)
  loc2 = wrf_user_ij_to_ll(a, mdims(nd-1), mdims(nd-2), True)
  
  print("Range of longitudes (degrees): " + loc1(0) + " to " + loc2(0) + cr) ;west2east
  print("Range of latitudes (degrees): " + loc1(1) + " to " + loc2(1))       ;south2north
  print(""+loc1(0))
  print(""+loc1(1))
  print(""+loc2(0))
  print(""+loc2(1))
