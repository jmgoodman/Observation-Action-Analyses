function sustainspace = findsustainspace(celldata,align_,criterion_)
% identifies the space spanned by sustained, condition-varying activity which manifests prior to the go cue,
% and which could correspond to any or all of the following (non-exhaustive):
%   1) odd expectation / baseline effects related to turntables
%   2) visual memory
%   3) (during VGG and Obs) visual feedback per se
%   4) a motor plan (instantiated as "initial conditions"?)
%
% we determine this space so we can orthogonalize movement-period activity w.r.t. it.
% we apply tests to determine
%   1) how much do we hurt pre-movement classification (at various epochs) by orthogonalizing w.r.t. this space? (across obs and execution)
%   2) how much do we hurt during- and post-movement classification? (across obs and execution)
%   3) how much do we actually change the object-dependent and time-dependent variation of the PCs when ortho

if (nargin == 1) || isempty(align_)
    align_ = 'both';
else
    assert( strcmpi(align_,'pregocue') || strcmpi(align_,'postlighton') || strcmpi(align_,'both'),'second input must be a string specifying alignment: "pregocue", "postlighton", or "both" (default: "both")' );
end

align_ = lower(align_);

if nargin < 3
    criterion_ = 'ZhuGhodsi';
else
    validmethods = {'ZhuGhodsi','BetterThanMeanNeuron','95percent'};
    assert( ismember(criterion_,validmethods),'third input must be a string specifying PCA criterion: "ZhuGhodsi", "BetterThanMeanNeuron", or "95percent".');
end

criterion_ = lower(criterion_);

triallabels = extractlabels(celldata);

% pool arrays to consider M1, F5, and AIP, instead of splitting among them
[pooledarraydatacell,arraynames] = poolarrays(celldata);

% 1 fixation / 2 light on / 3 light off / 4 cue onset / 5 move onset / 6 hold onset / 7 reward onset
switch align_
    case 'pregocue'
        memdata = cellfun(@(x) x{4}.Data(1:50,:,:),...
            pooledarraydatacell,'uniformoutput',false); % pre-cue (captures baseline, vision, visual memory [though the light never turns off...], early preparatory, and movement withholding signals)
    case 'postlighton'
        memdata = cellfun(@(x) x{2}.Data(51:end,:,:),...
            pooledarraydatacell,'uniformoutput',false); % post-light (captures baseline & vision, with less of the others, except maybe for movement withholding)
    case 'both'
        md0 = cellfun(@(x) x{2}.Data(51:end,:,:),...
            pooledarraydatacell,'uniformoutput',false); % postlighton
        md1 = cellfun(@(x) x{4}.Data(1:50,:,:),...
            pooledarraydatacell,'uniformoutput',false); % pregocue
        memdata = cellfun(@(x,y) cat(1,x,y),md0,md1,'uniformoutput',false);
        clear md0 md1
end

targetcontexts = {'active','passive'};

keeptrials     = ismember(triallabels.trialcontexts.names,targetcontexts);

keptlabels     = triallabels;
fn             = fieldnames(triallabels);

for fnind = 1:numel(fn)
    keptlabels.(fn{fnind}).names      = keptlabels.(fn{fnind}).names(keeptrials);
    keptlabels.(fn{fnind}).uniqueinds = keptlabels.(fn{fnind}).uniqueinds(keeptrials);
end

keptlabels.trialcontexts.uniquenames      = targetcontexts;
keptlabels.trialcontexts.nunique          = numel(targetcontexts);
[~,~,keptlabels.trialcontexts.uniqueinds] = unique(keptlabels.trialcontexts.uniqueinds);

keptdata = cellfun(@(x) x(:,:,keeptrials),memdata,'uniformoutput',false); % note: normalization is based on max rates which INCLUDE the "control" trials. you exclude them here. so if you ever get results that seem to defy the logic of your analysis pipeline at first glance... that's why!!!

% use TT x object x context to make the sorted trial average for each area
[~,~,trialsortlabels] = unique( [keptlabels.trialcontexts.uniqueinds,...
    keptlabels.turntablelabels.uniqueinds,...
    keptlabels.objects.uniqueinds],'rows' );

stacell = cell(size(arraynames));
for aind = 1:numel(arraynames)
    sortedtrialaverage = makesortedtrialaverage(keptdata{aind},trialsortlabels);
    stacell{aind}      = sortedtrialaverage;
end

