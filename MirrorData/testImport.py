# %%
from scipy.io import loadmat
import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import pandas as pd
# import plotly.graph_objects as go

# matplotlib.use('WebAgg') # qtagg might be default, I think? which requires PyQt. Or TkAgg, which requires TkInter.

mat = loadmat('structZara68.mat',simplify_cells=True)

print(mat)
# %%
# sample code binning the spike counts (using only the first kinematic "file" and one neuron, though )
spikeBins  = mat['Mstruct']['Kinematic'][0]['JointStruct']['data'][:,0]

# get the most-spiking neuron
spikeCounts = [neur['SpikeCount'] for neur in mat['Mstruct']['Neural']]
mostSpikesNeuron = np.argmax(spikeCounts)

spikeTimes = mat['Mstruct']['Neural'][mostSpikesNeuron]['spiketimes']

# and bin
binnedSpikeCounts,trueSpikeBins = np.histogram(spikeTimes,bins=spikeBins)

# and plot (not using hist, but rather just a time-varying trace)
plt.figure()
plt.plot(trueSpikeBins[:-1],binnedSpikeCounts)
plt.show() # important...

# %%
# convert to a pandas Series
# (note: DataFrame.hist is very slow here)
s = pd.Series(spikeTimes)
histo = s.value_counts(bins=spikeBins)

# %%
input('Press any key to end...\n')