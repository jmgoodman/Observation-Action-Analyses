function varargout = NeuronClustering(varargin)
% NEURONCLUSTERING MATLAB code for NeuronClustering.fig
%      NEURONCLUSTERING, by itself, creates a new NEURONCLUSTERING or raises the existing
%      singleton*.
%
%      H = NEURONCLUSTERING returns the handle to a new NEURONCLUSTERING or the handle to
%      the existing singleton*.
%
%      NEURONCLUSTERING('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NEURONCLUSTERING.M with the given input arguments.
%
%      NEURONCLUSTERING('Property','Value',...) creates a new NEURONCLUSTERING or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before NeuronClustering_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to NeuronClustering_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help NeuronClustering

% Last Modified by GUIDE v2.5 28-Mar-2022 10:28:27

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @NeuronClustering_OpeningFcn, ...
                   'gui_OutputFcn',  @NeuronClustering_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before NeuronClustering is made visible.
function NeuronClustering_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to NeuronClustering (see VARARGIN)

% Choose default command line output for NeuronClustering
handles.output = hObject;

% pull data and set to the handles structure as appdata
mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);
[cd_,~,~] = fileparts(cd_);

clusterDir = fullfile(cd_,'Analysis-Outputs','clustfiles');
mObj       = matfile( fullfile( clusterDir,'clustout_stats.mat' ),'Writable',false );

% write data to some fields
seshNames   = mObj.seshnames;

animalNames = cellfun(@(x) regexpi(x,'[a-z,A-Z]*','match'),seshNames,'uniformoutput',false);
animalNames = cellfun(@(x) x{1},animalNames,'uniformoutput',false);
uniqueAnimalNames = unique( char( animalNames ),'rows' );
uniqueAnimalNames = cellstr(uniqueAnimalNames);
uniqueAnimalNames = strcat(uniqueAnimalNames,'-pooled');

set( handles.sessionSelector,'String',vertcat( seshNames(:), uniqueAnimalNames(:) ) )
set(handles.sessionSelector,'Value',1);

contrastStruct  = mObj.contraststruct; partialAreas = unique(contrastStruct(1).pooledareanames); partialAreas = partialAreas(:);
nStruct         = mObj.Nstruct; wholeAreas = fieldnames(nStruct); wholeAreas = wholeAreas(:);
uniqueAreaNames = vertcat(...
    wholeAreas,...
    partialAreas...
    );
set(handles.areaSelector,'Max',numel(uniqueAreaNames));
set(handles.areaSelector,'String',uniqueAreaNames(:));
set(handles.areaSelector,'Value',2:4);

setappdata(handles.output,'clusterDir',clusterDir);
setappdata(handles.output,'clusterData',mObj);
setappdata(handles.output,'colorConvention',defColorConvention);

% Update handles structure
guidata(hObject, handles);

% make plots
plotRefresher_NeuronClustering(hObject,eventdata,handles);

% UIWAIT makes NeuronClustering wait for user response (see UIRESUME)
% uiwait(handles.NeuronClustering);


% --- Outputs from this function are returned to the command line.
function varargout = NeuronClustering_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in sessionSelector.
function sessionSelector_Callback(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% nevermind, this could get real annoying real fast
% plotRefresher_NeuronClustering(hObject,eventdata,handles);




% --- Executes during object creation, after setting all properties.
function sessionSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in areaSelector.
function areaSelector_Callback(hObject, eventdata, handles)
% hObject    handle to areaSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns areaSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from areaSelector

% nevermind, this could get real annoying real fast
% plotRefresher_NeuronClustering(hObject,eventdata,handles);



% --- Executes during object creation, after setting all properties.
function areaSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to areaSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in returnButton.
function returnButton_Callback(hObject, eventdata, handles)
% hObject    handle to returnButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

closereq();
ResultsExplorer();


% --- Executes on button press in saveMarginalPreference.
function saveMarginalPreference_Callback(hObject, eventdata, handles)
% hObject    handle to saveMarginalPreference (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataSaver(hObject,eventdata,handles,'marginalPreference');


% --- Executes on button press in saveMarginalCongruence.
function saveMarginalCongruence_Callback(hObject, eventdata, handles)
% hObject    handle to saveMarginalCongruence (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataSaver(hObject,eventdata,handles,'marginalCongruence');



% --- Executes on button press in saveJointMetrics.
function saveJointMetrics_Callback(hObject, eventdata, handles)
% hObject    handle to saveJointMetrics (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataSaver(hObject,eventdata,handles,'jointMetrics');



% --- Executes on button press in savePairsStats.
function savePairsStats_Callback(hObject, eventdata, handles)
% hObject    handle to savePairsStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataSaver(hObject,eventdata,handles,'pairsTable');


% --- Executes on button press in saveManovaStats.
function saveManovaStats_Callback(hObject, eventdata, handles)
% hObject    handle to saveManovaStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

dataSaver(hObject,eventdata,handles,'manovaTable');

% --- Executes on button press in plotButton.
function plotButton_Callback(hObject, eventdata, handles)
% hObject    handle to plotButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

plotRefresher_NeuronClustering(hObject,eventdata,handles);
