%% find the supplemental subsampling analysis results
D = dir('*-subsample-*.mat');
addpath('../Analysis-Scripts')
analysis_setup;

for ii = 1:numel(D)
    ffname = fullfile(D(ii).folder,D(ii).name);
    load(ffname);
    outputs = squeeze(outputs);

    %% arrange the results for plotting / stats
    active = squeeze( outputs(2,1,:) );
    passive = squeeze( outputs(2,2,:) );
    activeaccs  = arrayfun(@(x) squeeze( x.classificationAccuracyCell(:,1,1,2:3,2:3,:,:) ),active,'uniformoutput',false);
    passiveaccs = arrayfun(@(x) squeeze( x.classificationAccuracyCell(:,1,1,2:3,2:3,:,:) ),passive,'uniformoutput',false);
    
    % concatenate across k folds
    % AIP - F5 - M1 - pooled - chance
    activeaccs  = cellfun(@(subsampsize) cellfun(@(analysisparams) mean(horzcat(analysisparams{:}),2),...
        subsampsize,'uniformoutput',false),activeaccs,'uniformoutput',false);
    passiveaccs = cellfun(@(subsampsize) cellfun(@(analysisparams) mean(horzcat(analysisparams{:}),2),...
        subsampsize,'uniformoutput',false),passiveaccs,'uniformoutput',false);
    
    % pool across alignments, find the one with the max mean performance across
    % subsamplings
    %
    % fit separately for both contexts to give the passive context the best
    % chance possible
    activeaccs  = cellfun(@(x) x(:,:),activeaccs,'uniformoutput',false);
    passiveaccs = cellfun(@(x) x(:,:),passiveaccs,'uniformoutput',false);
    
    nsizes  = 10;
    niter   = 100;
    narea   = 5;
    nalign  = 36;
    
    act = zeros(nsizes,narea,niter,nalign);
    pas = zeros(nsizes,narea,niter,nalign);
    
    for sizeind = 1:nsizes
        act_ = activeaccs{sizeind};
        pas_ = passiveaccs{sizeind};
        
        for iterind = 1:niter
            act__ = act_(iterind,:);
            pas__ = pas_(iterind,:);
            
            for areaind = 1:narea
                actarea = cellfun(@(x) x(areaind),act__);
                pasarea = cellfun(@(x) x(areaind),pas__);
                
                act(sizeind,areaind,iterind,:) = actarea;
                pas(sizeind,areaind,iterind,:) = pasarea;
            end
        end
    end
    
    [~,actmaxind] = max( squeeze( mean(act,3) ),[],3 );
    [~,pasmaxind] = max( squeeze( mean(pas,3) ),[],3 );
    
    actmax = zeros( [size(actmaxind),niter] );
    pasmax = zeros( [size(pasmaxind),niter] );
    
    for sizeind = 1:nsizes
        for areaind = 1:narea
            ami = actmaxind(sizeind,areaind);
            pmi = pasmaxind(sizeind,areaind);
            
            actmax(sizeind,areaind,:) = act(sizeind,areaind,:,ami);
            pasmax(sizeind,areaind,:) = pas(sizeind,areaind,:,pmi);
        end
    end
    
    actmu = mean(actmax,3);
    pasmu = mean(pasmax,3);
    actsd = std(actmax,0,3);
    passd = std(pasmax,0,3);
    
    fracs = arrayfun(@(x) x.subsampleFraction,squeeze( outputs(1,1,:) ));
    
    cconv = defColorConvention;
    cconv.colors = cconv.colors([2:4,1],:);
    cconv.labels = cconv.labels([2:4,1]);
    
    figure
    for areaind = 1:4
        errorbar(fracs,actmu(:,areaind),actsd(:,areaind),'color',cconv.colors(areaind,:),'linewidth',2),hold all
        errorbar(fracs,pasmu(:,areaind),passd(:,areaind),'color',0.5 + 0.5*cconv.colors(areaind,:),'linewidth',2),hold all
    end
    
    customlegend(cconv.labels,'colors',cconv.colors);
    xlabel('Fraction of original population preserved')
    ylabel('Peak classification accuracy')
    xlim([0 1])
    ylim([0 1])
    box off
    
    % and show the chance level
    chanceLevel = ( mean( actmu(:,5) ) + mean( pasmu(:,5) ) ) / 2;
    hold all
    line(get(gca,'xlim'),chanceLevel*[1 1],'linewidth',2,'linestyle','--','color',[0 0 0])
    
    title([outputs(1).sessionName(1),outputs(1).sessionName((end-1):end)])
    
    targetFontSize = 16;
    aa = gca;
    set(aa,'fontsize',targetFontSize);
    textObjs = findobj(aa.Children,'-property','fontsize');
    
    for objInd = 1:numel(textObjs)
        set(textObjs(objInd),'fontsize',targetFontSize)
    end
    
    plotPreviewWrapper(aa)
    pause
end


    
    
    