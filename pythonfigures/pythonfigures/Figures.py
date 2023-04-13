import plotly.express as px
import plotly.graph_objects as go
from plotly.offline import iplot
from plotly.subplots import make_subplots

# plotly doesn't support "staircase" histogram
# at least not easily... what a pain in the butt!

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
        contrast = d['contraststruct']
        congruence = d['congruencestruct']
        
        # pool across sessions and get into a single dataframe
        # use this format:
        # https://stackoverflow.com/questions/57988604/overlaying-two-histograms-with-plotly-express
        self.datadict["df"] = pd.DataFrame(
            {"Area":np.concatenate((
                ["AIP"]*sum([len(x) for x in contrast["AIP"]]),
                ["F5"]*sum([len(x) for x in contrast["F5"]]),
                ["M1"]*sum([len(x) for x in contrast["M1"]])
                )),
             "Active-Passive Index":np.concatenate((
                np.concatenate(contrast["AIP"]),
                np.concatenate(contrast["F5"]),
                np.concatenate(contrast["M1"])
                )),
             "Congruence Index":np.concatenate((
                np.concatenate(congruence["AIP"]),
                np.concatenate(congruence["F5"]),
                np.concatenate(congruence["M1"])
                ))
            }
        )
        
        # let's bin the data beforehand
        self.datadict["binned_data"] = dict()
        
        for area in ['AIP','F5','M1']:
            b   = np.linspace(-1,1,24)
            
            api,_ = np.histogram(
                np.concatenate(contrast[area]),
                bins=b
                )
                        
            ci,_  = np.histogram(
                np.concatenate(congruence[area]),
                bins=b
                )
                        
            self.datadict['binned_data'][area] = {
                "Active-Passive Index":api,
                "Congruence Index":ci,
                "Bin Edges":b
            }
        
        self.datadict["colors"] = pd.read_csv(os.path.join('pythonfigures','colors.csv'))
                
        return
    
    def _build_fig(self):
        # pool across all animals & sessions for now
        # subplot 1: histograms of each area, API, with cdfs overlaid
        # subplot 2: histograms of each area, congruence, with cdfs overlaid
        
        self.figurehandle = make_subplots(rows=1,
                                          cols=2)
        
        shift = -0.001
        maxfreq = 0
        for area in ['AIP','F5','M1']:
            c = self.datadict["colors"]
            c = c[c["Area"]==area].to_numpy()
            c = c[0][:3]
            
            # api figure
            b   = self.datadict['binned_data'][area]['Bin Edges']
            api = self.datadict['binned_data'][area]['Active-Passive Index']
            api = api / sum(api)
            
            maxfreq = max(maxfreq,max(api))
            
            self.figurehandle.add_trace(
                go.Scatter(
                    x=b+shift,
                    y=np.append(api,api[-1]),
                    name=area,
                    mode='lines',
                    line={
                        'color':f'rgba({c[0]},{c[1]},{c[2]},0.5)',
                        'shape':'hv'
                    }
                ),
                row=1,
                col=1
            )
            
            # cong figure
            cong = self.datadict['binned_data'][area]['Congruence Index']
            cong = cong / sum(cong)
            
            maxfreq = max(maxfreq,max(cong))
            
            self.figurehandle.add_trace(
                go.Scatter(
                    x=b+shift,
                    y=np.append(cong,cong[-1]),
                    name=area,
                    mode='lines',
                    line={
                        'color':f'rgba({c[0]},{c[1]},{c[2]},0.5)',
                        'shape':'hv'
                    }
                ),
                row=1,
                col=2
            )
            
            shift += 0.001
                
        self.figurehandle.update_xaxes(ticks='outside',
                                       tickwidth=1,
                                       tickcolor='black',
                                       ticklen=4,
                                       linecolor='rgba(0,0,0,1)',
                                       linewidth=1,
                                       showgrid=False)
        
        self.figurehandle.update_yaxes(ticks='outside',
                                       tickwidth=1,
                                       tickcolor='black',
                                       ticklen=4,
                                       linecolor='rgba(0,0,0,1)',
                                       linewidth=1,
                                       showgrid=False
                                       )
        
        # guess I gotta go low-level for this
        self.figurehandle['layout']['xaxis']['title'] = 'Active-Passive Index'
        self.figurehandle['layout']['xaxis2']['title'] = 'Congruence Index'
        self.figurehandle['layout']['yaxis']['range'] = [0,maxfreq+0.001]
        self.figurehandle['layout']['yaxis2']['range'] = [0,maxfreq+0.001]
        
        self.figurehandle.update_layout(
            yaxis_title='Fraction of Neurons',
            plot_bgcolor='rgba(0,0,0,0)' ,
            paper_bgcolor='rgba(0,0,0,0)',
            showlegend=False
        )
        
        # I also need to do janky things to make a custom legend, too! wow!
        prepend=''
        for area in ['AIP','F5','M1']:
            c = self.datadict["colors"]
            c = c[c["Area"]==area].to_numpy()
            c = c[0][:3]
            
            self.figurehandle.add_annotation(xref='x domain',
                                             yref='y domain',
                                             x = 1,
                                             y = 1,
                                             text = prepend+area,
                                             showarrow=False,
                                             font={
                                                 'color':f'rgba({c[0]},{c[1]},{c[2]},0.7)',
                                                 'size':14
                                                 },
                                             align='right',
                                             valign='top',
                                             yanchor='top',
                                             xanchor='right',
                                             row=1,
                                             col=2)
            
            prepend+=' <br>' # needs a space
            
        # add panel labels
        # OR NOT
        panellabels = \
        """self.figurehandle.add_annotation(xref='x domain',
                                        yref='y domain',
                                        x=-0.3,
                                        y=1,
                                        text='A',
                                        showarrow=False,
                                        font={
                                            'color':'black',
                                            'size':18
                                            },
                                        align='left',
                                        valign='bottom',
                                        yanchor='bottom',
                                        xanchor='left',
                                        row=1,
                                        col=1)
        
        self.figurehandle.add_annotation(xref='x domain',
                                        yref='y domain',
                                        x=-0.16,
                                        y=1,
                                        text='B',
                                        showarrow=False,
                                        font={
                                            'color':'black',
                                            'size':18
                                            },
                                        align='right',
                                        valign='bottom',
                                        yanchor='bottom',
                                        xanchor='right',
                                        row=1,
                                        col=2)"""
        
        # old
        old="""c = self.datadict["colors"]
        
        self.figurehandle = px.histogram(self.datadict["df"],
                                         x="Active-Passive Index",
                                         color="Area",
                                         barmode="overlay",
                                         histnorm="probability",
                                         nbins=40,
                                         opacity=1,
                                         color_discrete_sequence=[f'rgb({c["R"][c["Area"]=="AIP"].item()},{c["G"][c["Area"]=="AIP"].item()},{c["B"][c["Area"]=="AIP"].item()})',
                                                                  f'rgb({c["R"][c["Area"]=="F5"].item()},{c["G"][c["Area"]=="F5"].item()},{c["B"][c["Area"]=="F5"].item()})',
                                                                  f'rgb({c["R"][c["Area"]=="M1"].item()},{c["G"][c["Area"]=="M1"].item()},{c["B"][c["Area"]=="M1"].item()})'],
                                         cumulative=False
        ).update_layout(plot_bgcolor='rgba(0,0,0,0)',
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
        
        self.figurehandle.update_traces(marker_line_width=2,
                                        marker_line_color='rgba(0,0,0,1)',
                                        xbins={
                                            "start":-1.0,
                                            "end":1.0,
                                            "size":0.05
                                        })"""
        
        
        
        return
    
    def preview(self):
        if self.figurehandle is not None:
            self.figurehandle.show()
            # iplot( self.figurehandle )



# manual unit test
if __name__ == "__main__":
    F = Figure3(datafiles = [os.path.join('Analysis-Outputs','clustfiles','clustout_stats.mat')],
                outputfilename = os.path.join('figs','fig3.svg'))
    
    F.save_image()
    