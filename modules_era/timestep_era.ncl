load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
begin
filename = systemfunc("ls postwrf_era_*")
var = str_match(filename,"/" )
if (ismissing(var)) then
  dir = systemfunc("pwd")
  myfile = addfile(dir + "/" + filename, "r")
  else
  myfile = addfile(filename, "r")
end if
 times = cd_calendar(myfile->time, 3)
 alltimes = dimsizes(times)-1
 if (alltimes .eq. 0) then
  print("Note: The file has only 1 time: " + times)
 else
  do ii=0, alltimes
    jj = ii + 1
    print(sprinti("%4.1i", jj) + ") " + times(ii))
  end do
 end if
end