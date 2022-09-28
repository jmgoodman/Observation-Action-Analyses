import os
import glob
import torch
from scipy.io import loadmat # imports need to happen in this order (on mac), otherwise scipy inits libiomp.dylib which is incompatible with torch's preference for libiomp5.dylib
import re
import pickle

from typing import Tuple, List

# to run on mac: https://stackoverflow.com/questions/53014306/error-15-initializing-libiomp5-dylib-but-found-libiomp5-dylib-already-initial
# actually nevermind, it's hopelessly bugged and the only version of pytorch that works with nomkl (1.4) is so feature-poor as to be useless. THANKS PYTORCH FOR BEING COOL AND GOOD

# define a method for getting metadata from file names
def getFileMetadata(filename:str) -> Tuple[str,str]:
	pathlist = os.path.split(file)
	filename = pathlist[-1]
	sessionName = filename[6:-4]

	animalNameTemplate = '^[a-zA-Z]+'
	sessionNumberTemplate = '[0-9]+$'

	animalMatch  = re.search(animalNameTemplate,sessionName)
	sessionMatch = re.search(sessionNumberTemplate,sessionName)

	animalName     = animalMatch.group()
	sessionNumber  = sessionMatch.group()

	return animalName, sessionNumber

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
def getKinematicData(mat:dict) -> Tuple[torch.DoubleTensor,List[str]]:
	kindata = mat['Mstruct']['Kinematic']

	for idx,val in enumerate(kindata):
		currentkindata = torch.tensor(val['JointStruct']['data'],dtype=torch.double)
		if idx == 0:
			catkindata = currentkindata
		else:
			catkindata = torch.cat((catkindata,currentkindata))

	colnames = kindata[0]['JointStruct']['columnNames']

	return catkindata, colnames

# split concatenated time bins according to contexts
# also extract neural data while you're here
# (we assume for now that contexts won't straddle splits in the data files)
def getContextData(mat:dict,targetcontext:str,area:str) -> Tuple[List[torch.DoubleTensor],List[torch.ByteTensor],List[str]]:
	contextnames, contextonsets, contextoffsets = getContextTimings(mat)
	catkindata, colnames = getKinematicData(mat)
	contextkindata = []
	contextneurdata = []
 
	# first off, reduce the neural data to the target area
	neuraldata = mat['Mstruct']['Neural']
 
	if area != 'all':
		neuraldata = [nd for nd in neuraldata if re.match(area,nd['array'])]
 
	for idx,cname in enumerate(contextnames):
		if cname == targetcontext:
			onset  = contextonsets[idx]
			offset = contextoffsets[idx]
			mask = (catkindata[:,0]>=onset) & (catkindata[:,0]<offset)
			maskedkindata = catkindata[mask]
			contextkindata += [maskedkindata]

			# now extract the neural data
			binnedspikecounts = []
			for nd in neuraldata:
				spikecounts,_ = torch.histogram(torch.tensor(nd['spiketimes'],dtype=torch.double),maskedkindata[:,0])
				binnedspikecounts += [torch.unsqueeze(spikecounts.to(torch.uint8),1)] # can't have negative or noninteger spikes, nor can you have more than like 10 in a 10ms bin

			binnedspikecounts = torch.cat(tuple(binnedspikecounts),dim=1)
			contextneurdata += [binnedspikecounts]


	return contextkindata,contextneurdata,colnames
    
    
    

# END METHODS DEFINITION
# setup: define set of files to process & create a directory to put the pickles
fileTemplate = os.path.join('..','struct*.mat')

mirrorDataFiles = glob.glob(fileTemplate)

fldr = os.path.join('.','pickles')
if not os.path.exists(fldr):
	os.mkdir(fldr)


for file in mirrorDataFiles:
	animalName, sessionNumber = getFileMetadata(file)
 
	# moe's data don't have simultaneous neural & kinematic data for the mirror context, so only pay attention to zara
	if animalName != 'Zara':
		continue
	elif sessionNumber == '65':
		continue # also ignore session 65 which lacks any neural data

	mat = loadmat(file,simplify_cells=True)

	# process and print out the intermediate product
	contextnames = []
	for context in mat['Mstruct']['TrialType']['names']:
		if not context in contextnames:
			contextnames += [context]
   
	areanames = ['all','M1','F5','AIP']

	for context in contextnames:
		for area in areanames:
			# inefficient that we extract the kinematic data anew every time we want a new area...
			# ...but this is a one-time preprocessing, nothing that is worth optimizing too much
			contextkindata,contextneurdata,colnames = getContextData(mat,context,area)
   
			if area == 'all':
				kinfile = animalName+sessionNumber+'_'+context+'_kin.pickle'
				kinfile = os.path.join(fldr,kinfile)
				with open(kinfile,'wb') as handle:
					kin = dict()
					kin['kinColNames'] = colnames
					kin['data']        = contextkindata
					pickle.dump(kin,handle,protocol=pickle.HIGHEST_PROTOCOL)

			neurfile = animalName+sessionNumber+'_'+context+'_'+area+'_neur.pickle'
			neurfile = os.path.join(fldr,neurfile)
			with open(neurfile,'wb') as handle:
				neur = dict()
				neur['data'] = contextneurdata # for style consistency with the kinematic data
				pickle.dump(neur,handle,protocol=pickle.HIGHEST_PROTOCOL)