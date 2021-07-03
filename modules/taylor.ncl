; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"  
load "./taylor_diagram.ncl"
begin
pairnum = tointeger(getenv("pairnumber"))
taylor_value = new(pairnum,"string")
tyalor_observation = taylor_value
ii=0
do while(ii.lt.pairnum)
 taylor_value(ii) = getenv("taylor_valfile"+ii)
 tyalor_observation(ii) = getenv("taylor_obsfile"+ii)
 ii=ii+1
end do
delete(ii)

;maximum column
max_totcolumns_wrf = 0
ii = 0
; kk = 0
do while(ii.lt.pairnum)
  data_tot :=  asciiread(taylor_value(ii),-1,"string")
  data_main := data_tot(4:)
  totcolumns_wrf = str_fields_count(data_main(0), " ") - 1
  ; if (max_totcolumns_wrf .ne. totcolumns_wrf) then ;Note of ignoring the error message
  ;   kk = kk + 1
  ; end if
  if (max_totcolumns_wrf .lt. totcolumns_wrf) then
    max_totcolumns_wrf = totcolumns_wrf
  end if
  ii= ii + 1
end do

bais_ratio_data = new( (/pairnum, max_totcolumns_wrf/), "float") ;container for each variable (case_study), with their cities
cc_ratio_data = bais_ratio_data
; bais_ratio_data = 0
; cc_ratio_data = 0
varslocs = tostring(bais_ratio_data)
ii=0
casestudylabels = new(1, "string")
city_case_labels = new(1, "string")
do while(ii.lt.pairnum)
  data_tot :=  asciiread(taylor_value(ii),-1,"string")
  data_main := data_tot(4:)
  varname = str_get_field(data_tot(1), 2, "(")
  varname = str_get_field(varname, 1, ")")
  if (all(ismissing(casestudylabels))) then
    casestudylabels = varname
    else
    casestudylabels := array_append_record(casestudylabels, varname, 0)
  end if
  unit = str_squeeze(str_get_field(data_tot(1), 3, ":"))
  totrecords = dimsizes(data_main)
  totcolumns_wrf = str_fields_count(data_main(0), " ") - 1 ;time column is subtracted
  data_tot_obv := asciiread(tyalor_observation(ii),-1,"string")
  data_main_obv := data_tot_obv(4:)
  totcolumns_obv = str_fields_count(data_main_obv(0), " ") - 1 ;time column is subtracted
  if (totcolumns_wrf .ne. totcolumns_obv) then
    print("Number of data columns in simulation and observation files must be equal.")
    print("Correct the data files and run again.")
    exit()
  end if
  ;Filling data for a case-study (WRF variable)
  do jj = 0, totcolumns_wrf-1
    data_value := tofloat(str_get_field(data_main, jj+2, " "))
    city_name = str_get_field(data_tot(3), jj+2, " ")
    city_shortname = str_get_field(city_name, 1, "_")
    data_obs := tofloat(str_get_field(data_main_obv, jj+2, " "))
    data_obs@long_name = "Observation: " + varname + " (" + unit + ")"
    bais_ratio_data(ii,jj) = stddev(data_value)/stddev(data_obs) ;Rations of Standard deviations
    cc_ratio_data(ii,jj) = escorc(data_value, data_obs) ;Rations of Pearson correlations
    if (all(ismissing(city_case_labels))) then
      ; city_case_labels = varname + "_" + city_shortname
      city_case_labels = city_shortname
      else
      ; city_case_labels := array_append_record(city_case_labels, varname+"_"+city_shortname, 0)
      city_case_labels := array_append_record(city_case_labels, city_shortname, 0)
    end if
    varslocs(ii,jj) = city_shortname
  end do
  ii=ii+1
end do

; mycolor = read_colormap_file("circular_2") ;24 colors
; color_intv = abs(24/pairnum)
; if (color_intv .eq. 0) then
;     color_intv = 1
; end if
; varSource = var +"_"+ source              ; add extra info [*not* required]
ty_opt   = True                           ; taylor diagram with options
ty_opt@Markers       = (/16, 16, 16/)         ; make all solid fill
ty_opt@Colors        = (/"red", "blue", "green3", "black", "magenta", "brown", "grey", "yellow"/)  ;mycolor(::color_intv,:)
ty_opt@varLabels     = city_case_labels ;(/"hello", "second", "third", "forth", "fifth", "sixth", "seventh", "eighth"/) ;varSource
ty_opt@caseLabels    = casestudylabels ;(/"red", "blue", "green"/)
ty_opt@varLabelsYloc = 1.5                ; Move location of variable labels [default 0.45]
taylorlabelsize = tofloat(getenv("taylorlabelsize"))
if (taylorlabelsize.le.1 .and. taylorlabelsize.ge.0) then
  taylorlabelsize = 0.1 + 0.7*taylorlabelsize
  else
  taylorlabelsize = 0.5
end if
ty_opt@caseLabelsFontHeightF = taylorlabelsize       ; make slight larger   [default=0.12 ]

taylormarkersize = tofloat(getenv("taylormarkersize"))
if (taylormarkersize.le.1 .and. taylormarkersize.ge.0) then
  taylormarkersize = 0.008 + 0.01*taylormarkersize
  else
  taylormarkersize = 0.013
end if
ty_opt@varLabelsFontHeightF  = taylormarkersize      ; make slight smaller  [default=0.013]

; ty_opt@tiMainString  = "Annual"           ; title
ty_opt@stnRad        = (/ 0.5, 1.5 /)     ; additional standard radii
ty_opt@ccRays        = (/ 0.6, 0.9 /)     ; correllation rays
ty_opt@centerDiffRMS = True               ; RMS 'circles'
taylormarkersize = tofloat(getenv("taylormarkersize"))
if (taylormarkersize.le.1 .and. taylormarkersize.ge.0) then
  taylormarkersize = 0.005 + 0.01*taylormarkersize
  else
  taylormarkersize = 0.01
end if
ty_opt@gsMarkerSizeF = taylormarkersize
wks   = gsn_open_wks(getenv("imgfmt"),"taylor_diagram")
plot  = taylor_diagram(wks,bais_ratio_data,cc_ratio_data,ty_opt)

end