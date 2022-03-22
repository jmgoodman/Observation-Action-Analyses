function varargout = ResultsExplorer(varargin)
% RESULTSEXPLORER MATLAB code for ResultsExplorer.fig
%      RESULTSEXPLORER, by itself, creates a new RESULTSEXPLORER or raises the existing
%      singleton*.
%
%      H = RESULTSEXPLORER returns the handle to a new RESULTSEXPLORER or the handle to
%      the existing singleton*.
%
%      RESULTSEXPLORER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RESULTSEXPLORER.M with the given input arguments.
%
%      RESULTSEXPLORER('Property','Value',...) creates a new RESULTSEXPLORER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ResultsExplorer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ResultsExplorer_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ResultsExplorer

% Last Modified by GUIDE v2.5 22-Mar-2022 12:05:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ResultsExplorer_OpeningFcn, ...
                   'gui_OutputFcn',  @ResultsExplorer_OutputFcn, ...
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


% --- Executes just before ResultsExplorer is made visible.
function ResultsExplorer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ResultsExplorer (see VARARGIN)

% Choose default command line output for ResultsExplorer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ResultsExplorer wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = ResultsExplorer_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in analysisSelector.
function analysisSelector_Callback(hObject, eventdata, handles)
% hObject    handle to analysisSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns analysisSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from analysisSelector


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


% --- Executes on button press in goButton.
function goButton_Callback(hObject, eventdata, handles)
% hObject    handle to goButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% 1 Neuron Clustering
% 2 Visual Orthogonalization
% 3 Common Subspace
% 4 Grip Classification

charArray = get(handles.analysisSelector,'String');
elementSelected = get(handles.analysisSelector,'value');

switch elementSelected
    case 1
    case 2
    case 3
    case 4
    otherwise
        error('Dropdown list was somehow set to wrong value')
end


disp( strtrim( charArray(elementSelected,:) ) );