% for each array, compute PCA, then use the Zhu-Ghodsi knee method to determine (CONSERVATIVELY!) the number of dimensions with respect to which you should be orthogonalizing.
sustainspacecell = cell(numel(arraynames)+1,1);
for aind = 1:(numel(arraynames)+1)
    
    if aind <= numel(arraynames)
        thissta      = stacell{aind}; % time x neurons x condition
        aname        = arraynames{aind};
    else
        thissta  = cat(2,stacell{:});
        aname    = 'all';
    end
    
    thismu       = squeeze( nanmean(thissta,1) ); % neurons x condition (capturing that "sustained component"; we're trying to be conservative here, that sustained component is the one most likely to just be visual) 
    % (note that this is, indeed, equal to taking the grand mean, as trial counts are matched when averaging across time bins within condition) 
    % (that said, just LOOK at the heatmaps! there is barely any difference between the time-averaged and non-time-averaged cases)
    % (indeed, there is less than 10 degrees' distance between the top PCs from the time-averaged and not)
    mutranspose  = thismu'; % condition x neurons
    
    % let's compute the variance captured by the time average, just to be sure
    % IN OTHER WORDS: R2
    thismu_rep      = repmat( nanmean(thissta,1), size(thissta,1),1,1 );
    
    mdlresids       = thissta - thismu_rep;
    
    mdlresidsperm   = permute(mdlresids,[2,1,3]); % neur x time x cond
    mdlresidsflat   = mdlresidsperm(:,:)';
    
    staperm         = permute(thissta,[2,1,3]);
    staflat         = staperm(:,:)';
    nullresidsflat  = bsxfun(@minus,staflat,nanmean(staflat,1));
    
    R2              = 1 - norm(mdlresidsflat,'fro')^2 / norm(nullresidsflat,'fro')^2;
    
    %%
    % now to do PCA
    [coeff,~,latent,~,~,mu] = pca(mutranspose);
    
    %% decide between Zhu-Ghodsi, Better-than-single-neuron, and 95% variance using inputs from an options struct
    switch criterion_
        case 'zhughodsi'
            %%
            [n_zg,LL_zg]            = ZhuGhodsiKnee(latent); % relatively conservative...
            
            %%
        case 'betterthanmeanneuron'
            n_zg  = find( latent > mean(var(staflat)),1,'last' ); % aggressive method for determining knee (basically, the "better than the average single rate-normalized neuron" criterion)
            LL_zg = mean(var(staflat)); % use this to indicate the average rate-normalized neuron's variance
            
        case '95percent'
            %% super aggressive 95% criterion (GOTTA do it like this, otherwise you end up with WAY too much residual classification accuracy!)
            n_zg  = find( cumsum(latent) > 0.95*sum(latent),1,'first' );
            LL_zg = 0.95*sum(latent);
        otherwise
            % pass
    end
    
    %%
    % do it with the time-averaged data
    tempstruct.timeaveraged.coeff             = coeff;
    tempstruct.timeaveraged.latent            = latent;
    tempstruct.timeaveraged.ncomp             = n_zg;
    tempstruct.timeaveraged.candidatecutoffLL = LL_zg;
    tempstruct.timeaveraged.mu                = mu;
    %     tempstruct.timeaveraged.array             = arraynames{aind};
    
    %%
    % do PCA without time-averaging anyway, just to see if anything changes
    %     staperm = permute(thissta,[2,1,3]); % neur x time x cond % already done for you
    %     staflat = staperm(:,:)'; % (time x cond) x neur
    
    [coeff,~,latent,~,~,mu] = pca(staflat);
    
    %% select criterion again
    switch criterion_
        case 'zhughodsi'
            %%
            [n_zg,LL_zg]            = ZhuGhodsiKnee(latent); % relatively conservative...
            
            %%
        case 'betterthanmeanneuron'
            n_zg  = find( latent > mean(var(staflat)),1,'last' ); % aggressive method for determining knee (basically, the "better than the average single rate-normalized neuron" criterion)
            LL_zg = mean(var(staflat)); % use this to indicate the average rate-normalized neuron's variance
            
        case '95percent'
            %% super aggressive 95% criterion (GOTTA do it like this, otherwise you end up with WAY too much residual classification accuracy!)
            n_zg  = find( cumsum(latent) > 0.95*sum(latent),1,'first' );
            LL_zg = 0.95*sum(latent);
        otherwise
            % pass
    end
    
    %%
    % do it with the "regular" data
    tempstruct.regular.coeff             = coeff;
    tempstruct.regular.latent            = latent;
    tempstruct.regular.ncomp             = n_zg;
    tempstruct.regular.candidatecutoffLL = LL_zg;
    tempstruct.regular.mu                = mu;
    %     tempstruct.regular.array             = arraynames{aind};
    
    tempstruct.array = aname; %arraynames{aind};
    tempstruct.R2    = R2; % variance of the "regular" data captured by the timeaveraged data
    tempstruct.align = align_;
    
    sustainspacecell{aind}       = tempstruct;
    clear tempstruct
end

% turn into a struct
sustainspacestruct(1) = sustainspacecell{1};
for aind = 2:numel(arraynames)
    sustainspacestruct(aind) = sustainspacecell{aind}; %#ok<AGROW>
end

sustainspacestruct( numel(arraynames)+1 ) = sustainspacecell{ numel(arraynames)+1 };

sustainspace = sustainspacestruct; 
end
