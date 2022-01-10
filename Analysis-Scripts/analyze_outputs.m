clear
clc
close all
restoredefaultpath
analysis_setup

%%
fldr = {'Moe50','Zara70_withKinematics'};

for ii = 1:numel(fldr)
    fname_common = fullfile('..','Analysis-Outputs',fldr{ii},...
        sprintf('commonspace_results_%s.mat',fldr{ii}));
    cspace_ = load(fname_common);
    
    fname_sus   = fullfile('..','Analysis-Outputs',fldr{ii},...
        sprintf('sustainspace_results_%s.mat',fldr{ii}));
    sus_  = load(fname_sus);
    
    %% thing to know 1: variance captured by different partitions of the common space
    % (in lieu of a proper classification analysis)
    lfuns = cellfun(@(x) x.lossfunction,cspace_.commonspace_FXVE_mov.subsamples,...
        'uniformoutput',false);
    lfcat = cat(3,lfuns{:});
    lfsum = sum(lfcat,3);
    
    [~,mininds] = min(lfsum,[],2);
    
    edata = cell(numel(mininds),1);
    odata = cell(numel(mininds),1);
    
    for jj = 1:numel(mininds)
        edata{jj} = cellfun(@(x) x.exec{jj,mininds(jj)},...
            cspace_.commonspace_FXVE_mov.subsamples,...
            'uniformoutput',false);
        odata{jj} = cellfun(@(x) x.obs{jj,mininds(jj)},...
            cspace_.commonspace_FXVE_mov.subsamples,...
            'uniformoutput',false);
    end
    
    % reshape
    edata_ = cellfun(@(x,y) ...
        cellfun(@(a) reshape(a',y,100,[]),x,'uniformoutput',false),...
        edata,num2cell(mininds),'uniformoutput',false);
    odata_ = cellfun(@(x,y) ...
        cellfun(@(a) reshape(a',y,100,[]),x,'uniformoutput',false),...
        odata,num2cell(mininds),'uniformoutput',false);
    
    % concatenate (which means, yes, mixing context dependency into the mix... which makes this a very CONSERVATIVE test of "too little object variance" (i.e., good for "proving a negative")
    cdata_ = cellfun(@(x,y) ...
        cellfun(@(a,b) cat(3,a,b),x,y,'uniformoutput',false),...
        edata_,odata_,'uniformoutput',false);
    
    % demean
    cdatadm = cellfun(@(x) cellfun(@(a) bsxfun(@minus,a,mean(a(:,:),2)),...
        x,'uniformoutput',false),cdata_,'uniformoutput',false);
        
    % calculate cross-condition mean (because you're dealing with trial-averaged data, the corollary is that any variance NOT explained by this component is that which differentiates among objects)
    % well, okay, there might be a LITTLE variance that differentiates among CONDITIONS...
    % ...but the WHOLE POINT of your optimization was to MINIMIZE that variance!
    % in other words, just *ASSUME* that & get this corollary-derived number!
    % this should be the most favorable toward mirror neurons anyway...
    cxcmu  = cellfun(@(x) cellfun(@(a) repmat( mean(a,3),1,1,size(a,3) ),...
        x,'uniformoutput',false), cdatadm,'uniformoutput',false);
    
    cresid = cellfun(@(x,y) cellfun(@(a,b) a-b,x,y,'uniformoutput',false),...
        cdatadm,cxcmu,'uniformoutput',false); % here, residuals include both object AND context dependent activity. The latter *should* be quite low variance, and in any case allows us to estimate an upper bound on object-related information when making a corollary argument based on the condition-independent component.
    
    % sum of squares = squared frobenium norm = measure of total variance
    fnormcomp = @(X) cellfun(@(x) cellfun(@(a) sum(a(:).^2),x),X,'uniformoutput',false);
    cmufnorm = fnormcomp(cxcmu);
    crefnorm = fnormcomp(cresid);
    
    % fractions explained by the mu component
    FVCMU    = cellfun(@(cmu,cre) cmu./(cmu+cre),cmufnorm,crefnorm,'uniformoutput',false);
    
    %% answer: 80-85% of the variance is commanded by the common component (justifying the classification analysis)
    
    %% thing I want to know 2: variance captured, during movement, by the visual sustained component
    % (i.e., how much variance is preserved by this transformation?)
    load(fullfile('..','MirrorData',sprintf('%s_datastruct.mat',fldr{ii})))
    [pdatacell,anames] = poolarrays(datastruct.cellform);
    
    % take movement-period activity
    movdata = cellfun(@(x) reshape( permute(x{5}.Data,[2,1,3]),numel(x{5}.ArrayIDs),[] )',...
        pdatacell,'uniformoutput',false);
    
    mddm    = cellfun(@(x) bsxfun(@minus,x,mean(x)),movdata,'uniformoutput',false);
    mddm    = vertcat(mddm, horzcat(mddm{:})); %#ok<AGROW>
    
    % project!
    sspace  = arrayfun(@(x) x.timeaveraged.coeff( :,1:(x.timeaveraged.ncomp) ),sus_.sustainspace,'uniformoutput',false);
    mddm_proj = cellfun(@(x,y) x*y,mddm,sspace(:),'uniformoutput',false);
    
    % squared fronorm!
    fullfnorm = cellfun(@(x) sum(x(:).^2),mddm);
    projfnorm = cellfun(@(x) sum(x(:).^2),mddm_proj);
    rats      = 1 - projfnorm ./ fullfnorm; % fraction of variance left after removal
    
    
    
end