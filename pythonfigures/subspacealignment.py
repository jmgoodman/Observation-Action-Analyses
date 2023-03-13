from __future__ import annotations
from typing import List, Optional

import mat73
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
import os

# what is the subspace alignment index?
# essentially, it's the ratio of variance explained by some arbitrary n-dimensional manfiold w.r.t. that explained by the n-dimensional pca decomposition of the data

# TODO: refactor refactor refactor! have "data" be a parent data object, then "view" be a subclass that adds dimensional grouping, epoch selection, array selection, and context selection
# Hmmm, is "view" a subclass of data, or rather, a wrapper around data? I think it's the latter, actually

class Data:
    def __init__(self,
                 filename:str = os.path.join('MirrorData','Zara70_datastruct.mat')
                 ):
        # presets:
        # Zara70
        # alignment to 500ms straddling start of movement
        # data from F5
        self.filename = filename
        self.data     = None
        
    def load(self):
        self.data = mat73.loadmat(self.filename)
    
    
class View(Data):
    def __init__(self,
                 dobj:Data,
                 dimension_grouping:Optional[List[List[int]]] = [[1,2],[0]],
                 epoch_selection:List[int] = [4],
                 array_selection:List[int] = [2,3],
                 context_selection:List[str] = ['active']
    ):
        self.dobj = dobj
        self.dimension_grouping = dimension_grouping
        self.epoch_selection = epoch_selection
        self.array_selection = array_selection
        self.context_selection = context_selection
        