from __future__ import annotations
from typing import List

import mat73
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
import os

# what is the subspace alignment index?
# essentially, it's the ratio of variance explained by some arbitrary n-dimensional manfiold w.r.t. that explained by the n-dimensional pca decomposition of the data

# todo: make Data's internals based on pandas to enable sql-like selection, aggregation, & grouping

class Data:
    def __init__(self):
        self.filename = 'muster'
        self._view    = [[]]
        self.data     = np.array([])
        self.subspace = np.array([])
    def load(self,filename:str):
        pass
    def setview(self,dimension_groupings:List[List[int]]):
        pass
    def applyview(self) -> np.array:
        pass
    def infer_pca_subspace(self):
        pass
    def compute_pca_variance_captured(self) -> List[float]:
        pass
    def compute_subspace_alignment(self,data:Data) -> float:
        pass