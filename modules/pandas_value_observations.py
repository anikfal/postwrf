import pandas as pd
import numpy as np
from glob import glob

for valfile in glob("values-*"):
    obsfile = valfile.replace("values", "observation")
    ff0 = pd.read_csv(valfile, header=None)
    ff = pd.read_csv(valfile, skiprows=4, header=None, delim_whitespace=True)
    for var in range(1, ff.columns.shape[0]):
       ff[ff.columns[var]] = ff[ff.columns[var]] + (np.random.uniform(-1,1,ff.count()[var]) * ff[ff.columns[var]].mean() * 0.1)
    header = ff0[:4]
    header.to_csv(obsfile, header=False, index=None)
    ff.to_csv(obsfile, mode='a', header=False, sep=" ", index=None)
    print("Generating", obsfile)
