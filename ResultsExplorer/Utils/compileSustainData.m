function compileSustainData(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this collects data to then make a plot

colorStruct = defColorConvention(); 

mirrorDataDir      = getappdata(handles.output,'mirrorDataDir');
analysisOutputsDir = getappdata(handles.output,'analysisOutputsDir');

sessions2analyze = get(handles.sessionSelector,'String');
for ii = 1:numel(sessions2analyze)
    commonSpaceFile = fullfile(analysisOutputsDir,sessions2analyze{ii},...
        sprintf('sustainspace_results_%s.mat',sessions2analyze{ii})); % loads sustainspace into file
    load(commonSpaceFile); %#ok<*LOAD>
    
    sessionDataFile = fullfile( mirrorDataDir,sprintf('%s_datastruct.mat',...
        sessions2analyze{ii}) );
    load(sessionDataFile);
    [pooledarraydatacell,arraynames] = poolarrays(datastruct.cellform); %#ok<*ASGLU>
    
    gottenPreMovement  = cellfun(@(x) vertcat( x{2}.Data(51:end,:,:), ...
        x{4}.Data(1:50,:,:) ), pooledarraydatacell,'uniformoutput',false);
    gottenPeriMovement = cellfun(@(x) vertcat( x{5}.Data(:,:,:), ...
        x{6}.Data(:,:,:) ), pooledarraydatacell,'uniformoutput',false);
    
    triallabels = extractlabels(datastruct.cellform);
    
    gottenPreMovement  = vertcat( gottenPreMovement,  {horzcat(gottenPreMovement{:})} ); %#ok<AGROW>
    gottenPeriMovement = vertcat( gottenPeriMovement, {horzcat(gottenPeriMovement{:})} ); %#ok<AGROW>
    
    % okay I discovered the issue
    % sustainspace is computed on trial averages
    % so to get a *meaningful* estimate of variance captured...
    % ...Imma need to compute trial averages
    
    % first of all, get active & passive conditions
    % then get all 3 conditions with the 1 turntable where it matters
    % repeat this for both the pre- and peri-movement data\
    staMegaCell = cell(2,2);
    for dataType = 1:2 % allobj vs allcontext
        for epochAlign = 1:2 % pre & peri
    
            switch dataType
                case 1 % allobj
                    targetcontexts = {'active','passive'};
                    dtstr = 'allobj';
                    
                    keeptrials     = ismember(triallabels.trialcontexts.names,targetcontexts);
                case 2 % allcontext
                    targetTurntables = 1;
                    dtstr = 'allcontext';
                    
                    keeptrials     = ismember(triallabels.turntablelabels.names,targetTurntables);
            end
                    
            keptlabels     = triallabels;
            fn             = fieldnames(triallabels);
            
            for fnind = 1:numel(fn)
                keptlabels.(fn{fnind}).names      = keptlabels.(fn{fnind}).names(keeptrials);
                keptlabels.(fn{fnind}).uniqueinds = keptlabels.(fn{fnind}).uniqueinds(keeptrials);
            end
            
            keptlabels.trialcontexts.uniquenames      = targetcontexts;
            keptlabels.trialcontexts.nunique          = numel(targetcontexts);
            [~,~,keptlabels.trialcontexts.uniqueinds] = unique(keptlabels.trialcontexts.uniqueinds);
            
            switch epochAlign
                case 1 % pre
                    eastr = 'pre';
                    keptdata = cellfun(@(x) x(:,:,keeptrials),gottenPreMovement,'uniformoutput',false); % note: normalization is based on max rates which INCLUDE the "control" trials. you exclude them here. so if you ever get results that seem to defy the logic of your analysis pipeline at first glance... that's why!!!
                case 2 % peri
                    eastr = 'peri';
                    keptdata = cellfun(@(x) x(:,:,keeptrials),gottenPeriMovement,'uniformoutput',false);
            end
            
            % use TT x object x context to make the sorted trial average for each area
            [~,~,trialsortlabels] = unique( [keptlabels.trialcontexts.uniqueinds,...
                keptlabels.turntablelabels.uniqueinds,...
                keptlabels.objects.uniqueinds],'rows' );
            
            stacell = cell(size(keptdata));
            for aind = 1:numel(keptdata)
                sortedtrialaverage = makesortedtrialaverage(keptdata{aind},trialsortlabels);
                % transpose and flatten
                sta                = permute(sortedtrialaverage,[2,1,3]); % neur x time x (context x TT x object)
                sta                = sta(:,:)'; % neuron x (time x context x TT x object)
                stacell{aind}      = sta;
            end
            
            staMegaCell{dataType,epochAlign}.data = stacell;
            staMegaCell{dataType,epochAlign}.epochAlign = eastr;
            staMegaCell{dataType,epochAlign}.dataKept   = dtstr;
        end
    end
    
    % projections
    projMegaCell = cell(size(staMegaCell));
    coef         = arrayfun(@(x) x.regular.coeff,sustainspace(:),'uniformoutput',false); %#ok<*IDISVAR,*NODEF>
    for cellInd = 1:numel(staMegaCell)
        % split by context
        epochAlign = staMegaCell{cellInd}.epochAlign; % 'peri' or 'pre'
        dataKept   = staMegaCell{cellInd}.dataKept; % 'allobj' or 'allcontext'
        thisData   = staMegaCell{cellInd}.data;
        
        nel        = size(thisData{1},1);
        
        switch epochAlign
            case 'peri'
                time_  = 200;
            case 'pre'
                time_  = 100;
        end
        
        switch dataKept
            case 'allobj'
                context_ = 2;
                TT_      = nel / (context_*time_*6);
                contextNames = {'active','passive'};
            case 'allcontext'
                context_ = 3;
                TT_      = 1;
                contextNames = {'active','control','passive'};
        end
        
        object_ = 6;
        
        % context = (2 for allobj, 3 for allcontext)
        % TT      = (n for allobj, 1 for allcontext)
        % object  = 6 (per TT)
        % time = (100 for premovement, 200 for perimovement)
        % ...but in reverse order
        sz = [time_,object_,TT_,context_];
        [timeind,objectind,TTind,contextind] = ind2sub(sz,(1:nel)');
        
        projcell  = cell(max(contextind),1);
        
        % if you wanna normalize by cross-context variance (to reinforce, for
        % example, that M1 has nothing going on in the passive condition)
        totalproj = cellfun(@(x,y) bsxfun(@minus,x,...
            mean(x))*y,...
            staMegaCell{cellInd}.data,coef,'uniformoutput',false);
        
        % remove context-specific means, so that totalvar doesn't account
        % for that variance
        for contextind_ = 1:max(contextind)
            keepinds = contextind == contextind_;
            for areaind = 1:numel(totalproj)
                thismat = totalproj{areaind};
                thismu   = mean( thismat(keepinds,:) );
                totalproj{areaind}(keepinds,:) = ...
                    bsxfun(@minus,...
                    totalproj{areaind}(keepinds,:),...
                    thismu);
            end
        end
        
        totalvar  = cellfun(@(x) sum(x(:).^2),totalproj,'uniformoutput',false);
        
        for contextind_ = 1:max(contextind)
            keepinds = contextind == contextind_;
            proj = cellfun(@(x,y) bsxfun(@minus,x(keepinds,:),...
                mean(x(keepinds,:)))*y,...
                staMegaCell{cellInd}.data,coef,'uniformoutput',false);
            var_ = cellfun(@(x) sum(x.^2),proj,'uniformoutput',false);
            normvar_ = cellfun(@(x,y) cumsum(x)./sum(y),var_,totalvar,'uniformoutput',false);
            projcell{contextind_}.scree      = normvar_;
            projcell{contextind_}.context    = contextNames{contextind_};
        end
        
        projMegaCell{cellInd}.data       = projcell;
        projMegaCell{cellInd}.epochAlign = epochAlign;
        projMegaCell{cellInd}.dataKept   = dataKept;
    end
    
    % now make a series of plots
    alabs = vertcat(arraynames,'pooled');
    for cellInd = 1:numel(projMegaCell)
        figure
        thisCell = projMegaCell{cellInd};
        epochAlign = thisCell.epochAlign;
        dataKept   = thisCell.dataKept;
        thisData   = thisCell.data;
        
        nsubplots = numel(thisData);
        
        ylab = sprintf('Fraction of %s %smovement variance captured (%s)',dataKept,epochAlign,sessions2analyze{ii});
        
        for subPlotInd = 1:nsubplots
            subplot(1,nsubplots,subPlotInd)
            thisScree   = thisData{subPlotInd}.scree;
            thisContext = thisData{subPlotInd}.context;
            
            for areaInd = 1:numel(thisScree)
                thisAreaScree = thisScree{areaInd};
                whichColor = ismember( colorStruct.labels, alabs{areaInd} );
                whichColor = colorStruct.colors(whichColor,:);
                hold all
                plot(0:numel(thisAreaScree),[0,thisAreaScree(:)'],'linewidth',1,'color',whichColor)
                hold all
                plot([0,numel(thisAreaScree)],thisAreaScree(end)*[1 1],'linewidth',1,'linestyle','--','color',whichColor)
            end
            
            xlim([0 30])
            ylim([0 1])
            title(thisContext)
            if subPlotInd == 1
                xlabel('Number of Principal Components')
                ylabel(ylab)
            else
                % pass
            end
            
            if subPlotInd == nsubplots
                customlegend( colorStruct.labels, 'colors', colorStruct.colors )
            else
                % pass
            end
        end
    end  
                
% TODO:
% remember the point you're trying to make here

% forget about distribution of variance across contexts (which you just
% wasted a BUNCH of time visualizing...) (and which tells the exact story
% you expected it to anyway - yeah, AIP has more explicit vision than the other two,
% big whoop, the point is to see how ORTHOGONAL that visual component is
% w.r.t. the movement component, which these plots do NOT address!)

% just report how much is preserved after orthogonalization at both
% alignments
            
        
    
end