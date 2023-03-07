import plotly.express as px
import mat73
import pandas as pd
import numpy as np
import os

# kaleido is a sneaky dependency, too

class Figure:
    def __init__(self,datafiles:list=[],outputfilename:str='test.svg'):
        self.datafiles = datafiles
        self.datadict  = dict()
        self.figurehandle = None
        self.outputfilename = outputfilename
        
        self.build()
    
    def _build_data(self):
        # load the datafiles in
        self.datadict['x'] = pd.DataFrame(np.random.randn(100))
        self.datadict['x'].columns = ['xtest']
        
    def _build_fig(self):
        self.figurehandle = px.histogram(self.datadict['x'],
                                         x='xtest',
                                         opacity=0.5,
                                         color_discrete_sequence=['rgb(255,0,0)'],
                                         nbins=50
                                         ).update_layout(yaxis_title='ytest',
                                                         plot_bgcolor='rgba(0,0,0,0)',
                                                         bargap=0.05)
        self.figurehandle.update_xaxes(ticks='outside',
                                       tickwidth=1,
                                       tickcolor='black',
                                       ticklen=4,
                                       linecolor='rgba(0,0,0,1)',
                                       linewidth=1)
        
        self.figurehandle.update_yaxes(ticks='outside',
                                       tickwidth=1,
                                       tickcolor='black',
                                       ticklen=4,
                                       linecolor='rgba(0,0,0,1)',
                                       linewidth=1)
        
        self.figurehandle.update_traces(marker_line_width=3,
                                        marker_line_color='rgba(0,0,255,0.8)')
        
    def build(self):
        self._build_data()
        self._build_fig()
        
    def preview(self):
        if self.figurehandle is not None:
            self.figurehandle.show()
        
    def save_image(self):
        if self.figurehandle is not None:
            self.figurehandle.write_image(self.outputfilename)

class Figure3(Figure):
    def __init__(self,datafiles:list,outputfilename:str):
        super().__init__(datafiles=datafiles,outputfilename=outputfilename)
        
    def _build_data(self):
        d = mat73.loadmat(self.datafiles[0])
        print(d.keys())
        return
    
    def _build_fig(self):
        return

# manual unit test
if __name__ == "__main__":
    F = Figure3(datafiles = [os.path.join('Analysis-Outputs','clustfiles','clustout_stats.mat')],
                outputfilename = 'fig3test.svg')
    
    """F.preview()
    input()
    
    F.save_image()"""
    