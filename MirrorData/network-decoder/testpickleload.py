import os
import glob
from scipy.io import loadmat
import torch
import re
import pickle

session = 'Zara70'
area    = 'M1'

kinfile  = session+"_kin.pickle"
neurfile = session+"_"+area+".pickle"

kinfile  = os.path.join('.','pickles',kinfile)
neurfile = os.path.join('.','pickles',neurfile)

with open(kinfile, 'rb') as handle:
    kindata = pickle.load(handle)

with open(neurfile, 'rb') as handle:
    neurdata = pickle.load(handle)

print(kindata)
print(neurdata)

# also test windowing
