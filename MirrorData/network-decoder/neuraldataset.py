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
		binnedjointangles = []

		for kd in kindata:
			kinbins += [torch.tensor(kd['JointStruct']['data'][:,0])]
			binnedjointangles += [torch.tensor(kd['JointStruct']['data'][:,1:])]

		# index 1 = time
		# indices 2-30 (29 total) = the following kinematics:
		#  'floatyaw', 'floatroll', 'floatpitch', 'floatx', 'floaty',
		# floatz', 'pro_sup_l', 'deviation_l', 'flexion_l', 'cmc_flexion_l',
		# 'cmc_abduction_l', 'mp_flexion_l', 'ip_flexion_l',
		# '2mcp_flexion_l', '2mcp_abduction_l', '2pm_flexion_l',
		# '2md_flexion_l', '3mcp_flexion_l', '3mcp_abduction_l',
		# '3pm_flexion_l', '3md_flexion_l', '4mcp_flexion_l',
		# '4mcp_abduction_l', '4pm_flexion_l', '4md_flexion_l',
		# '5mcp_flexion_l', '5mcp_abduction_l', '5pm_flexion_l',
		# '5md_flexion_l'
		#
		# note: floatyaw / floatroll / floatpitch SHOULD be held constant while pro_sup_l, devation_l, and flexion_l do all the work
		# (to be specific, the floatrotations do the work of establishing an intuitive baseline orientation with respect to which the wrist rotations can be understood)
		# that said, floatx, floaty, and floatz should NOT be held constant, as they're doing the shoulder's work

		# step 2: bin the spike counts
		neurdata = mat['Mstruct']['Neural']

		binnedspikecounts = []

		for block in kinbins:
			temp = []
			for nd in neurdata:
				bsc,_ = torch.histogram(torch.tensor(nd['spiketimes']),block)
				temp += [torch.unsqueeze(bsc,dim=-1)]

			temp = torch.cat(tuple(temp),dim=1)
			binnedspikecounts += [temp]

		# now save it as a data file
		# (in fact this should probably be preprocessing for the dataset)



	def __len__(self):

	def __getitem__(self,idx:int):
		return neuraldata, kinematicdata # image, label framework: https://pytorch.org/tutorials/beginner/basics/data_tutorial.html