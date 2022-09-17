import os
import glob
from scipy.io import loadmat
import torch
import re

fileTemplate = os.path.join('..','struct*.mat')

mirrorDataFiles = glob.glob(fileTemplate)

for file in mirrorDataFiles:
	# mat = loadmat(file,simplify_cells=True)
	pathlist = os.path.split(file)
	filename = pathlist[-1]
	sessionName = filename[6:-4]

	animalNameTemplate = '^[a-zA-Z]+'
	sessionNumberTemplate = '[0-9]+$'

	animalMatch  = re.search(animalNameTemplate,sessionName)
	sessionMatch = re.search(sessionNumberTemplate,sessionName)

	print(animalMatch.group())
	print(sessionMatch.group())

