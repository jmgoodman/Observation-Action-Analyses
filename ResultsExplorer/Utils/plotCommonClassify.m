function plotCommonClassify(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes a by-area breakdown of the classification accuracy prior to
% orthogonalization, after orthogonalization, and after further restricting
% yourself to the "common" subspace capturing the most variance. 
% (No "aggro" orthogonalization because we never applied aggro ortho to the
% commonspace pipeline, so no way to compare)
% Panel C!

% classification cell structure:
% subsamp x context x context x align x align x subalign x subalign
% within: fold
% within-within: area (with chance level appended)

%% step 1: import data
seshNames = get(handles.sessionSelector,'String');
seshInd   = get(handles.sessionSelector,'Value');
thisSesh  = seshNames{seshInd};

classifyCell  = getappdata(handles.output,'classifyCell');

% % find all with the same animal
% thisAnimal = regexpi( thisSesh,'\d*','split' );
% thisAnimal = thisAnimal{1};
% sessions2select = cellfun(@(x) ~isempty( regexpi(x,thisAnimal,'once') ),...
%     seshNames);

% actually pool all animals for this analysis
sessions2select = true(size(classifyCell));
sessions2select(4) = false; % ignore the session with way fewer units than the others (<30 per subsample!) & which therefore tells a muddier story

% DO extract the first letter of each name tho
firstLetters = cellfun(@(x) x(1),seshNames,'uniformoutput',false);

classifyData  = classifyCell(sessions2select);
firstLetters  = firstLetters(sessions2select);

%% step 2: arrange into matrices

newCell = cell(size(classifyData));
% step 2.1: cat
for seshind = 1:numel(classifyData)
    cD = classifyData{seshind};
    fn = fieldnames(cD);
    
    for fieldind = 1:numel(fn)
        thisField = fn{fieldind};
        
        activepassive = {'active','passive'};
        
        for apind = 1:2
            thisap = activepassive{apind};
                                
            cdTemp = cellfun(@(y) mean(horzcat(y{:}),2),cD.(thisField).(thisap),'uniformoutput',false);
            cdTemp = squeeze(cdTemp); % squeeze out the cross-context dims
        
            % next, arrange the outer level as appropriate
            % ughhhh my brain does NOT want to work
            %
            % okay so we have 20x3x3x3x3
            % subsamples x align x align x subalign x subalign
            % also recall things go in order from train-to-test
            % so (1,2) trains on 1 and tests on 2, for instance
            %
            % for self-trained movement-tested we want:
            % (1:20) x ( (2,2),(3,3) ) x ( (1,1),(2,2),(3,3) )
            %
            % for cross-trained movement-tested we want:
            % (1:20) x ( (1,2),(1,3) ) x all
            
            % take max along dim 2
            % after taking mean along dim 1
            
            % SELF
            tempSelfTrained = cat(4, squeeze( cdTemp(:,2,2,:,:) ), ...
                squeeze( cdTemp(:,3,3,:,:) ) );
            tempSelfTrained = cat(2,squeeze( tempSelfTrained(:,1,1,:) ),...
                squeeze( tempSelfTrained(:,2,2,:) ),...
                squeeze( tempSelfTrained(:,3,3,:) ) );
            tempSelfTrained = cellfun(@(x) permute(x,[2,3,1]),tempSelfTrained,...
                'uniformoutput',false);
            tempSelfTrained = cell2mat(tempSelfTrained); % now should be: subsamp x (align x subalign) x area
            
            selfTrainedMu = squeeze( mean(tempSelfTrained,1) );
            selfTrainedSd = squeeze( std(tempSelfTrained,0,1) ); % std is appropriate here
            % now we have (align x subalign) x area
            % take max mean across this first dimension
            % apply this to chance, too! not that it matters, it's always a
            % theoretical calculation (which might be unfair?)
            [maxSelfTrainedMu,maxind] = max(selfTrainedMu,[],1);
            maxSelfTrainedSd = nan(size(maxSelfTrainedMu));
            for colInd = 1:numel(maxind)
                maxSelfTrainedSd(colInd) = selfTrainedSd(maxind(colInd),colInd);
            end
            
            % CROSS
            tempCrossTrained = cat(4, squeeze( cdTemp(:,1,2,:,:) ), ...
                squeeze( cdTemp(:,1,3,:,:) ) );
            tempCrossTrained = tempCrossTrained(:,:);
            tempCrossTrained = cellfun(@(x) permute(x,[2,3,1]),tempCrossTrained,...
                'uniformoutput',false);
            tempCrossTrained = cell2mat(tempCrossTrained); % now should be: subsamp x (align x subalign) x area
            
            crossTrainedMu = squeeze( mean(tempCrossTrained,1) );
            crossTrainedSd = squeeze( std(tempCrossTrained,0,1) ); % std is appropriate here
            % now we have (align x subalign) x area
            % take max mean across this first dimension
            % apply this to chance, too! not that it matters, it's always a
            % theoretical calculation (which might be unfair?)
            [maxCrossTrainedMu,maxind] = max(crossTrainedMu,[],1);
            maxCrossTrainedSd = nan(size(maxCrossTrainedMu));
            for colInd = 1:numel(maxind)
                maxCrossTrainedSd(colInd) = crossTrainedSd(maxind(colInd),colInd);
            end
            
            newStruct.(thisField).(thisap).crossmu = maxCrossTrainedMu;
            newStruct.(thisField).(thisap).crosssd = maxCrossTrainedSd;
            newStruct.(thisField).(thisap).selfmu  = maxSelfTrainedMu;
            newStruct.(thisField).(thisap).selfsd  = maxSelfTrainedSd;
        end
        
    end
    newCell{seshind} = newStruct;
end




%% plan:
% compare vision vs. movement-period? might be necessary given conservative
% ortho's inability to make performance sink below chance
%
% pre-vs-post orthogonalization? probably NOT needed, the main point of
% this figure is to show that a restriction to the common space has a 
% deleterious effect
%
% compare obs vs. exe? obviously, we then get to tease that exe is the only
% one with object selectivity per se
%
% so here's how it'll probably work:
% scatterplot of regular vs. commonspace-restricted performance
% put all areas & monkeys on the same scatterplot
% have separate plots for obs vs exe
% have separate plots for vision vs. movement-period 
% (so a 2x2 grid, context x alignment)
% (maybe even show that the commonspace doesn't really affect residual
% visual classification?)

%% alright time to plot
% pre- and post-commonspace
prepost = {'regularpostortho','commonspace'};
ap      = {'active','passive'};

prepostnames = {'Fullspace','Subspace'};

cstruct = defColorConvention();

axind = 0;
for prepostID = 1:2
    thisprepost = prepost{prepostID};
    for apID = 1:2
        thisap = ap{apID};
        
        thisplot = sprintf('classifyPlot%i',axind);
        axes( get(handles,thisplot) )
        
        thisCell = cellfun(@(x) x.(thisprepost).(thisap),newCell,...
            'uniformoutput',false);
        
        
    end
end
        
        




