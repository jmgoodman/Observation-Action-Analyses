function loadClassifyData(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this loads in the data for the particular animal

%% step 1: get animal name
seshIdx   = get(hObject,'sessionSelector','Value');
seshNames = get(hObject,'sessionSelector','String');
thisSesh  = seshNames{seshIdx};

animalName = regexp(thisSesh,'\d+','split');
animalName = animalName{1};

%% step 2: get all sessions for this animal
thisAnimalInds = cellfun(@(x) ~isempty( regexp(x,animalName,'once') ),...
    seshNames );

thisAnimalSessionNames = seshNames(thisAnimalInds);