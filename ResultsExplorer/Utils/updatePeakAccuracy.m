function updatePeakAccuracy(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this updates the peak accuracy plots based on the field selections in the
% grip classification gui
%
% this particular gui, by the way, is quite rushed.

%% TODO: implement pooling across alignments & subalignments and taking the MAX across them!!!
% this means ignoring subAlignmentValue and re-interpreting alignmentValue

%% step 1: get the fields

% forget about session, that's for the heatmap (which you probably won't
% bother with)

% but do pull up the cell of results
classifyCell = getappdata(handles.output,'classifyCell');

% DO grab analysis type
analysisTypes = get(handles.controlSelector,'String');
currentValue  = get(handles.controlSelector,'Value');
analysisType  = analysisTypes{currentValue};

% also grab context
contextNames  = get(handles.contextSelector,'String');
contextValue  = get(handles.contextSelector,'Value');
contextName   = contextNames{contextValue};

% and the subcontext
subContextNames  = get(handles.subContextSelector,'String');
subContextValue  = get(handles.subContextSelector,'Value');
subContextName   = subContextNames{subContextValue}; % "subcontext" is confusingly just an indication of whether we're orthogonalizing or not. it's entirely an analysis context, not an experimental one!

% and the context comparison (entirely for MGG x VGG)
contextComparisonCount   = numel( get(handles.contextComparisonSelector,'String') );
contextComparisonValue   = get(handles.contextComparisonSelector,'Value');
[trainContextComparison,testContextComparison] = ind2sub(...
    sqrt(contextComparisonCount)*[1 1],contextComparisonValue);

% and the alignment (comparisons always form a square, so sqrt is *fine*)
alignmentCount   = numel( get(handles.alignmentSelector,'String') );
alignmentValue   = get(handles.alignmentSelector,'Value');
[trainAlign,testAlign] = ind2sub(sqrt(alignmentCount)*[1 1],alignmentValue);

% and the subalignment (comparisons always form a square, so sqrt is *fine*)
subAlignmentCount   = numel( get(handles.subAlignmentSelector,'String') );
subAlignmentValue   = get(handles.subAlignmentSelector,'Value');
[trainSubAlign,testSubAlign] = ind2sub(sqrt(subAlignmentCount)*[1 1],...
    subAlignmentValue);

%% now pull the relevant data
data_ = cellfun(@(x) x.data.cstruct.(analysisType),classifyCell,'uniformoutput',false);

if ~strcmpi(subContextName,'N/A')
    data_ = cellfun(@(x) x.(subContextName),data_,'uniformoutput',false);
else
    % pass
end

data_ = cellfun(@(x) x.(contextName),data_,'uniformoutput',false);

%% pull the data
% if no overrides, handle it like this

trainOverrideString = get(handles.trainPoolOverride,'String');
testOverrideString = get(handles.testPoolOverride,'String');
trainOverrideValue = get(handles.trainPoolOverride,'Value');
testOverrideValue = get(handles.testPoolOverride,'Value');

trainOverride = trainOverrideString{trainOverrideValue};
testOverride  = testOverrideString{testOverrideValue};

