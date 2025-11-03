# PostWRF

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.8191714.svg)](https://zenodo.org/record/8191714)

### Visualization and Postprocessing of WRF and ERA5 Data

**Plot WRF and ERA5 data with a namelist — just like running the WRF model.**

**PostWRF** is a collection of interactive tools, written in **NCL** and **Bash**, for visualizing and post-processing **WRF model outputs**, as well as **ERA5** and **RTTOV** data (to some extent).

It is designed for both **beginners** and **expert users**:
- **Students** can easily plot WRF or ERA5 outputs without dealing with programming syntax or script debugging.  
- **Advanced users** can perform routine postprocessing tasks quickly and reproducibly.

---

## 🧩 Main Capabilities
- WRF data extraction  
- WRF horizontal contour plotting  
- WRF vertical cross-section plotting  
- WRF statistical diagrams  
- RTTOV input (from WRF) and output data generation  
- WRF data conversion to GeoTIFF  
- WRF Skew-T and wind rose diagrams  
- ERA5 horizontal contour plotting  
- ERA5 data extraction  

---

## 🖼️ Sample Visualizations
![PostWRF sample plots](https://github.com/anikfal/PostWRF/assets/11738727/16be89c3-1bb1-4245-a430-1d07876563dd)

---

## ⚙️ Installation

Install **NCL** on a Linux system (example for Fedora):

```bash
sudo dnf install ncl
```

That’s it! This is sufficient for most of PostWRF’s features.

---

## 🚀 Usage

1. Clone the repository:
```git clone git@github.com:anikfal/PostWRF.git
cd PostWRF
```

2. Make scripts executable:
```
chmod +x postwrf.sh modules/*.sh modules_era/*.sh
```

3. Copy or link your WRF or ERA5 files into the `postwrf` directory.
4. Run the main script:
```
./postwrf.sh
```

5. Follow the on-screen instructions to visualize or postprocess your data.

## 📘 Documentation
Comprehensive documentation with practical examples:<br>
[https://postwrf.readthedocs.io/en/master](https://postwrf.readthedocs.io/en/master)

## 🎥 YouTube Training Videos
Watch video tutorials here:\
[PostWRF YouTube Playlist](https://youtube.com/playlist?list=PL93HaRiv5QkCOWQ4E_Oeszi9DBOYrdNXD)

## 📄 Citation
If you use PostWRF in your research, please cite the following publication:

Nikfal, A. (2022). PostWRF: An Interactive Visualization and Postprocessing Tool for WRF Outputs. Environmental Modelling & Software, 105591.\
https://doi.org/10.1016/j.envsoft.2022.105591