#PostWRF Version 1.2 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

echo -e "\n Specify The Format Of The Images: 1, 2, or 3?"
select imgfmt in "x11" "pdf" "png"; do
  case $imgfmt in
  x11) ;;
  pdf) ;;
  png) ;;
  *) echo "Output Images Will Be 'X11'" ;;
  esac
  export imgfmt
  break
done

if [[ ${imgfmt} == "x11" ]]; then
  outname="nclplot"
else
  read -p "$(echo -e "\n ")Specify The Output File Name (Press Enter for the default name): " outname2
  if [ -z "$outname2" ]; then
    outname="domain-map"
    echo "  Contour file will be named $outname"
  else
    outname=$outname2
  fi
fi
export outname

if [[ ${domtopo_onoff} != 1 ]]; then

  if [[ -z "$wpslables" ]]; then
    wpslables=0
  fi
  if [[ ${wpslables} == "1" ]]; then
    echo -e "\nSelect the font size of the locations' lables"
    select fontsz in "Small" "Medium" "Large"; do
      case $fontsz in
      Small) fontsz="0.013" ;;
      Medium) fontsz="0.02" ;;
      Large) fontsz="0.027" ;;
      *)
        echo "Font size of lables has been set to medium"
        fontsz="0.02"
        ;;
      esac
      break
    done
  fi
  export fontsz
  ncl -nQ modules/domain.ncl

else

  domcount=1
  while [ $domcount -le $dom_number ]; do
    echo -e "\nDomain $domcount (output of wrf.exe, geogrid.exe, or metgrid.exe):"
    wrflist=$(ls wrfout_d* geo_em.d* geo_nmm.d* met_em.d* met_nmm.d* 2>/dev/null)
    wrflistvar=$(echo $wrflist | wc -w)
    if [ -z "$wrflist" ]; then
      echo "      No WRF output files in the current directory."
      echo "      You can link or copy one or more files to the current directory."
      nofile=True
    elif [ $wrflistvar == 1 ]; then
      wrfout=$wrflist
      echo -e "\n"$wrfout" has been selected in the current directory.\n"
    else
      COUNTER=0
      ls wrfout_d* geo_em.d* geo_nmm.d* met_em.d* met_nmm.d* 2>/dev/null > .listfile
      while [ $COUNTER -lt $wrflistvar ]; do
        wrffile[$COUNTER]=$(sed -n "$((COUNTER + 1)) p" .listfile)
        COUNTER=$((COUNTER + 1))
      done
      COUNTER=0
      while [ $COUNTER -lt $wrflistvar ]; do
        echo -e "   $((COUNTER + 1))) ${wrffile[$COUNTER]}"
        COUNTER=$((COUNTER + 1))
      done
      echo ""
      unset COUNTER
      varrr=True
      while [ $varrr == True ]; do
        read -p "Enter the number of the favored file: " filenum
        if [[ $filenum -le $wrflistvar && $filenum -ge 1 ]] 2>/dev/null; then
          wrfout=${wrffile[$((filenum - 1))]}
          break
        fi
        echo " Not valid. Select an integer between 1 to" $wrflistvar "..."
      done
      echo -e "\n"$wrfout" has been selected\n"
      unset filenum
      rm -f .listfile
    fi
    declare domfile$domcount=$wrfout
    export domfile$domcount
    domcount=$(($domcount + 1))
  done
  ncl -nQ modules/3dom.ncl
fi
