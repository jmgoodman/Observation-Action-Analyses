import torch
import torch.nn as nn
import torch.nn.functional as F

from typing import Optional

# helper method: set device depending on hardware
def set_device() -> str:
    """set_device spits out a device name for use with PyTorch tensors

    Returns:
        str: "cuda" or "cpu" depending on whether cuda hardware is available or not. Default is to return "cuda" if hardware is available, otherwise, return "cpu"
    """
    if torch.cuda.is_available():
        DEVICE = "cuda"
    else:
        DEVICE = "cpu"
    return DEVICE
    
# helper method: mask-making
def make_mask(src_size:int,tgt_size:Optional[int]=None,diag_ind:int=0) -> torch.DoubleTensor:
    """make_mask defines a masking paradigm to make sure transformer decoders aren't basing their predictions of the future... on information from the future 

    Args:
        src_size (int): number of entries in the source sequence (or all sequences if all of them are equal-sized)
        tgt_size (Optional[int], optional): number of entries in the target sequence, or, if None, gets set to the src_size. Defaults to None.
        diag_ind (int, optional): how far to shift the diagonal. Typically, if focusing on the source, you want to mask everything *beyond* the diagonal (value=1), whereas if focusing on the target, you want to mask everything beyond or ON the diagonal (value=0). Defaults to 0.
    """
    if tgt_size==None:
        tgt_size = src_size
        
    mask = torch.zeros( (tgt_size,src_size), dtype=torch.double ) # hopefully this works with float('-inf')
    for i in range(tgt_size):
        for j in range(src_size):
            if (j+diag_ind) >= i:
                mask[i][j] = float('-inf')
    
    return mask
    
class DecoderNet(nn.Module):
    def __init__(self,dimensionality_neural:int,dimensionality_kinematic:int,d_model:int=30,n_head:int=6,
                 num_encoder_layers:int=3,num_decoder_layers:int=3,dropout:float=0.1,device:Optional[str]=None):
        super(DecoderNet, self).__init__()
        self.dimensionality_neural = dimensionality_neural
        self.dimensionality_kinematic = dimensionality_kinematic
        self.neural_compressor      = nn.Linear(in_features=dimensionality_neural,out_features=d_model)
        self.kinematic_compressor   = nn.Linear(in_features=dimensionality_kinematic,out_features=d_model)
        self.kinematic_decompressor = nn.Linear(in_features=d_model,out_features=dimensionality_kinematic)
        
        if device==None:
            device = set_device()
        
        self.big_fat_model          = nn.Transformer(d_model = d_model,
                                                     n_head = n_head,
                                                     num_encoder_layers = num_encoder_layers,
                                                     num_decoder_layers = num_decoder_layers,
                                                     dropout=dropout,
                                                     activation="relu",
                                                     custom_encoder=None,
                                                     custom_decoder=None,
                                                     layer_norm_eps=1e-06,
                                                     batch_first=True,
                                                     norm_first=False,
                                                     device=device,
                                                     dtype=None
                                                     ) # norm_first does not control whether layer normalization happens, but rather whether it happens before (True) or after (False) attention & feedforward operations
        
    def forward(self,neur:torch.DoubleTensor,kin:torch.DoubleTensor):
        neur = self.neural_compressor(neur)
        kin  = self.kinematic_compressor(kin)
        
        seqlen = neur.shape[1]
        
        neurmask = make_mask(seqlen,diag_ind=1)
        