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
	contextnames   = []
	contextonsets  = []
	contextoffsets = []

	trialcontexts = mat['Mstruct']['TrialType']['names']
	trialonsets   = [tr['trial_start_time'] for tr in mat['Mstruct']['Event']]
	trialoffsets  = [tr['trial_end_time'] for tr in mat['Mstruct']['Event']]

	for idx,val in enumerate(trialcontexts):
		if idx == 0 or trialcontexts[idx]!=trialcontexts[idx-1]:
			contextnames  += [val]
			contextonsets += [trialonsets[idx]]
		if idx == (len(trialcontexts)-1):
			contextoffsets += [trialoffsets[idx]]
		elif trialcontexts[idx]!=trialcontexts[idx+1]:
			contextoffsets += [trialoffsets[idx]]

	return contextnames, contextonsets, contextoffsets

# get concatenated kinematic time bins and data
def getKinematicData(mat:dict) -> Tuple[torch.FloatTensor,List[str]]:
	kindata = mat['Mstruct']['Kinematic']

	for idx,val in enumerate(kindata):
		currentkindata = torch.tensor(val['JointStruct']['data'],dtype=torch.float)
		if idx == 0:
			catkindata = currentkindata
		else:
			catkindata = torch.cat((catkindata,currentkindata))

	colnames = kindata[0]['JointStruct']['columnNames']

	return catkindata, colnames

# split concatenated time bins according to contexts
# (we assume for now that contexts won't straddle splits in the data files)
def getContextKinematicData(mat:dict,targetcontext:str) -> Tuple[List[torch.FloatTensor],List[str]]:
	contextnames, contextonsets, contextoffsets = getContextTimings(mat)
	catkindata, colnames = getKinematicData(mat)
	contextkindata = []
	for idx,cname in enumerate(contextnames):
		if cname == targetcontext:
			onset  = contextonsets[idx]
			offset = contextoffsets[idx]
			# why are pytorch's logical indexing rules so opaque?
			# and why does pytorch's documentation lie to me and say this is a valid comparison?
			mask = torch.logical_and(catkindata[:,0]>=onset,catkindata[:,0]<offset)
			maskedkindata = catkindata[mask]
			contextkindata += [maskedkindata]

	return contextkindata,colnames

# bin the neural data (from a particular area) and split into appropriate context-block bins
# TODO

# END METHODS DEFINITION
# setup: define set of files to process & create a directory to put the pickles
fileTemplate = os.path.join('..','struct*.mat')

mirrorDataFiles = glob.glob(fileTemplate)

fldr = os.path.join('.','pickles')
if not os.path.exists(fldr):
	os.mkdir(fldr)


for file in mirrorDataFiles:
	animalName, sessionNumber = getFileMetadata(file)

	mat = loadmat(file,simplify_cells=True)

	# process and print out the intermediate product
	contextnames = []
	for context in mat['Mstruct']['TrialType']['names']:
		if not context in contextnames:
			contextnames += [context]

	for context in contextnames:
		contextkindata,colnames = getContextKinematicData(mat,context)

		# extract the neural data to go with it

	break