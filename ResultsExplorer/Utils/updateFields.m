function updateFields(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this updates the fields to select from

%% session
seshIdx   = get(handles.sessionSelector,'Value');
seshNames = get(handles.sessionSelector,'String');
thisSesh  = seshNames{seshIdx};

classifyCell = getappdata(handles.output,'classifyCell');

idxThisSesh  = find( cellfun(@(x) strcmpi(x.seshID,thisSesh),classifyCell) );

cellThisSesh = classifyCell{idxThisSesh}; %#ok<*FNDSB>


%% analysis type
analysisTypes = fieldnames( cellThisSesh.data.copts );

currentValue = get(handles.controlSelector,'Value');
if currentValue > numel(analysisTypes)
    currentValue = 1;
    set(handles.controlSelector,'Value',currentValue)
else
    % pass
end
    
set(handles.controlSelector,'String',analysisTypes);

analysisType         = analysisTypes{currentValue};

%% context
contextNames = fieldnames( cellThisSesh.data.copts.(analysisType) );

currentValue = get(handles.contextSelector,'Value');
if currentValue > numel(contextNames)
    currentValue = 1;
    set(handles.contextSelector,'Value',currentValue)
else
    % pass
end
    
set(handles.contextSelector,'String',contextNames);

thisContext = contextNames{currentValue};

%% subcontext
subContextNames = fieldnames( cellThisSesh.data.cstruct.(analysisType) );

if strcmpi(analysisType,'kinematics')
    subContextNames = {'N/A'};
else
    % pass
end

currentValue = get(handles.subContextSelector,'Value');
if currentValue > numel(subContextNames)
    currentValue = 1;
    set(handles.subContextSelector,'Value',currentValue)
else
end
    
set(handles.subContextSelector,'String',subContextNames);

thisSubContext = subContextNames{currentValue};

%% context comparison
[contextTest,contextTrain] = meshgrid( classifyCell{1}.data.copts.(analysisType).(thisContext).targetcontexts );
alignCrosses = strcat( contextTrain(:),'-train/',contextTest(:),'-test' );

currentValue = get(handles.contextComparisonSelector,'Value');
if currentValue > numel(alignCrosses)
    currentValue = 1;
    set(handles.contextComparisonSelector,'Value',currentValue)
else
    % pass
end

set(handles.contextComparisonSelector,'String',alignCrosses)

%% alignment

[alignTest,alignTrain] = meshgrid( cellThisSesh.data.copts.(analysisType).(thisContext).alignment );

alignCrosses = strcat( alignTrain(:),'-train/',alignTest(:),'-test' );

currentValue = get(handles.alignmentSelector,'Value');
if currentValue > numel(alignCrosses)
    currentValue = 1;
    set(handles.alignmentSelector,'Value',currentValue)
else
    % pass
end
    
set(handles.alignmentSelector,'String',alignCrosses);

% thisAlign = alignCrosses{currentValue};

%% subalignment (hard-coded to conventions used in the study, sorry!)

if strcmpi(analysisType,'kinematics') || strcmpi(thisSubContext,'kinematics')
    subAlignIdxVals = cellstr( num2str((1:5)') );
else
    subAlignIdxVals = cellstr( num2str((1:3)') );
end

[subAlignTest,subAlignTrain] = meshgrid( subAlignIdxVals );
subAlignCrosses = strcat(subAlignTrain(:),'-train/',subAlignTest(:),'-test');

currentValue = get(handles.subAlignmentSelector,'Value');
if currentValue > numel(subAlignCrosses)
    currentValue = 1;
    set(handles.alignmentSelector,'Value',currentValue)
else
    % pass
end
    
set(handles.subAlignmentSelector,'String',subAlignCrosses);

%% area
if strcmpi(analysisType,'kinematics') || strcmpi(thisSubContext,'kinematics')
    set(handles.areaSelector,'String','N/A' );
    set(handles.areaSelector,'Value',1);
else
    set(handles.areaSelector,'String',fieldnames( cellThisSesh.data.cstruct.Nstruct ) );
    set(handles.areaSelector,'Value',1);
end

%% update plots
updatePeakAccuracy(hObject, eventdata, handles);

return