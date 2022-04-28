function plotProjections(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes the scatterplot for Figure 4C (variance captured in pre-
% versus peri-movement epochs)

seshCell         = getappdata(handles.output,'seshCell');
trialAverageCell = getappdata(handles.output,'trialAverageCell');
ncompsConservative = getappdata(handles.output,'ncompsConservative'); % cols = AIP - F5 - M1 - pooled, rows = sessions
ncompsAggressive   = getappdata(handles.output,'ncompsAggressive');
seshNames        = get(handles.sessionSelector,'String');
arrayNames       = get(handles.areaSelector,'String');
seshIdx          = get(handles.sessionSelector,'Value');
arrayIdx         = get(handles.areaSelector,'Value');
objectNames      = getappdata(handles.output,'objectNames');
oNames           = cellfun(@(x) x(:),objectNames,'uniformoutput',false);

trueArrayIdx     = mod(arrayIdx-2,4)+1; % AIP - F5 - M1 - pooled, but listed with pooled first in the GUI



% (time x context x TT x object) x neuron
% we're just gonna look at active vs. passive, screw control
% so we have 2 contexts
% n TT
% 6 objects per TT
% and 150 samples for perimovement and 100 for premovement

periAlign   = trialAverageCell{seshIdx}{1,2}.data{trueArrayIdx};
periAlignPC = trialAverageCell{seshIdx}{1,2}.nativeCoef{trueArrayIdx};

preAlign    = trialAverageCell{seshIdx}{1,1}.data{trueArrayIdx};
preAlignPC  = trialAverageCell{seshIdx}{1,1}.nativeCoef{trueArrayIdx};

n           = ncompsConservative(seshIdx,trueArrayIdx);

% concatenate pre & peri and find the top PC of THAT
combinedAlign_full = vertcat(preAlign,periAlign);
mu_combined        = mean(combinedAlign_full);
coeff_combined     = pca(combinedAlign_full);

periAlign_full  = bsxfun(@minus,periAlign,mu_combined);% * periAlignPC;
periAlign_ortho = bsxfun(@minus,periAlign,mu_combined) * ...
    ( preAlignPC(:,(n+1):end)*preAlignPC(:,(n+1):end)' );% * periAlignPC;

% preAlign activity will trivially be equal to 0 after orthogonalization
preAlign_full   = bsxfun(@minus,preAlign,mu_combined);% * preAlignPC;
preAlign_ortho  = bsxfun(@minus,preAlign,mu_combined) * ...
    ( preAlignPC(:,(n+1):end)*preAlignPC(:,(n+1):end)' );

% unflatten
periDur = 150;
contextCount = 2;
objectCountPerTT = 6;

periAlign_full = reshape(periAlign_full,periDur,...
    [],contextCount,size(periAlign_full,2));
periAlign_ortho = reshape(periAlign_ortho,periDur,...
    [],contextCount,size(periAlign_ortho,2));

preDur = 100;
preAlign_full = reshape(preAlign_full,preDur,...
    [],contextCount,size(preAlign_full,2));
preAlign_ortho = reshape(preAlign_ortho,preDur,...
    [],contextCount,size(preAlign_ortho,2));

% next: find a pair of objects that maximize the dynamic movement-coupled
% variation between the two during the execution context

% also find a second pair of objects that illustrates this for the
% vision-coupled component

% (also you're seeking optimal DIMENSIONS to show off for these, too, which
% means it no longer makes 0 sense to show the orthogonalized premovement
% data!)

%% find the dimension that captures dynamic object information during grasping
objCount = size(periAlign_full,2);
varMax   = 0;
indices  = [0 0]; % objects

% reduce dimensionality: find the dimension that captures time x object
% variance (in the OBSERVATION context)
periAlign_slice = squeeze( periAlign_full(:,:,2,:) ); % time x object x neuron

% remove average across objects (preserving time) and average across time
% (preserving objects)
periAlign_demeaned = periAlign_slice;
% periAlign_demeaned = bsxfun(@minus,periAlign_demeaned,mean(periAlign_demeaned,2)); % average across objects, time-varying trace
% periAlign_demeaned(1:50,:,:) = bsxfun(@minus,periAlign_demeaned(1:50,:,:),...
%     mean(periAlign_demeaned(1:50,:,:),1)); % average over time, object-varying offsets
% periAlign_demeaned(51:end,:,:) = bsxfun(@minus,periAlign_demeaned(51:end,:,:),...
%     mean(periAlign_demeaned(51:end,:,:),1)); % average over time, object-varying offsets
% % all that's left now is object x time effects

periAlign_permute  = permute(periAlign_demeaned,[3,1,2]); % now neuron x time x object
periAlign_flat     = periAlign_permute(:,:)'; % now (time x object) x neuron

[coeff,score]      = pca(periAlign_flat);
score              = periAlign_flat * periAlignPC(:,1);

score_unflat       = reshape( score(:,1),...
    size(periAlign_slice,1),size(periAlign_slice,2) );

% now project the *original* data on the top dimension
periAlign_permute  = permute(periAlign_slice,[3,1,2]);
periAlign_flat     = periAlign_permute(:,:)';
periAlign_project  = bsxfun(@minus,periAlign_flat,mean(periAlign_flat)) * coeff;

varProject         = var(periAlign_project);
varProportion      = varProject(1) / sum(varProject);

periAlign_unflat   = reshape( periAlign_project(:,1),...
    size(periAlign_slice,1),size(periAlign_slice,2) ); % time x object

for objInd1 = 1:objCount
    for objInd2 = (objInd1+1):objCount
        trace1  = periAlign_unflat(:,objInd1);
        trace2  = periAlign_unflat(:,objInd2);
        
        score1  = score_unflat(:,objInd1);
        score2  = score_unflat(:,objInd2);
        
        % find a dimension that maximizes the variance between these
        % objects
        del = trace1 - trace2;
        thisVar = var(del);
        
        if thisVar > varMax
            varMax  = thisVar;
            indices = [objInd1, objInd2];
            keptTraces = [trace1,trace2];
        end
    end
end

% figure,plot( keptTraces(:,1) ),hold all,plot( keptTraces(:,2) )


%% do the same but for pre-align (do continue to focus on the time x object component tho, it's more interesting to look at...)
objCount = size(preAlign_full,2);
varMax   = 0;
indices_ = [0 0]; % objects

% reduce dimensionality: find the dimension that captures time x object
% variance
preAlign_slice = squeeze( preAlign_full(:,:,2,:) ); % time x object x neuron

% remove average across objects (preserving time) and average across time
% (preserving objects)
preAlign_demeaned = preAlign_slice;
% preAlign_demeaned = bsxfun(@minus,preAlign_demeaned,mean(preAlign_demeaned,2)); % average across objects, time-varying trace
% preAlign_demeaned(1:50,:,:) = bsxfun(@minus,preAlign_demeaned(1:50,:,:),...
%     mean(preAlign_demeaned(1:50,:,:),1)); % average over time, object-varying offsets
% preAlign_demeaned(51:end,:,:) = bsxfun(@minus,preAlign_demeaned(51:end,:,:),...
%     mean(preAlign_demeaned(51:end,:,:),1)); % average over time, object-varying offsets

preAlign_permute  = permute(preAlign_demeaned,[3,1,2]); % now neuron x time x object
preAlign_flat     = preAlign_permute(:,:)'; % now (time x object) x neuron

[coeff_,score]     = pca(preAlign_flat);
score              = preAlign_flat * preAlignPC(:,1);

score_unflat       = reshape( score(:,1),...
    size(preAlign_slice,1),size(preAlign_slice,2) );

% now project the *original* data on the top dimension
preAlign_permute  = permute(preAlign_slice,[3,1,2]);
preAlign_flat     = preAlign_permute(:,:)';
preAlign_project  = bsxfun(@minus,preAlign_flat,mean(preAlign_flat)) * coeff_;

varProject         = var(preAlign_project);
varProportion_     = varProject(1) / sum(varProject);

preAlign_unflat   = reshape( preAlign_project(:,1),...
    size(preAlign_slice,1),size(preAlign_slice,2) ); % time x object

for objInd1 = 1:objCount
    for objInd2 = (objInd1+1):objCount
        trace1  = preAlign_unflat(:,objInd1);
        trace2  = preAlign_unflat(:,objInd2);
        
        score1  = score_unflat(:,objInd1);
        score2  = score_unflat(:,objInd2);
        
        % find a dimension that maximizes the variance between these
        % objects
        del = trace1 - trace2;
        thisVar = var(del);
        
        if thisVar > varMax
            varMax   = thisVar;
            indices_ = [objInd1, objInd2];
            keptTraces = [trace1,trace2];
        end
    end
end

% figure,plot( keptTraces(:,1) ),hold all,plot( keptTraces(:,2) )

%%
% then plot 32 traces: 2 contexts x 2 objects x 2 projection axes x 2 alignments x 2 (full or ortho)
pre_on_pre_full = permute(preAlign_full,[4,1,2,3]);
pre_on_pre_full = pre_on_pre_full(:,:)';
pre_on_pre_full_var = sum( var(pre_on_pre_full) );

pre_on_pre_full = pre_on_pre_full * preAlignPC(:,1); %coeff_(:,1);
pre_on_pre_full_pcvar = var(pre_on_pre_full);

pre_on_pre_full = reshape( pre_on_pre_full,size(preAlign_full,1),...
    size(preAlign_full,2),size(preAlign_full,3) );
pre_on_pre_full = pre_on_pre_full(:,indices_,:); % 4 plots: 2 objects x 2 contexts


pre_on_pre_ortho = permute(preAlign_ortho,[4,1,2,3]);
pre_on_pre_ortho = pre_on_pre_ortho(:,:)';
pre_on_pre_ortho_var = sum( var(pre_on_pre_ortho) );

pre_on_pre_ortho = pre_on_pre_ortho * preAlignPC(:,1); %coeff_(:,1);
pre_on_pre_ortho_pcvar = var(pre_on_pre_ortho);

pre_on_pre_ortho = reshape( pre_on_pre_ortho,size(preAlign_ortho,1),...
    size(preAlign_ortho,2),size(preAlign_ortho,3) );
pre_on_pre_ortho = pre_on_pre_ortho(:,indices_,:); % 8 plots


pre_on_post_full = permute(preAlign_full,[4,1,2,3]);
pre_on_post_full = pre_on_post_full(:,:)';
pre_on_post_full_var = sum( var(pre_on_post_full) );

pre_on_post_full = pre_on_post_full * periAlignPC(:,1); %coeff(:,1);
pre_on_post_full_pcvar = var(pre_on_post_full);

pre_on_post_full = reshape( pre_on_post_full,size(preAlign_full,1),...
    size(preAlign_full,2),size(preAlign_full,3) );
pre_on_post_full = pre_on_post_full(:,indices,:); % 12 plots


pre_on_post_ortho = permute(preAlign_ortho,[4,1,2,3]);
pre_on_post_ortho = pre_on_post_ortho(:,:)';
pre_on_post_ortho_var = sum( var(pre_on_post_ortho) );

pre_on_post_ortho = pre_on_post_ortho * periAlignPC(:,1); %coeff(:,1);
pre_on_post_ortho_pcvar = var(pre_on_post_ortho);

pre_on_post_ortho = reshape( pre_on_post_ortho,size(preAlign_ortho,1),...
    size(preAlign_ortho,2),size(preAlign_ortho,3) );
pre_on_post_ortho = pre_on_post_ortho(:,indices,:); % 16 plots


post_on_pre_full = permute(periAlign_full,[4,1,2,3]);
post_on_pre_full = post_on_pre_full(:,:)';
post_on_pre_full_var = sum( var(post_on_pre_full) );

post_on_pre_full = post_on_pre_full * preAlignPC(:,1);%coeff_(:,1);
post_on_pre_full_pcvar = var(post_on_pre_full);

post_on_pre_full = reshape( post_on_pre_full,size(periAlign_full,1),...
    size(periAlign_full,2),size(periAlign_full,3) );
post_on_pre_full = post_on_pre_full(:,indices_,:); % 20


post_on_pre_ortho = permute(periAlign_ortho,[4,1,2,3]);
post_on_pre_ortho = post_on_pre_ortho(:,:)';
post_on_pre_ortho_var = sum( var(post_on_pre_ortho) );

post_on_pre_ortho = post_on_pre_ortho * preAlignPC(:,1);%coeff_(:,1);
post_on_pre_ortho_pcvar = var(post_on_pre_ortho);

post_on_pre_ortho = reshape( post_on_pre_ortho,size(periAlign_ortho,1),...
    size(periAlign_ortho,2),size(periAlign_ortho,3) );
post_on_pre_ortho = post_on_pre_ortho(:,indices_,:); % 24


post_on_post_full = permute(periAlign_full,[4,1,2,3]);
post_on_post_full = post_on_post_full(:,:)';
post_on_post_full_var = sum( var(post_on_post_full) );

post_on_post_full = post_on_post_full * periAlignPC(:,1); %coeff(:,1);
post_on_post_full_pcvar = var(post_on_post_full);

post_on_post_full = reshape( post_on_post_full,size(periAlign_full,1),...
    size(periAlign_full,2),size(periAlign_full,3) );
post_on_post_full = post_on_post_full(:,indices,:); % 28


post_on_post_ortho = permute(periAlign_ortho,[4,1,2,3]);
post_on_post_ortho = post_on_post_ortho(:,:)';
post_on_post_ortho_var = sum( var(post_on_post_ortho) );

post_on_post_ortho = post_on_post_ortho * periAlignPC(:,1); %coeff(:,1);
post_on_post_ortho_pcvar = var(post_on_post_ortho);

post_on_post_ortho = reshape( post_on_post_ortho,size(periAlign_ortho,1),...
    size(periAlign_ortho,2),size(periAlign_ortho,3) );
post_on_post_ortho = post_on_post_ortho(:,indices,:); % 32


%% now plot em

% projections onto the pre-space
preSpaceFull  = vertcat(pre_on_pre_full,post_on_pre_full);
preSpaceOrtho = vertcat(pre_on_pre_ortho,post_on_pre_ortho);

% on the post-space
postSpaceFull  = vertcat(pre_on_post_full,post_on_post_full);
postSpaceOrtho = vertcat(pre_on_post_ortho,post_on_post_ortho);

% get limits
yl_pre  = [min( vertcat( preSpaceFull(:),preSpaceOrtho(:) ) ),...
    max( vertcat( preSpaceFull(:),preSpaceOrtho(:) ) )];
yl_post = [min( vertcat( postSpaceFull(:),postSpaceOrtho(:) ) ),...
    max( vertcat( postSpaceFull(:),postSpaceOrtho(:) ) )];

contextClors  = lines(2);

axes(handles.projectionPlot0)
cla
axes(handles.projectionPlot1)
cla
for objInd = 1:2
    for contextInd = 1:2
        if contextInd == 1
            axes(handles.projectionPlot0) %#ok<*LAXES>
        else
            axes(handles.projectionPlot1)
        end
        fullTrace  = preSpaceFull(:,objInd,contextInd);
        orthoTrace = preSpaceOrtho(:,objInd,contextInd);
        
        if objInd == 1
            clor = contextClors(contextInd,:);
        else
            clor = [0.7 0.7 0.7];
        end
        
        for whichAlign = 1:3
            switch whichAlign
                case 1
                    inds  = 1:50;
                    addMe = 0;
                case 2
                    inds  = 51:150;
                    addMe = 15;
                case 3
                    inds  = 151:250;
                    addMe = 30;
            end
            
            hold all
            plot(inds+addMe,fullTrace(inds),'linewidth',2,'linestyle','-',...
                'color',clor)
            
            hold all
            plot(inds+addMe,orthoTrace(inds),'linewidth',1,'linestyle','--',...
                'color',clor)
        end
    end
end

olabs = oNames{seshIdx}(indices_);
hasSpace = cellfun(@(x) ~isempty(regexpi(x,'(\s|\d)','once')),olabs);

if any(hasSpace)
    olabs(hasSpace) = cellfun(@(x) regexpi(x,'(\s|\d)','split'),...
        olabs(hasSpace),'uniformoutput',false);
    olabs(hasSpace) = cellfun(@(x) x{1},olabs(hasSpace),'uniformoutput',false);
end

areSpecial = cellfun(@(x) strcmpi(x,'Special'),olabs);
olabs(areSpecial) = cellfun(@(x) 'Abstract',olabs(areSpecial),'uniformoutput',false);

axes(handles.projectionPlot0)
axis tight
ylim(yl_pre)
xlabel('Time (ms)')
ylabel('First visual principal component')
customlegend(olabs,'colors',[contextClors(1,:);0.7 0.7 0.7])
set(gca,'xtick',[1 50 115.5 165 230.5 280],'xticklabel',{'Object Illumination',...
    '+500','Go cue','+500','Object Lift','+500'},...
    'xticklabelrotation',-45)

axes(handles.projectionPlot1)
axis tight
ylim(yl_pre)
xlabel('Time (ms)')
ylabel('First visual principal component')
customlegend(olabs,'colors',[contextClors(2,:);0.7 0.7 0.7])
set(gca,'xtick',[1 50 115.5 165 230.5 280],'xticklabel',{'Object Illumination',...
    '+500','Go cue','+500','Object Lift','+500'},...
    'xticklabelrotation',-45)

axes(handles.projectionPlot2)
cla
axes(handles.projectionPlot3)
cla
for objInd = 1:2
    for contextInd = 1:2
        if contextInd == 1
            axes(handles.projectionPlot2)
        else
            axes(handles.projectionPlot3)
        end
        fullTrace  = postSpaceFull(:,objInd,contextInd);
        orthoTrace = postSpaceOrtho(:,objInd,contextInd);
        
        if objInd == 1
            clor = contextClors(contextInd,:);
        else
            clor = [0.7 0.7 0.7];
        end
        
        for whichAlign = 1:3
            switch whichAlign
                case 1
                    inds  = 1:50;
                    addMe = 0;
                case 2
                    inds  = 51:150;
                    addMe = 15;
                case 3
                    inds  = 151:250;
                    addMe = 30;
            end
            
            hold all
            plot(inds+addMe,fullTrace(inds),'linewidth',2,'linestyle','-',...
                'color',clor)
            
            hold all
            plot(inds+addMe,orthoTrace(inds),'linewidth',1,'linestyle','--',...
                'color',clor)
        end
    end
end

olabs = oNames{seshIdx}(indices);
hasSpace = cellfun(@(x) ~isempty(regexpi(x,'(\s|\d)','once')),olabs);

if any(hasSpace)
    olabs(hasSpace) = cellfun(@(x) regexpi(x,'(\s|\d)','split'),...
        olabs(hasSpace),'uniformoutput',false);
    olabs(hasSpace) = cellfun(@(x) x{1},olabs(hasSpace),'uniformoutput',false);
end

areSpecial = cellfun(@(x) strcmpi(x,'Special'),olabs);
olabs(areSpecial) = cellfun(@(x) 'Abstract',olabs(areSpecial),'uniformoutput',false);

axes(handles.projectionPlot2)
axis tight
ylim(yl_post)
xlabel('Time (ms)')
ylabel('First movement principal component')
customlegend(olabs,'colors',[contextClors(1,:);0.7 0.7 0.7])
set(gca,'xtick',[1 50 115.5 165 230.5 280],'xticklabel',{'Object Illumination',...
    '+500','Go cue','+500','Object Lift','+500'},...
    'xticklabelrotation',-45)

axes(handles.projectionPlot3)
axis tight
ylim(yl_post)
xlabel('Time (ms)')
ylabel('First movement principal component')
customlegend(olabs,'colors',[contextClors(2,:);0.7 0.7 0.7])
set(gca,'xtick',[1 50 115.5 165 230.5 280],'xticklabel',{'Object Illumination',...
    '+500','Go cue','+500','Object Lift','+500'},...
    'xticklabelrotation',-45)
%% now put it in the gui
