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

%% step 2: get the data you need (experimental, way too convoluted to report)

% % remove all components which do not vary with time
% % y_c + y_o + y_co = <y>_t
% % y_t   = <y>_co
% % y_c   = <y>_to
% % y_o   = <y>_tc
% % y_tc  = <y>_o - y_t - y_c
% % y_to  = <y>_c - y_t - y_o
% % y_co  = <y>_t - y_c - y_o
% % y_tco = y - y_tc - y_to - y_co - y_t - y_c - y_o
% %       = y - <y>_o - <y>_c - <y>_t + y_c + y_o + y_t
% %
% % y - y_c - y_tc = y - <y>_o + <y>_co
% % <y>_o - <y>_co
% % <y>_o = y_tc + y_t + y_c
% % <y>_co = y_t
% 
% % get the common spaces
% fullCommonSpace = cellfun(@(sesh) ... % for each session
%     cellfun(@(x) ... % for each subsample
%     cellfun(@(y,z) ... % for each dimensionality x array (consider both contexts, y and z)
%     permute( cat( 4,...
%     reshape(y,200,[],size(y,2)),...
%     reshape(z,200,[],size(z,2)) ...
%     ),... % concatenates different contexts, gets (time x alignment) x object x dimension x context
%     [3,4,2,1] ),... % reorders dimensions, gets dimension x context x object x (time x alignment)
%     x.exec,x.obs,'uniformoutput',false),...
%     sesh.subsamples(1:(end-1)),'uniformoutput',false ),...
%     commonSpaceData,'uniformoutput',false);
% 
% % remove the time-invariant component
% fullCommonSpace = cellfun(@(sesh) ...
%     cellfun(@(subsamp) ...
%     cellfun(@(dimXarr) ...
%     bsxfun(@minus,dimXarr,mean(dimXarr,4)),...
%     subsamp,'uniformoutput',false),...
%     sesh,'uniformoutput',false),...
%     fullCommonSpace,'uniformoutput',false);
% 
% % get the full PCA space, which you'll then take PC by PC
% fullPCASpace = cellfun(@(sesh) ... % for each session
%     cellfun(@(x) ... % for each subsample
%     cellfun(@(y,z) ... % for each array (consider both contexts, y and z)
%     permute( cat( 4,...
%     reshape(y,200,[],size(y,2)),...
%     reshape(z,200,[],size(z,2)) ...
%     ),... % concatenates different contexts, gets (time x alignment) x object x dimension x context
%     [3,4,2,1] ),... % reorders dimensions, gets dimension x context x object x (time x alignment)
%     x.exec_,x.obs_,'uniformoutput',false),...
%     sesh.subsamples(1:(end-1)),'uniformoutput',false),...
%     commonSpaceData,'uniformoutput',false);
% 
% % remove the time-invariant component
% fullPCASpace = cellfun(@(sesh) ...
%     cellfun(@(subsamp) ...
%     cellfun(@(dimXarr) ...
%     bsxfun(@minus,dimXarr,mean(dimXarr,4)),...
%     subsamp,'uniformoutput',false),...
%     sesh,'uniformoutput',false),...
%     fullPCASpace,'uniformoutput',false);
% 
% % now we want to find the "common component" - i.e., all variance NOT
% % explained in any way by object- or context-dependent variance
% %
% % this should put the commonspace at a disadvantage, since there's the y_tc
% % component in both the numerator and denominator which should leave it at
% % a disadvantage
% % 
% conditionInvariantCommonSpace = cellfun(@(sesh) ...
%     cellfun(@(subsamp) ...
%     cellfun(@(dimXarr) ...
%     repmat(mean(mean(dimXarr,2),3),1,size(dimXarr,2),size(dimXarr,3),1),...
%     subsamp,'uniformoutput',false),...
%     sesh,'uniformoutput',false),...
%     fullCommonSpace,'uniformoutput',false);
% 
% conditionInvariantPCASpace = cellfun(@(sesh) ...
%     cellfun(@(subsamp) ...
%     cellfun(@(dimXarr) ...
%     repmat(mean(mean(dimXarr,2),3),1,size(dimXarr,2),size(dimXarr,3),1),...
%     subsamp,'uniformoutput',false),...
%     sesh,'uniformoutput',false),...
%     fullPCASpace,'uniformoutput',false);
% 
% % now compute variance capture as a residual
% commonSpace_fullVE = cellfun(@(sesh) ...
%     cellfun(@(subsamp) ...
%     cellfun(@(arrayXdimensionality) ...
%     norm( arrayXdimensionality(:,:),'fro' )^2, ...
%     subsamp),...
%     sesh,'uniformoutput',false),...
%     fullCommonSpace,'uniformoutput',false);
% 
% commonSpace_partVE = cellfun(@(xsesh,ysesh) ...
%     cellfun(@(xsubsamp,ysubsamp) ...
%     cellfun(@(xarrayXdimensionality,yarrayXdimensionality) ...
%     norm( xarrayXdimensionality(:,:) - yarrayXdimensionality(:,:),'fro' )^2, ...
%     xsubsamp,ysubsamp),...
%     xsesh,ysesh,'uniformoutput',false),...
%     fullCommonSpace,conditionInvariantCommonSpace,'uniformoutput',false);
% 
% commonSpace_FVE = cellfun(@(xsesh,ysesh) ...
%     cellfun(@(xsubsamp,ysubsamp) ...
%     1 - xsubsamp ./ ysubsamp,...
%     xsesh,ysesh,'uniformoutput',false),...
%     commonSpace_partVE,commonSpace_fullVE,'uniformoutput',false);
% 
% ndims_ = 30; % hardcoded! bad boy!
% for dims = 1:ndims_
%     temp_fullVE = cellfun(@(sesh) ...
%         cellfun(@(subsamp) ...
%         cellfun(@(array) ...
%         norm( array(1:dims,:),'fro' )^2, ...
%         subsamp),...
%         sesh,'uniformoutput',false),...
%         fullPCASpace,'uniformoutput',false);
%     
%     temp_partVE = cellfun(@(xsesh,ysesh) ...
%         cellfun(@(xsubsamp,ysubsamp) ...
%         cellfun(@(xarray,yarray) ...
%         norm( xarray(1:dims,:) - yarray(1:dims,:),'fro' )^2, ...
%         xsubsamp,ysubsamp),...
%         xsesh,ysesh,'uniformoutput',false),...
%         fullPCASpace,conditionInvariantPCASpace,'uniformoutput',false);
%     
%     temp_FVE = cellfun(@(xsesh,ysesh) ...
%         cellfun(@(xsubsamp,ysubsamp) ...
%         1 - xsubsamp ./ ysubsamp,...
%         xsesh,ysesh,'uniformoutput',false),...
%         temp_partVE,temp_fullVE,'uniformoutput',false);
%     
%     if dims == 1
%         PCASpace_FVE = temp_FVE;
%     else
%         PCASpace_FVE = cellfun(@(xsesh,ysesh) ...
%             cellfun(@(xsubsamp,ysubsamp) ...
%             horzcat(xsubsamp,ysubsamp), ...
%             xsesh,ysesh,'uniformoutput',false),...
%             PCASpace_FVE,temp_FVE,'uniformoutput',false);
%     end
%     clear temp_fullVE temp_partVE temp_FVE
% end
% 
% % okay now things make sense: if you just focus on the time-varying
% % component to work around residual visual stuff, 
% % then the fraction of common-space variance captured by the
% % commonspace is greater than that captured by PCA (presumably because
% % y_tco is wiped out by hte former)
% % but this is WAY too convoluted to explain
% % just leave the plot as it was
% % and just explain "there sure is a lot of context-independent variance
% % here, huh? we better use powerful classifiers to pull out the
% % action-specific component"
    
    
%% step 2: get the data you need (old version)
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
% ---------------------------
% UGHHH but I wanna compare against PCA
% What's the appropriate denominator THERE?
% well you still wanna look at the cross-context component, right?
% yeah, because we use classification to then dig into action specificity
% PER SE
% this is all about action specificity in the SHARED space
% but wait, isn't taking the cross-context mean and variance partitioning
% that going to just give you the same damn answer?
% it's just computing the same damn thing but in two slightly different
% ways!
% i.e. the dPCA way vs. the manopt way!
% FUCK
% okay, so here's the deal:
% 1) we apply PCA to the data as-is (including the contextual differences)
% 2) we partition both the PCA and the commonspace variance according to
% the action-specific component
% 3) quantify FVEs by the action-specific components, show the commonspace
% actively avoids action-specific variance to an extent that PCA does NOT
% 
% This is an appropriate null. Don't try to subtract the condition-specific
% mean PETHs across objects or whatever, because then you're just skinning
% the cat a different way and probably shouldn't expect a different result.
%
% What we want to know is: if we just consider the dimensions where
% differences between action and observation are minimized, do we get a
% lower fraction of object-specific variance than if we just took PCA? What
% we're controlling for is the prevalence of a condition-invariant
% component *per se*
% ---------------------------


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