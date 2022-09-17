# %%
from scipy.io import loadmat
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
import torch
# import plotly.graph_objects as go

# matplotlib.use('WebAgg') # qtagg might be default, I think? which requires PyQt. Or TkAgg, which requires TkInter.

mat = loadmat('structZara70.mat',simplify_cells=True)

# step 1: get the kinematic data bins (don't concatenate because they won't be contiguous)
kindata = mat['Mstruct']['Kinematic']
kinbins = []
binnedjointangles = []

for kd in kindata:
	kinbins += [torch.tensor(kd['JointStruct']['data'][:,0])]
	binnedjointangles += [torch.tensor(kd['JointStruct']['data'][:,1:])]

print(kindata[0]['JointStruct']['columnNames'][1:])

print(kinbins[3][-1] - kinbins[3][-2])
print(kinbins[3][1] - kinbins[3][0])
print(kinbins[4][0] - kinbins[3][-1])

# step 2: bin the spike counts
neurdata = mat['Mstruct']['Neural']

print(mat['Mstruct']['TrialType'])

binnedspikecounts = []

for block in kinbins:
	temp = []
	for nd in neurdata:
		bsc,_ = torch.histogram(torch.tensor(nd['spiketimes']),block)
		temp += [torch.unsqueeze(bsc,dim=-1)]

	temp = torch.cat(tuple(temp),dim=1)
	binnedspikecounts += [temp]

print(binnedspikecounts[0].size())
print(binnedspikecounts[1].size())
print(binnedjointangles[0].size())
print(binnedjointangles[1].size())


# %%
# sample code binning the spike counts (using only the first kinematic "file" and one neuron, though )
spikeBins  = mat['Mstruct']['Kinematic'][0]['JointStruct']['data'][:,0]

# get the most-spiking neuron
spikeCounts = [neur['SpikeCount'] for neur in mat['Mstruct']['Neural']]
mostSpikesNeuron = np.argmax(spikeCounts)

spikeTimes = mat['Mstruct']['Neural'][mostSpikesNeuron]['spiketimes']

# and bin
binnedSpikeCounts,trueSpikeBins = np.histogram(spikeTimes,bins=spikeBins)

# and plot (not using hist, but rather just a time-varying trace)
# plt.figure()
# plt.plot(trueSpikeBins[:-1],binnedSpikeCounts)
# plt.show() # important...

# from here, you can trivially get binned spike counts and binned kinematics to go with them (thanks past me for painstakingly aligning them in MATLAB!)
# then you can dump each session into a table of a lil sql file
# and write a PyTorch dataloader to query a session and then a snippet of data from it
# then get BERT involved and decode joint kinematics
# TODO: figure out how to decode observed actions: as a literal representation of the viewed hand movements, or as some trial-averaged version of the average grip adopted by the monkey themselves?
#   probably some variation of both? use the literal representation of viewed hand movements as your model of training a decoder on observed actions, and use the average grip adopted by the monkey themselves as one of two models (the other being "hold still") of what is being decoded by a movement-trained decoder during an observation context
# TODO: figure out how to stitch sessions together? Given Jannik's work and all... (although this could be trickier with ANN decoders...) (maybe CEBRA is a solution to this?)
# But both of those todo items are "nice-to-haves". If we can just do raw-ass decoding, PERIOD, that's an EXCELLENT first step.
# But to that end:
# TODO: for observation contexts, switch kinematics from the observed ones to a constant stream of the average "on-handrest" position of the animal

# %%
# convert to a pandas Series
# (note: DataFrame.hist is very slow here)
# s = pd.Series(spikeTimes)
# histo = s.value_counts(bins=spikeBins)

# %%
input('Press enter to end...\n')