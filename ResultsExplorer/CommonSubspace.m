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

% Last Modified by GUIDE v2.5 22-Mar-2022 13:32:16

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


% --- Executes on button press in saveStats.
function saveStats_Callback(hObject, eventdata, handles)
% hObject    handle to saveStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