if strcmpi(trainOverride,'None') && strcmpi(testOverride,'None')
    % for some reason this STILL works if you don't slice dims 4-7 and just squeeze the sliced dimensions.
    % question: WHY
    data_ = cellfun(@(x) squeeze( x(:,trainContextComparison,testContextComparison,...
        trainAlign,testAlign,trainSubAlign,testSubAlign) ),...
        data_,'uniformoutput',false);
    
    % now we have:
    % level 1: sessions
    % level 2: subsamples
    % level 3: kfold
    % level 4: (double, not cell) pool - AIP - F5 - M1 - chance
    
    % take the average across folds within each subsample
    foldaverage = cellfun(@(session) ...
        cellfun(@(subsample) ...
        mean(horzcat(subsample{:}),2),session,'uniformoutput',false),...
        data_,'uniformoutput',false);
    
    % level 1: sessions
    % level 2: subsamples
    % level 3: (double, not cell) AIP - F5 - M1 - pooled - chance
    % (crossclassify_refactor confirms this)
    
    % turn subsamples into columns
    foldaverage = cellfun(@(session) ...
        horzcat(session{:}),foldaverage,'uniformoutput',false);
    
    % count sessions and areas
    nsesh = numel(foldaverage);
    narea = size( foldaverage{1},1 ) - 1;
    
    % and rearrange the rows to match the color convention
    colorStruct = getappdata(handles.output,'colorStruct');
    if narea == numel(colorStruct.labels)
        foldaverage = cellfun(@(session) ...
            session([4,1:3,5],:),foldaverage,'uniformoutput',false);
    else
        colorStruct.colors = zeros(narea,3);
        colorStruct.labels = repmat({'kinematics'},1,narea);
    end
    
    % okay, now we make a grouped bar plot
    % with scatter
    
    axes( (handles.peakAccuracyPlot) );
    cla;
    barx = 0;
    sessionMids = zeros(nsesh,1);
    for seshind = 1:nsesh
        % barx   = seshind - 1; % group by session, not by area
        beginSession = barx;
        foldav = foldaverage{seshind};
        
        for areaind = 1:narea
            foldavrow = foldav(areaind,:);
            barht     = mean(foldavrow); % average across subsamples
            xscatter  = barx - 0.05 + 0.1*rand(size(foldavrow));
            hold all
            b = bar(barx,barht,1);
            thisColor = colorStruct.colors(areaind,:);
            set(b,'facecolor',thisColor)
            
            %         if max(thisColor) < 0.3
            %             outlineColor = [1 1 1];
            %         else
            %             outlineColor = [0 0 0];
            %         end
            
            hold all
            scatter(xscatter,foldavrow,36,0.5+0.5*thisColor);% ,...
            % 'markeredgecolor',outlineColor,...
            % 'markerfacecolor',thisColor)
            
            barx = barx+1;
        end
        endSession = barx - 1;
        sessionMids(seshind) = (beginSession + endSession)/2;
        barx = barx+1; % group by session, not by area (since different sessions have different subsample sizes!)
    end
    
    % plot the chance level
    % (use a white-outlined black dashed line)
    chanceLevel = cellfun(@(x) x(end,:),foldaverage,'uniformoutput',false);
    chanceLevel = mean( horzcat(chanceLevel{:}) );
    
    axis tight
    xl = get(gca,'xlim');
    hold all
    line(xl,chanceLevel*[1 1],'linewidth',1,'color',[1 1 1])
    hold all
    line(xl,chanceLevel*[1 1],'linewidth',0.75,'color',[0 0 0],'linestyle','--')
    
    % adjust margins & stuff
    ylim([0 1])
    ylabel('Classification accuracy')
    
    % add legend
    customlegend(colorStruct.labels,'colors',colorStruct.colors);
    
    % adjust tick marks
    sessionLabels = cellfun(@(x) x.seshID,classifyCell,'uniformoutput',false);
    set(gca,'xtick',sessionMids,'xticklabel',sessionLabels)
    
    % terminate here, don't execute the rest of the script which handles
    % max pooling
    return
    
else
    % pass
end

%% experimental feature, disregard (will NOT be implemented in the end, the plot I envision is not well-served by this gui!)
% (the peak accuracy plot is ENOUGH!)
% % if not None, replace aligns & subaligns with appropriate values
% nSubAlign = sqrt(subAlignmentCount);
% 
% midSubAlign = (nSubAlign + 1)/2;
% alignNames  = cellstr( unique( char(trainAlign(:)),'rows' ) );
% 
% % iterate over train & test
% % NEW IDEA: classification accuracy TRACES instead of bar plots
% for traintest = 1:2
%     switch traintest
%         case 1
%             switchval = trainOverride;
%         case 2
%             switchval = testOverride;
%         otherwise
%             % pass
%     end
%     
%     switch switchval
%         case 'None'
%             % pass
%         case 'Baseline'
%             newAlign = find( ...
%                 cellfun(@(x) ~isempty( regexpi(x,'lighton','once') ),alignNames) ...
%                 );
%             newSubAlign = 1:(midSubAlign-1); % assume all alignments have equal subalignment counts.
%         case 'Vision'
%             newAlign = find( ...
%                 cellfun(@(x) ~isempty( regexpi(x,'lighton','once') ),alignNames) ...
%                 );
%             newSubAlign = midSubAlign:nSubAlign; % assume all alignments have equal subalignment counts.
%         case 'Late Memory'
%             newAlign = find( ...
%                 cellfun(@(x) ~isempty( regexpi(x,'move','once') ),alignNames) ...
%                 );
%             newSubAlign = 1:(midSubAlign-1); % assume all alignments have equal subalignment counts.
%         case 'Early Movement'
%             newAlign = find( ...
%                 cellfun(@(x) ~isempty( regexpi(x,'move','once') ),alignNames) ...
%                 );
%             newSubAlign = midSubAlign:nSubAlign; % assume all alignments have equal subalignment counts.
%         case 'Late Movement'
%             newAlign = find( ...
%                 cellfun(@(x) ~isempty( regexpi(x,'hold','once') ),alignNames) ...
%                 );
%             newSubAlign = 1:(midSubAlign-1); % assume all alignments have equal subalignment counts.
%         case 'Contact'
%             newAlign = find( ...
%                 cellfun(@(x) ~isempty( regexpi(x,'hold','once') ),alignNames) ...
%                 );
%             newSubAlign = midSubAlign:nSubAlign; % assume all alignments have equal subalignment counts.
%         otherwise
%             % pass
%     end
% end
% data_ = cellfun(@(x) squeeze( x(:,trainContextComparison,testContextComparison,...
%     trainAlign,testAlign,trainSubAlign,testSubAlign) ),...
%     data_,'uniformoutput',false);
