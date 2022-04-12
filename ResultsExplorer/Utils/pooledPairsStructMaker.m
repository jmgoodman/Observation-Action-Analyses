function pooledPairsStructMaker(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this is a subroutine of NeuronClustering.m which creates a pooled-sessions PAIRS struct

% step 1: get your data

mObj           = getappdata(handles.output,'clusterData');

theseAnimals   = {'Moe','Zara'};
nAnimals       = numel(theseAnimals);

for animalInd = 1:nAnimals
    contrastStruct = mObj.contraststruct;
    theseStrings   = get(handles.sessionSelector,'string');
    pooledStrings  = cellfun(@(x) ~isempty( ...
        regexpi(x,'\-pooled$','once') ),...
        theseStrings);
    theseStrings   = regexp(theseStrings,'\-pooled$','split');
    theseStrings   = cellfun(@(x) x{1},theseStrings,'uniformoutput',false);
    sessionStrings = theseStrings(~pooledStrings);
    thisAnimal     = theseAnimals{animalInd}; %theseStrings{whichSession};
    theseSessions  = cellfun(@(x) ...
                         ~isempty(...
                             regexpi(...
                                 x,thisAnimal,'once'...
                             )...
                         ), ...
                         sessionStrings...
                     );

    tempStruct     = contrastStruct(theseSessions);

    fnames         = fieldnames(tempStruct);

    for fieldind = 1:numel(fnames)
        fieldName             = fnames{fieldind};
        tempcell              = arrayfun(@(x) x.(fieldName),tempStruct,'uniformoutput',false);
        newStruct.(fieldName) = vertcat( tempcell{:} );
    end
    
    contrastStruct = newStruct;
    
    % pull & pool figure data
    theseSessionInds = find(theseSessions);
    nSessions        = numel(theseSessionInds);
    
    figureContrast.(thisAnimal)   = [];
    figureCongruence.(thisAnimal) = [];
    areaLabels.(thisAnimal)       = contrastStruct.pooledareanames;
    nanInds                       = isnan(contrastStruct.pooled);
    areaLabels.(thisAnimal)       = areaLabels.(thisAnimal)(~nanInds);

    clusterDir = getappdata(handles.output,'clusterDir');
    for sessionInd = 1:nSessions
        thisSessionInd = theseSessionInds(sessionInd);
        
        figNumber   = 6 + (thisSessionInd-1)*7;
        fileName    = sprintf('clustfigure%0.2i.fig',figNumber);
        fullFigPath = fullfile( clusterDir,fileName );
        
        fig_   = openfig(fullFigPath,'invisible');
        child_ = get(fig_,'Children'); % dataObjs = findobj(fig_,'-property','YData')
        figureContrast.(thisAnimal)   = vertcat( figureContrast.(thisAnimal),   child_.Children.XData(:) );
        figureCongruence.(thisAnimal) = vertcat( figureCongruence.(thisAnimal), child_.Children.YData(:) );
        close(fig_)
        clear fig_
    end 
end

% for each field name
areaNames = get(handles.areaSelector,'string');
nAreas    = numel(areaNames);

for animalInd = 1:nAnimals
    thisAnimal  = theseAnimals{animalInd};
    contrast_   = figureContrast.(thisAnimal);
    congruence_ = figureCongruence.(thisAnimal);
    labels_     = areaLabels.(thisAnimal);
    
    for areaInd = 1:nAreas
        areaName = areaNames{areaInd};
        
        if strcmpi(areaName,'pooled') % just keep it all
            contrast__   = contrast_;
            congruence__ = congruence_;
        else
            theseInds    = cellfun( @(x) ~isempty( regexpi(x,areaName,'once') ), labels_ );
            contrast__   = contrast_(theseInds);
            congruence__ = congruence_(theseInds);
        end
        
        X = [contrast__(:),congruence__(:)];
        
        fieldName = dash2underscore(areaName);
        pStruct.(thisAnimal).(fieldName) = ...
            PAIRStest(X,3,2,1e4,true); % running for 1e4 iterations takes like 20 mins. I guess I better parallelize that...
    end
end

cDir  = getappdata(handles.output,'clusterDir');
sFile = fullfile(cDir,'pooled_pairs_stats.mat');

save(sFile,'pStruct','-v7.3');
