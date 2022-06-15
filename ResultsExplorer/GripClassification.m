function varargout = GripClassification(varargin)
% GRIPCLASSIFICATION MATLAB code for GripClassification.fig
%      GRIPCLASSIFICATION, by itself, creates a new GRIPCLASSIFICATION or raises the existing
%      singleton*.
%
%      H = GRIPCLASSIFICATION returns the handle to a new GRIPCLASSIFICATION or the handle to
%      the existing singleton*.
%
%      GRIPCLASSIFICATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GRIPCLASSIFICATION.M with the given input arguments.
%
%      GRIPCLASSIFICATION('Property','Value',...) creates a new GRIPCLASSIFICATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before GripClassification_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to GripClassification_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help GripClassification

% Last Modified by GUIDE v2.5 15-Jun-2022 14:32:02

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @GripClassification_OpeningFcn, ...
                   'gui_OutputFcn',  @GripClassification_OutputFcn, ...
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


% --- Executes just before GripClassification is made visible.
function GripClassification_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to GripClassification (see VARARGIN)

% Choose default command line output for GripClassification
handles.output = hObject;

mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);
[cd_,~,~] = fileparts(cd_);

mirrorDataDir      = fullfile(cd_,'MirrorData');
analysisOutputsDir = fullfile(cd_,'Analysis-Outputs');

setappdata(handles.output,'mirrorDataDir',mirrorDataDir)
setappdata(handles.output,'analysisOutputsDir',analysisOutputsDir);

% load in the data for these analyses
classmatfile = fullfile(analysisOutputsDir,'all-sessions-classmats.mat');
load(classmatfile); %#ok<LOAD> % sole variable set to "classmats": see "classify_output_analysis.m" under "Analysis-Outputs" for confirmation
setappdata(handles.output,'classmats',classmats);

% set the names of the epochs
epochNames = {'Pre-illumination','Post-illumination','Pre-movement','Post-movement','Pre-lift','Post-lift'};
setappdata(handles.output,'epochNames',epochNames);

%%%%%%%% NOT NEEDED %%%%%%%%
% sessions2analyze = {'Moe46';'Moe50';'Zara64';'Zara70'};
% set(handles.sessionSelector,'String',sessions2analyze);
% 
% arrays2analyze = {'pooled';'AIP';'F5';'M1'};
% set(handles.areaSelector,'String',arrays2analyze)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%

colorStruct = defColorConvention(); 
setappdata(handles.output,'colorStruct',colorStruct)

% update editable fields
updateEditableFieldsGripClassification(hObject, eventdata, handles);

% update figure (done as part of updateEditableFieldsGripClassification)

% update data table

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes GripClassification wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = GripClassification_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in monkeySelector.
function monkeySelector_Callback(hObject, eventdata, handles)
% hObject    handle to monkeySelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns monkeySelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from monkeySelector

% no need to update the editable fields, nothing would change anyway
updateFigureGripClassification(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function monkeySelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to monkeySelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in analysisSelector.
function analysisSelector_Callback(hObject, eventdata, handles)
% hObject    handle to analysisSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns analysisSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from analysisSelector
updateEditableFieldsGripClassification(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function analysisSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to analysisSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in testContextSelector.
function testContextSelector_Callback(hObject, eventdata, handles)
% hObject    handle to testContextSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns testContextSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from testContextSelector
updateEditableFieldsGripClassification(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function testContextSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to testContextSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in trainingContextIndicator.
function trainingContextIndicator_Callback(hObject, eventdata, handles)
% hObject    handle to trainingContextIndicator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trainingContextIndicator contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trainingContextIndicator

% always an indicator, no need to have a callback here


% --- Executes during object creation, after setting all properties.
function trainingContextIndicator_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trainingContextIndicator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in trainingEpochIndicator.
function trainingEpochIndicator_Callback(hObject, eventdata, handles)
% hObject    handle to trainingEpochIndicator (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns trainingEpochIndicator contents as cell array
%        contents{get(hObject,'Value')} returns selected item from trainingEpochIndicator

% always an indicator, no need to have a callback here

% --- Executes during object creation, after setting all properties.
function trainingEpochIndicator_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trainingEpochIndicator (see GCBO)
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


% --- Executes on selection change in preprocessingSelector.
function preprocessingSelector_Callback(hObject, eventdata, handles)
% hObject    handle to preprocessingSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns preprocessingSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from preprocessingSelector
updateEditableFieldsGripClassification(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function preprocessingSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to preprocessingSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in figureExport.
function figureExport_Callback(hObject, eventdata, handles)
% hObject    handle to figureExport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
dataSaver(hObject,eventdata,handles,'accuracyPlot');

% --- Executes on button press in dataExport.
function dataExport_Callback(hObject, eventdata, handles)
% hObject    handle to dataExport (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in gripClusteringSelector.
function gripClusteringSelector_Callback(hObject, eventdata, handles)
% hObject    handle to gripClusteringSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns gripClusteringSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from gripClusteringSelector
updateEditableFieldsGripClassification(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function gripClusteringSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to gripClusteringSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
