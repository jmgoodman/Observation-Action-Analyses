import torch
import torch.nn as nn
import torch.nn.functional as F

from typing import Optional

# decide device
if torch.cuda.is_available():
    DEVICE = "cuda"
else:
    DEVICE = "cpu"
    
# helper method: mask-making
def make_mask(src_size:int,tgt_size:Optional[int]=None,diag_ind:int=0):
    """make_mask defines a masking paradigm to make sure transformer decoders aren't basing their predictions of the future... on information from the future 

    Args:
        src_size (int): number of entries in the source sequence (or all sequences if all of them are equal-sized)
        tgt_size (Optional[int], optional): number of entries in the target sequence, or, if None, gets set to the src_size. Defaults to None.
        diag_ind (int, optional): how far to shift the diagonal. Typically, if focusing on the source, you want to mask everything *beyond* the diagonal (value=1), whereas if focusing on the target, you want to mask everything beyond or ON the diagonal (value=0). Defaults to 0.
    """
    if tgt_size==None:
        tgt_size = src_size
        
    mask = torch.zeros( (tgt_size,src_size), dtype=torch.float )
    for i in range(tgt_size):
        for j in range(src_size):
            if (j+diag_ind) >= i:
                mask[i][j] = float('-inf')
    
    return mask
    
class DecoderNet(nn.Module):
    def __init__(self,dimensionality_neural:int,dimensionality_kinematic:int):
        super(DecoderNet, self).__init__()
        self.dimensionality_neural = dimensionality_neural
        self.dimensionality_kinematic = dimensionality_kinematic
        self.
        
    
    

mdl = nn.Transformer(d_model = 30,
                     nhead=8,
                     num_encoder_layers=3,
                     num_decoder_layers=3,
                     dim_feedforward=100,
                     dropout=0.1,
                     activation="relu",
                     custom_encoder=None,
                     custom_decoder=None,
                     layer_norm_eps=1e-06,
                     batch_first=True,
                     norm_first=False,
                     device=DEVICE,
                     dtype=None
                     )