from neuraldataset import *

nd = NeuralDataset('Zara70','active','M1',60000)

l = len(nd)

print(l)

for idx in range(l):
    n,k = nd[idx]
    print("-----")
    print(idx)
    print(n)
    print(k)
    print("-----")
    
