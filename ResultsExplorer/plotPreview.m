function varargout = plotPreview(varargin)
% PLOTPREVIEW MATLAB code for plotPreview.fig
%      PLOTPREVIEW, by itself, creates a new PLOTPREVIEW or raises the existing
%      singleton*.
%
%      H = PLOTPREVIEW returns the handle to a new PLOTPREVIEW or the handle to
%      the existing singleton*.
%
%      PLOTPREVIEW('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PLOTPREVIEW.M with the given input arguments.
%
%      PLOTPREVIEW('Property','Value',...) creates a new PLOTPREVIEW or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before plotPreview_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to plotPreview_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help plotPreview

% Last Modified by GUIDE v2.5 29-Mar-2022 12:57:37

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @plotPreview_OpeningFcn, ...
                   'gui_OutputFcn',  @plotPreview_OutputFcn, ...
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


% --- Executes just before plotPreview is made visible.
function plotPreview_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to plotPreview (see VARARGIN)

% access global target axes, which should always, ALWAYS be set before
% calling this GUI
global axes2Copy

if isempty(axes2Copy)
    error('No axes selected for preview! Cannot continue...')
else
    % pass
end

% Choose default command line output for plotPreview
handles.output = hObject;

% do some other stuff
set(handles.pageAxes,'xtick',[],'ytick',[],'box','on')
cla(handles.plotAxes); % cleanup

% store properties to keep
tag2keep = get(handles.plotAxes,'Tag');
oldPos = get(handles.plotAxes,'position');

% copy axes over
copyaxes(axes2Copy,handles.plotAxes);

% properties that are super important to preserve
set(handles.plotAxes,'Tag',tag2keep);
set(handles.plotAxes,'units','inches')
set(handles.plotAxes,'position',oldPos);
set(handles.plotAxes,'PlotBoxAspectRatioMode','auto')
set(handles.plotAxes,'DataAspectRatioMode','auto')


% Min=0 by default
set(handles.horizontalSizeSlider,'Max',7.5,'Value',3.75);
set(handles.verticalSizeSlider,'Max',10,'Value',4.5);
set(handles.textSizeSlider,'Max',32,'Value',10);

% testing colorbars
% handles.plotAxes = pairedColorBar(handles.plotAxes,'hello','fontsize',10);

% replace "hObject" with these handles, since we're pretending we just
% manually set these
pairedSliderText(handles.horizontalSizeSlider, eventdata, handles, 'horizontalSizeSlider', 'horizontalSize');
pairedSliderText(handles.verticalSizeSlider, eventdata, handles, 'verticalSizeSlider', 'verticalSize');
pairedSliderText(handles.textSizeSlider, eventdata, handles, 'textSizeSlider', 'textSize');

% now set the properties
% note: while I would PREFER to set OuterPosition, I am stuck manipulating
% Position
% I suspect that what this shows is NOT exactly what you'll get, but merely an
% approximation.
% part of the issue is what I believe to be a miscalulation in MATLAB when
% converting from pixels to real-world units.
% ergo the text is probably not exactly the size it appears to be.
setPlotAxesProperties(hObject, eventdata, handles);


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes plotPreview wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = plotPreview_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function verticalSizeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to verticalSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

pairedSliderText(hObject, eventdata, handles, 'verticalSizeSlider', 'verticalSize');

% now set the properties
setPlotAxesProperties(hObject, eventdata, handles);



% --- Executes during object creation, after setting all properties.
function verticalSizeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to verticalSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function textSizeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to textSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

pairedSliderText(hObject, eventdata, handles, 'textSizeSlider', 'textSize');

% now set the properties
setPlotAxesProperties(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function textSizeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function horizontalSizeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to horizontalSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

pairedSliderText(hObject, eventdata, handles, 'horizontalSizeSlider', 'horizontalSize');

% now set the properties
setPlotAxesProperties(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function horizontalSizeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to horizontalSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function horizontalSize_Callback(hObject, eventdata, handles)
% hObject    handle to horizontalSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of horizontalSize as text
%        str2double(get(hObject,'String')) returns contents of horizontalSize as a double
pairedSliderText(hObject, eventdata, handles, 'horizontalSizeSlider', 'horizontalSize');

% now set the properties
setPlotAxesProperties(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function horizontalSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to horizontalSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function verticalSize_Callback(hObject, eventdata, handles)
% hObject    handle to verticalSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of verticalSize as text
%        str2double(get(hObject,'String')) returns contents of verticalSize as a double
pairedSliderText(hObject, eventdata, handles, 'verticalSizeSlider', 'verticalSize');

% now set the properties
setPlotAxesProperties(hObject, eventdata, handles);



% --- Executes during object creation, after setting all properties.
function verticalSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to verticalSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function textSize_Callback(hObject, eventdata, handles)
% hObject    handle to textSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of textSize as text
%        str2double(get(hObject,'String')) returns contents of textSize as a double
pairedSliderText(hObject, eventdata, handles, 'textSizeSlider', 'textSize');

% now set the properties
setPlotAxesProperties(hObject, eventdata, handles);


% --- Executes during object creation, after setting all properties.
function textSize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to textSize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in exportButton.
function exportButton_Callback(hObject, eventdata, handles)
% hObject    handle to exportButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);

thisObj = handles.plotAxes;

testName      = 'dataPlot';
defaultFile   = fullfile(cd_,'Outputs',sprintf('%s.svg',testName));
[fname,fpath] = uiputfile(defaultFile);

if fname
    fullfname = fullfile(fpath,fname);
    axPos  = get(thisObj,'Position');
    figPos = axPos;
    figPos(1:2) = [0 0];
    figPos(3:4) = figPos(3:4) + [1 1];
    ff=figure('Visible','off'); set(ff,'Units','inches','Position',figPos,'renderer','painters'); % renderer needs to be manually set here... for some god-forsaken reason. In literally no other context has this given me a problem, but here? nah dude, can't let you do that!
    axPos(1:2) = [0.5 0.5];
    aa=copyobj(thisObj,ff);
    set(aa,'Position',axPos);
    set(ff,'paperposition',figPos,'paperunits','inches')
    print(ff,fullfname,'-dsvg');
    delete(ff)
    delete(aa)
else
    warning('no file chosen, saving aborted')
end


% --- Executes on button press in lockAspectRatio.
function lockAspectRatio_Callback(hObject, eventdata, handles)
% hObject    handle to lockAspectRatio (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of lockAspectRatio


% --- Executes on button press in exportPngButton.
function exportPngButton_Callback(hObject, eventdata, handles)
% hObject    handle to exportPngButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);

thisObj = handles.plotAxes;

testName      = 'dataPlot';
defaultFile   = fullfile(cd_,'Outputs',sprintf('%s.png',testName));
[fname,fpath] = uiputfile(defaultFile);

if fname
    fullfname = fullfile(fpath,fname);
    axPos  = get(thisObj,'Position');
    figPos = axPos;
    figPos(1:2) = [0 0];
    figPos(3:4) = figPos(3:4) + [1 1];
    ff=figure('Visible','off'); set(ff,'Units','inches','Position',figPos);
    axPos(1:2) = [0.5 0.5];
    aa=copyobj(thisObj,ff);
    set(aa,'Position',axPos);
    set(ff,'paperposition',figPos,'paperunits','inches')
    print(ff,fullfname,'-dpng',['-r',get(handles.dpi,'String')]); % genuinely in units of dpi according to matlab documentation ("resolution" parameter of "print" function)
    delete(ff)
    delete(aa)
else
    warning('no file chosen, saving aborted')
end



function dpi_Callback(hObject, eventdata, handles)
% hObject    handle to dpi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dpi as text
%        str2double(get(hObject,'String')) returns contents of dpi as a double


% --- Executes during object creation, after setting all properties.
function dpi_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dpi (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
