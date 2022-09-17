import torch
import os
import pandas as pd
from torch.utils.data import Dataset
from scipy.io import loadmat

class NeuralDataset(Dataset):

	def __init__(self,session:str,area:str,context:str,window:float):
		self.session = session
		self.area    = area
		self.window  = window # let's make the 


	def __len__(self):

	def __getitem__(self,idx:int):
		return neuraldata, kinematicdata # image, label framework: https://pytorch.org/tutorials/beginner/basics/data_tutorial.html