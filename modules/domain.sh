#!/bin/bash
#PostWRF Version 1.0 (May 2018)
#This shell script uses a NCL code to draw the map of WRF model domain.
#Coded by "Amirhossein Nikfal" <ah.nikfal@gmail.com>, <anik@ut.ac.ir>

    echo -e "\n Specify The Format Of The Images: 1, 2, or 3?"
     select imgfmt in "x11" "pdf" "png"
      do
       case $imgfmt in
        x11);;
        pdf);;
        png);;
          *) echo "Output Images Will Be 'X11'"
       esac
       export imgfmt
       break
      done
 
     if [[ ${imgfmt} == "x11" ]]; then
      outname="nclplot"
     else
    read -p "`echo -e "\n "`Specify The Output File Name (Press Enter for the default name): " outname2
      if [ -z "$outname2" ]; then
       outname="domain-map"
       echo "  Contour file will be named $outname"
      else
       outname=$outname2
      fi
     fi
    export outname

     if [[ -z "$wpslables" ]]; then
	     wpslables=0
     fi

     if [[ ${wpslables} == "1" ]]; then
       echo -e "\nSelect the font size of the locations' lables" 
       select fontsz in "Small" "Medium" "Large"
       do
	case $fontsz in
		Small) fontsz="0.013";;
		Medium) fontsz="0.02";;
		Large) fontsz="0.027";;
		*) echo "Font size of lables has been set to medium"; fontsz="0.02";;
       esac
       break
      done 
     fi  

       export fontsz

   ncl modules/domain.ncl

