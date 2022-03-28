function [] = pairedSliderText(hObject, eventdata, handles, boundSliderName, boundTextName)

% hObject           handle to sessionSelector (see GCBO)
% eventdata         reserved - to be defined in a future version of MATLAB
% handles           structure with handles and user data (see GUIDATA)
% boundSliderName   name of the slider of this bound duo
% boundTextName     name of the text field of this bound duo

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this is the callback which links slider and text objects to axis
% properties.  this is a helper function for plotPreview.

%% test whether hObject is the slider or the text field
% whichever it is, edit the other

switch get(hObject,'Tag')
    case boundSliderName
        set( handles.(boundTextName),'String',num2str(get(hObject,'Value')) );
        
    case boundTextName
        set( handles.(boundSliderName),'Value',str2double(get(hObject,'String')) );
        
    otherwise
        error('Error resolving names of slider and text')
end

return