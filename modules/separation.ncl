load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"

equation = asciiread("totalequation.txt", -1, "string")
ppcount = str_fields_count(equation, "()^*/+-")
pp = new(ppcount,"string")
 kk=0
 do while(kk.lt.ppcount)
  pp(kk) = str_squeeze(str_get_field(equation, kk+1, "()^*/+-"))
  print("pp(" + kk + "): " + pp(kk))
  kk=kk+1
 end do
kk=0
stringvar = new(1,"string")
do while(kk.lt.ppcount)
 if ( ismissing(stringtofloat(pp(kk))) .and. pp(kk).ne."" ) then  ;if is string
  printvar := array_append_record (stringvar, pp(kk), 0)
  stringvar := printvar
 end if
kk=kk+1
end do
asciiwrite ("variables.txt" , stringvar(1:))
