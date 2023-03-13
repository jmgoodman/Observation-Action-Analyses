from __future__ import annotations
from typing import List, Optional

import mat73
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
import os

# what is the subspace alignment index?
# essentially, it's the ratio of variance explained by some arbitrary n-dimensional manfiold w.r.t. that explained by the n-dimensional pca decomposition of the data

# TODO: load data files as dataframe databases, the "Data" object will be a wrapper for these
# each array will be a different table (dataframe) in each of these databases
# in each table (dataframe), features will be firing rates of individual neurons
# each time x trial will have an entry in this table
# in addition to firing rates, trial index and time will be features of this table
# in addition, there will be a table with object and context as features of each trial
# the Data object will then leverage sql-like view selection in pandas

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
        self.predata  = None
    
    def preload(self):
        if not self.predata:
            self.predata = mat73.loadmat(self.filename)

    def load(self):
        if not self.predata:
            self.preload()
            
        temp = self.predata
        
        # re-init dict (this will be how you implement a database)
        self.data = dict()
        
        # add tables to your database
        align_ = ['fixation','cue onset','cue offset','go cue onset','movement onset','hold onset','reward onset']
        time_  = temp['datastruct']['cellform'][0][0][0][0]['BinTimes']
        obj_   = temp['datastruct']['cellform'][0][0][0][0]['Objects']
        context_ = temp['datastruct']['cellform'][0][0][0][0]['TrialTypes']
        trial_ = np.arange(len(context_))
        
        align_expand,trial_expand,time_expand = np.meshgrid(align_,trial_,time_)
        trial_expand = trial_expand.astype('int')
        time_expand  = time_expand.astype('int')
        
        indexmat     = np.column_stack( (align_expand.flatten(),trial_expand.flatten(),time_expand.flatten()))
        indexdf      = pd.DataFrame(indexmat,columns=['Alignment','Trial','Time'])
        
        trialmat     = np.column_stack( (trial_,obj_,context_) )
        trialdf      = pd.DataFrame(trialmat,columns=['Trial','Object','Context'])
        
        self.data['Trial_Info'] = trialdf
        self.data['Index_Info'] = indexdf
        
        arraynames = [ d[0][0][0]['ArrayIDs'][0][0] for d in temp['datastruct']['cellform'] ]
        
        for arrayidx,array in enumerate(arraynames):
            dcataligns = []
            for alignidx,align in enumerate(temp['datastruct']['cellform'][arrayidx][0]):
                # grab data and reshape
                dtrials  = np.transpose( align[0]['Data'],[1,2,0] ) # from time x neuron x trial to neuron x trial x time
                dreshape = np.reshape(dtrials,(dtrials.shape[0],-1)) # C-like order is the opposite of MATLAB-like order, but is standard in numpy (hence why we permuted to have time be the last, i.e., fastest-changing index)
                dreshape = np.transpose(dreshape,[1,0]) # from neuron x (trial x time) to (trial x time) x neuron
                
                dcataligns.append(dreshape)
                
            dcat = np.concatenate( tuple(dcataligns),axis=0 )
            dcat = np.column_stack( (trial_expand.flatten(),dcat) )
            colnames = ['Trial'] + [f'Neuron_{i}' for i in range(dcat.shape[1]-1)]
            
            self.data[array] = pd.DataFrame(dcat,columns=colnames)
            self.data[array]['Trial'] = self.data[array]['Trial'].astype(int) # for some reason numpy and/or pandas is obsessed with converting this into a float, so here I convert it back 