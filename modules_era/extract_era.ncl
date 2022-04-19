load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

begin

myfilename = systemfunc("ls postwrf_era_*")
var = str_match(myfilename,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  aaa = addfile(dir + "/" + myfilename,"r")
  else
  aaa = addfile(myfilename,"r")
end if

levs = aaa->level
levdim = dimsizes(levs)-1
lowestPressureLev = levs(levdim)
NCLaverage_onoff = tointeger(getenv("average_onoff"))
NCLaverage_time = tointeger(getenv("averagetime"))
all_steps = tointeger(cd_calendar(aaa->time, 3))
time_last = getenv("tlast_ind")
time_first = tointeger(getenv("tfirst_ind")) - 1
if (time_last .eq. "last_index_era") then
  time_last := dimsizes(all_steps) - 1
  else
  time_last := tointeger(time_last) - 1
end if

lines = tointeger(getenv("nclvars"))
NCLvarnames = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLvarnames(i) = getenv("nclwrfvar"+i)
 i=i+1
end do
delete(lines)

;Second Line
linesmain = tointeger(getenv("ncllocs"))
NCLlocnames = new(linesmain,"string")
i=0
do while(i.le.(linesmain-1))
 NCLlocnames(i) = getenv("ncllocnames"+i)
 i=i+1
end do
totlocs=dimsizes(NCLlocnames)

;Third Line
lines = tointeger(getenv("ncllats"))
NCLloclats2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLloclats2(i) = getenv("nclloclats"+i)
 i=i+1
end do
NCLloclats=stringtofloat(NCLloclats2)
delete(lines)

;Fourth Line
lines = tointeger(getenv("ncllons"))
NCLloclons2 = new(lines,"string")
i=0
do while(i.le.(lines-1))
 NCLloclons2(i) = getenv("nclloclons"+i)
 i=i+1
end do
NCLloclons=stringtofloat(NCLloclons2)
delete(lines)
delete(i)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; Continue
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mylat = aaa->latitude
mylat := mylat(::-1)
mylon = aaa->longitude
cr = inttochar(10)
loc1=new(2,"float")
loc2=loc1
loc1(0)=min(mylon)
loc1(1)=min(mylat)
loc2(0)=max(mylon)
loc2(1)=max(mylat)
  print("")
  print("Range of Domain Latitudes (south-north): " + decimalPlaces(loc1(1),2,True) + " to " + decimalPlaces(loc2(1),2,True))
  print("Range of Domain Longitudes (west-east) : " + decimalPlaces(loc1(0),2,True) + " to " + decimalPlaces(loc2(0),2,True) + cr)

ii=0
outlocs=""
outlocs@_FillValue=""
 do while(ii.le.(totlocs-1))
  if ((NCLloclats(ii) .lt. loc1(1)) .or. (NCLloclats(ii) .gt. loc2(1)) .or. (NCLloclons(ii) .lt. loc1(0)) .or. (NCLloclons(ii) .gt. loc2(0))) then
   outlocs = outlocs + NCLlocnames(ii) + ", "
  end if
  ii = ii+1
 end do ;ii Loop

 if (.not.all(ismissing(outlocs))) then
  print("Warning: Location(s) " + outlocs + " are out of domain boundaries." )
 end if
totvars = dimsizes(NCLvarnames)
yy  = asciiread(".AllWRFVariables", -1, "string")
ii=0

do while(ii.le.(totvars-1)) ;code ttjj

varplus = str_match(NCLvarnames(ii),"+")
varminus = str_match(NCLvarnames(ii),"-")
varmult = str_match(NCLvarnames(ii),"*")
vardiv = str_match(NCLvarnames(ii),"/")
varexp = str_match(NCLvarnames(ii),"^")
varopenp = str_match(NCLvarnames(ii),"(")
varclosep = str_match(NCLvarnames(ii),")")
if( ismissing(varplus) .and. ismissing(varminus) .and. ismissing(varmult) .and. ismissing(vardiv) .and. ismissing(varexp) .and. ismissing(varopenp) .and. ismissing(varclosep) ) then  ;sssif
if ( any(yy.eq.NCLvarnames(ii)) ) then ;abcdif

  if (NCLvarnames(ii) .eq. "wind_s") then
    uu10  = short2flt(aaa->u)
    vv10  = short2flt(aaa->v)
    tc2 = wind_speed(uu10, vv10)
    tc2@long_name = "wind speed"
    tc2@units = "m s-1"
  else if (NCLvarnames(ii) .eq. "wind_d") then
    uu10  = short2flt(aaa->u)
    vv10  = short2flt(aaa->v)
    tc2 = wind_direction(uu10, vv10, 0)
    tc2@long_name = "wind direction"
    tc2@units = "Degrees from north"
  else if (NCLvarnames(ii) .eq. "z") then
    print("Note:")
    print("z (geopotential - unit: m**2 s**-2) has been converted to geopotential-height (unit: decameter)")
    print("you can put z in polynomials which is treated as its original variable with unit: m**2 s**-2")
    print("")
    tc0 = short2flt(aaa->z)
    tc2 = tc0/98.1 ;convert to hectopascal
    copy_VarCoords(tc0, tc2)
    copy_VarAtts(tc0, tc2)
    delete(tc0)
    tc2@units = "Decameter"
  else
  tc2 = short2flt(aaa->$NCLvarnames(ii)$)
end if
end if
end if

lat = NCLloclats
lon = NCLloclons
LocNum = dimsizes(lat)
vardims = dimsizes(dimsizes(tc2))

if (NCLaverage_onoff.ne.1) then  ;average_OFF code qwe
    if (vardims .eq. 3) then
        xTemp = linint2_points_Wrap(mylon, mylat, tc2(time_first:time_last, ::-1, :), False, lon, lat, 0)
      else if (vardims .eq. 4) then
        xTemp = linint2_points_Wrap(mylon, mylat, tc2(time_first:time_last, levdim, ::-1, :), False, lon, lat, 0)
      end if
    end if

      header=(/"----------------------------------------------------------------------------", \
              " ERA5 output variable: " + NCLvarnames(ii) + " (" + tc2@long_name + ") - " +  "unit_scale: " + tc2@units + "  -  on " + lowestPressureLev + "hpa",\
              "----------------------------------------------------------------------------"/)
    hlist=[/header/]
    tablename="values-"+NCLvarnames(ii)
      write_table( tablename, "w", hlist, "%s" ) ; Write header on the table
      timecap = tostring(all_steps(time_first:time_last))

      nameformat="%19s"

else  ;average_ON code qwe

  hourstep = all_steps(1) - all_steps(0)
  NCLaverage_time = tointeger(getenv("averagetime"))
  ncltstep = tointeger(NCLaverage_time/hourstep)
  totstepsminus = time_last - time_first
  ntimes = totstepsminus - mod(totstepsminus, ncltstep) - ncltstep ;equal to the exact steps, multiple of ncltstep
    xTemp = new((/ (ntimes+ncltstep)/ncltstep, LocNum /), typeof(tc2))
    n=0
    if (vardims .eq. 3) then
        xTemp0 = linint2_points_Wrap(mylon, mylat, tc2(:time_last, ::-1, :), False, lon, lat, 0)
      else if (vardims .eq. 4) then
        xTemp0 = linint2_points_Wrap(mylon, mylat, tc2(:time_last, levdim, ::-1, :), False, lon, lat, 0)
      end if
    end if
    end_timestep = ntimes + time_first
    do while(n.le.(LocNum-1))
        kk = 0
        do it = time_first, end_timestep, ncltstep
          xTemp(kk, n) = dim_avg_n(xTemp0(it:(it+ncltstep), n), 0)
          kk = kk + 1
        end do
      n=n+1
    end do

      header=(/"---------------------------------------------------------------------------------------------------", \
              " Average (" + NCLaverage_time + " hours) of the ERA5 output variable: " + NCLvarnames(ii) + " (" + tc2@long_name + ") - " +  "unit_scale: " + tc2@units + "  -  on " + lowestPressureLev + "hpa",\
              "---------------------------------------------------------------------------------------------------"/)
    hlist=[/header/]
    tablename="average_values-"+NCLvarnames(ii)
      write_table( tablename, "w", hlist, "%s" ) ; Write header on the table
      timecap_start = all_steps(time_first:(ntimes+time_first):ncltstep)
      timecap_end = all_steps((time_first+ncltstep):(ntimes+time_first+ncltstep):ncltstep)
      tstart = timecap_start
      tend = tstart
      end_loop = dimsizes(timecap_start)-1
      do it=0, end_loop
        start_arr = timecap_start(it)
        end_arr = timecap_end(it)
        tstart(it) = start_arr(0)
        tend(it) = end_arr(0)
      end do
      timecap = tstart + " to " + tend
      nameformat="%24s"

end if  ;average end code qwe

timename=(/"Time"/)
alist = NewList("lifo")
valueformat="%19s"
;;;;;;;;;;;;;;;;newwwwwwwwwww
hnamelist = NewList("lifo")
ListAppend(hnamelist,timename)
city100=new(100,"string",default_fillvalue("string"))
city100(:(totlocs-1))=NCLlocnames+"_("+NCLloclats+"-"+NCLloclons+")"
c1 = city100(0)
c2 = city100(1)
c3 = city100(2)
c4 = city100(3)
c5 = city100(4)
c6 = city100(5)
c7 = city100(6)
c8 = city100(7)
c9 = city100(8)
c10 = city100(9)
c11 = city100(10)
c12 = city100(11)
c13 = city100(12)
c14 = city100(13)
c15 = city100(14)
c16 = city100(15)
c17 = city100(16)
c18 = city100(17)
c19 = city100(18)
c20 = city100(19)
c21 = city100(20)
c22 = city100(21)
c23 = city100(22)
c24 = city100(23)
c25 = city100(24)
c26 = city100(25)
c27 = city100(26)
c28 = city100(27)
c29 = city100(28)
c30 = city100(29)
c31 = city100(30)
c32 = city100(31)
c33 = city100(32)
c34 = city100(33)
c35 = city100(34)
c36 = city100(35)
c37 = city100(36)
c38 = city100(37)
c39 = city100(38)
c40 = city100(39)
c41 = city100(40)
c42 = city100(41)
c43 = city100(42)
c44 = city100(43)
c45 = city100(44)
c46 = city100(45)
c47 = city100(46)
c48 = city100(47)
c49 = city100(48)
c50 = city100(49)
c51 = city100(50)
c52 = city100(51)
c53 = city100(52)
c54 = city100(53)
c55 = city100(54)
c56 = city100(55)
c57 = city100(56)
c58 = city100(57)
c59 = city100(58)
c60 = city100(59)
c61 = city100(60)
c62 = city100(61)
c63 = city100(62)
c64 = city100(63)
c65 = city100(64)
c66 = city100(65)
c67 = city100(66)
c68 = city100(67)
c69 = city100(68)
c70 = city100(69)
c71 = city100(70)
c72 = city100(71)
c73 = city100(72)
c74 = city100(73)
c75 = city100(74)
c76 = city100(75)
c77 = city100(76)
c78 = city100(77)
c79 = city100(78)
c80 = city100(79)
c81 = city100(80)
c82 = city100(81)
c83 = city100(82)
c84 = city100(83)
c85 = city100(84)
c86 = city100(85)
c87 = city100(86)
c88 = city100(87)
c89 = city100(88)
c90 = city100(89)
c91 = city100(90)
c92 = city100(91)
c93 = city100(92)
c94 = city100(93)
c95 = city100(94)
c96 = city100(95)
c97 = city100(96)
c98 = city100(97)
c99 = city100(98)
c100 = city100(99)
citylist = [/c1, c2, c3, c4, c5, c6, c7, c8, c9, c10, c11, c12, c13, c14, c15, c16, c17, c18, c19, c20, c21, c22, c23, c24, c25, c26, c27, c28, c29, c30, c31, c32, c33, c34, c35, c36, c37, c38, c39, c40, c41, c42, c43, c44, c45, c46, c47, c48, c49, c50, c51, c52, c53, c54, c55, c56, c57, c58, c59, c60, c61, c62, c63, c64, c65, c66, c67, c68, c69, 70, c71, c72, c73, c74, c75, c76, c77, c78, c79, c80, c81, c82, c83, c84, c85, c86, c87, c88, c89, c90, c91, c92, c93, c94, c95, c96, c97, c98, c99, c100/]

jj=0
do while(jj.lt.totlocs)
  ListAppend(hnamelist,citylist[jj])
jj=jj+1
end do
 tt100 = new((/100,dimsizes(xTemp(:,0))/), typeof(tc2), default_fillvalue("float"))
delete(tc2)
alist = NewList("lifo")
ListAppend(alist, timecap)
j=0
do while(j.lt.totlocs)
 tt100(j,:) = xTemp(:, j)
 j=j+1
end do
v1 = tt100(0,:)
v2 = tt100(1,:)
v3 = tt100(2,:)
v4 = tt100(3,:)
v5 = tt100(4,:)
v6 = tt100(5,:)
v7 = tt100(6,:)
v8 = tt100(7,:)
v9 = tt100(8,:)
v10 = tt100(9,:)
v11 = tt100(10,:)
v12 = tt100(11,:)
v13 = tt100(12,:)
v14 = tt100(13,:)
v15 = tt100(14,:)
v16 = tt100(15,:)
v17 = tt100(16,:)
v18 = tt100(17,:)
v19 = tt100(18,:)
v20 = tt100(19,:)
v21 = tt100(20,:)
v22 = tt100(21,:)
v23 = tt100(22,:)
v24 = tt100(23,:)
v25 = tt100(24,:)
v26 = tt100(25,:)
v27 = tt100(26,:)
v28 = tt100(27,:)
v29 = tt100(28,:)
v30 = tt100(29,:)
v31 = tt100(30,:)
v32 = tt100(31,:)
v33 = tt100(32,:)
v34 = tt100(33,:)
v35 = tt100(34,:)
v36 = tt100(35,:)
v37 = tt100(36,:)
v38 = tt100(37,:)
v39 = tt100(38,:)
v40 = tt100(39,:)
v41 = tt100(40,:)
v42 = tt100(41,:)
v43 = tt100(42,:)
v44 = tt100(43,:)
v45 = tt100(44,:)
v46 = tt100(45,:)
v47 = tt100(46,:)
v48 = tt100(47,:)
v49 = tt100(48,:)
v50 = tt100(49,:)
v51 = tt100(50,:)
v52 = tt100(51,:)
v53 = tt100(52,:)
v54 = tt100(53,:)
v55 = tt100(54,:)
v56 = tt100(55,:)
v57 = tt100(56,:)
v58 = tt100(57,:)
v59 = tt100(58,:)
v60 = tt100(59,:)
v61 = tt100(60,:)
v62 = tt100(61,:)
v63 = tt100(62,:)
v64 = tt100(63,:)
v65 = tt100(64,:)
v66 = tt100(65,:)
v67 = tt100(66,:)
v68 = tt100(67,:)
v69 = tt100(68,:)
v70 = tt100(69,:)
v71 = tt100(70,:)
v72 = tt100(71,:)
v73 = tt100(72,:)
v74 = tt100(73,:)
v75 = tt100(74,:)
v76 = tt100(75,:)
v77 = tt100(76,:)
v78 = tt100(77,:)
v79 = tt100(78,:)
v80 = tt100(79,:)
v81 = tt100(80,:)
v82 = tt100(81,:)
v83 = tt100(82,:)
v84 = tt100(83,:)
v85 = tt100(84,:)
v86 = tt100(85,:)
v87 = tt100(86,:)
v88 = tt100(87,:)
v89 = tt100(88,:)
v90 = tt100(89,:)
v91 = tt100(90,:)
v92 = tt100(91,:)
v93 = tt100(92,:)
v94 = tt100(93,:)
v95 = tt100(94,:)
v96 = tt100(95,:)
v97 = tt100(96,:)
v98 = tt100(97,:)
v99 = tt100(98,:)
v100 = tt100(99,:)
valuelist = [/v1, v2, v3, v4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15, v15, v16, v17, v18, v19, v20, v21, v22, v23, v24, v25, v26, v27, v28, v29, v30, v31, v32, v33, v34, v35, v36, v37, v38, v39, v40, v41, v42, v43, v44, v45, v46, v47, v48, v49, v50, v51, v52, v53, v54, v55, v56, v57, v58, v59, v60, v61, v62, v63, v64, v65, v66, v67, v68, v69, v70, v71, v72, v73, v74, v75, v76, v77, v78, v79, v80, v81, v82, v83, v84, v85, v86, v87, v88, v89, v90, v91, v92, v93, v94, v95, v96, v97, v98, v99, v100/]
jj=0
do while(jj.lt.totlocs)
  ListAppend(alist,valuelist[jj])
jj=jj+1
end do

j=0
do while(j.lt.totlocs)
 nameformat=nameformat+"%19s"
 valueformat=valueformat+"%19.5f"
j=j+1
end do
delete(j)
   write_table( tablename, "a", hnamelist, nameformat ) ; Write header on the table
   write_table( tablename, "a", alist, valueformat ) ; Write main data
else
print("PostWRF Warning: " + "<" + NCLvarnames(ii) + ">" + " is not among the output variables")
end if ;abcdif
print("Variable " + NCLvarnames(ii) + " has been extracted")

else ;;;###########################################

 homedir = getenv("postwrf_dir")
 asciiwrite (homedir+"/modules_era/totalequation.txt" , NCLvarnames(ii))
 system("cd $postwrf_dir/modules_era && ./separation.sh") ;;variable.txt
 system("cd $postwrf_dir/modules_era && ./extract_era_equation.sh") ;;sed
 system("ln -sf $postwrf_dir/modules_era/extract_era_equation.ncl .")
 system("ln -sf $postwrf_dir/modules_era/variables.txt .")
 system("ln -sf $postwrf_dir/modules_era/totalequation.txt .")
 system("ncl -Qn extract_era_equation.ncl")
end if ;sssif

ii = ii+1
end do ;code ttjj

end