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

deltaHt   = newHt - oldPos(4);
newPos    = oldPos;
newPos(2) = newPos(2) - deltaHt;
newPos(3) = newWid;
newPos(4) = newHt;

set(handles.plotAxes,'Position',newPos);


newFontSize = get(handles.textSizeSlider,'Value');
set(handles.plotAxes,'fontsize',newFontSize);

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

return