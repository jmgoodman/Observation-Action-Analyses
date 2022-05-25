function plotCommonDimSweep(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes a by-area breakdown of the loss function as a function of
% dimensionality. 
% Panel B!

%%
% step 1: get the target session (may need to replace with iterative
% process if pooling across sessions)

% outputDir = getappdata(handles.output,'analysisOutputsDir');

seshNames = get(handles.sessionSelector,'String');
seshInd   = get(handles.sessionSelector,'Value');
thisSesh  = seshNames{seshInd};
 
% seshFullFileName = fullfile( outputDir,thisSesh,...
%     sprintf('commonspace_results_%s.mat',thisSesh) );

% commonSpaceData = load(seshFullFileName);
allSessionData  = getappdata(handles.output,'allSessionsCommonSpace');

% find all with the same animal
thisAnimal = regexpi( thisSesh,'\d*','split' );
thisAnimal = thisAnimal{1};
sessions2select = cellfun(@(x) ~isempty( regexpi(x,thisAnimal,'once') ),...
    seshNames);

if strcmpi(thisAnimal,'Zara')
    sessions2select(4) = false; % ignore the session with way fewer units than the others (<30 per subsample!) & which therefore tells a muddier story
end

% % override
% sessions2select = false(size(sessions2select));
% sessions2select(seshInd) = true;

commonSpaceData = allSessionData(sessions2select);

% mirrorDataDir   = getappdata(handles.output,'mirrorDataDir');
% dataStructFile  = fullfile( mirrorDataDir,sprintf('%s_datastruct.mat',thisSesh) );
% dataStruct      = load(dataStructFile);
% dataLabels      = extractlabels(dataStruct.datastruct.cellform);

% dataStruct = getappdata(handles.output,'dataStruct');
% dataLabels = getappdata(handles.output,'dataLabels');
% 
% areaNames = get(handles.areaSelector,'String');
% areaInd   = get(handles.areaSelector,'Value');
% thisArea  = areaNames{areaInd};

% if strcmpi(thisArea,'pooled')
%     thisArea = 'all';
% else
%     % pass
% end

%% step 2: get the data you need
% use the full data, not a subsample iteration (the latter is for stats!)
% also make it a projection on the optimal plane
% note: exec_ and obs_ come pre-demeaned (in fact, they reflect the top 30
% dimensions of PCA!)
varExplained = cellfun(@(sesh) cellfun(@(x) 1 - bsxfun(@times, x.lossfunction, ...
    1./cellfun(@(y,z) norm(y,'fro').^2 + norm(z,'fro').^2,...
    x.exec_,x.obs_) ),sesh.subsamples(1:(end-1)),...
    'uniformoutput',false), commonSpaceData,'uniformoutput',false);

% average & standard deviation across iterations
varExplainedLoaf = cellfun(@(x) cat(3,x{:}),varExplained,'uniformoutput',false);
VEmu = cellfun(@(x) mean(x,3),varExplainedLoaf,'uniformoutput',false);
VEsd = cellfun(@(x) std(x,0,3),varExplainedLoaf,'uniformoutput',false);

VEmu = cat(3,VEmu{:});
VEsd = cat(3,VEsd{:});

VEmu = VEmu([4,1:3],:,:);
VEsd = VEsd([4,1:3],:,:);

%% step 3: plot
axes(handles.dimSweep)
cla

cstruct = defColorConvention();

for areaInd = 1:numel(cstruct.labels)
    hold all
    for sind = 1:size(VEmu,3)
        errorbar(VEmu(areaInd,:,sind),VEsd(areaInd,:,sind),'color',cstruct.colors(areaInd,:),'linewidth',1.5);
    end
end

customlegend(cstruct.labels,'colors',cstruct.colors)

% print unit counts and subsample sizes
disp('------------------------------------------------------------------------------------------------------------------------------------------------')
subsampcounts = cellfun(@(x) numel(x), allSessionData{seshInd}.subsamples{1}.subspacecell(:,1));
subsampcounts = subsampcounts([4,1:3]);
subsampcell   = cellfun(@(x,y) sprintf('%s subsample size: %i',x,y),cstruct.labels(:),num2cell(subsampcounts(:)),'uniformoutput',false);
disp( char( subsampcell ) )
disp('------------------------------------------------------------------------------------------------------------------------------------------------')
ucounts = cellfun(@(x) numel(x), allSessionData{seshInd}.subsamples{end}.subspacecell(:,1));
ucounts = ucounts([4,1:3]);
ucountscell   = cellfun(@(x,y) sprintf('%s population size: %i',x,y),cstruct.labels(:),num2cell(ucounts(:)),'uniformoutput',false);
disp( char( ucountscell ) )
disp('------------------------------------------------------------------------------------------------------------------------------------------------')

% put it in the table
set(handles.commonStats,'ColumnName',{'Subsample_size','Population_size'})
set(handles.commonStats,'RowName',cstruct.labels)
set(handles.commonStats,'Data',[ subsampcounts(:), ucounts(:) ])
