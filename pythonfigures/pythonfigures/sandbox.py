from pythonfigures.neuraldatabase import Query
import pandas as pd
import numpy as np
import plotly.express as px # warning: "plotly" has a secret dependency that it doesn't install on its own: "packaging"!
from sklearn.decomposition import PCA


sessions =  ['Moe46'] # ['Moe46','Moe50','Zara64','Zara68','Zara70']
areas    = ['M1'] #['M1','F5','AIP']

for session in sessions:
    seshout = []
    for area in areas:
        q = Query(query=f"""SHOW COLUMNS FROM `{session}`.`{area}-med`;""",
                  queryfile=False)
        colsmed = q.read()
        colsmed = colsmed['Field'][ colsmed['Field'].str.startswith('Neuron_') ].values.tolist()
        
        q = Query(query=f"""SHOW COLUMNS FROM `{session}`.`{area}-lat`;""",
                  queryfile=False)
        colslat = q.read()
        colslat = colslat['Field'][ colslat['Field'].str.startswith('Neuron_') ].values.tolist()
        
        # construct the big bad aggregate query
        
        # first, average across time as your subquery
        subquery = 'SELECT '
        
        nidx=0
        for col in colsmed:
            subquery+=f"AVG(`{session}`.`{area}-med`.`{col}`) as n{nidx},\n"
            nidx+=1
            
        for col in colslat:
            subquery+=f"AVG(`{session}`.`{area}-lat`.`{col}`) as n{nidx},\n"
            nidx+=1
            
        subquery+=f"""MAX(`{session}`.`Trial_Info`.`Trial`) as trial,
        MAX(`{session}`.`Trial_Info`.`Object`) as object,
        MAX(`{session}`.`Trial_Info`.`Context`) as context,
        MAX(`{session}`.`Index_Info`.`Alignment`) as alignment
        FROM `{session}`.`{area}-med`
        LEFT JOIN `{session}`.`{area}-lat`
        ON `{session}`.`{area}-med`.`index`=`{session}`.`{area}-lat`.`index`
        LEFT JOIN `{session}`.`Index_Info`
        ON `{session}`.`{area}-med`.`index`=`{session}`.`Index_Info`.`index`
        LEFT JOIN `{session}`.`Trial_Info`
        ON `{session}`.`{area}-med`.`Trial`=`{session}`.`Trial_Info`.`Trial`
        GROUP BY `{session}`.`Trial_Info`.`Trial`,
        `{session}`.`Index_Info`.`Alignment`
        HAVING `{session}`.`Index_Info`.`Alignment`='movement onset'
        ORDER BY object,
        context"""
                
        print(subquery)
        
        # now generate an aggregating query that gets averages aggregated over object x context
        aggquery = 'SELECT '
        
        for idx in range(nidx):
            aggquery+=f"AVG(n{idx}) as mu_n{idx},\n"
        
        aggquery+="MAX(object) as objectagg,\nMAX(context) as contextagg\n"
        aggquery+=f"""FROM ({subquery}) t
        GROUP BY object, context
        ORDER BY object, context"""
        
        # now produce an outer query that joins the two
        # (in practice this should be handled by a window function, but there's a column limit on that...)
        joinquery = f"""SELECT sub.*,
        agg.*
        FROM ({subquery}) sub
        LEFT JOIN ({aggquery}) agg
        ON sub.context=agg.contextagg AND sub.object=agg.objectagg
        ORDER BY sub.object,sub.context"""
        
        # now subtract columns from their means
        deltaquery = "SELECT "
        for idx in range(nidx):
            deltaquery+=f"n{idx}-mu_n{idx} as d{idx},\n"
        
        deltaquery+="contextagg as contextdiff, objectagg as objectdiff\n"
        deltaquery+=f"FROM ({joinquery}) j;"
        
        # make the queries
        # aggregate (between-class variance)
        print(aggquery+";")
        
        qagg = Query(query=aggquery+";",
                     queryfile=False)
        df_agg = qagg.read()
        
        print(df_agg)
        
        # delta (within-class variance)
        print(deltaquery)
        
        qdel = Query(query=deltaquery,
                  queryfile=False)
        df_del = qdel.read()
        
        print(df_del)
        
        # and now we have the dataframes needed to do LDA
        aggdata = dict()
        aggdata['active']  = df_agg[df_agg['contextagg']=='active'].iloc[:,:-2].to_numpy()
        aggdata['passive'] = df_agg[df_agg['contextagg']=='passive'].iloc[:,:-2].to_numpy()
        
        print(aggdata)
        print(aggdata['active'].shape)
        print(aggdata['passive'].shape)
        
        diffdata = dict()
        diffdata['active'] = df_del[df_del['contextdiff']=='active'].iloc[:,:-2].to_numpy()
        diffdata['passive'] = df_del[df_del['contextdiff']=='passive'].iloc[:,:-2].to_numpy()
        
        print(diffdata)
        print(diffdata['active'].shape)
        print(diffdata['passive'].shape)

        
        