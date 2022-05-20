function varargout = CommonSubspace(varargin)
% COMMONSUBSPACE MATLAB code for CommonSubspace.fig
%      COMMONSUBSPACE, by itself, creates a new COMMONSUBSPACE or raises the existing
%      singleton*.
%
%      H = COMMONSUBSPACE returns the handle to a new COMMONSUBSPACE or the handle to
%      the existing singleton*.
%
%      COMMONSUBSPACE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in COMMONSUBSPACE.M with the given input arguments.
%
%      COMMONSUBSPACE('Property','Value',...) creates a new COMMONSUBSPACE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before CommonSubspace_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to CommonSubspace_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help CommonSubspace

% Last Modified by GUIDE v2.5 19-May-2022 10:29:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @CommonSubspace_OpeningFcn, ...
                   'gui_OutputFcn',  @CommonSubspace_OutputFcn, ...
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


% --- Executes just before CommonSubspace is made visible.
function CommonSubspace_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to CommonSubspace (see VARARGIN)

% Choose default command line output for CommonSubspace
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

colorStruct = defColorConvention(); 
setappdata(handles.output,'colorStruct',colorStruct)

% load in data
seshNames = get(handles.sessionSelector,'String');
seshInd   = get(handles.sessionSelector,'Value');
thisSesh  = seshNames{seshInd};
seshFullFileName = fullfile( analysisOutputsDir,thisSesh,...
    sprintf('commonspace_results_%s.mat',thisSesh) );
commonSpaceData = load(seshFullFileName);
setappdata(handles.output,'commonSpaceData',commonSpaceData);

dataStructFile  = fullfile( mirrorDataDir,sprintf('%s_datastruct.mat',thisSesh) );
dataStruct      = load(dataStructFile);
dataLabels      = extractlabels(dataStruct.datastruct.cellform);
setappdata(handles.output,'dataStruct',dataStruct);
setappdata(handles.output,'dataLabels',dataLabels);

currentAnimal = regexpi(thisSesh,'[A-Z,a-z]*','match');
setappdata(handles.output,'currentAnimal',currentAnimal);

% make plots
plotCommonProjection(hObject,eventdata,handles);
% plotCommonDimSweep(hObject,eventdata,handles);
% plotCommonClassify(hObject,eventdata,handles); % subsample x context1 x context2 x align1 x align2 x subalign1 x subalign2

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes CommonSubspace wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = CommonSubspace_OutputFcn(hObject, eventdata, handles) 
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

% load in data
disp('LOADING...')
analysisOutputsDir = getappdata(handles.output,'analysisOutputsDir');
seshNames = get(handles.sessionSelector,'String');
seshInd   = get(handles.sessionSelector,'Value');
thisSesh  = seshNames{seshInd};
seshFullFileName = fullfile( analysisOutputsDir,thisSesh,...
    sprintf('commonspace_results_%s.mat',thisSesh) );
commonSpaceData = load(seshFullFileName);
setappdata(handles.output,'commonSpaceData',commonSpaceData);

mirrorDataDir   = getappdata(handles.output,'mirrorDataDir');
dataStructFile  = fullfile( mirrorDataDir,sprintf('%s_datastruct.mat',thisSesh) );
dataStruct      = load(dataStructFile);
dataLabels      = extractlabels(dataStruct.datastruct.cellform);
setappdata(handles.output,'dataStruct',dataStruct);
setappdata(handles.output,'dataLabels',dataLabels);
disp('...DONE')
plotCommonProjection(hObject,eventdata,handles);

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
plotCommonProjection(hObject,eventdata,handles);

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



% --- Executes on button press in saveProjection.
function saveProjection_Callback(hObject, eventdata, handles)
% hObject    handle to saveProjection (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in saveDimSweep.
function saveDimSweep_Callback(hObject, eventdata, handles)
% hObject    handle to saveDimSweep (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in saveClassify.
function saveClassify_Callback(hObject, eventdata, handles)
% hObject    handle to saveClassify (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in areaSelector.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to areaSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns areaSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from areaSelector


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to areaSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in saveCommonStats.
function saveCommonStats_Callback(hObject, eventdata, handles)
% hObject    handle to saveCommonStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
