# testing file
import mat73
import numpy as np
from pythonfigures.neuraldatabase import Query

# numpy manipulations
m = mat73.loadmat('../MirrorData/Zara70_datastruct.mat')

aipmed = np.mean( m['datastruct']['cellform'][4][0][4][0]['Data'][51:,:,:],axis=0 )
aiplat = np.mean( m['datastruct']['cellform'][5][0][4][0]['Data'][51:,:,:],axis=0 )
aip = np.concatenate((aipmed,aiplat),axis=0)
obj =  m['datastruct']['cellform'][5][0][5][0]['Objects']
obj = np.array(obj)
keepinds = [x[0]=='active' for x in m['datastruct']['cellform'][5][0][5][0]['TrialTypes']]
lindx    = np.array(keepinds)
 
obj_ = obj[lindx]
aip_ = aip[:,lindx].T


# sql to grab data -> pandas to clean it
session = 'Zara70'
area    = 'AIP'
subquery = 'SELECT '

q = Query(query=f"""SHOW COLUMNS FROM `{session}`.`{area}-med`;""",
            queryfile=False)
colsmed = q.read()
colsmed = colsmed['Field'][ colsmed['Field'].str.startswith('Neuron_') ].values.tolist()

q = Query(query=f"""SHOW COLUMNS FROM `{session}`.`{area}-lat`;""",
            queryfile=False)
colslat = q.read()
colslat = colslat['Field'][ colslat['Field'].str.startswith('Neuron_') ].values.tolist()
        
nidx=0
for col in colsmed:
    subquery+=f"AVG(CASE WHEN `{session}`.`Index_Info`.`Time`>0 THEN `{session}`.`{area}-med`.`{col}` END) as n{nidx},\n"
    nidx+=1
    
for col in colslat:
    subquery+=f"AVG(CASE WHEN `{session}`.`Index_Info`.`Time`>0 THEN `{session}`.`{area}-lat`.`{col}` END) as n{nidx},\n"
    nidx+=1
    
subquery+=f"""CAST( MAX(`{session}`.`Trial_Info`.`Trial`) AS UNSIGNED ) as trial,
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
HAVING alignment='movement onset'
ORDER BY trial;"""

q = Query(query=subquery,queryfile=False)
df = q.read()

objquery = f"SELECT Object, Trial FROM {session}.Trial_Info WHERE Context='active';"
q = Query(query=objquery,queryfile=False)
objframe = q.read()


# pure sql