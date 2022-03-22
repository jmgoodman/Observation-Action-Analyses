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

% Last Modified by GUIDE v2.5 22-Mar-2022 13:33:49

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


% --- Executes on selection change in level1Selector.
function level1Selector_Callback(hObject, eventdata, handles)
% hObject    handle to level1Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns level1Selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level1Selector


% --- Executes during object creation, after setting all properties.
function level1Selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level1Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in level2Selector.
function level2Selector_Callback(hObject, eventdata, handles)
% hObject    handle to level2Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns level2Selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level2Selector


% --- Executes during object creation, after setting all properties.
function level2Selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level2Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in level3Selector.
function level3Selector_Callback(hObject, eventdata, handles)
% hObject    handle to level3Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns level3Selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level3Selector


% --- Executes during object creation, after setting all properties.
function level3Selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level3Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in level4Selector.
function level4Selector_Callback(hObject, eventdata, handles)
% hObject    handle to level4Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns level4Selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level4Selector


% --- Executes during object creation, after setting all properties.
function level4Selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level4Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in level5Selector.
function level5Selector_Callback(hObject, eventdata, handles)
% hObject    handle to level5Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns level5Selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level5Selector


% --- Executes during object creation, after setting all properties.
function level5Selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level5Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in level6Selector.
function level6Selector_Callback(hObject, eventdata, handles)
% hObject    handle to level6Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns level6Selector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from level6Selector


% --- Executes during object creation, after setting all properties.
function level6Selector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to level6Selector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in axisSelector.
function axisSelector_Callback(hObject, eventdata, handles)
% hObject    handle to axisSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns axisSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from axisSelector


% --- Executes during object creation, after setting all properties.
function axisSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to axisSelector (see GCBO)
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



% --- Executes on button press in saveHeatmap.
function saveHeatmap_Callback(hObject, eventdata, handles)
% hObject    handle to saveHeatmap (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in savePeakAccuracyPlot.
function savePeakAccuracyPlot_Callback(hObject, eventdata, handles)
% hObject    handle to savePeakAccuracyPlot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in saveStats.
function saveStats_Callback(hObject, eventdata, handles)
% hObject    handle to saveStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
