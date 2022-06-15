function updateFigureGripClassification(hObject, eventdata, handles) %#ok<INUSL>
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this updates the figure depicting grip classification over time

%%
% grab a couple key data
classmats = getappdata(handles.output,'classmats');

monkeyIdx   = get(handles.monkeySelector,'Value');
monkeys     = get(handles.monkeySelector,'String');
monkey      = monkeys{monkeyIdx}; % singular

analysisIdx = get(handles.analysisSelector,'Value');
% 1. Base Result
% 2. Why Ortho? Visual cross-training
% 3. Why Ortho? Special Turntable
% 4. Preserved Grip Representation? MGG cross-training
% 5. Preserved Grip Representation? Preferential boost of grip clustering

testContextIdx = get(handles.testContextSelector,'Value');
testContexts   = get(handles.testContextSelector,'String');
testContext    = testContexts{testContextIdx}; % singular

preprocessingIdx = get(handles.preprocessingSelector,'Value');
preprocessings   = get(handles.preprocessingSelector,'String');
preprocessing    = preprocessings{preprocessingIdx}; % singular

gripClusteringIdx = get(handles.gripClusteringSelector,'Value');
gripClusterings   = get(handles.gripClusteringSelector,'String');
gripClustering    = gripClusterings{gripClusteringIdx}; % singular

%% now pick the slice of classmats you wanna look at

switch monkey
    case 'Moe'
        targetSessions = {'Moe46','Moe50'}; % hard-coded, I know, poor form, but I've resolved that this ain't gonna scale.
    case 'Zara'
        targetSessions = {'Zara64','Zara70'}; % ignore session 68 due to its low subsample count.
end

classmatCell = cell(size(targetSessions));

for sessionIdx = 1:numel(targetSessions)
    thisSession = targetSessions{sessionIdx};
    cmat        = classmats.(thisSession);
    classmatCell{sessionIdx} = cmat;
end

% now set some other access parameters
% {'VGG','Obs.'}
switch testContext
    case 'VGG'
        contextField = 'active';
    case 'Obs.'
        contextField = 'passive';
end

% {'none','orthogonal','aggressively orthogonal','mirror metric median split'}
medianSplitOverride = false;
switch preprocessing
    case 'none'
        preprocessingField = 'preortho';
    case 'orthogonal'
        preprocessingField = 'postortho';
    case 'aggressively orthogonal'
        preprocessingField = 'postortho_aggro';
    case 'mirror metric median split'
        medianSplitOverride = true;
        preprocessingField = 'preortho';
end

% {'none','clustered'}
switch gripClustering
    case 'none'
        analysisTypeField = 'normal'; % can be overridden depending on analysis type or median splitting
    case 'clustered'
        analysisTypeField = 'kinclust';
end

if medianSplitOverride
    analysisTypeField = 'mediansplit';
end

% remember the order of the areas:
% AIP - F5 - M1 - pooled - chance

% also the order of the dimensions per se:
% train x test x array

% here are the epoch names:
% epochNames = {'Baseline','Object Viewing','Late Viewing/Memory','Transport-aligned movement','Contact-aligned movement','Post-contact'};
% getappdata(handles.output,'epochNames');
% 
% here are the indices that correspond with them:
% baseline: 1
% object viewing: 2:3
% late viewing/memory: 4
% transport-aligned movement: 5:6
% contact-aligned movement: 7
% post-contact: 8:9

