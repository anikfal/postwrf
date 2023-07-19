# PostWRF

### Visualization and postprocessing of the WRF and ERA5 data

**Plot the WRF and ERA5 data, in the same simple way as you run the WRF model!**

PostWRF is a bunch of interactive tools, written in NCL and Bash scripts, to visualize and post-process the WRF model outputs (as well as ERA5 and RTTOV data, to some extent).

PostWRF is useful for both the expert and less-experienced users. Students can plot the WRF and ERA5 outputs whithout struggling with coding and syntax errors. Expert users can also carry out common postprocessing tasks in a simple and straightforward way.

## Main capabilities:
- WRF Data extraction
- WRF horizontal contour plot
- WRF cross-section plot
- WRF statistical diagrams
- RTTOV input (from WRF) and output data generation
- WRF data conversion to Geotiff
- WRF Skew-T and windrose diagrams
- ERA5 horizontal contour plot
- ERA5 data extraction

## Sample visualizations and postprocessing
![github_postwrf](https://github.com/anikfal/PostWRF/assets/11738727/16be89c3-1bb1-4245-a430-1d07876563dd)


## Installation:
Install NCL on a Linux machine (e.g. Fedora):
```bash
sudo dnf install ncl
```
Finished! That's enough for most of the PostWRF's capabilities!

## Run PostWRF:
1. ``` git clone git@github.com:anikfal/PostWRF.git ```
2. ``` cd PostWRF ```
3. ``` chmod +x postwrf.sh modules/*.sh modules_era/*.sh ```
4. Copy or link your WRF or ERA5 files in the PostWRF directory
5. ``` ./postwrf.sh ```
6. Follow the instructions and give relevant information to visualize/postprocess your data


## HTML Documentations:
Documentations with practical examples: https://postwrf.readthedocs.io/en/master

## YouTube Training Videos:
https://youtube.com/playlist?list=PL93HaRiv5QkCOWQ4E_Oeszi9DBOYrdNXD

## Paper:
For more detailed information about the backend structure of the software, please read https://doi.org/10.1016/j.envsoft.2022.105591

If you find PostWRF helpful, please kindly cite it in your works.
