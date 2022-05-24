function plotCommonClassify(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes a by-area breakdown of the classification accuracy prior to
% orthogonalization, after orthogonalization, and after further restricting
% yourself to the "common" subspace capturing the most variance. 
% (No "aggro" orthogonalization because we never applied aggro ortho to the
% commonspace pipeline, so no way to compare)
% Panel C!

% classification cell structure:
% subsamp x context x context x align x align x subalign x subalign
% within: fold
% within-within: area (with chance level appended)