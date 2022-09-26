import os
import glob
from scipy.io import loadmat
import torch
import re
import pickle

from typing import Tuple, List

# define a method for getting metadata from file names
def getFileMetadata(filename:str) -> Tuple[str,int]:
	pathlist = os.path.split(file)
	filename = pathlist[-1]
	sessionName = filename[6:-4]

	animalNameTemplate = '^[a-zA-Z]+'
	sessionNumberTemplate = '[0-9]+$'

	animalMatch  = re.search(animalNameTemplate,sessionName)
	sessionMatch = re.search(sessionNumberTemplate,sessionName)

	animalName     = animalMatch.group()
	sessionNumber  = sessionMatch.group()

	return animalName, int(sessionNumber)

# define a method for extracting the context names, onsets, and offsets present
def getContextTimings(mat:dict) -> Tuple[List[str],List[float],List[float]]:
	# TODO: do stuff

# setup: define set of files to process & create a directory to put the pickles
fileTemplate = os.path.join('..','struct*.mat')

mirrorDataFiles = glob.glob(fileTemplate)

fldr = os.path.join('.','pickles')
if not os.path.exists(fldr):
	os.mkdir(fldr)


for file in mirrorDataFiles:
	animalName, sessionNumber = getFileMetadata(file)

	mat = loadmat(file,simplify_cells=True)
