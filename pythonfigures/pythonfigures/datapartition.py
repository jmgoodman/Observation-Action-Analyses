from pythonfigures.neuraldatabase import Query
import pandas as pd
import numpy as np

from typing import List, Dict, Optional

class DataPartitioner:
    def __init__(self,
                 session:str,
                 areas:List[str],
                 aligns:List[str],
                 contexts:List[str],
                 groupings:List[str]):
        # let's just handle a single session at a time, trying to handle pooling of sessions and the different behavior thereof (namely, trial averaging to make joining possible) sounds like a pain
        self._session           = session
        self._areas             = areas
        self._aligns            = aligns
        self._contexts          = contexts
        
        # expand groupings
        self._groupings         = list()
        for i in range(2**len(groupings)):
            temp = list()
            
            # binary decoder
            itemp = i
            for j in reversed(range(len(groupings))):
                if itemp>>j > 0:
                    temp  = [groupings[j]]+temp
                    itemp %= 2**j
            
            self._groupings += [set(temp)]
        
        # these will be determined later when building the queries
        self._neuronColumnNames = None
        self._queries           = None
        
        # speaking of which
        self._buildQueries()
        
    def _buildQueries(self):
        # first off, get the neuron columns
        all_cols = []
        for area in self._areas:
            q = Query(query=f"""SHOW COLUMNS FROM `{self._session}`.`{area}-med`;""",
                        queryfile=False)
            colsmed = q.read()
            colsmed = colsmed['Field'][ colsmed['Field'].str.startswith('Neuron_') ].values.tolist()
            colsmed = [f"`{self._session}`.`{area}-med`.`{x}`" for x in colsmed]
            
            q = Query(query=f"""SHOW COLUMNS FROM `{self._session}`.`{area}-lat`;""",
                        queryfile=False)
            colslat = q.read()
            colslat = colslat['Field'][ colslat['Field'].str.startswith('Neuron_') ].values.tolist()
            colslat = [f"`{self._session}`.`{area}-lat`.`{x}`" for x in colslat]
            
            all_cols+=colsmed+colslat
            
        # now, get all the tables to join
        tables_to_join = []
        for area in self._areas:
            tables_to_join+=[f"{area}-med",f"{area}-lat"]
        
        tables_to_join+=["Trial_Info","Index_Info"]
        maintbl = tables_to_join.pop(0)
        
        # now, build the base query
        query = "SELECT "
        
        neuridx = 0
        for colname in all_cols:
            query+=f"{colname} as n{neuridx},\n"
            neuridx+=1
            
        self._neuronColumnNames = [f"n{idx}" for idx in range(neuridx)]
        
        # get the trial index too
        query+=f"CAST(`{self._session}`.`{maintbl}`.`Trial` as UNSIGNED) as trial,\n"
        
        query+=f"`{self._session}`.`Trial_Info`.`Object` as object,\n"
        query+=f"`{self._session}`.`Trial_Info`.`Context` as context,\n"
        query+=f"CAST(`{self._session}`.`Trial_Info`.`Turntable` as UNSIGNED) as turntable,\n"
        
        query+=f"`{self._session}`.`Index_Info`.`Alignment` as alignment,\n"
        query+=f"CAST(`{self._session}`.`Index_Info`.`Time` as SIGNED) as time,\n"
        
        query+=f"CAST(`{self._session}`.`grip_info`.`Grip` as UNSIGNED) as grip\n"
        
        
        query+=f"FROM `{self._session}`.`{maintbl}`\n"
        
        for table in tables_to_join:
            query+=f"LEFT JOIN `{self._session}`.`{table}`\n"
            
            if table=="Trial_Info":
                joincol = "Trial"
            else:
                joincol = "index"
                
            query+=f"ON `{self._session}`.`{maintbl}`.`{joincol}`=`{self._session}`.`{table}`.`{joincol}`\n"
            
        # join grip information, too (which requires joining on two columns)
        query+=f"LEFT JOIN `{self._session}`.`grip_info`\n"
        query+=f"ON `{self._session}`.`trial_info`.`Context`=`{self._session}`.`grip_info`.`Context`\n"
        query+=f"AND `{self._session}`.`trial_info`.`Object`=`{self._session}`.`grip_info`.`Object`\n"
            
        query+="WHERE alignment IN ("
        
        for align in self._aligns:
            query+=f"'{align}'"
            if align==self._aligns[-1]:
                query+=") "
            else:
                query+=","
        
        # needed to avoid collision with grip_info's context column     
        query+=f"AND `{self._session}`.`Trial_Info`.`Context` IN ("
        for context in self._contexts:
            query+=f"'{context}'"
            if context==self._contexts[-1]:
                query+=")\n"
            else:
                query+=","
        
        query+="ORDER BY trial, alignment, time"
            
        # now, construct the grouped queries
        self._queries = []
        for grouping in self._groupings:
            grouping = list(grouping) # they're sets to allow for indexing
            if len(grouping)==0:
                self._queries+=[query+";"]
            else:
                # now, build the base query
                gquery = "SELECT "
                
                for col in self._neuronColumnNames:
                    gquery+=f"AVG({col}) as {col},\n"
                
                # preserve grouped indices
                for col in grouping:
                    gquery+=f"MAX({col}) as {col}"
                    if col!=grouping[-1]:
                        gquery+=","
                    gquery+="\n"
                
                gquery+=f"FROM ({query}) t\n"
                gquery+=f"GROUP BY "
                
                for col in grouping:
                    gquery+=f"{col}"
                    if col!=grouping[-1]:
                        gquery+=","
                    gquery+="\n"
                
                gquery+="ORDER BY "
                
                for col in grouping:
                    gquery+=f"{col}"
                    if col!=grouping[-1]:
                        gquery+=",\n"
                
                gquery+=";"
                
                self._queries+=[gquery]
        
    def readQuery(self,idx) -> pd.DataFrame:
        if self._queries is None:
            print('run buildQueries first!')
            return
        
        if isinstance(idx,int):
            pass
        elif isinstance(idx,(list,set,tuple)):
            idx = self._groupings.index(idx)
        
        q = Query(query=self._queries[idx],
                  queryfile=False)
        
        return q.read()
        
    def get(self,
            param:str):
        return self.__dict__["_"+param]
    
    def set(self,
            param:str,
            val):
        
        if param in ["queries","neuronColumnNames"]:
            print("I won't let you set queries or neuronColumnNames, sorry.")
            return
        
        # TODO: find a way to constrain val's type
        if "_"+param in self.__dict__:
            self.__dict__["_"+param] = val
        else:
            print(f"Invalid parameter '{param}'")
            return
        
        # reset _queries and _neuronColumnNames
        self._queries           = None
        self._neuronColumnNames = None
        self._buildQueries()

        
