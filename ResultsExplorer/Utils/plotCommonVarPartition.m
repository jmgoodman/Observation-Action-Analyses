function plotCommonVarPartition(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes a plot similar to dimSweep, except instead of showing variance
% captured overall, it plots the fraction of variance within each subspace
% which is condition-independent

%% step 1: import data
%%
% step 1: get the target session (may need to replace with iterative
% process if pooling across sessions)

seshNames = get(handles.sessionSelector,'String');
seshInd   = get(handles.sessionSelector,'Value');
thisSesh  = seshNames{seshInd};

allSessionData  = getappdata(handles.output,'allSessionsCommonSpace');

% find all with the same animal
thisAnimal = regexpi( thisSesh,'\d*','split' );
thisAnimal = thisAnimal{1};
sessions2select = cellfun(@(x) ~isempty( regexpi(x,thisAnimal,'once') ),...
    seshNames);

if strcmpi(thisAnimal,'Zara')
    sessions2select(4) = false; % ignore the session with way fewer units than the others (<30 per subsample!) & which therefore tells a muddier story
end

commonSpaceData = allSessionData(sessions2select);

%% step 2: get the data you need
% use the full data, not a subsample iteration (the latter is for stats!)
% also make it a projection on the optimal plane
% note: exec_ and obs_ come pre-demeaned (in fact, they reflect the top 30
% dimensions of PCA!)
% this also applies to exec and obs (i.e., the projections onto the optimal
% subspaces)
% 200 samples per object

byObjectTraces = cellfun(@(sesh) ... % for each session
    cellfun(@(x) ... % for each subsample
    cellfun(@(y,z) ... % for each dimensionality (consider both contexts, y and z)
    reshape( ...
    permute( cat( 4,...
    reshape(y,200,[],size(y,2)),...
    reshape(z,200,[],size(z,2)) ...
    ),... % concatenates different contexts, (time x alignment) x object x dimension x context
    [1,3,2,4] ),... % reorders dimensions, (time x alignment) x dimension x object x context
    200,size(y,2),[] ), ... % reshapes array, (time x alignment) x dimension x (object x context)
    x.exec,x.obs,'uniformoutput',false),...
    sesh.subsamples(1:(end-1)),'uniformoutput',false ),...
    commonSpaceData,'uniformoutput',false);

contextIndependentMeans = cellfun(@(sesh) ... % for each session
    cellfun(@(x) ... % for each subsample
    cellfun(@(y) ... % for each dimensionality
    mean(y,3),... % average across all (object x context), gives (time x alignment) x dimension
    x,'uniformoutput',false),...
    sesh,'uniformoutput',false),...
    byObjectTraces,'uniformoutput',false);

% note: instead of comparing to TOTAL variance in the subspace, compare
% instead to the variance captured by the mean across contexts (which tends
% to be a pretty high fraction of the total variance anyway, by design)
% (you end up uniformly shaving 10 percentage points off the denominator by
% doing it this way)
% (indeed, this helps motivate the decision to treat each context
% separately instead of trying to force cross-classification through: the
% kinematics are just too different, and maybe our attempts to find a
% common space are failing to find grip specificity for that reason!)
meansAcrossContextsButNotObjects = cellfun(@(sesh) ... % for each session
    cellfun(@(x) ... % for each subsample
    cellfun(@(y,z) ... % for each dimensionality (consider both contexts, y and z)
    mean( ...
    permute( cat( 4,...
    reshape(y,200,[],size(y,2)),...
    reshape(z,200,[],size(z,2)) ...
    ),... % concatenates different contexts, (time x alignment) x object x dimension x context
    [1,3,2,4] ),... % reorders dimensions, (time x alignment) x dimension x object x context
    4 ), ... % mean across dim 4, gives (time x alignment) x dimension x object
    x.exec,x.obs,'uniformoutput',false),...
    sesh.subsamples(1:(end-1)),'uniformoutput',false ),...
    commonSpaceData,'uniformoutput',false);

contextResiduals = cellfun(@(sesh0,sesh1) ... % for each session
    cellfun(@(x0,x1) ... % for each subsample
    cellfun(@(y0,y1) ... % for each dimensionality
    bsxfun(@minus,y0,y1),...
    x0,x1,'uniformoutput',false),...
    sesh0,sesh1,'uniformoutput',false),...
    meansAcrossContextsButNotObjects,contextIndependentMeans,'uniformoutput',false);

totalVar = cellfun(@(sesh) ... % for each session
    cellfun(@(x) ... % for each subsample
    cellfun(@(y) ... % for each dimensionality
    sum(y(:).^2),...
    x),...
    sesh,'uniformoutput',false),...
    meansAcrossContextsButNotObjects,'uniformoutput',false);

residVar = cellfun(@(sesh) ... % for each session
    cellfun(@(x) ... % for each subsample
    cellfun(@(y) ... % for each dimensionality
    sum(y(:).^2),...
    x),...
    sesh,'uniformoutput',false),...
    contextResiduals,'uniformoutput',false);

% concatenate across subsamples, get area x dimensionality x subsample
residVar = cellfun(@(sesh) ... % for each session
    cat(3,sesh{:}),...
    residVar,'uniformoutput',false);

totalVar = cellfun(@(sesh) ... % for each session
    cat(3,sesh{:}),...
    totalVar,'uniformoutput',false);

% now get the FVE
FVE = cellfun(@(seshresid,seshtotal) ...
    1 - seshresid./seshtotal,...
    residVar,totalVar,'uniformoutput',false);

% now rearrange to get in order of pooled-AIP-F5-M1
FVE = cellfun(@(sesh) ...
    sesh([4,1:3],:,:), ...
    FVE,'uniformoutput',false);

% take means and sds across subsamples
FVEmu = cellfun(@(sesh) ...
    mean(sesh,3),...
    FVE,'uniformoutput',false);
FVEsd = cellfun(@(sesh) ...
    std(sesh,0,3),...
    FVE,'uniformoutput',false);

% cat the sessions
FVEmu = cat(3,FVEmu{:});
FVEsd = cat(3,FVEsd{:});

%% step 3: plot
axes(handles.varPartition)
cla

cstruct = defColorConvention();

for areaInd = 1:numel(cstruct.labels)
    hold all
    for sind = 1:size(FVEmu,3)
        errorbar(FVEmu(areaInd,:,sind),FVEsd(areaInd,:,sind),'color',cstruct.colors(areaInd,:),'linewidth',1.5);
    end
end

xlabel('Dimensionality')
ylabel('FVE by the Condition-Independent Component')
box off, axis tight
ylim([0 1])

customlegend(cstruct.labels,'colors',cstruct.colors)