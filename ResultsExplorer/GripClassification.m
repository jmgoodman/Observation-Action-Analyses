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

% Last Modified by GUIDE v2.5 14-Jun-2022 11:39:26

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

% Choose default command line output for CommonSubspace
handles.output = hObject;

% pull data and set to the handles structure as appdata
disp('This one requires a lot of data to be loaded. Patience!')

mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);
[cd_,~,~] = fileparts(cd_);

mirrorDataDir      = fullfile(cd_,'MirrorData');
analysisOutputsDir = fullfile(cd_,'Analysis-Outputs');

setappdata(handles.output,'mirrorDataDir',mirrorDataDir)
setappdata(handles.output,'analysisOutputsDir',analysisOutputsDir);

sessions2analyze = {'Moe46';'Moe50';'Zara64';'Zara70'};
set(handles.sessionSelector,'String',sessions2analyze);

arrays2analyze = {'pooled';'AIP';'F5';'M1'};
set(handles.areaSelector,'String',arrays2analyze)

colorStruct = defColorConvention(); 
setappdata(handles.output,'colorStruct',colorStruct)

seshNames = sessions2analyze;

% load in the animal-specific data
loadClassifyData(hObject, eventdata, handles);
updatePeakAccuracy(hObject, eventdata, handles);

% pull in some kinematic classification numbers
% TODO

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

% this is going to be HELLA unoptimized
% load data anew for changing this value
loadClassifyData(hObject, eventdata, handles);


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
updateFields(hObject, eventdata, handles);


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
dataSaver(hObject,eventdata,handles,'peakAccuracyPlot');

% --- Executes on button press in saveStats.
function saveStats_Callback(hObject, eventdata, handles)
% hObject    handle to saveStats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on selection change in controlSelector.
function controlSelector_Callback(hObject, eventdata, handles)
% hObject    handle to controlSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns controlSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from controlSelector
updateFields(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function controlSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to controlSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in contextSelector.
function contextSelector_Callback(hObject, eventdata, handles)
% hObject    handle to contextSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns contextSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from contextSelector
updateFields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function contextSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contextSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in subContextSelector.
function subContextSelector_Callback(hObject, eventdata, handles)
% hObject    handle to subContextSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns subContextSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from subContextSelector
updateFields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function subContextSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subContextSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in alignmentSelector.
function alignmentSelector_Callback(hObject, eventdata, handles)
% hObject    handle to alignmentSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns alignmentSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from alignmentSelector
updateFields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function alignmentSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to alignmentSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in subAlignmentSelector.
function subAlignmentSelector_Callback(hObject, eventdata, handles)
% hObject    handle to subAlignmentSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns subAlignmentSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from subAlignmentSelector
updateFields(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function subAlignmentSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to subAlignmentSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in text100.
function contextComparisonSelector_Callback(hObject, eventdata, handles)
% hObject    handle to text100 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns text100 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from text100
updateFields(hObject, eventdata, handles);

% --- Executes during object creation, after setting all properties.
function text100_CreateFcn(hObject, eventdata, handles)
% hObject    handle to text100 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes during object creation, after setting all properties.
function contextComparisonSelector_CreateFcn(hObject, eventdata, handles)
% hObject    handle to contextComparisonSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
