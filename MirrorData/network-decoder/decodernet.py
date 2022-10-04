import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import Dataset, DataLoader
from tqdm import tqdm, trange

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
        
        # compressors and decompressors because the transformer module assumes src and tgt live in the same embedding space
        self.neural_compressor      = nn.Linear(in_features=dimensionality_neural,out_features=d_model)
        self.kinematic_compressor   = nn.Linear(in_features=dimensionality_kinematic,out_features=d_model)
        self.kinematic_decompressor = nn.Linear(in_features=d_model,out_features=dimensionality_kinematic)
        
        if device==None:
            device = set_device()
        
        # does this implicitly apply a softmax at the end? surely not, as the transformer only knows about embeddings and not the token vocabulary we would have been working with...
        # indeed, softmax would also assume implicitly that you only care about CrossEntropy loss, but here's an example that uses a transformer model with an NLLLoss: https://github.com/pytorch/examples/blob/main/word_language_model/main.py
        # as with all things, just play with it in the testing phase to make sure it behaves the way you expect (that is, in a way conducive to MSELoss regression problems)
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
                                                     norm_first=True,
                                                     device=device,
                                                     dtype=None
                                                     ) # norm_first does not control whether layer normalization happens, but rather whether it happens before (True) or after (False) attention & feedforward operations (before is better, see: https://arxiv.org/pdf/2002.04745.pdf)

    def forward(self,neur:torch.DoubleTensor,kin:torch.DoubleTensor):
        neur = self.neural_compressor(neur)
        kin  = self.kinematic_compressor(kin)
        
        # batch x sequence length x neurons
        seqlen = neur.shape[1]
        
        assert seqlen == kin.shape[1], "source (neural) and target (kinematic) data need to have equal sequence lengths in this framework"
        
        neurmask = make_mask(seqlen,diag_ind=1)
        kinmask  = make_mask(seqlen,diag_ind=0)
        memmask  = make_mask(seqlen,diag_ind=0)
        
        neurc = self.neural_compressor(neur) # if the transformer ain't powerful enough on its own, consider making these deep feature extraction modules and not just linear dimensionality reduction
        kinc  = self.kinematic_compressor(kin)
        
        kinhat = self.big_fat_model(src=neurc,tgt=kinc,src_mask=neurmask,tgt_mask=kinmask,memory_mask=memmask)
        
        kinhat = self.kinematic_decompressor(kinhat)
        
        return kinhat

# training methods
# (I assume classes DecoderNet and Subset inherit from their parents in a way that makes these type hints valid)
def train(model:nn.Module,device:str,trainloader:DataLoader,validloader:DataLoader,epochs:int) -> None:
    criterion = nn.MSEloss() # ideally this, like the optimizer, would also be adjustable via an options dict
    
    # I like SGD more than ADAM in general, especially for (relatively) low-D problems like this
    # also: weight_decay is an L2 regularization factor, not strictly necessary but might help tame gradients if need be
    # ideally, these would be parameters to the train method (maybe a single dict holding all these parameter values and an options-constructor method to help guide their selection), but for now, hard-code them
    optimizer = torch.optim.SGD(model.parameters(), lr=0.1, momentum=0, dampening=0, weight_decay=0)
    
    # we can save the loss history in these lists if needed
    # trainloss = []
    # validloss = []
    
    # for each epoch
    for epoch in range(epochs):
        thisepochloss = 0
        nbatches      = 0
        model.train() # "training mode" for e.g. Dropout
        with tqdm(trainloader,unit='batch') as tepoch: # runs the dataloader, wrapped in tqdm, and dumps the outputs in tepoch
            for data,target in tepoch:
                data, target = data.to(device), target.to(device) # tuple unpacking syntax
                
                optimizer.zero_grad() # init optimizer
                output = model(data)
                loss   = criterion(output,target)
                
                thisepochloss+=loss
                nbatches+=1
                
                loss.backward() # calc gradients
                optimizer.step() # step the optimizer based on those gradients
                tepoch.set_postfix(loss=loss.item()) # display the loss for this epoch & batch
                
        # now compute validation loss
        validloss = 0
        validnbatches = 0
        for vdata,vtarget in validloader:
            vdata, vtarget = vdata.to(device), vtarget.to(device)
            voutput        = model(vdata).detach() # evaluate the expression without letting it update the gradient
            validloss     += criterion(voutput,vtarget).detach() # again, make sure it won't update the gradient
            validnbatches  += 1
        
        thisepochloss /= nbatches
        validloss /= validnbatches
        
        print(f"train MSE = {thisepochloss:.2f}, valid MSE = {validloss:.2f}")


# TODO: before getting too deep in the train/test weeds, test the forward method of merely initialized nets, make sure it does what you hope (e.g., isn't somehow doing implicit softmax the way the typical transformer diagrams imply, despite your trawling through the source code suggesting it very much should NOT be doing this)