function loadClassifyData(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this loads in the data for the particular animal

%% step 1: get animal name
seshIdx   = get(handles.sessionSelector,'Value');
seshNames = get(handles.sessionSelector,'String');
thisSesh  = seshNames{seshIdx};

animalName = regexp(thisSesh,'\d+','split');
animalName = animalName{1};

%% step 2: get all sessions for this animal
thisAnimalInds = cellfun(@(x) ~isempty( regexp(x,animalName,'once') ),...
    seshNames );

thisAnimalSessionNames = seshNames(thisAnimalInds);
classifyCell           = cell(size(thisAnimalSessionNames));

analysisOutputsDir     = getappdata(handles.output,'analysisOutputsDir');

for seshInd = 1:numel(thisAnimalSessionNames)
    thisSession = thisAnimalSessionNames{seshInd};
    file2load = fullfile(analysisOutputsDir,thisSession,...
        sprintf('classification_results_%s.mat',thisSession));
    classifyCell{seshInd}.data   = load(file2load);
    classifyCell{seshInd}.seshID = thisSession;
end

setappdata(handles.output,'classifyCell',classifyCell)

% save the names of the seleted sessions too
setappdata(handles.output,'thisAnimalSessionNames',thisAnimalSessionNames);

%% step 2.5: load all_classmats
allClassmatsFile = fullfile(analysisOutputsDir,'all-sessions-classmats.mat');
allClassmats = load(allClassmatsFile);
setappdata(handles.output,'allClassmats',allClassmats.classmats);

%% step 3: set the levels
analysisTypes = fieldnames( classifyCell{1}.data.copts );
set(handles.controlSelector,'String',analysisTypes);
set(handles.controlSelector,'Value',1);

thisType = analysisTypes{1};

contextNames = fieldnames( classifyCell{1}.data.copts.(thisType) );

set(handles.contextSelector,'String',contextNames);
set(handles.contextSelector,'Value',1);

thisContext = contextNames{1};

subContextNames = fieldnames( classifyCell{1}.data.cstruct.(thisType) );
if ~strcmpi(thisType,'kinematics')
    set(handles.subContextSelector,'String',subContextNames);
    set(handles.subContextSelector,'Value',1);
else
    set(handles.subContextSelector,'String','N/A');
    set(handles.subContextSelector,'Value',1);
end

thisSubContext = subContextNames{1};

% collect contexts (only 1 cross-context comparison, but still, we should
% support it)
[contextTest,contextTrain] = meshgrid( classifyCell{1}.data.copts.(thisType).(thisContext).targetcontexts );
alignCrosses = strcat( contextTrain(:),'-train/',contextTest(:),'-test' );

set(handles.contextComparisonSelector,'String',alignCrosses)
set(handles.contextComparisonSelector,'Value',1)

% subsample x context x context x align x align x subalign x subalign
% collect alignments
[alignTest,alignTrain] = meshgrid( classifyCell{1}.data.copts.(thisType).(thisContext).alignment );

alignCrosses = strcat( alignTrain(:),'-train/',alignTest(:),'-test' );

set(handles.alignmentSelector,'String',alignCrosses)
set(handles.alignmentSelector,'Value',1)

% if kinematic, 5 subaligns. otherwise, 3.
if strcmpi(thisType,'kinematics') || strcmpi(thisSubContext,'kinematics')
    subAlignIdxVals = cellstr( num2str((1:5)') );
else
    subAlignIdxVals = cellstr( num2str((1:3)') );
end

[subAlignTest,subAlignTrain] = meshgrid( subAlignIdxVals );
subAlignCrosses = strcat(subAlignTrain(:),'-train/',subAlignTest(:),'-test');

set(handles.subAlignmentSelector,'String',subAlignCrosses)
set(handles.subAlignmentSelector,'Value',1)

if strcmpi(thisType,'kinematics') || strcmpi(thisSubContext,'kinematics')
    set(handles.areaSelector,'String','N/A' );
    set(handles.areaSelector,'Value',1);
else
    set(handles.areaSelector,'String',fieldnames( classifyCell{1}.data.cstruct.Nstruct ) );
    set(handles.areaSelector,'Value',1);
end

% update fields after loading the data
updateFields(hObject, eventdata, handles)

return
