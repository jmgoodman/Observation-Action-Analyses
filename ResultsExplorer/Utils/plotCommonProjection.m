function plotCommonProjection(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes a phase-space plot onto the 2D commonspace projection
% plot 2 contexts (VGG vs Obs) and 2 objects (maximally different). 
% Panel A!

% step 1: get the target session

% outputDir = getappdata(handles.output,'analysisOutputsDir');
% 
% seshNames = get(handles.sessionSelector,'String');
% seshInd   = get(handles.sessionSelector,'Value');
% thisSesh  = seshNames{seshInd};
% 
% seshFullFileName = fullfile( outputDir,thisSesh,...
%     sprintf('commonspace_results_%s.mat',thisSesh) );

% commonSpaceData = load(seshFullFileName);
allSessionData  = getappdata(handles.output,'allSessionsCommonSpace');
sessionIndex    = get(handles.sessionSelector,'Value');
commonSpaceData = allSessionData{sessionIndex};

% mirrorDataDir   = getappdata(handles.output,'mirrorDataDir');
% dataStructFile  = fullfile( mirrorDataDir,sprintf('%s_datastruct.mat',thisSesh) );
% dataStruct      = load(dataStructFile);
% dataLabels      = extractlabels(dataStruct.datastruct.cellform);

% dataStruct = getappdata(handles.output,'dataStruct');
dataLabels = getappdata(handles.output,'dataLabels');

areaNames = get(handles.areaSelector,'String');
areaInd   = get(handles.areaSelector,'Value');
thisArea  = areaNames{areaInd};
thisAreaName = thisArea;

if strcmpi(thisArea,'pooled')
    thisArea = 'all';
    thisAreaName = 'Pooled';
else
    % pass
end

whichDataIn = find( ismember(commonSpaceData.arraynames,...
    thisArea) );

% use the full data, not a subsample iteration (the latter is for stats!)
% also make it a projection on the optimal plane
execData = commonSpaceData.subsamples{end}.exec{whichDataIn,2};
obsData  = commonSpaceData.subsamples{end}.obs{whichDataIn,2};

% concatenated movement onset + hold onset alignments
% extract just the stuff centered on movement onset
movementOnsetIdx = 1:200:size(execData,1);
objCount         = numel(movementOnsetIdx);
execExtracted    = zeros(100,size(execData,2),numel(movementOnsetIdx));
obsExtracted     = zeros(100,size(obsData,2),numel(movementOnsetIdx));

for ii = 1:objCount
    thisObjectAlignedOnMovementOnset = movementOnsetIdx(ii) + (0:99);
    execExtracted(:,:,ii) = execData(thisObjectAlignedOnMovementOnset,:);
    obsExtracted(:,:,ii)  = obsData(thisObjectAlignedOnMovementOnset,:);
end

% find the pair of objects which *maximize* the peak difference between the
% two contexts
bestpair  = [2,1];
maxdelta  = @(pairinds) max( sum( diff( execExtracted(:,:,pairinds),1,3 ).^2,2 ) + ...
    sum( diff( obsExtracted(:,:,pairinds),1,3 ).^2,2 ) );
contextdelta = @(pairinds) max( sum( ( execExtracted(:,:,pairinds(1)) - ...
    obsExtracted(:,:,pairinds(1)) ).^2,2 ) + ...
    sum( ( execExtracted(:,:,pairinds(2)) - ...
    obsExtracted(:,:,pairinds(2)) ).^2,2 ) );
bestdelta = maxdelta(bestpair) - contextdelta(bestpair);

for pairInd1 = 3:objCount
    for pairInd2 = 1:(pairInd1-1)
        thispair  = [pairInd1,pairInd2];
        thisdelta = maxdelta(thispair) - contextdelta(thispair);
        
        if thisdelta > bestdelta
            bestdelta = thisdelta;
            bestpair  = [pairInd1,pairInd2];
        else
            % pass
        end
    end
end

theseObjects = dataLabels.objects.uniquenames(bestpair);
disp(theseObjects);

% print out the variance captured by this plane
edata = commonSpaceData.subsamples{end}.exec_{whichDataIn};
odata = commonSpaceData.subsamples{end}.obs_{whichDataIn};
evar  = sum(var(edata));
ovar  = sum(var(odata));
evar_proj = sum(var(execData));
ovar_proj = sum(var(obsData));

disp('execution variance captured:')
disp(evar_proj / evar);
disp('observation variance captured:')
disp(ovar_proj / ovar);

deltavar = commonSpaceData.subsamples{end}.lossfunction(whichDataIn,2);
totalvar = norm(edata,'fro')^2 + norm(odata,'fro')^2;
disp('FVE across contexts by common manifold');
disp( 1 - deltavar / totalvar );

bestExec = execExtracted(:,:,bestpair);
bestObs  = obsExtracted(:,:,bestpair);

% theseinds = round( linspace(1,objCount,7) );
% bestExec = execExtracted(:,:,theseinds);
% bestObs  = obsExtracted(:,:,theseinds);

contextClors  = lines(2);
% objClors      = lines(7);

axes(handles.projectionPlot);
cla
for objInd = 1:2
    if objInd == 1
        eclor = contextClors(1,:);
        oclor = contextClors(2,:);
    else
        eclor = 0.7 + 0.3*contextClors(1,:);
        oclor = 0.7 + 0.3*contextClors(2,:);
    end
    
    %     eclor = objClors(objInd,:);
    %     oclor = objClors(objInd,:)*0.3 + 0.7;
    
    hold all
    plot(bestExec(:,1,objInd),bestExec(:,2,objInd),'color',eclor,'linewidth',2)
    hold all
    plot(bestObs(:,1,objInd),bestObs(:,2,objInd),'color',oclor,'linewidth',2)
    hold all
    plot(bestExec(1,1,objInd),bestExec(1,2,objInd),'ko','color',eclor,'markerfacecolor',eclor,'linewidth',1,'markersize',10)
    hold all
    plot(bestObs(1,1,objInd),bestObs(1,2,objInd),'ko','color',oclor,'markerfacecolor',oclor,'linewidth',1,'markersize',10)
    hold all
    plot(bestExec(end,1,objInd),bestExec(end,2,objInd),'ks','color',eclor,'markerfacecolor',eclor,'linewidth',1,'markersize',10)
    hold all
    plot(bestObs(end,1,objInd),bestObs(end,2,objInd),'ks','color',oclor,'markerfacecolor',oclor,'linewidth',1,'markersize',10)
    hold all
    plot(bestExec(50,1,objInd),bestExec(50,2,objInd),'k>','color',eclor,'markerfacecolor',eclor,'linewidth',1,'markersize',10)
    hold all
    plot(bestObs(50,1,objInd),bestObs(50,2,objInd),'k>','color',oclor,'markerfacecolor',oclor,'linewidth',1,'markersize',10)
end

axis tight
axis equal
axis square
xl = [ min(get(gca,'xlim')), max(get(gca,'xlim')) ]; xl = xl + [-1 1]*0.1*range(xl);
yl = [ min(get(gca,'ylim')), max(get(gca,'ylim')) ]; yl = yl + [-1 1]*0.1*range(yl);

minlim = min([xl,yl]);
maxlim = max([xl,yl]);

% center on 0
totalmaxlim = max(abs(minlim),abs(maxlim));

xlim(totalmaxlim*[-1,1])
ylim(totalmaxlim*[-1,1])

xlabel(sprintf('%s Common Subspace Factor 1',thisAreaName))
ylabel(sprintf('%s Common Subspace Factor 2',thisAreaName))



return