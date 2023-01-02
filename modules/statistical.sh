#PostWRF Version 1.2 (May 2021)
#Author: Amirhossein Nikfal <ah.nikfal@gmail.com>, <https://github.com/anikfal>

trap 'my_exit; exit' SIGINT SIGQUIT
my_exit() {
  rm $outputsdir/*.ncl $postwrf_dir/*.ncl 2>/dev/null
}

wrflist=$(ls -d outputs_postwrf_* 2>/dev/null)
wrflistvar=$(echo $wrflist | wc -w)
if [ -z "$wrflist" ]; then
  echo "      No outputs directory."
  echo "      You must run the 'Data Extract' section to have some values."
  nofile=True
elif [ $wrflistvar == 1 ]; then
  echo ""
  echo Entering inside the directory $wrflist ...
  echo ""
  cd outputs_postwrf_*
  export outputsdir=$(pwd)
  ls values-* 2>/dev/null >.listfile
  value_files=$(ls values-* 2>/dev/null)
  export value_files_count=$(echo $value_files | wc -w)
  if [[ $value_files_count -lt 1 ]] 2>/dev/null; then
    echo "There is no values-files inside the output dir. You need to run the extract section of PostWRF to generate such files."
    exit
  fi
else # more than one output folder
  echo -e "\nWhich directory are you looking for the simulation/observation data?\n"
  COUNTER=0
  ls -d outputs_postwrf_* 2>/dev/null >.listfile
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
  cd $wrfout
  export outputsdir=$(pwd)
  ls values-* 2>/dev/null >.listfile
  value_files=$(ls values-* 2>/dev/null)
  export value_files_count=$(echo $value_files | wc -w)
  if [[ $value_files_count -lt 1 ]] 2>/dev/null; then
    echo "There is no values-files inside the output dir. You need to run the extract section of PostWRF to generate such files."
    exit
  fi
fi

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

if [ $timeseries_onoff == 1 ]; then
  COUNTER=0
  while [ $COUNTER -lt $value_files_count ]; do
    one_value_file=$(sed -n "$((COUNTER + 1)) p" .listfile)
    one_observation_file=$(echo $one_value_file | awk -F'-' 'BEGIN { OFS=FS } {$1="observation"; print} ') #replace values- with observation-
    output_file_name=$(echo $one_value_file | awk -F'-' 'BEGIN { OFS=FS } {$1="timeseries"; print} ')      #replace timeseries- with observation-
    declare ts_valfile$COUNTER=$one_value_file
    declare ts_obsfile$COUNTER=$one_observation_file
    declare ts_outputname$COUNTER=$output_file_name
    export ts_valfile$COUNTER
    export ts_obsfile$COUNTER
    export ts_outputname$COUNTER
    COUNTER=$((COUNTER + 1))
  done
  echo ""
  read -p "Y-axis Maximum value (press Enter to set automatically): " y_axis_max
  if [[ -z $y_axis_max ]] 2>/dev/null; then
    unset y_axis_max
    echo " Maximum value of the Y-axis will be set automatically"
    echo ""
  else
    export y_axis_max
  fi

  echo ""
  read -p "Y-axis Minimum value (press Enter to set automatically): " y_axis_min
  if [[ -z $y_axis_min ]] 2>/dev/null; then
    unset y_axis_min
    echo " Minimum value of the Y-axis will be set automatically"
    echo ""
  else
    export y_axis_min
  fi

  if [[ $panelplot != 1 ]]; then
    ln -sf $postwrf_dir/modules/timeseries.ncl $outputsdir
    ncl -nQ timeseries.ncl
  else
    ln -sf $postwrf_dir/modules/timeseries_panel.ncl $outputsdir
    ncl -nQ timeseries_panel.ncl
  fi
fi

if [ $scatter_onoff == 1 ]; then
  pairnumber=0
  COUNTER=0
  while [ $COUNTER -lt $value_files_count ]; do
    export one_value_file=$(sed -n "$((COUNTER + 1)) p" .listfile)
    export one_observation_file=$(echo $one_value_file | awk -F'-' 'BEGIN { OFS=FS } {$1="observation"; print} ') #replace values- with observation-
    if [[ -f $one_observation_file ]]; then                                                                       #check if the observation file exists
      declare scatter_valfile$pairnumber=$one_value_file
      declare scatter_obsfile$pairnumber=$one_observation_file
      export scatter_valfile$pairnumber
      export scatter_obsfile$pairnumber
      pairnumber=$((pairnumber + 1))
    fi
    COUNTER=$((COUNTER + 1))
  done
  export pairnumber
  if [[ $panelplot != 1 ]]; then
    ln -sf $postwrf_dir/modules/scatter.ncl $outputsdir
    ncl -nQ scatter.ncl
  else
    ln -sf $postwrf_dir/modules/scatter_panel.ncl $outputsdir
    ncl -nQ scatter_panel.ncl
  fi
fi

if [ $taylor_onoff == 1 ]; then
  if [[ $value_files_count -gt 3 ]] 2>/dev/null; then
    echo -e "\nTaylor Diagram: for the sake of clear visualization, number of the pairs of values/observations cannot be more than 3\n"
    exit
  fi
  ln -sf $postwrf_dir/modules/taylor_diagram.ncl $outputsdir
  pairnumber=0
  COUNTER=0
  while [ $COUNTER -lt $value_files_count ]; do
    export one_value_file=$(sed -n "$((COUNTER + 1)) p" .listfile)
    export one_observation_file=$(echo $one_value_file | awk -F'-' 'BEGIN { OFS=FS } {$1="observation"; print} ') #replace values- with observation-
    if [[ -f $one_observation_file ]]; then                                                                       #check if the observation file exists
      declare taylor_valfile$pairnumber=$one_value_file
      declare taylor_obsfile$pairnumber=$one_observation_file
      export taylor_valfile$pairnumber
      export taylor_obsfile$pairnumber
      pairnumber=$((pairnumber + 1))
    fi
    COUNTER=$((COUNTER + 1))
  done
  export pairnumber
  if [[ $panelplot != 1 ]]; then
    ln -sf $postwrf_dir/modules/taylor.ncl $outputsdir
    ncl -nQ taylor.ncl
  else
    ln -sf $postwrf_dir/modules/taylor_panel.ncl $outputsdir
    ncl -nQ taylor_panel.ncl
  fi
fi

rm $outputsdir/*.ncl $postwrf_dir/*.ncl 2>/dev/null
