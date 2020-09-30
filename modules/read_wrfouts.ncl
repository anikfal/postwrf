;Script to read WRF output file(s). Loaded at the begining of the NCL scripts.
myfile = systemfunc("ls postwrf_wrfout*")
var = str_match(myfile,"/" )
multiwrf_num = dimsizes(myfile)
  if (ismissing(var)) then
    dir = systemfunc("pwd")
    a = addfiles(dir + "/" + myfile,"r")
    else
    a = addfiles(myfile,"r")
  end if
  ;Checking for correct file selection
  atts = new( (/multiwrf_num, 6/), "string")
  do ii = 0, multiwrf_num-1
    fileatts := getvaratts(a[ii])
    atts(ii,0) = a[ii]@$fileatts(2)$
    atts(ii,1) = a[ii]@$fileatts(3)$
    atts(ii,2) = a[ii]@$fileatts(4)$
    atts(ii,3) = a[ii]@$fileatts(5)$
    atts(ii,4) = a[ii]@$fileatts(6)$
    atts(ii,5) = a[ii]@$fileatts(7)$
  end do
  atts_transpose = transpose(atts)
  do ii = 0, 5
    if ( any( atts_transpose(ii,:).ne.atts_transpose(ii,0) ) ) then
     print("")
     print("Error: Selected files are not for the same WRF run")
     print("Try again with correct file numbers")
     exit()
    end if
  end do