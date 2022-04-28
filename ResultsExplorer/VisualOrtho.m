function varargout = VisualOrtho(varargin)
% VISUALORTHO MATLAB code for VisualOrtho.fig
%      VISUALORTHO, by itself, creates a new VISUALORTHO or raises the existing
%      singleton*.
%
%      H = VISUALORTHO returns the handle to a new VISUALORTHO or the handle to
%      the existing singleton*.
%
%      VISUALORTHO('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VISUALORTHO.M with the given input arguments.
%
%      VISUALORTHO('Property','Value',...) creates a new VISUALORTHO or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VisualOrtho_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VisualOrtho_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VisualOrtho

% Last Modified by GUIDE v2.5 22-Mar-2022 13:43:33

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VisualOrtho_OpeningFcn, ...
                   'gui_OutputFcn',  @VisualOrtho_OutputFcn, ...
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


% --- Executes just before VisualOrtho is made visible.
function VisualOrtho_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VisualOrtho (see VARARGIN)

% Choose default command line output for VisualOrtho
handles.output = hObject;

% pull data and set to the handles structure as appdata
mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);
[cd_,~,~] = fileparts(cd_);

mirrorDataDir      = fullfile(cd_,'MirrorData');
analysisOutputsDir = fullfile(cd_,'Analysis-Outputs');

setappdata(handles.output,'mirrorDataDir',mirrorDataDir)
setappdata(handles.output,'analysisOutputsDir',analysisOutputsDir);

sessions2analyze = {'Moe46';'Moe50';'Zara64';'Zara68';'Zara70'};
set(handles.sessionSelector,'String',sessions2analyze);

arrays2analyze = {'pooled';'AIP';'F5';'M1'};
set(handles.areaSelector,'String',arrays2analyze)

% note: variancePlot will always show ALL the data, won't change with
% session or area
%
% so, just make it here & get it over with

% if the core data file isn't there (which defines some scatterplots of X =
% source variance kept and Y = destination variance kept)

colorStruct = defColorConvention(); 
setappdata(handles.output,'colorStruct',colorStruct)

% check if sustain data are created
file2check4 = fullfile(cd_,'ResultsExplorer','Data','sustainData.mat');

if ~exist(file2check4,'file')
    compileSustainData(hObject,eventdata,handles);
else
    load(file2check4); %#ok<LOAD>
    % seshCell
    % trialAverageCell
    % ncompsConservative
    % ncompsAggressive
    setappdata(handles.output,'seshCell',seshCell)
    setappdata(handles.output,'trialAverageCell',trialAverageCell)
    setappdata(handles.output,'ncompsConservative',ncompsConservative)
    setappdata(handles.output,'ncompsAggressive',ncompsAggressive)
    setappdata(handles.output,'objectNames',objectNames)
end
    
plotVarianceCaptured(hObject,eventdata,handles);
plotProjections(hObject, eventdata, handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VisualOrtho wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VisualOrtho_OutputFcn(hObject, eventdata, handles) 
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
plotProjections(hObject, eventdata, handles)


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
plotProjections(hObject, eventdata, handles)


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



% --- Executes on button press in saveProjectionPlot.
function saveProjectionPlot_Callback(hObject, eventdata, handles)
% hObject    handle to saveProjectionPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
for ii = 0:3
    dataSaver(hObject,eventdata,handles,['projectionPlot',num2str(ii)]);
    uiwait;
end


% --- Executes on button press in saveVariancePlot.
function saveVariancePlot_Callback(hObject, eventdata, handles)
% hObject    handle to saveVariancePlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dataSaver(hObject,eventdata,handles,'variancePlot');


% --- Executes on button press in saveStats.
function saveStats_Callback(hObject, eventdata, handles)
% hObject    handle to saveStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('nothing here buddy!')
