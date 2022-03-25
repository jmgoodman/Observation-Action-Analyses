function plotRefresher(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this is the common callback for the two dropdown selectors.

% pull the clustering analysis data struct
mObj = getappdata(handles.output,'clusterData');

contrastStruct = mObj.contraststruct;

whichAreas   = get(handles.areaSelector,'Value');
whichSession = get(handles.sessionSelector,'Value');

if isempty(whichAreas)
    % clear figures
    axes( (handles.marginalPreference) );
    cla;
    
    axes( (handles.marginalCongruence) );
    cla;
    
    axes( (handles.jointMetrics) );
    cla;
    
    % clear tables
    set(handles.manovaTable,'RowName',{''})
    set( handles.manovaTable,'ColumnName', {''} );
    set(handles.manovaTable,'Data',{''});
    
    set(handles.pairsTable,'RowName',{''})
    set( handles.pairsTable,'ColumnName', {''} );
    set(handles.pairsTable,'Data',{''});
    
    return
end

contrastStruct = contrastStruct(whichSession); % this only gets active-passive indices

% pull data from the figures that were generated
clusterDir = getappdata(handles.output,'clusterDir');

figNumber   = 6 + (whichSession-1)*7;
fileName    = sprintf('clustfigure%0.2i.fig',figNumber);
fullFigPath = fullfile( clusterDir,fileName );
        
fig_   = openfig(fullFigPath,'invisible');
child_ = get(fig_,'Children'); % dataObjs = findobj(fig_,'-property','YData')
figureContrast   = child_.Children.XData(:);
figureCongruence = child_.Children.YData(:);
close(fig_)
clear fig_

% register figure data to struct data
contrastData   = contrastStruct.pooled;
areaLabels     = contrastStruct.pooledareanames;
areNan         = isnan(contrastData);
contrastData   = contrastData(~areNan);
areaLabels     = areaLabels(~areNan);

assert( all(contrastData == figureContrast),'error in data registration - this is my bad, not yours' ) % TODO: make a routine that registers everything correctly...
congruenceData = figureCongruence;

% reset plots
axes( (handles.marginalPreference) );
cla;

axes( (handles.marginalCongruence) );
cla;

axes( (handles.jointMetrics) );
cla;

% select only the units with area ID matching your current selection
colorStack = [];
areaStack  = {};

% keep a running table of all the areas you collate (users will need to be
% smart enough not to mix selections which consitute overlapping areas,
% e.g., contrasting F5 against F5-lat)
tableData  = [];
tableAreas = {};

for whichArea = whichAreas
    areaStrings  = get(handles.areaSelector,'String');
    thisAreaName = areaStrings{whichArea};
    
    % pick color
    colorConvention = getappdata(handles.output,'colorConvention');
    whichColorInd   = ( cellfun(@(x) ...
        ~isempty( regexpi( thisAreaName,x,'once' ) ),...
        colorConvention.labels ) );
    thisColor       = colorConvention.colors( whichColorInd,: );
    
    % determine -lat or -med color
    ismed = ~isempty( regexpi(thisAreaName,'-med','once') );
    islat = ~isempty( regexpi(thisAreaName,'-lat','once') );
    
    if ismed
        thisColor = 0.5 + 0.5*thisColor;
    elseif islat
        thisColor = 0.5*thisColor;
    else
        % pass
    end
    
    colorStack = vertcat(colorStack,thisColor); %#ok<*AGROW>
    areaStack  = vertcat(areaStack,{thisAreaName});
    
    
    if ~strcmpi(thisAreaName,'pooled')
        theseinds = cellfun(@(x) ~isempty( regexpi(x,thisAreaName,'once') ),...
            areaLabels);
        contrastData_   = contrastData(theseinds);
        congruenceData_ = congruenceData(theseinds);
    else
        contrastData_   = contrastData;
        congruenceData_ = congruenceData;
    end
    
    axes( (handles.marginalPreference) ); %#ok<*LAXES>
    hold all
    h=cdfplot(contrastData_);
    set(h,'color',thisColor,'linewidth',1);
    xlabel('Active-Passive Index');
    ylabel('Cumulative fraction of units');
    title('');
    xlim([-1 1])
    ylim([0 1])
    box off, grid off
    
    axes( (handles.marginalCongruence) );
    hold all
    h=cdfplot(congruenceData_);
    set(h,'color',thisColor,'linewidth',1);
    xlabel('Congruence (\rho)');
    ylabel('Cumulative fraction of units');
    title('');
    xlim([-1 1])
    ylim([0 1])
    box off, grid off
    
    axes( (handles.jointMetrics) );
    hold all
    scatter(contrastData_,congruenceData_,64,thisColor,'linewidth',1);
    axis equal
    xlim([-1 1])
    ylim([-1 1])
    box off, grid off
    xlabel('Active-Passive Index')
    ylabel('Congruence (\rho)')
    
    % add to the tableData and tableAreas arrays
    nneur      = numel(contrastData_);
    tableData  = vertcat(tableData,[contrastData_,congruenceData_]);
    tableAreas = vertcat(tableAreas,repmat({thisAreaName},nneur,1));
end

% add legends
axes( (handles.marginalPreference) );
customlegend(areaStack,'colors',colorStack)

axes( (handles.marginalCongruence) );
customlegend(areaStack,'colors',colorStack)

axes( (handles.jointMetrics) );
customlegend(areaStack,'colors',colorStack)

% update tables
% note: repeated-measures ANOVA is fucking BONKERS and makes NO sense. use
% manova1 instead
% you can tell this is where I stopped giving a hoot...
[dManova,pManova,statsManova] = manova1(tableData,tableAreas);
[~,tabContrast,statsContrast] = anova1(tableData(:,1),tableAreas,'off');
[~,tabCongruence,statsCongruence] = anova1(tableData(:,2),tableAreas,'off');


rowN = {'Preference','Congruence','MANOVA'};
colN = horzcat({'(equivalent) df-groups','(equivalent) df-error','(equivalent) F','p','Wilks'' Lambda','dim'},...
    strcat(statsManova.gnames(:),' neuron count')',...
    strcat(statsManova.gnames(:),' marg. mean')');

% marg means
margMu = vertcat( num2cell( vertcat( statsContrast.means, statsCongruence.means ) ), repmat({''},1,numel(whichAreas)) );

% n-stats
nStats = vertcat( repmat({''},2,numel(whichAreas)), num2cell( statsContrast.n ) );

% F-test stats
whichInd = max(dManova,1);
if ~isempty(dManova)
    [manovaF,manovaDf1,manovaDf2] = wilkLambda2F(statsManova.lambda(whichInd),numel(whichAreas),2,numel(tableAreas),false); % lambda stat, # groups, # measures, # obs, toggle to display things to command window
    
    fTable   = vertcat( horzcat( tabContrast(2:3,3)',tabContrast(2,5:6) ),...
        horzcat( tabCongruence(2:3,3)',tabCongruence(2,5:6) ),...
        num2cell( horzcat( manovaDf1, manovaDf2, manovaF, pManova(whichInd) ) ) );
else
    fTable   = vertcat( horzcat( tabContrast(2:3,3)',tabContrast(2,5:6) ),...
        horzcat( tabCongruence(2:3,3)',tabCongruence(2,5:6) ),...
        repmat({''},1,4) );
end

% wilks' lambda, MANOVA-specific
if ~isempty(dManova)
    lambdaTable = vertcat( repmat({''},2,2),...
        num2cell( [statsManova.lambda(whichInd),dManova] ) );
else
    lambdaTable = repmat({''},3,2);
end

bigData     = horzcat(fTable,lambdaTable,nStats,margMu);

set(handles.manovaTable,'RowName',rowN)
set( handles.manovaTable,'ColumnName', colN );
set(handles.manovaTable,'Data',bigData);

% ---
% now, the PAIRS table
pairsStruct = mObj.PAIRSstruct;

% take only this session
sessionStruct = pairsStruct(whichSession);

% sorry, we don't bother splitting areas for these!
pairsFields = fieldnames(sessionStruct);

% keep the ones which are members of the area selector
keepFields  = ...
cellfun(@(x) ...
    any( ...
        cellfun(@(y) ...
            ~isempty( ...
                regexpi( ...
                    y,x,'once'...
                )... 
            ),...
            statsManova.gnames(:)...
        ) ...
    ),...
    pairsFields...
);

keepFields = pairsFields(keepFields);

% now get the data
pairsData = [];
for fieldInd = 1:numel(keepFields)
    tempStruct = sessionStruct.(keepFields{fieldInd});
    delta      = tempStruct.dataPAIRS - tempStruct.nullPAIRS;
    
    % lower quartile - median delta-PAIRS - upper quartile - bootstrapped p < 0
    pairsData = vertcat(pairsData,[...
        prctile(delta,25:25:75),...
        mean(delta<0)]);
end

set(handles.pairsTable,'ColumnName',{'lower quartile','median delta-PAIRS','upper quartile','bootstrapped p<0'});
set(handles.pairsTable,'RowName',keepFields)
set(handles.pairsTable,'Data',pairsData)
