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


# these should probably be class methods, eh? especially for get_auth, you probably want to avoid exposing that for security purposes, no? 
# ah well, I'll refactor when it matters.
def get_auth(auth_file:str) -> Tuple[str,str]:
    with open(auth_file) as f:
        
        lines = [line.rstrip() for line in f]
    
    # format: (user, pass)
    return tuple(lines)

def get_query(query_file:str) -> str:
    with open(query_file) as f:
        return f.read()
        

class Data:
    def __init__(self,
                 auth:str=os.path.join('.','auth'),
                 databasename:str="Zara70",
                 host:str="localhost",
                 filename:str = os.path.join('..','MirrorData','Zara70_datastruct.mat'),
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
        
        if not self.predata:
            return
        
        temp = self.predata
        
        # re-init dict (this will be how you implement a database)
        self.data = dict()
        
        # add tables to your database
        align_ = ['fixation','cue onset','cue offset','go cue onset','movement onset','hold onset','reward onset']
        time_  = temp['datastruct']['cellform'][0][0][0][0]['BinTimes']
        obj_   = temp['datastruct']['cellform'][0][0][0][0]['Objects']
        context_ = temp['datastruct']['cellform'][0][0][0][0]['TrialTypes']
        turntable_ = temp['datastruct']['cellform'][0][0][0][0]['TurnTableIDs']
        trial_ = np.arange(len(context_))
        
        align_expand,trial_expand,time_expand = np.meshgrid(align_,trial_,time_)
        trial_expand = trial_expand.astype('int')
        time_expand  = time_expand.astype('int')
        
        indexmat     = np.column_stack( (align_expand.flatten(),trial_expand.flatten(),time_expand.flatten()))
        indexdf      = pd.DataFrame(indexmat,columns=['Alignment','Trial','Time'])
        
        trialmat     = np.column_stack( (trial_,obj_,context_,turntable_) )
        trialdf      = pd.DataFrame(trialmat,columns=['Trial','Object','Context','Turntable'])
        
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
                
def create():
    session_names = ['Moe46','Moe50','Zara64','Zara68','Zara70']
    for sname in session_names:
        d = Data(databasename=sname,
                 filename=os.path.join('..','MirrorData',f'{sname}_datastruct.mat'))
        d.preload()
        d.load()
        d.export()
        
class Query:
    def __init__(self,
                 query:str=os.path.join('pythonfigures','query.sql'),
                 queryfile:bool=True,
                 auth:str=os.path.join('.','auth'),
                 host:str='localhost'
                 ):
        """Generates an instance of a Query object
        
        Args:
            query (str): MySQL query. Can span multiple databses, but databases must always be specified in the query! Can either be a query string or a file name (see 'queryfile' arg for more info). Defaults to 'pythonfigures/query.sql' (with appropriate platform-dependent path separator)
            queryfile (bool, optional): If true, reads SQL query from the specified file. Else, treats the input string as a literal query. Defaults to True.
            auth (str, optional): Sets the file from which to read authentication credentials for use of the SQL connector. Defaults to pythonfigures/auth.
            host (str, optional): Sets the host IP for sending SQL requests. Defaults to localhost.
        """
        self.query = query
        self.queryfile = queryfile
        self.auth = auth
        self.host = host
        
        usr,pwd = get_auth(self.auth)
        url_object = URL.create(
            "mysql",
            username=usr,
            password=pwd,
            host=self.host,
        )
        
        self.engine = create_engine(url_object)
        
    def read(self) -> pd.DataFrame:
        # note: once you have the df in python, it turns out that df.groupby([list,of,columns])[list,of,columns].mean() is way more powerful than trying to do something with an sql query...
        # indeed, see this answer: https://stackoverflow.com/questions/70320083/mode-of-each-column-in-mysql-without-explicitly-writing-column-names
        # but geez it's annoying to have to load everything in memory to make this work
        # in the end, I may need to write a python script that extracts the column names of all tables across all databases
        # extracts just the ones with neuron_ in their name
        # and builds avg(column) queries using those column names
        if self.queryfile:
            q = get_query(self.query)
        else:
            q = self.query
        
        with self.engine.begin() as conn:
            df = pd.read_sql_query(text(q), con=conn)
        
        return df
            
            
    
            
if __name__=='__main__':
    create()
    
    