function compileSustainData(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this collects data to then make a plot

colorStruct = defColorConvention();
colorStruct.colors = colorStruct.colors([2:4,1],:);
colorStruct.labels = colorStruct.labels([2:4,1]);

mirrorDataDir      = getappdata(handles.output,'mirrorDataDir');
analysisOutputsDir = getappdata(handles.output,'analysisOutputsDir');

sessions2analyze = get(handles.sessionSelector,'String');

tic
seshCell         = cell(numel(sessions2analyze),2); % col 1 = allTT, col2 = allcontext
trialAverageCell = cell(numel(sessions2analyze),1);

ncompsConservative = zeros( numel(sessions2analyze),4 );
ncompsAggressive   = zeros( numel(sessions2analyze),4 );
objectNames        = cell( numel(sessions2analyze),1 );

for ii = 1:numel(sessions2analyze)
    commonSpaceFile = fullfile(analysisOutputsDir,sessions2analyze{ii},...
        sprintf('sustainspace_results_%s.mat',sessions2analyze{ii})); % loads sustainspace into file
    load(commonSpaceFile); %#ok<*LOAD>
    
    nCons = arrayfun(@(x) x.regular.ncomp,sustainspace);
    nAgg  = arrayfun(@(x) x.regular.ncomp,sustainspace_aggressive);
    
    ncompsConservative(ii,:) = nCons;
    ncompsAggressive(ii,:)   = nAgg;
    
    sessionDataFile = fullfile( mirrorDataDir,sprintf('%s_datastruct.mat',...
        sessions2analyze{ii}) );
    load(sessionDataFile);
    [pooledarraydatacell,arraynames] = poolarrays(datastruct.cellform); %#ok<*ASGLU>
    
    gottenPreMovement  = cellfun(@(x) vertcat( x{2}.Data(51:end,:,:), ...
        x{4}.Data(1:50,:,:) ), pooledarraydatacell,'uniformoutput',false);
    gottenPeriMovement = cellfun(@(x) vertcat( x{4}.Data(51:end,:,:), ...
        x{6}.Data(:,:,:) ), pooledarraydatacell,'uniformoutput',false); % go from go cue onset to ensure you capture some prep activity prior to movement onset while avoiding direct overlap with the visual / memory subspace
    
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
            [trialsortinds,~,trialsortlabels] = unique( [keptlabels.trialcontexts.uniqueinds,...
                keptlabels.turntablelabels.uniqueinds,...
                keptlabels.objects.uniqueinds],'rows' );
            
            tinds  = trialsortinds(1:(size(trialsortinds,1)/2),2:3);
            if dataType == 1 && epochAlign == 1
                onames = cell(6,max(tinds(:,1)));
                for rowind = 1:size(tinds,1)
                    oname = keptlabels.objects.uniquenames{ tinds(rowind,2) };
                    onames{ mod(rowind-1,6)+1, tinds(rowind,1)} = oname;
                end
                
                objectNames{ii} = onames;
            else
                % pass
            end
            
            stacell = cell(size(keptdata));
            for aind = 1:numel(keptdata)
                sortedtrialaverage = makesortedtrialaverage(keptdata{aind},trialsortlabels);
                % transpose and flatten
                sta                = permute(sortedtrialaverage,[2,1,3]); % neur x time x (context x TT x object)
                sta                = sta(:,:)'; % neuron x (time x context x TT x object)
                stacell{aind}      = sta;
            end
            
            nativeCoef   = cell(size(stacell));
            nativeLatent = cell(size(stacell));
            
            for cellInd = 1:numel(stacell)
                [coef_,~,latent_] = pca( stacell{cellInd} );
                nativeCoef{cellInd}   = coef_;
                nativeLatent{cellInd} = latent_;
            end
            
            staMegaCell{dataType,epochAlign}.data = stacell;
            staMegaCell{dataType,epochAlign}.nativeCoef   = nativeCoef;
            staMegaCell{dataType,epochAlign}.nativeLatent = nativeLatent;
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
                time_  = 150;
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
        % time = (100 for premovement, 150 for perimovement)
        % ...but in reverse order
        sz = [time_,object_,TT_,context_];
        [timeind,objectind,TTind,contextind] = ind2sub(sz,(1:nel)');
        
        % keep contexts together - the difference between projections is
        % NOT important here and turns out NOT to bolster your story
        % (namely, that movement & visual subspaces are orthogonal - adding
        % the complexity of splitting different contexts just makes the
        % plot harder to read, even though a systematic difference between
        % action & observation contexts might well further support your
        % claim)
        
        proj = cellfun(@(x,y) bsxfun(@minus,x,mean(x))*y,...
            staMegaCell{cellInd}.data,coef,'uniformoutput',false);
        proj = cellfun(@(x) var(x),proj,'uniformoutput',false);
        proj = cellfun(@(x) cumsum(x)./sum(x),proj,'uniformoutput',false);
        
        nullModel = cell(numel(proj),1);
        Niter     = 1000;
        for arrayInd = 1:numel(proj)
            cc = coef{arrayInd};
            projmat = zeros( Niter,size( proj{arrayInd},2 ) );
            for iter = 1:Niter
                [Q,~]   = qr(randn( size( proj{arrayInd},2 ) ) );
                cmat    = Q' * diag( staMegaCell{cellInd}.nativeLatent{arrayInd} ) * Q;
                projmat_temp = sum( cc.*(cmat*cc) );
                projmat_temp = cumsum(projmat_temp)./sum(projmat_temp);
                projmat(iter,:) = projmat_temp;
            end
            nullModel{arrayInd} = projmat;
        end
        
        projMegaCell{cellInd}.data       = proj;
        projMegaCell{cellInd}.nullModel  = nullModel;
        projMegaCell{cellInd}.epochAlign = epochAlign;
        projMegaCell{cellInd}.dataKept   = dataKept;
    end
            
    % col 1 = pre, col 2 = peri
    % row 1 = allobj, row 2 = allcontext
    % pre / peri -> active / (control) / passive -> AIP / F5 / M1 / pooled
    
    seshCell{ii,1} = projMegaCell(1,:);
    seshCell{ii,2} = projMegaCell(2,:);
    trialAverageCell{ii} = staMegaCell;
    toc
end

mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);
[cd_,~,~] = fileparts(cd_);
file2save = fullfile(cd_,'Data','sustainData.mat');
save(file2save,'seshCell','trialAverageCell','ncompsConservative',...
    'ncompsAggressive','objectNames','-v7.3')

setappdata(handles.output,'seshCell',seshCell)
setappdata(handles.output,'trialAverageCell',trialAverageCell)
setappdata(handles.output,'ncompsConservative',ncompsConservative)
setappdata(handles.output,'ncompsAggressive',ncompsAggressive)
setappdata(handles.output,'objectNames',objectNames)
%% test plots
% % (session,allobj/allcontext) -> pre / peri -> active / (control) / passive -> AIP / F5 / M1 / pooled
% x = cellfun(@(x) x{1},seshCell,'uniformoutput',false); % pre  = x
% y = cellfun(@(x) x{2},seshCell,'uniformoutput',false); % peri = y
% 
% % for each data type AND animal:
% animalNames = cellfun(@(x) x(1:(end-2)),sessions2analyze,'uniformoutput',false);
% 
% [uniqueAnimalNames,~,uniqueAnimalInds] = ...
%     unique(char(animalNames),'rows');
% 
% for animalInd = 1:max(uniqueAnimalInds)
%     keepInds = uniqueAnimalInds == animalInd;
%     for dataTypeInd = 1:size(x,2) % allobj vs allcontext
%         figure
%         x_thisDataType = x(keepInds,dataTypeInd);
%         y_thisDataType = y(keepInds,dataTypeInd);
%         
%         nC = ncompsConservative(keepInds,:);
%         nA = ncompsAggressive(keepInds,:);
%         
%         if dataTypeInd == 1
%             typeName     = 'all objects';
%         else
%             typeName     = 'all contexts';
%         end
%         
%         nAreas = numel(colorStruct.labels);
%         for areaInd = 1:nAreas
%             x_thisArea = cellfun(@(x) x.data{areaInd},x_thisDataType,'uniformoutput',false);
%             y_thisArea = cellfun(@(x) x.data{areaInd},y_thisDataType,'uniformoutput',false);
%             nullModel_thisArea = cellfun(@(x) x.nullModel{areaInd},y_thisDataType,'uniformoutput',false); % no need to check pre- vs- pre: we know for a fact that's gonna ALIGN better than chance
%             thisColor  = colorStruct.colors(areaInd,:);
%             
%             for sessionInd = 1:numel(x_thisArea)
%                 nCons = nC(sessionInd,areaInd);
%                 nAgg  = nA(sessionInd,areaInd);
%                 hold all
%                 x_thisSession = x_thisArea{sessionInd};
%                 y_thisSession = y_thisArea{sessionInd};
%                 null_thisSession = mean( nullModel_thisArea{sessionInd} );
%                 scatter(x_thisSession,y_thisSession,16,thisColor)
%                 hold all
%                 plot(x_thisSession,null_thisSession,'linewidth',1,'color',0.5*thisColor+0.5)
%                 hold all
%                 plot(x_thisSession([nCons,nAgg]),y_thisSession([nCons,nAgg]),...
%                     'ko','markersize',12,'linewidth',1.5,'color',thisColor)
%             end
%         end
%         
%         xlab = sprintf('%s | %s | FVE pre-movement',...
%             strtrim( uniqueAnimalNames(animalInd,:) ),...
%             typeName);
%         ylab = sprintf('%s | %s | FVE peri-movement',...
%             strtrim( uniqueAnimalNames(animalInd,:) ),...
%             typeName);
%         
%         xlabel(xlab)
%         ylabel(ylab)
%         customlegend( colorStruct.labels,'colors',colorStruct.colors )
%         
%         % plot unity line
%         hold all
%         xl = get(gca,'xlim');
%         yl = get(gca,'ylim');
%         combinedLims = [0, min(max(xl),max(yl))];
%         line(combinedLims,combinedLims,'linewidth',1,'color',[0 0 0],'linestyle','--')
%         axis square
%     end
% end
% 
% 
% % TODO: null models, and consider re-merging the contexts (the "control"
% % context doesn't really tell us anything super interesting, honestly... it
% % just looks like the "active" condition, meaning the main effect in our
% % data is the difference between active & passive) (this might control for
% % SOMETHING, but idk what, so may as well not burden the reader with it)
% 
% % to make a null model:
% % take the scree plot of the NATIVE PCA of the peri-movement data, then
% % generate a hyperspherically random orthonormal projection, then generate
% % a covariance matrix and compute projections along the NON-NATIVE PCA
% % space
% 
% % okay so:
% % NOT more orthogonal than random
% % but way closer to orthogonal than aligned
% % (control: test vision vs. preCue, contrast with vision vs. periMove?) (I
% % need a win here... a way to say that we're more orthogonal than SOMETHING
% % here... since our random surrogate is actually MORE orthogonal than our
% % data are) (OR we just report the data as they are, forget about a point
% % of comparison, and simply point to the chasm of variance between our
% % curve and the unity line, with a throwaway mention of how it's more
% % aligned than chance but that's frankly expected?)
