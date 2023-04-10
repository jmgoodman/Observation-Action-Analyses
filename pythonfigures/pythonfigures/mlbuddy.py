from pythonfigures.datapartition import DataPartitioner
from pythonfigures.neuraldatabase import Query
import pandas as pd
import numpy as np

from sklearn.decomposition import PCA
from sklearn.discriminant_analysis import LinearDiscriminantAnalysis as LDA
from sklearn.model_selection import StratifiedKFold
from scipy.linalg import subspace_angles, null_space, orth

from typing import Optional

class MLBuddy:
    """MLBuddy: a class encapsulating a variety of ML training & evaluation methods

    Args:
        traindata (pd.DataFrame): the data the model will be trained on.
        labels (pd.DataFrame): the variable that the ML model will be trying to predict. Whether it's categorical or continuous will depend on modelType.
        modelType (str, optional): a string that reads either 'regression' or 'classification'. Defaults to 'classification'.
        pairedTestData (Optional[pd.DataFrame], optional): a paired dataset that matches with the training data. Useful when needing to cancel out context-specific means, or to avoid overfitting to matched trial information. Defaults to None.
        nullData (Optional[pd.DataFrame], optional): dataframe containing data where the plan is to "null out" the subspace related to it (for example, object vision during movement). Defaults to None.
        nullDataPaired (bool, optional): Only meaningful when "nullData" is not None. Determines whether nullData is paired with the traindata or not. Defaults to False.
        nullDataLabels (Optional[pd.DataFrame],optional): a set of labels to pair with the nullData if it isn't paired with the traindata. Default is None.
        crossval (bool, optional): Whether or not to cross-validate within the model. No cross-validation is desirable when the training data for a ML problem is unpaired data from another context relative to the test data. Defaults to True.
    """
    def __init__(self,
                 traindata:pd.DataFrame,
                 labels:pd.DataFrame,
                 modelType:str='classification',
                 pairedTestData:Optional[pd.DataFrame]=None,
                 nullData:Optional[pd.DataFrame]=None,
                 nullDataPaired:bool=False,
                 nullDataLabels:Optional[pd.DataFrame]=None,
                 crossval:bool=True):

        
        # listen bud, it's up to you to make sure your paired datasets have lined-up trial indices
        # just turn sort=False off when doing pandas groupby stuff
        # I'll put in your stinkin' guardrails later
        self.Xtrain    = traindata
        self.Xtest     = pairedTestData
        self.y         = labels
        self.modelType = modelType
        self.crossval  = crossval
        self.nullData  = nullData
        self.nullDataLabels = nullDataLabels
        self.nullDataPaired = nullDataPaired
        
        self.nullSpaceSize  = 0
        
        self.PCmodels  = []
        self.LDmodels  = []
        self.deltamu   = []
        self.nullableSpaces = []
        
        if self.crossval:
            self.crossvalsplits = list( StratifiedKFold(n_splits=5,shuffle=False).split(np.zeros(len(labels)),labels) )
        else:
            self.crossval = None
        
    def findNullSpaces(self):
        """finds the null spaces that the classifier will not be looking in.
        """
        
        # ughhhh no the PCs here need to be on AGGREGATED data which means I need to add that functionality to the WRAPPER, too!
        maxAxesToRemove = min(self.nullData.shape)-1
        if self.nullData is None:
            return
        else:
            if self.crossval and self.nullDataPaired:
                labels = self.y
                splits = self.crossvalsplits
            else:
                # ad hoc splits
                labels = self.nullDataLabels
                splits = list( StratifiedKFold(n_splits=5,shuffle=False).split(np.zeros(len(self.nullDataLabels)),self.nullDataLabels) )
                
            for train_,_ in splits:                    
                PCmdl = PCA(n_components = maxAxesToRemove)
                PCmdl.fit(self.nullData.iloc[train_].to_numpy())
                nullableSpaces += [PCmdl.components_]
                
        # finally, find the size of the nullspace that you need to delete
        # (hmmm this could stand to be refactored, eh?)
        flag = False
        axesToRemove    = 0
        while not flag:
            correct_count = 0
            chance_count  = 0 
            total_count   = 0
            
            for fold,(train_,test_) in enumerate(splits):
                trainX = self.nullData.iloc[train_]
                testX  = self.nullData.iloc[test_]
                
                trainy = labels[train_]
                testy  = labels[test_]
                
                if axesToRemove > 0:
                    nullSpace = null_space( np.matrix( nullableSpaces[fold][:axesToRemove,:] ) )
                else:
                    nullSpace = np.eye(trainX.shape[1])
                
                # project onto the null space
                trainX = trainX.to_numpy() @ nullSpace
                testX  = testX.to_numpy() @ nullSpace
                
                # reduce dimensionality
                innerPC = PCA(n_components=30)
                trainX = innerPC.fit_transform(trainX)
                testX  = innerPC.transform(testX)
                
                # run the model
                LDmdl = LDA()
                LDmdl.fit(trainX,trainy)
                yhat  = LDmdl.predict(testX)
                
                correct_count += np.sum(yhat==testy)
                chance_count  += len(testy) * max(LDmdl.priors_)
                
            correct_rate   = correct_count / total_count
            chance_rate    = chance_count / total_count
            threshold_rate = chance_rate + np.sqrt( chance_rate*(1-chance_rate)/total_count ) # chance + 1 SE
            
            if correct_rate > threshold_rate and axesToRemove < maxAxesToRemove:
                axesToRemove+=1
            else:
                flag = True
                
        self.nullSpaceSize  = axesToRemove
        
        if self.crossval and self.nullDataPaired:
            self.nullableSpaces = nullable
        
        
                
                
        
                    
    def findDeltaMu(self):
        """finds the separation in context means, if it is desired
        """
        