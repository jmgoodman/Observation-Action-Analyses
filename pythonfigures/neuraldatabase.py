from __future__ import annotations
from typing import List, Optional, Tuple

import mat73
import pandas as pd
import numpy as np
from sklearn.decomposition import PCA
import os

from sqlalchemy import create_engine, URL, text
from sqlalchemy_utils import database_exists, create_database

# sneaky dependency: pip install mysqlclient

# still won't work on mac
# read this: https://stackoverflow.com/questions/63109987/nameerror-name-mysql-is-not-defined-after-setting-change-to-mysql
# specifically, the comment that says to run the following in the terminal: cp -r /usr/local/mysql/lib/* /usr/local/lib/
# basically, mysqlclient expects the mysql lib functions to be located in /usr/local/lib/, and not nested inside the mysql directory of /usr/local/



def get_auth(auth_file:str) -> Tuple[str,str]:
    with open(auth_file) as f:
        lines = [line.rstrip() for line in f]
    
    # format: (user, pass)
    return tuple(lines)

class Data:
    def __init__(self,
                 auth:str=os.path.join('pythonfigures','auth'),
                 databasename:str="Zara70",
                 host:str="localhost",
                 filename:str = os.path.join('MirrorData','Zara70_datastruct.mat'),
                 ):
        # presets:
        # Zara70
        # alignment to 500ms straddling start of movement
        # data from F5
        self.filename = filename
        self.data     = None
        self.predata  = None
        
        self.authfile = auth
        self.databasename = databasename
        self.host = host
        
        usr,pwd = get_auth(self.authfile)
        url_object = URL.create(
            "mysql",
            username=usr,
            password=pwd,
            host=self.host,
            database=self.databasename
        )
        
        self.engine = create_engine(url_object)
            
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
            for align in temp['datastruct']['cellform'][arrayidx][0]:
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
    
    
    def create_database_if_not_exist(self):
        """Creates the database specified by the sqlalchemy engine if it doesn't already exist. This is done as a separate, explicit method to guard against fragmenting disks via implicit database creations upon instantiation of FinDataReader objects.
        """
        if not database_exists(self.engine.url):
            create_database(self.engine.url)
            
    def export(self,if_exists='replace'):
        self.create_database_if_not_exist()
        if not (self.data==None):
            for key in self.data.keys():
                self.data[key].to_sql(key,con=self.engine,if_exists=if_exists)
            
            
    
            
if __name__=='__main__':
    # you should probably make a proper test class for this
    d = Data()
    d.preload()
    d.load()
    d.export()
    
    