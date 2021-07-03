load "read_wrfouts.ncl"
wrffile = a
times = wrf_user_getvar(wrffile,"times",-1)

alltimes = dimsizes(times)-1
ii=0
do ii=0, alltimes
    jj = ii + 1
    ; print(jj + ")  " + times(ii))
    print(sprinti("%4.1i", jj) + ") " + times(ii))
end do