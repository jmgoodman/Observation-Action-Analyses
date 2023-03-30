from pythonfigures.neuraldatabase import Query
import pandas as pd
import numpy as np

from typing import List, Dict, Optional

class VariancePartitioner:
    def __init__(self,
                 session:str,
                 areas:List[str],
                 aligns:List[str]):
        # let's just handle a single session at a time, trying to handle pooling of sessions and the different behavior thereof (namely, trial averaging to make joining possible) sounds like a pain
        self._session  = session
        self._areas    = areas
        self._aligns   = aligns
        self._neuronColumnNames = None
        self._query     = None
        self._df       = None
        
    def _buildQuery(self):
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
            
        # now, build the query
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
        query+=f"CAST(`{self._session}`.`Index_Info`.`Time` as SIGNED) as time\n"
        
        
        query+=f"FROM `{self._session}`.`{maintbl}`\n"
        
        for table in tables_to_join:
            query+=f"LEFT JOIN `{self._session}`.`{table}`\n"
            
            if table=="Trial_Info":
                joincol = "Trial"
            else:
                joincol = "index"
                
            query+=f"ON `{self._session}`.`{maintbl}`.`{joincol}`=`{self._session}`.`{table}`.`{joincol}`\n"
            
        query+="WHERE alignment IN ("
        
        for align in self._aligns:
            query+=f"'{align}'"
            if align==self._aligns[-1]:
                query+=")\n"
            else:
                query+=","
        
        query+="ORDER BY trial, alignment, time;"
        
        self._query = query
        
    def _readQuery(self):
        if self._query is None:
            print('run _buildQuery first!')
            return
            
        q = Query(query=self._query,
                  queryfile=False)
        
        self._df = q.read()
        # self._df.astype({'time':int}) # this did not work, pandas still insists on converting the "time" axis to a float when making a multiindex out of it. this is CRAZY
    
    def getDataFrame(self):
        self._buildQuery()
        self._readQuery()
        
    # TODO: getter & setter methods to discourage changing properties directly (and to reset the query & dataframe with these changes)
    def get(self,
            param:str):
        return self.__dict__["_"+param]
    
    def set(self,
            param:str,
            val):
        
        if param in ["df","query","neuronColumnNames"]:
            print("I won't let you set df or query or neuronColumnNames, sorry.")
            return
        
        # TODO: find a way to constrain val's type
        self.__dict__["_"+param] = val
        
        # reset _df and _query
        self._query = None
        self._df = None
        print("Setting parameters changes the query metadata of the dataframe!")
        print("To avoid decoupling the two, I've reset the _query and _df properties!")
        print("Therefore, you should re-run getDataFrame!")
        
    def where(self,
               filterfun=None) -> pd.DataFrame:
        """_summary_

        Args:
            filterfun (fun, optional): lambda function which evaluates to a boolean and specifies your keeping criteria. Defaults to None.

        Returns:
            pd.DataFrame: _description_
        """
        if filterfun is None:
            return self._df
        else:
            return self._df.where(filterfun)
    
    def groupMeans(self,
                   groupby:Optional[List[str]]=None,
                   filterfun=None) -> pd.DataFrame:
        """Computes means grouped by factors specified in inputs

        Args:
            groupby (Optional[List[str]], optional): Names of columns along which to group. Defaults to None.
            filterfun (fun,optional): lambda function which evaluates to a boolean and specifies the data you keep prior to taking group means. Defaults to None.

        Returns:
            pd.DataFrame: the group mean firing rates for the groups specified in groupby (or the overall mean firing rates if no grouping variables are specified).
        """
        
        if self._df is None:
            print('run getDataFrame first!')
            return
        
        # t = grouped by time (cross-context average trace)
        # tc = grouped by time, context - t (cross-grip average trace for each context)
        # tcg = grouped by time, context, grip - tc - t (average trace for each grip x context) (can be further split into contextual components)
        
        if filterfun is None:
            df = self._df
        else:
            df = self._df.where(filterfun)
        
        if groupby is None:
            return df[self._neuronColumnNames].mean()
        else:
            return df.groupby(by=groupby)[self._neuronColumnNames].mean()
            
        
            
        
    
        
if __name__=='__main__':
    vp = VariancePartitioner(session='Moe46',
                             areas=['M1'],
                             aligns=['movement onset','hold onset'])
    
    vp.getDataFrame()
    df = vp.groupMeans(groupby=['alignment','time'],
                       filterfun=lambda x:x['context']!='control')
    
    # oh my god I wanna scream
    # it's like 5 billion times easier to just do this with SQL my LORD
    
    print(df)
    
    # df.loc['hold onset']
    
    # https://stackoverflow.com/questions/17921010/how-to-query-multiindex-index-columns-values-in-pandas
    # oh my WORD is multi-indexing TERRIBLE in pandas
    # not only does it take nice int indices and convert them into impossible-to-index floats,
    # but this is the expected syntax for querying a multi-index:
    #
    # In [536]: result_df = df.loc[(df.index.get_level_values('A') > 1.7) & (df.index.get_level_values('B') < 666)]
    #
    # or we use 'query':
    # df.query('3.3 <= A <= 6.6') # for closed interval
    # why on earth is the full query a string? is pandas using eval under the hood? say it ain't so!
    
                
                
        
        