switch analysisIdx
    case 1
        theseMats = cellfun(@(session) ...
            session.(analysisTypeField).(preprocessingField).(contextField).stack,...
            classmatCell,'uniformoutput',false); % training (context x align x subalign) x testing (context x align x subalign) x array x subsample x fold
    
    case 2
        % restricted to all those trained on the object viewing epochs,
        % i.e., those aligned to illumination onset (take max across all
        % cross-trainings as your "canonical" value)
        theseMats = cellfun(@(session) ...
            session.(analysisTypeField).(preprocessingField).(contextField).stack(1:3,:,:,:,:),...
            classmatCell,'uniformoutput',false);
        
    case 3 % special TT, overrides task selection
        theseMats = {};
        for sessionIdx = 1:numel(classmatCell)
            if isfield(classmatCell{sessionIdx},'special')
                thisCell = classmatCell{sessionIdx}.special.(preprocessingField).(contextField).stack;
                theseMats = vertcat(theseMats,thisCell); %#ok<AGROW>
            else
                % pass
            end
        end
        
    case 4
        analysisTypeField = 'withMGG'; % override for this context, too
        % restricted to all those trained on MGG ("control", which comes
        % second) and tested on VGG ("active", which comes first)
        theseMats = cellfun(@(session) ...
            session.(analysisTypeField).(preprocessingField).(contextField).stack(10:end,1:9,:,:,:),...
            classmatCell,'uniformoutput',false);
        
    case 5 % again, actually just a subset of the info offered by analysis context 1, but curated better.
        theseMats = cellfun(@(session) ...
            session.(analysisTypeField).(preprocessingField).(contextField).stack,...
            classmatCell,'uniformoutput',false);
end

% concatenate the cells
catCells = cat(6,theseMats{:}); % 6th dim will now be session

% take the mean across folds
meanOverFolds = squeeze( mean(catCells,5) ); % now the 5th dim is session
meanOverFoldsSize = size(meanOverFolds);


% now diagonalize if size(x,1) == size(x,2)
% otherwise take the max along the training dimension
if size(meanOverFolds,1) == size(meanOverFolds,2)
    nDiag = size(meanOverFolds,1);
    
    
    newMat = zeros([nDiag,meanOverFoldsSize(3:end)]);
    
    for diagInd = 1:nDiag
        newMat(diagInd,:,:,:) = ...
            squeeze( meanOverFolds(diagInd,diagInd,:,:,:) );
    end
    
else
    % temporarily take mean over subsamples
    tempSubsampleMean = squeeze( mean( meanOverFolds,4 ) ); % now dim 4 = session
    
    % get maxima (shouldn't matter for chance level since it's always the
    % same across alignments...)
    [~,idx] = max(tempSubsampleMean,[],1);
    idx = squeeze(idx);
    
    newMat = zeros( meanOverFoldsSize(2:end) );
    for ind = 1:numel(idx)
        [testAlign,area,session] = ind2sub( size(idx),ind );
        slice = squeeze( meanOverFolds(idx(ind),testAlign,area,:,session) );
        newMat(testAlign,area,:,session) = slice;
    end
end

% take the mean & standard deviation across subsamples
mu = squeeze( mean(newMat,3) );
sd = squeeze( std(newMat,0,3) );

% group the alignments
% here are the epoch names:
% epochNames = {'Baseline','Object Viewing','Late Viewing/Memory','Transport-aligned movement','Contact-aligned movement','Post-contact'};
% getappdata(handles.output,'epochNames');
% 
% here are the indices that correspond with them:
% baseline: 1
% object viewing: 2:3
% late viewing/memory: 4
% transport-aligned movement: 5:6
% contact-aligned movement: 7
% post-contact: 8:9

epochNames = getappdata(handles.output,'epochNames');

%% NEW: keep distinct subalignments, just give them reasonable names
newmu = mu;
newsd = sd;

