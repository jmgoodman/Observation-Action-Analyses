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


	def __len__(self):

	def __getitem__(self,idx:int):