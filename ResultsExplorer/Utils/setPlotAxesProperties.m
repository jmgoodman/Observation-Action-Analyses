function [] = setPlotAxesProperties(hObject, eventdata, handles)

% hObject           handle to sessionSelector (see GCBO)
% eventdata         reserved - to be defined in a future version of MATLAB
% handles           structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this is the callback that sets properties in the plotPreview GUI.

% maintain the positioning on the page
oldPos = get(handles.plotAxes,'Position');
newWid = get(handles.horizontalSizeSlider,'Value');
newHt  = get(handles.verticalSizeSlider,'Value');

% add mechanism to preserve aspect ratio
oldRatio = oldPos(3) / oldPos(4);
deltaHt   = newHt - oldPos(4);

if abs(deltaHt) > 1e-6
    yMoved = true;
else
    yMoved = false;
end

if handles.lockAspectRatio.Value
    if yMoved
        newWid = oldRatio * newHt;
        set(handles.horizontalSizeSlider,'Value',newWid);
        set(handles.horizontalSize,'String',num2str(newWid));
    else
        newHt   = newWid / oldRatio;
        deltaHt = newHt - oldPos(4);
        
        set(handles.verticalSizeSlider,'Value',newHt);
        set(handles.verticalSize,'String',num2str(newHt));
    end
else
    % pass
end

newPos    = oldPos;
newPos(2) = newPos(2) - deltaHt;
newPos(3) = newWid;
newPos(4) = newHt;

% now set the new position
set(handles.plotAxes,'Position',newPos);

newFontSize = get(handles.textSizeSlider,'Value');
set(handles.plotAxes,'fontsize',newFontSize);

% colorbar handling
if isfield(handles.plotAxes.UserData,'ColorBar')
    if ~isempty(handles.plotAxes.UserData.ColorBar)
        strText = get(handles.plotAxes.UserData.ColorBar.Title,'String');
        delete(handles.plotAxes.UserData.ColorBar);
        handles.plotAxes = pairedColorBar(handles.plotAxes,strText,'FontSize',newFontSize);
    else
        % pass
    end
else
    % pass
end

% handling line widths and marker sizes
propList = {'markersize','sizedata','linewidth'};

for propInd = 1:numel(propList)
    thisProp = propList{propInd};
    fObj = findobj(handles.plotAxes.Children,'-property',thisProp);
    
    % pick transform
    switch thisProp
        case 'markersize'
            newVal = newFontSize * .5;
        case 'sizedata'
            newVal = (newFontSize * .5)^2;
        case 'linewidth'
            newVal = 1/10 * newFontSize;
        otherwise
            error('something goofed up here')
    end
    
    for objInd = 1:numel(fObj)
        set(fObj(objInd),thisProp,newVal);
    end
end


% if text fields are present (say, delineating a makeshift legend), adjust their size
textObjs = findobj(handles.plotAxes.Children,'-property','fontsize');

for objInd = 1:numel(textObjs)
    set(textObjs(objInd),'fontsize',newFontSize)
end

return