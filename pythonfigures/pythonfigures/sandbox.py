from pythonfigures.neuraldatabase import Query
import pandas as pd
import numpy as np
import plotly.express as px # warning: "plotly" has a secret dependency that it doesn't install on its own: "packaging"!
from sklearn.decomposition import PCA
from scipy.linalg import subspace_angles, orth
import json
from json import JSONEncoder

# define a class for parsing numpy arrays
# https://pynative.com/python-serialize-numpy-ndarray-into-json/
class NumpyArrayEncoder(JSONEncoder):
    def default(self, obj):
        if isinstance(obj,np.ndarray):
            return obj.tolist()
        return JSONEncoder.default(self,obj)


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
        # print(deltaquery)
        
        # qdel = Query(query=deltaquery,
        #           queryfile=False)
        # df_del = qdel.read()
        
        # print(df_del)
        
        # full data pull (subquery)
        print(subquery)
        qsub = Query(query=subquery,
                     queryfile=False)
        df_sub = qsub.read()
        
        print(df_sub)
        
        # and now we have the dataframes needed to do LDA
        aggdata = dict()
        aggdata['active']  = df_agg[df_agg['contextagg']=='active'].iloc[:,:-2].to_numpy()
        aggdata['passive'] = df_agg[df_agg['contextagg']=='passive'].iloc[:,:-2].to_numpy()
        
        print(aggdata)
        print(aggdata['active'].shape)
        print(aggdata['passive'].shape)
        
        # diffdata = dict()
        # diffdata['active'] = df_del[df_del['contextdiff']=='active'].iloc[:,:-2].to_numpy()
        # diffdata['passive'] = df_del[df_del['contextdiff']=='passive'].iloc[:,:-2].to_numpy()
        
        # print(diffdata)
        # print(diffdata['active'].shape)
        # print(diffdata['passive'].shape)
        
        subdata = dict()
        subdata['active'] = df_sub[ df_sub['context']=='active' ].iloc[:,:-4].to_numpy()
        subdata['passive'] = df_sub[ df_sub['context']=='active' ].iloc[:,:-4].to_numpy()
        print(subdata)
        print(subdata['active'].shape)
        print(subdata['passive'].shape)
        
        # misnomer, it's just PCA applied to the trial averages (i.e., between-group variances)
        LDAvecs = dict()
        LDAvals = dict()
        
        for context in ['active','passive']:
            neigs = aggdata[context].shape[0]-1 # nobjs - 1 eigenvalues
            B = np.cov( aggdata[context],rowvar=False )
            # W = np.cov( diffdata[context], rowvar=False )
            # W = W + 1e-6 * np.eye(W.shape[0])
            
            # D = np.linalg.solve(W,B)
            
            # test symmetry (all values are real so no conjugates to worry about)
            # (test is failed, a skew-symmetric divided by a skew-symmetric does not give a skew-symmetric per se)
            # Dtest = D + D.T
            # print('symmetry test: should be all zeros')
            # print(Dtest)
            
            print(context)
            print(B)
            print(B.shape)
            # print(W)
            # print(W.shape)
            # print(D)
            # print(D.shape)
            
            # can't use eigh due to the non-symmetry
            # only keep up to neigs, as all other dimensions beyond that will have zero magnitude (and be riddled with floating point problems)
            vals,vecs = np.linalg.eig(B) # if we just use B, we get much better alignment than if we use D... this probably points to instabilities in the manifolds that can be extracted from LDA arising from the matrix division step
            # ergo, let's just use B and ignore the "diff" query
            # note, we still will want to use the same neigs parameter, as the rank of B is what limited the rank of D!
            vals = vals[:neigs]
            vecs = vecs[:,:neigs]
            
            # extract the real components, as the computation of vals & vecs is corrupted by complex garbage resulting from floating point errors
            vals = np.real(vals)
            vecs = np.real(vecs)
            
            print('vals')
            print(vals)
            
            print('vecs')
            print(vecs)
            
            # save the vectors and values
            LDAvecs[context] = vecs
            LDAvals[context] = vals
            
            
        # get principal angles (note: my custom method only work for orthonormal bases, and returns supra-1 eigenvalues for non-orthonormal bases, ergo it tends to underestimate the subspace angles as it overestimates the cosine projections)
        # (that said, the svd method works when using scipy.linalg.orth to extract orthonormal basis sets)
        # we should probably iterate this over # of vectors kept in each subspace tho
        # (note: subspace angles apparently also work when there's a difference in the number of vectors in each subspace? wild. seems to work by finding the "best-case" subspace within the larger which matches up to the smaller)
        out = dict()
        out['subspace_dimension'] = list()
        out['theta'] = list()
        out['vals'] = dict()
        out['vecs'] = dict()
        out['vals']['active'] = list()
        out['vals']['passive'] = list()
        out['vecs']['active'] = list()
        out['vecs']['passive'] = list()
        
        print(LDAvecs['active'].shape[1])
        print(LDAvecs['passive'].shape[1])
        maxvecs   = min(LDAvecs['active'].shape[1],LDAvecs['passive'].shape[1])
        neurcount = LDAvecs['active'].shape[0]
        
        for ndims in range(1,maxvecs):
            out['theta'] += [np.degrees( subspace_angles(LDAvecs['active'][:,:ndims],LDAvecs['passive'][:,:ndims])[::-1] )] # list the closest angles first! and use degrees, they're easier to read
            out['subspace_dimension'] += [ndims]
            
        # contrast with random subspaces
        niter = 1000
        out['theta_noise'] = list()
        for ndims in range(1,maxvecs):
            temp = []
            for iter in range(niter):
                r = np.random.randn(neurcount,2*ndims) # no need to call orth here, subspace_angles does that internally
                temp += [np.degrees( subspace_angles( r[:,:ndims],r[:,ndims:] )[::-1] )]
            
            out['theta_noise'] += [np.column_stack(temp).T]
            
        out['vals']['active'] = LDAvals['active']
        out['vals']['passive'] = LDAvals['passive']
        out['vecs']['active'] = LDAvecs['active']
        out['vecs']['passive'] = LDAvecs['passive']
            
        # print(out)
        
        with open('testdata.json','w',encoding='utf-8') as f:
            json.dump(out,f,ensure_ascii=False,indent=4,cls=NumpyArrayEncoder)
            
        # or try rtheta (weighted subspace angles)
        badmethod = """
        rtheta = list()
        
        maxvecs = min(LDAvecs['active'].shape[1],LDAvecs['passive'].shape[1])
        
        for ndims in range(1,maxvecs):
            act = LDAvecs['active'][:,:ndims] #@ np.diag( np.sqrt( LDAvals['active'][:ndims] ) ) # scale dimensions by standard deviation, rather than variance, along each dimension
            pas = LDAvecs['passive'][:,:ndims] #@ np.diag( np.sqrt( LDAvals['passive'][:ndims] ) )
            S = np.linalg.svd(act.T @ pas)[1]
            S[S>1] = 1
            rtheta += [np.arccos(S[::-1])] # to match the ordering convention of scipy
            
        with open('testdata_selfangles.json','w',encoding='utf-8') as f:
            json.dump(rtheta,f,ensure_ascii=False,indent=4,cls=NumpyArrayEncoder)"""
        
        # and compute alignment indices, too
        # this requires a "raw" data query
        
        # remember: Jannik's paper tells us that poor classification performance is not enough! the manifolds have to have poor alignment, too!
        # that said, we should compare both pre- and post-orthogonalization alignment values
        # so:
        # W's are actually quite well-aligned
        # B's are less well-aligned
        # and D, the LDA matrices, are not well-aligned at ALL
        
        # note: compare alignments in all the following cases:
        # prior to orthogonalization
        # after orthogonalization
        # within the orthogonalized space (!)
        