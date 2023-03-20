from pythonfigures.neuraldatabase import Query
import pandas as pd
import numpy as np
import plotly.express as px # warning: "plotly" has a secret dependency that it doesn't install on its own: "packaging"!
from sklearn.decomposition import PCA


sessions =  ['Moe46'] # ['Moe46','Moe50','Zara64','Zara68','Zara70']
areas    = ['M1','F5','AIP']

for session in sessions:
    seshout = []
    for area in areas:
        q = Query(query=f"""SHOW COLUMNS FROM `{session}`.`{area}-med`;""",
                  queryfile=False)
        cols = q.read()
        cols = cols['Field'][ cols['Field'].str.startswith('Neuron_') ].values.tolist()
        
        # construct the big bad aggregate query
        query = 'SELECT '
        
        for col in cols:
            query+=f'AVG(`{session}`.`{area}-med`.`{col}`),\n'
            
        # now add the other table parts
        # (note: the indents are quite weird)
        query+=f"""`{session}`.`Trial_Info`.`Object`,
`{session}`.`Trial_Info`.`Context`,
`{session}`.`Index_Info`.`Alignment`
FROM `{session}`.`{area}-med`
LEFT JOIN `{session}`.`Index_Info`
ON `{session}`.`{area}-med`.`index`=`{session}`.`Index_Info`.`index`
LEFT JOIN `{session}`.`Trial_Info`
ON `{session}`.`{area}-med`.`Trial`=`{session}`.`Trial_Info`.`Trial`
GROUP BY `{session}`.`Trial_Info`.`Object`,
`{session}`.`Trial_Info`.`Context`,
`{session}`.`Index_Info`.`Alignment`
HAVING `{session}`.`Index_Info`.`Alignment`='movement onset'
ORDER BY `{session}`.`Trial_Info`.`Object`,
`{session}`.`Trial_Info`.`Context`;"""
            
        print(query)
        
        q = Query(query=query, queryfile=False)
        df = q.read()
        
        # get the active & passive dataframes
        df_active  = df[df['Context']=='active'].iloc[:,:-3]
        df_passive = df[df['Context']=='passive'].iloc[:,:-3]
        
        # pca = object-separating subspace (kinda... LDA is better but let's use this as a proxy)
        active  = df_active.to_numpy()
        passive = df_passive.to_numpy()
        
        # demean
        active  = active - np.mean(active,axis=0)
        passive = passive - np.mean(passive,axis=0)
        
        print(active)
        print(passive)
        
        aPCA = PCA().fit(active)
        pPCA = PCA().fit(passive)
        
        CVE = lambda x: np.cumsum( np.var(x,axis=0) )# / np.sum( np.var(x,axis=0) )
        TVE = lambda x: np.sum( np.var( x,axis=0 ))
        
        active_in_active = CVE( aPCA.transform(active) )
        passive_in_passive = CVE( pPCA.transform(passive) )
        active_in_passive = CVE( pPCA.transform(active) )
        passive_in_active = CVE( aPCA.transform(passive) )
        
        d = pd.DataFrame({'alignment-index-active':active_in_passive/active_in_active,
                          'alignment-index-passive':passive_in_active/passive_in_passive})
        
        print(d)
        
        fig = px.line(d,y=d['alignment-index-active'])
        fig.add_scatter(y=d['alignment-index-passive'])
        fig.show()
        
        # okay, computed alignment indices that vary as a function of dimensionality
        # question: WHAT DOES IT MEAN?!?!?!?
        
        
        