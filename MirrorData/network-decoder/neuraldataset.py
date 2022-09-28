import torch
import os
import pandas as pd
import pickle
from torch.utils.data import Dataset
from scipy.io import loadmat
from typing import Tuple

class NeuralDataset(Dataset):

	def __init__(self,session:str,context:str,area:str,window:float) -> None:
		self.session = session
		self.area    = area
		self.window  = window # the window parameter is in milliseconds for user convenience. We sample at 100Hz and for implementation convenience, we store an internal property __window in terms of bins
		self.__window = window // 10
  
		kinfile  = os.path.join('.','pickles',session+'_'+context+'_kin.pickle')
		neurfile = os.path.join('.','pickles',session+'_'+context+'_'+area+'_neur.pickle')
  
		with open(kinfile,'rb') as handle:
			self.kindata = pickle.load(handle)
   
		with open(neurfile,'rb') as handle:
			self.neurdata = pickle.load(handle)
   
	def __len__(self) -> int:
		# use the "window" parameter to identify how many nonoverlapping chunks you can break things into
		nwindows = [t.size(dim=0) // self.__window for t in self.kindata['data']]
		return sum(nwindows)

	def __getitem__(self,idx:int) -> Tuple[dict,dict]:
		# use the "window" parameter once more to break things up
		nwindows = [t.size(dim=0) // self.__window for t in self.kindata['data']]
  
		listind = 0
		while idx >= nwindows[0]:
			idx -= nwindows[0]
			listind += 1
			nwindows.pop(0)
   
		startind = self.__window * idx
		endind   = startind + self.__window # non-inclusive
  
		neuraldata    = self.neurdata['data'][listind][startind:endind,:]
		kinematicdata = self.kindata['data'][listind][startind:endind,1:]

		return neuraldata, kinematicdata # image, label framework: https://pytorch.org/tutorials/beginner/basics/data_tutorial.html