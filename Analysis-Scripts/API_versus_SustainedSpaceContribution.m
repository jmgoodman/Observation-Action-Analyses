%% step 0: setup
close all
clc
analysis_setup;

seshnames = {'Moe46','Moe50','Zara64','Zara68','Zara70'};

%% step 1: load the proper data (test on one session first)
clustout   = load(fullfile('..','Analysis-Outputs','clustfiles','clustout_stats.mat'));

for seshid = 1:numel(seshnames)
    seshname = seshnames{seshid};
    sustainout = load( fullfile('..','Analysis-Outputs',seshname,sprintf('sustainspace_results_%s.mat',seshname)) );
    data       = load( fullfile('..','MirrorData',sprintf('%s_datastruct.mat',seshname)) );
    
    [pooleddata,arraynames] = poolarrays(data.datastruct.cellform);
    triallabels             = extractlabels(pooleddata);
    
    %% step 2: focus on movement-period data (the same data used for API calcs)
    % this means concatenate post-start and pre-hold epochs
    
    movdata = cellfun(@(x) vertcat( x{5}.Data(51:end,:,:),x{6}.Data(1:50,:,:) ),...
        pooleddata,'uniformoutput',false);
    
    % add pooled data
    movdata{4}    = horzcat(movdata{:});
    arraynames{4} = 'pooled';
    
    % restrict to VGG trials
    movdata_vgg   = cellfun(@(x) x(:,:,strcmp( triallabels.trialcontexts.names,'active' )),...
        movdata,'uniformoutput',false);
    
    % flatten
    movdata_flat = cellfun(@(x) reshape( permute(x,[2,1,3]),size(x,2),[] )',...
        movdata_vgg,'uniformoutput',false);
    
    % centralize (don't use the mean fit to the sustained period, variance is
    % computed w.r.t. the *local* mean!)
    movdata_dm   = cellfun(@(x) bsxfun(@minus,x,mean(x)),movdata_flat,'uniformoutput',false);
    
    % project & reproject
    sspace       = arrayfun(@(x) x.regular.coeff(:,1:x.regular.ncomp), ...
        sustainout.sustainspace_aggressive,'uniformoutput',false);
    movdata_proj = cellfun(@(x,y) x * (y*y'),movdata_dm(:),sspace(:),'uniformoutput',false);
    
    % variance capture on a neuron-by-neuron basis
    vtot         = cellfun(@(x) var(x), movdata_dm,'uniformoutput',false);
    vcap         = cellfun(@(x,y) 1 - var(x-y)./(var(x)),...
        movdata_dm,movdata_proj,'uniformoutput',false);
    
    % okay yeah, negative reconstruction values are possible on a neuron-by-neuron basis
    % when taken in AGGREGATE, the effect of pooling these dimensions together
    % is to get a better reconstruction!
    
    % anyway, let's pair vcaps with the appropriate index values
    contrast_indices = cell(size(vcap));
    
    for ii = 1:numel(contrast_indices)
        contrast_indices{ii}  = clustout.contraststruct(seshid).(arraynames{ii});
    end
    
    %% step 3: make plots!
    colorData = defColorConvention();
    figure('name',seshname)
    for areaind = 1:numel(contrast_indices)
        X = vcap{areaind}(:);
        Y = contrast_indices{areaind}(:);
        
        coloridx = strcmpi( colorData.labels,arraynames{areaind} );
        colorval = colorData.colors(coloridx,:);
        
        kickout = isnan(Y) | vtot{areaind}(:) < 1e-2;
        
        % mean(kickout)
        
        X = X(~kickout);
        Y = Y(~kickout);
        
        subplot(2,2,areaind)
        scatter(X,Y,36,colorval,'markeredgecolor',colorval)
        xlabel('FVE by Orthogonal Space During Movement')
        ylabel('Active-Passive Index')
        
        R = corr(X,Y);
        title(sprintf('%s: R = %0.4f',arraynames{areaind},R))
        
        axis tight
        % set(gca,'xlim',[0 1])
        set(gca,'ylim',[-1 1])
        
        lsl = lsline;
        set(lsl,'linewidth',1,'color',[0 0 0])
        
        box off, axis square
    end
    print(fullfile('..','Analysis-Outputs',sprintf('%s_API-vs-OrthoFVE.svg',seshname)),'-dsvg')
    print(fullfile('..','Analysis-Outputs',sprintf('%s_API-vs-OrthoFVE.png',seshname)),'-dpng','-r300')
end