if __name__=='__main__':
    dp = DataPartitioner(session='Moe46',
                         areas=['M1'],
                         aligns=['movement onset','hold onset'],
                         contexts=['active','passive'],
                         groupings=['grip','object','context'])
    
    groupslist = dp.get('groupings')
    
    print(groupslist)
    
    df = dp.readQuery(0) # just get the full data
    df_mu = dp.readQuery(7) # note: joining the grip table on object x context yields a few "NaN" grip labels in Moe's dataset. Why? Because we didn't have human kinematics in Moe's dataset, and the human subjects grasped objects that were not present in the human datasets for Zara's recordings! (which means: if you see NaN, don't freak out too much! It's a genuine feature of the data, not a bug!)
    
    # sql-style join
    df_joined = pd.merge(df,df_mu,how='left',on=['grip','object','context'],sort=False,suffixes=("","_mu")) # sort=False to keep the nx_mu columns congruent with the columns in df_win
    
    print(df)
    print(df_mu)
    print(df_joined)
    
    # sql-style window function, i.e., agg() over (partition by)
    df_win = df.groupby(['grip','object','context'])[dp.get('neuronColumnNames')].transform('mean') # only work with the neuron columns, as the others are columns that were not grouped by and then we try to take an average of, for instance, the time indices. NOT NEEDED and throws an annoying warning. (note: the grouped-by columns are excluded from the output by default, so you need to rely on congruence between the indices of this dataframe and the source dataframe)
    print(df_win)
    
    # sql-style groupby and aggregate
    df_mu2 = df.groupby(['grip','object','context'])[dp.get('neuronColumnNames')].aggregate('mean') # also need to only work with the neuron columns here for similar reasons (note: instead of just deleting the grouped-by labels, they instead get coalesced into a multi-index)
    print(df_mu2)
                
        
        