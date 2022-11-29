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

## Installation:
You just need to install NCL on a Linux machine (e.g. Fedora):
```bash
sudo dnf install ncl
```
That's all! You're ready to go!

## Documentations:
HTML documentations with practical examples at: https://postwrf.readthedocs.io/en/master

## Paper:
For more detailed information about the backend structure of the software, please read https://doi.org/10.1016/j.envsoft.2022.105591

If you find PostWRF a helpful tool, please kindly cite it in your works.