%% OLD: from when I wanted to pool subalignments.
% newmu = zeros( numel(epochNames), size(mu,2), size(mu,3) );
% newsd = zeros( numel(epochNames), size(mu,2), size(mu,3) );
% 
% % almost certainly a better way to do this but whatever
% for epochInd = 1:numel(epochNames)
%     %     epochName = epochNames{epochInd};
%     switch epochInd
%         case 1
%             newmu(epochInd,:,:) = mu(1,:,:);
%             newsd(epochInd,:,:) = sd(1,:,:);
%         case 2
%             %             keepinds = 2:3;
%             %             [newmu(epochInd,:,:),idx] = max(mu(keepinds,:,:),[],1);
%             %             % okay matlab requires very particular shit to avoid edge cases
%             %             % that arise from all the bullshit it's doing under the hood
%             %             % so here we go
%             %             idx = permute(idx,[2,3,1]); % squeeze like this to avoid weird edge cases
%             %             for ii = 1:numel(idx)
%             %                 idx(ii) = keepinds(idx(ii)); % preserve shape when indexing like this
%             %             end
%             %             sz  = size(idx);
%             %             for ii = 1:numel(idx)
%             %                 [area,session] = ind2sub(sz,ii);
%             %                 newsd(epochInd,area,session) = ...
%             %                     sd( idx(ii),area,session );
%             %             end
%             newmu(epochInd,:,:) = mu(3,:,:); % make it truly post-alignment and don't include aynthing centered on the alignment
%             newsd(epochInd,:,:) = sd(3,:,:);
%         case 3
%             newmu(epochInd,:,:) = mu(4,:,:);
%             newsd(epochInd,:,:) = sd(4,:,:);
%         case 4
%             %             keepinds = 5:6;
%             %             [newmu(epochInd,:,:),idx] = max(mu(keepinds,:,:),[],1);
%             %             idx = permute(idx,[2,3,1]); % squeeze like this to avoid weird edge cases
%             %             for ii = 1:numel(idx)
%             %                 idx(ii) = keepinds(idx(ii)); % preserve shape when indexing like this
%             %             end
%             %             sz  = size(idx);
%             %             for ii = 1:numel(idx)
%             %                 [area,session] = ind2sub(sz,ii);
%             %                 newsd(epochInd,area,session) = ...
%             %                     sd( idx(ii),area,session );
%             %             end
%             newmu(epochInd,:,:) = mu(6,:,:); % make it truly post-alignment and don't include aynthing centered on the alignment
%             newsd(epochInd,:,:) = sd(6,:,:);
%         case 5
%             newmu(epochInd,:,:) = mu(7,:,:);
%             newsd(epochInd,:,:) = sd(7,:,:);
%         case 6
%             %             keepinds = 8:9;
%             %             [newmu(epochInd,:,:),idx] = max(mu(keepinds,:,:),[],1);
%             %             idx = permute(idx,[2,3,1]); % squeeze like this to avoid weird edge cases
%             %             for ii = 1:numel(idx)
%             %                 idx(ii) = keepinds(idx(ii)); % preserve shape when indexing like this
%             %             end
%             %             sz  = size(idx);
%             %             for ii = 1:numel(idx)
%             %                 [area,session] = ind2sub(sz,ii);
%             %                 newsd(epochInd,area,session) = ...
%             %                     sd( idx(ii),area,session );
%             %             end
%             newmu(epochInd,:,:) = mu(9,:,:); % make it truly post-alignment and don't include aynthing centered on the alignment
%             newsd(epochInd,:,:) = sd(9,:,:);
%     end
% end

%%
% now make a plot
colorStruct = getappdata(handles.output,'colorStruct');
areamu = newmu(:,[4,1:3],:); % pooled-AIP-F5-M1 convention\
areasd = newsd(:,[4,1:3],:);
chanceLevel = mean( squeeze( newmu(1,5,:) ) );

axis(handles.accuracyPlot);
cla;

shiftval = -( size(areamu,2)*size(areamu,3) - 1 )/2;
for areaind = 1:size(areamu,2)
    for seshind = 1:size(areamu,3)
        mutrace = areamu(:,areaind,seshind);
        sdtrace = areasd(:,areaind,seshind);
        
        % split up by alignment
        mutrace = [mutrace(1:3);nan;mutrace(4:6);nan;mutrace(7:9)];
        sdtrace = [sdtrace(1:3);nan;sdtrace(4:6);nan;sdtrace(7:9)];
        xtrace  = [1:3,3.5,4:6,6.5,7:9]';
        
        hold all
        errorbar( xtrace + shiftval*0.02,mutrace,sdtrace,...
            'linewidth',1,'color',colorStruct.colors(areaind,:))
        shiftval = shiftval + 1;
    end
end

axis tight
hold all
line(get(gca,'xlim'),chanceLevel*[1 1],'linewidth',1,'color',[1 1 1],'linestyle','-')
line(get(gca,'xlim'),chanceLevel*[1 1],'linewidth',0.75,'color',[0 0 0],'linestyle','--')

ylim([0 1])
ylabel('Accuracy')
xlabel('Epoch')
set(gca,'xtick',1:numel(epochNames),'xticklabel',epochNames,'xticklabelrotation',45)

% todo: add in the kinematic classification accuracy at hold as a point of
% comparison
% I don't want anyone eyein' these plots thinkin' the effect is one of
% nondistinct human grips

return
        