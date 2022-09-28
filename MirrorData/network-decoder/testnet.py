from neuraldataset import *
from torch.utils.data import random_split
import torch.nn as nn

nd = NeuralDataset(session='Zara70',context='active',area='M1',window=20000)

trainvalid = int(0.8*len(nd))
test       = len(nd) - trainvalid

train      = int(0.75*trainvalid)
valid      = trainvalid - train

trainset,validset,testset = random_split(nd,[train,valid,test])

print(len(trainset))
print(len(validset))
print(len(testset))

print(len(nd))

# now load in your model
mdl = nn.Transformer() # transformer with the standard fixings

# create masks
neurdata,kindata = trainset[0]
seqlen = neurdata.size(dim=0)
encmask = torch.triu(torch.full((seqlen, seqlen), float('-inf')), diagonal=1)
memmask = torch.triu(torch.full((seqlen, seqlen), float('-inf')), diagonal=1)
decmask = torch.triu(torch.full((seqlen, seqlen), float('-inf')), diagonal=0)

print(seqlen)
print(encmask)
print(memmask)
print(decmask)

# now spit out forward result
mdl.forward(src=neurdata,tgt=kindata,src_mask=encmask,tgt_mask=decmask,memory_mask=memmask)
