function updateEditableFieldsGripClassification(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this updates the editable fields of the grip classification gui

%%

% pull up the analysis name, it's going to dictate everything else
analysisIdx   = get(handles.analysisSelector,'Value');
% analysisNames = get(handles.analysisSelector,'String');
% thisAnalysis  = analysisNames{analysisIdx};

% 1. Base Result
% 2. Why Ortho? Visual cross-training
% 3. Why Ortho? Special Turntable
% 4. Preserved Grip Representation? MGG cross-training
% 5. Preserved Grip Representation? Preferential boost of grip clustering

switch analysisIdx
    case 1
        set(handles.testContextSelector,'String',{'VGG','Obs.'});
        set(handles.trainingContextIndicator,'String',{'Same'});
        set(handles.trainingEpochIndicator,'String',{'Same'});
        set(handles.preprocessingSelector,'String',{'none','orthogonal','aggressively orthogonal','mirror metric median split'}); % for the sake of transparency and sanity checking. won't actually dedicate real estate to this slice of the data in the paper
        set(handles.gripClusteringSelector,'String',{'none','clustered'}); % once again, include for the sake of transparency and sanity.
    case 2 
        set(handles.testContextSelector,'String',{'VGG'});
        set(handles.trainingContextIndicator,'String',{'Same'});
        set(handles.trainingEpochIndicator,'String',{'Object Viewing'});
        set(handles.preprocessingSelector,'String',{'none','orthogonal','aggressively orthogonal','mirror metric median split'});
        set(handles.gripClusteringSelector,'String',{'none','clustered'});
    case 3
        set(handles.testContextSelector,'String',{'VGG'});
        set(handles.trainingContextIndicator,'String',{'Same'});
        set(handles.trainingEpochIndicator,'String',{'Same'});
        set(handles.preprocessingSelector,'String',{'none','orthogonal','aggressively orthogonal'}); % no mirror metric median split available for the special turntable control, so don't let it be an option!
        set(handles.gripClusteringSelector,'String',{'none'}); % grip clustering would've resulted in a single class
    case 4
        set(handles.testContextSelector,'String',{'VGG'});
        set(handles.trainingContextIndicator,'String',{'MGG'});
        set(handles.trainingEpochIndicator,'String',{'Same'});
        set(handles.preprocessingSelector,'String',{'none','orthogonal','aggressively orthogonal'});
        set(handles.gripClusteringSelector,'String',{'none'}); % grip clustering not available
    case 5 % actually offers no new slices of the data not accessible in case 1. but it offers better curation when navigating.
        set(handles.testContextSelector,'String',{'VGG'});
        set(handles.trainingContextIndicator,'String',{'Same'});
        set(handles.trainingEpochIndicator,'String',{'Same'});
        set(handles.preprocessingSelector,'String',{'none','aggressively orthogonal'});
        set(handles.gripClusteringSelector,'String',{'none','clustered'}); % toggling this is the entire point of this control analysis
end

% now go thru each field and make sure the value is appropriate. If not,
% set to 1.
handleNames = {'testContextSelector','trainingContextIndicator','trainingEpochIndicator','preprocessingSelector','gripClusteringSelector'};

for handleInd = 1:numel(handleNames)
    thisHandle = handleNames{handleInd};
    v = get(handles.(thisHandle),'Value');
    s = get(handles.(thisHandle),'String');
    
    if numel(s) < v
        set(handles.(thisHandle),'Value',1);
    else
        % pass
    end
end

% mirror metric median split has no grip clustering option, so if that's
% your preprocessing, eliminate this option from your
% gripClusteringSelector
if get(handles.preprocessingSelector,'Value') == 4
    set(handles.gripClusteringSelector,'String',{'none'});
    set(handles.gripClusteringSelector,'Value',1);
else
    % pass
end

%% update figures to go with your new editable fields
updateFigureGripClassification(hObject, eventdata, handles);
    
return
    