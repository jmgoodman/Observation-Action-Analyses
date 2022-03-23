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

whichArea    = get(handles.areaSelector,'Value');
whichSession = get(handles.sessionSelector,'Value');

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

% select only the units with area ID matching your current selection
areaStrings  = get(handles.areaSelector,'String');
thisAreaName = areaStrings{whichArea};

% pick color
colorConvention = getappdata(handles.output,'colorConvention');
whichColorInd   = ( cellfun(@(x) ...
    ~isempty( regexpi( thisAreaName,x,'once' ) ),...
    colorConvention.labels ) );
thisColor       = colorConvention.colors( whichColorInd,: );

% thought: should users have the option to select areas from a checklist,
% instead of being pigeonholed into one?
%
% answer: uhhh yeah after testing it out that's exactly what I crave
%
% another thought: there's an awful lot happening in this script, you maybe
% wanna abstract some of it out buddy?
% 
% answer: listen, Satan, Jesus, WHOEVER you are...
% I've been stuck in refactoring hell (heaven?) for HOW long now?
% And my codebase is STILL woefully cruddy in that regard?
% let's get something up & running before circling back to that idea...

if ~strcmpi(thisAreaName,'pooled') && ~strcmpi(thisAreaName,'pooled-split')
    theseinds = cellfun(@(x) ~isempty( regexpi(x,thisAreaName,'once') ),...
        areaLabels);
    contrastData   = contrastData(theseinds);
    congruenceData = congruenceData(theseinds);
else
    % pass
end

axes( (handles.marginalPreference) );
h=cdfplot(contrastData);
set(h,'color',thisColor,'linewidth',1);
xlabel('Active-Passive Index');
ylabel('Cumulative fraction of units');
title('');
xlim([-1 1])
ylim([0 1])
box off, grid off

axes( (handles.marginalCongruence) );
h=cdfplot(congruenceData);
set(h,'color',thisColor,'linewidth',1);
xlabel('Congruence (\rho)');
ylabel('Cumulative fraction of units');
title('');
xlim([-1 1])
ylim([0 1])
box off, grid off

axes( (handles.jointMetrics) );
scatter(contrastData,congruenceData,64,thisColor,'linewidth',1);
axis equal
xlim([-1 1])
ylim([-1 1])
box off, grid off
xlabel('Active-Passive Index')
ylabel('Congruence (\rho)')


set(handles.manovaTable,'columnName',{'hello','world'})
set(handles.manovaTable,'Data',randn(2))

set(handles.pairsTable,'columnName',{'foo','bar'})
set(handles.pairsTable,'Data',randn(2))