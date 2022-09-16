import torch
import os
import pandas as pd
from torch.utils.data import Dataset
from scipy.io import loadmat

class NeuralDataset(Dataset):

	def __init__(self,session:str,area:str,window:float):
		self.session = session
		self.area    = area
		self.window  = window

		mat = loadmat(session,simplify_cells=True)

		# step 1: get the kinematic data bins (don't concatenate because they won't be contiguous)
		kindata = mat['Mstruct']['Kinematic']
		kinbins = []

		for kd in kindata:
			kinbins += [torch.tensor(kd['JointStruct']['data'][:,0])]

		# step 2: bin the spike counts
		neurdata = mat['Mstruct']['Neural']

		binnedspikecounts = []

		for nd in neurdata:
			bsc = torch.histogram(torch.tensor(nd['spiketimes']),kinbins[0])
			binnedspikecounts += [bsc]

		

	def __len__(self):

	def __getitem__(self,idx:int):