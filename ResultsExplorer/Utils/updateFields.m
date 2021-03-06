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
if ~strcmpi(analysisType,'kinematics')
    contextNames = fieldnames( cellThisSesh.data.copts.(analysisType) );
else
    contextNames = fieldnames( cellThisSesh.data.cstruct.(analysisType) ); % no subcontext to wade through...
end

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

% if subcontext = kinematics, reset context according to the kinematic
% classifier
if strcmpi(thisSubContext,'kinematics')
    contextNames = fieldnames( cellThisSesh.data.cstruct.kinematics );
    
    currentValue = get(handles.contextSelector,'Value');
    if currentValue > numel(contextNames)
        currentValue = 1;
        set(handles.contextSelector,'Value',currentValue)
    else
        % pass
    end
    
    set(handles.contextSelector,'String',contextNames);
    
    thisContext = contextNames{currentValue};
end

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

setappdata(handles.output,'contextTest',contextTest)
setappdata(handles.output,'contextTrain',contextTrain)

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

% save to appdata
setappdata(handles.output,'alignTest',alignTest)
setappdata(handles.output,'alignTrain',alignTrain)

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
    set(handles.subAlignmentSelector,'Value',currentValue)
else
    % pass
end
    
set(handles.subAlignmentSelector,'String',subAlignCrosses);

% save to appdata
setappdata(handles.output,'subAlignTest',subAlignTest)
setappdata(handles.output,'subAlignTrain',subAlignTrain)

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