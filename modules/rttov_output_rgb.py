import numpy
import numpy as np
import netCDF4 as nc
from PIL import Image
from glob import glob
import os

AllBrightnessFiles = glob("*values*.nc")
if os.path.isfile("rgb.txt"):
    ff = open("rgb.txt", "r")
    red_eq = ff.readline().split("=")[1]
    green_eq = ff.readline().split("=")[1]
    blue_eq = ff.readline().split("=")[1]
    for myfile in AllBrightnessFiles:
        print("\nProcessing", myfile)
        ncfile =nc.Dataset(myfile)
        allbands = list(ncfile.variables.keys())[:-2]
        allbandsnum = len(allbands)
        for bb in allbands:
            exec(bb + " = np.array(ncfile.variables[bb])")
        red = eval(red_eq)
        green = eval(green_eq)
        blue = eval(blue_eq)
        myshape = ncfile.variables.get("band1").shape
        bands = np.zeros(np.append(myshape, allbandsnum))
        RGBlayers = np.zeros(np.append(myshape, allbandsnum), dtype="uint8")
        ##NetCDF data array starts from top-left, but image data array starts from bottom-left, therefore, ::-1 is required
        RGBlayers[::-1,:,0] = np.where(red>255, 255, red)
        RGBlayers[::-1,:,1] = np.where(green>255, 255, green)
        RGBlayers[::-1,:,2] = np.where(blue>255, 255, blue)
        myRGB = Image.fromarray(RGBlayers)
        myRGB_large = myRGB.resize((600, 600))
        myRGB_large.save(myfile+"_rgb.png", quality=100, subsampling=0, dpi=(600, 600))
else:
    print("\nYou can specify formulas for each R, G, and B channels in a file named 'rgb.txt', in PostWRF main directory")
    print("An 'rgb.txt' file can be specified in numpy functions, like below:")
    print("------------------------------------")
    print("red = band1 - np.min(band2)")
    print("green = band2 / np.mean(band3)")
    print("blue = band2 - 100")
    print("------------------------------------")
    for myfile in AllBrightnessFiles:
        print("\nProcessing", myfile)
        ncfile =nc.Dataset(myfile)
        allbands = list(ncfile.variables.keys())[:-2]
        allbandsnum = len(allbands)
        for bb in allbands:
            exec(bb + " = np.array(ncfile.variables[bb])")
        print("\n\nEquations for each R, G, and B channels must be (numpy) functions of:", allbands, "and between 0 to 255")
        # print("Sample function: band1 - np.min(band2)\n")
        red_eq = input("\nEnter the RED channel equation: ")
        red = eval(red_eq)
        green_eq = input("\nEnter the GREEN channel equation: ")
        green = eval(green_eq)
        blue_eq = input("\nEnter the BLUE channel equation: ")
        blue = eval(blue_eq)
        myshape = ncfile.variables.get("band1").shape
        bands = np.zeros(np.append(myshape, allbandsnum))
        RGBlayers = np.zeros(np.append(myshape, allbandsnum), dtype="uint8")
        ##NetCDF data array starts from top-left, but image data array starts from bottom-left, therefore, ::-1 is required
        RGBlayers[::-1,:,0] = np.where(red>255, 255, red)
        RGBlayers[::-1,:,1] = np.where(green>255, 255, green)
        RGBlayers[::-1,:,2] = np.where(blue>255, 255, blue)
        myRGB = Image.fromarray(RGBlayers)
        myRGB_large = myRGB.resize((600, 600))
        myRGB_large.save(myfile+"_rgb.png", quality=100, subsampling=0, dpi=(600, 600))