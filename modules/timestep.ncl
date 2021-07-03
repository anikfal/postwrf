load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
begin
 filename=getenv("wrfout")
 myfile=addfile(filename,"r")
 all_steps=myfile->XTIME
 if (dimsizes(all_steps) .eq. 0) then
  print("Note: The file has only 1 time!")
 else
  t_step = (all_steps(1) - all_steps(0))/60
  print(" Note:   every 1 time-step in this file = " + t_step + " hour(s)")
 end if
end
