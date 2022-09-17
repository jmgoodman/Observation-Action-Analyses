import os
import glob
from scipy.io import loadmat
import torch
import re
import pickle

# TODO: separate contexts!

fileTemplate = os.path.join('..','struct*.mat')

mirrorDataFiles = glob.glob(fileTemplate)

fldr = os.path.join('.','pickles')
if not os.path.exists(fldr):
	os.mkdir(fldr)

for file in mirrorDataFiles:
	# mat = loadmat(file,simplify_cells=True)
	pathlist = os.path.split(file)
	filename = pathlist[-1]
	sessionName = filename[6:-4]

	animalNameTemplate = '^[a-zA-Z]+'
	sessionNumberTemplate = '[0-9]+$'

	animalMatch  = re.search(animalNameTemplate,sessionName)
	sessionMatch = re.search(sessionNumberTemplate,sessionName)

	animalName     = animalMatch.group()
	sessionNumber  = sessionMatch.group()

	mat = loadmat(file,simplify_cells=True)

	# gets the context order that the kinematic files follow

	contextorder   = []
	contextonsets  = []
	contextoffsets = []
	trialcontexts = mat['Mstruct']['TrialType']['names']
	trialonsets   = [tr['trial_start_time'] for tr in mat['Mstruct']['Event']]
	trialoffsets  = [tr['trial_end_time'] for tr in mat['Mstruct']['Event']]
	for idx, val in enumerate(trialcontexts):
		if idx == 0 or trialcontexts[idx]!=trialcontexts[idx-1]:
			contextorder   +=[val]
			contextonsets  +=[trialonsets[idx]]
		if idx == (len(trialcontexts)-1):
			contextoffsets +=[trialoffsets[idx]]
		elif trialcontexts[idx]!=trialcontexts[idx+1]: # seems redundant, but done as a safety to try preventing out-of-bounds errors
			contextoffsets +=[trialoffsets[idx]]

	print(contextorder)
	print(contextonsets)
	print(contextoffsets)
	uniquecontexts = set(contextorder)
	print(uniquecontexts) # we can now use this information to create separate files based on context!

	# step 1: get the kinematic data bins (don't concatenate because they won't be contiguous)
	kindatadict = dict()
	kindata = mat['Mstruct']['Kinematic']
	kindatadict['kinColNames'] = kindata[0]['JointStruct']['columnNames'][1:]
	kindatadict['kinTimeBins'] = [] # times in ms from "experiment begin". sampling rate = 100 Hz (so 10ms bins, established via the MirrorData MATLAB methods)
	kindatadict['binnedJointAngles'] = []

	for kd in kindata:
		kindatadict['kinTimeBins'] += [torch.tensor(kd['JointStruct']['data'][:,0])]
		kindatadict['binnedJointAngles'] += [torch.tensor(kd['JointStruct']['data'][:,1:])]

	ktb = torch.cat(tuple(kindatadict['kinTimeBins']),dim=0)
	bja = torch.cat(tuple(kindatadict['binnedJointAngles']),dim=0)

	for context in uniquecontexts:
		consets  = [conset for idx,conset in enumerate(contextonsets) if contextorder[idx]==context]
		coffsets = [coffset for idx,coffset in enumerate(contextoffsets) if contextorder[idx]==context]

		kin = dict()
		kin['kinColNames'] = kindata[0]['JointStruct']['columnNames'][1:]
		kin['kinTimeBins'] = [] # times in ms from "experiment begin". sampling rate = 100 Hz (so 10ms bins, established via the MirrorData MATLAB methods)
		kin['binnedJointAngles'] = []

		# now make a list of tensors containing data ONLY FROM THIS CONTEXT
		# with the list separating noncontiguous tensors
		# (god this is exhausting... pytorch tensors are such a *drag* to work with, what with their autosqueezing nonsense...)
		# (and my brain is REFUSING to deal with it anymore... a todo item for a different day, I'm afraid)

	kinfilename = animalName+sessionNumber+'_kin.pickle'
	kinfile = os.path.join(fldr,kinfilename)
	with open(kinfile,'wb') as handle: # use 'w' to write from scratch
		pickle.dump(kindatadict,handle,protocol=pickle.HIGHEST_PROTOCOL)

	# step 2: bin the spike counts
	neurdata = mat['Mstruct']['Neural']

	areas = ['M1','F5','AIP','all']

	for area in areas:
		if area == 'all':
			tempdata = neurdata
		else:
			tempdata = [nd for nd in neurdata if re.match(area,nd['array'])]

		print(area+": "+str(len(tempdata)))
		binnedspikecounts = []

		for block in kindatadict['kinTimeBins']:
			temp = []
			for nd in tempdata:
				bsc,_ = torch.histogram(torch.tensor(nd['spiketimes']),block)
				temp += [torch.unsqueeze(bsc,dim=-1)]

			temp = torch.cat(tuple(temp),dim=1)
			binnedspikecounts += [temp]

		neurfilename = animalName + sessionNumber + "_" + area + ".pickle"
		neurfile = os.path.join(fldr,neurfilename)
		with open(neurfile,'wb') as handle: # use 'w' to write from scratch
			pickle.dump(binnedspikecounts,handle,protocol=pickle.HIGHEST_PROTOCOL)