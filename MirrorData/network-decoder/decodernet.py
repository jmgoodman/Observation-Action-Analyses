import torch
import torch.nn as nn
import torch.nn.functional as F

# uh oh. can't just use the standard transformer model.
# why? because it assumes the input & output embedding dimensionalities are the same!
# which I guess I could achieve by applying PCA to both...
# ...then reconstructing based on those...
# ...but why would I limit myself in this way?
# (ughhhh an LSTM would be WAY easier conceptually...)
mdl = nn.Transformer()