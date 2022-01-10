function commonspace = findcommonspace(celldata,sustainspace,lossmode,alignmode)

% commonspace: a struct containing information about the common space
% celldata: data in cell format
% sustainspace: a struct containing info about the sustained-activity space (found via "findsustainspace")
% lossmode: string reading 'FXVE' or 'GScorr', standing for "Fraction cross-variance explained" or "Gram-Schmidt correlation" loss functions, respectively.
% alignmode: string reading 'move' or 'hold' or 'both'. default 'both'.

%%
% naturally, it would've been nice to have an "options" struct for this, the same way there is for the surrogate creation and classification methods. Maybe I'll implement that at a later date...
% ...or maybe the GitHub folks will just have to live with this gross inconsistency, as pushing this to publication-ready status kinda takes priority
% nah it'll take like 5 minutes to, like, do it *right*
% (but like... what about debugging? that's the scary part imo...)

%%
% defaults: sustainspace=[],lossmode='FXVE'
if nargin < 2
    sustainspace = [];
end

if (nargin < 3) || isempty(lossmode)
    lossmode = 'FXVE';
end

if nargin < 4
    alignmode = 'both';
end

triallabels = extractlabels(celldata);
[pooledarraydatacell,arraynames] = poolarrays(celldata);

% 1 fixation / 2 light on / 3 light off / 4 cue onset / 5 move onset / 6 hold onset / 7 reward onset
movdata  = cellfun(@(x) x{5}.Data,...
    pooledarraydatacell,'uniformoutput',false);
holddata = cellfun(@(x) x{6}.Data,...
    pooledarraydatacell,'uniformoutput',false); % also account for hold-aligned data, as I believe these later alignments may hold the key, actually...
bothdata = cellfun(@(x,y) cat(1,x,y),movdata,holddata,'uniformoutput',false);

% below, we process the cellform data to only include trials from the active & passive conditions; no MGG! (for now)
targetcontexts = {'active','passive'};

keeptrials = ismember(triallabels.trialcontexts.names,targetcontexts);

keptlabels = triallabels;
fn         = fieldnames(triallabels);

for fnind = 1:numel(fn)
    keptlabels.(fn{fnind}).names      = keptlabels.(fn{fnind}).names(keeptrials);
    keptlabels.(fn{fnind}).uniqueinds = keptlabels.(fn{fnind}).uniqueinds(keeptrials);
end

keptlabels.trialcontexts.uniquenames      = targetcontexts;
keptlabels.trialcontexts.nunique          = numel(targetcontexts);
[~,~,keptlabels.trialcontexts.uniqueinds] = unique(keptlabels.trialcontexts.uniqueinds);

keptmov  = cellfun(@(x) x(:,:,keeptrials),movdata,'uniformoutput',false);
kepthold = cellfun(@(x) x(:,:,keeptrials),holddata,'uniformoutput',false);
keptboth = cellfun(@(x) x(:,:,keeptrials),bothdata,'uniformoutput',false);

% use object x context to compute trial averages
% (the idea is: you've eliminated the sustained component, which was the main way turntable information was preserved during grasps of the same damn object. obviously, though, you'll want to output a test of this assumption...)
travrowcount = keptlabels.objects.nunique * size( keptmov{1},1 ); % TRial AVerage rowcount

movE  = cellfun(@(x) nan(travrowcount,size(x,2)),keptmov,'uniformoutput',false);
movO  = cellfun(@(x) nan(travrowcount,size(x,2)),keptmov,'uniformoutput',false);
holdE = cellfun(@(x) nan(travrowcount,size(x,2)),kepthold,'uniformoutput',false);
holdO = cellfun(@(x) nan(travrowcount,size(x,2)),kepthold,'uniformoutput',false);
bothE = cellfun(@(x) nan(travrowcount,size(x,2)),keptboth,'uniformoutput',false);
bothO = cellfun(@(x) nan(travrowcount,size(x,2)),keptboth,'uniformoutput',false);

for objectind = 1:keptlabels.objects.nunique
    thisobj = keptlabels.objects.uniqueinds == objectind;
    
    firstind = (objectind-1) * size( keptmov{1},1 ) + 1;
    lastind  = objectind * size( keptmov{1},1 );

    firstboth = (objectind-1) * size(keptboth{1},1)+1;
    lastboth  = objectind * size( keptboth{1},1 );
    
    for contextind = 1:keptlabels.trialcontexts.nunique
        thiscontext = keptlabels.trialcontexts.uniqueinds == contextind;
        this_objXcontext = thisobj & thiscontext;
        movmu            = cellfun(@(x) nanmean( x(:,:,this_objXcontext),3 ),keptmov,'uniformoutput',false);
        holdmu           = cellfun(@(x) nanmean( x(:,:,this_objXcontext),3 ),kepthold,'uniformoutput',false);
        bothmu           = cellfun(@(x) nanmean( x(:,:,this_objXcontext),3 ),keptboth,'uniformoutput',false);
        
        switch contextind
            case 1 % active / execution
                for cellind = 1:numel(movE)
                    movE{cellind}(firstind:lastind,:)  = movmu{cellind};
                    holdE{cellind}(firstind:lastind,:) = holdmu{cellind};
                    bothE{cellind}(firstboth:lastboth,:) = bothmu{cellind};
                end
                
            case 2 % passive / observation
                for cellind = 1:numel(movO)
                    movO{cellind}(firstind:lastind,:)  = movmu{cellind};
                    holdO{cellind}(firstind:lastind,:) = holdmu{cellind};
                    bothO{cellind}(firstboth:lastboth,:) = bothmu{cellind};
                end
                
            otherwise
                % pass
        end
        
    end
    
end
    

% pool across all areas (consider SUBsampling to avoid having some areas being overrepresented in the pooled common manifold merely by virtue of their neuron counts) (but not until AFTER you get rid of the sustained component)
movE{numel(movE)+1}   = horzcat(movE{:});
movO{numel(movO)+1}   = horzcat(movO{:});
holdE{numel(holdE)+1} = horzcat(holdE{:});
holdO{numel(holdO)+1} = horzcat(holdO{:});
bothE{numel(bothE)+1} = horzcat(bothE{:});
bothO{numel(bothO)+1} = horzcat(bothO{:});
arraynames{numel(arraynames)+1} = 'all';

if ~isempty(sustainspace)
    susman = arrayfun(@(x) x.regular.coeff(:,1:x.regular.ncomp),... % use "regular" to squeeze more dimensions out... then use a 95% variance criterion if that still doesn't work...
        sustainspace,'uniformoutput',false);
    susman = susman(1:numel(movE));
    
    orthosusman = cellfun(@(x) eye(size(x,1)) - (x*x'),... % project onto the null of the sustained space, but then re-project back into original space for the sake of keeping track of which area everything comes from in the pooled case (less efficient, more unstable, but less cognitive overhead for me, personally, to convert into an interpretable form)
        susman,'uniformoutput',false);
    
    movEproj  = cellfun(@(x,y) x*y,movE,orthosusman','uniformoutput',false);
    movOproj  = cellfun(@(x,y) x*y,movO,orthosusman','uniformoutput',false);
    holdEproj = cellfun(@(x,y) x*y,holdE,orthosusman','uniformoutput',false);
    holdOproj = cellfun(@(x,y) x*y,holdO,orthosusman','uniformoutput',false);
    bothEproj = cellfun(@(x,y) x*y,bothE,orthosusman','uniformoutput',false);
    bothOproj = cellfun(@(x,y) x*y,bothO,orthosusman','uniformoutput',false);
else   
    movEproj  = movE;
    movOproj  = movO;
    holdEproj = holdE;
    holdOproj = holdO;
    bothEproj = bothE;
    bothOproj = bothO;
end

% save backups
movEproj_  = movEproj;
movOproj_  = movOproj;
holdEproj_ = holdEproj;
holdOproj_ = holdOproj;
bothEproj_ = bothEproj;
bothOproj_ = bothOproj;

% NOW subsample
% implement subsampling: 90% of the sample size of the smallest sample
% (trust that a similar distribution of good/bad units is present across all areas... i.e., trust your sorts)
subsampsize = round( 0.9 * min( cellfun(@(x) size(x,2),keptmov) ) ); % maybe you need to triple this number for the pooled case, so that you can take full advantage of the increased statistical power available in this case, and since once you pool areas you're no longer comparing across areas in quite the same way that requires nice & equal sample sizes...

% subsample, like, idk man, 20 times (ideally 100 but we'll save that for the FINAL final run, not for testing!)
nssreps = 20;
ssrepcell = cell(nssreps,1);

% progressdenom = nssreps * 4 * 15 * 1;
% % subsample iterations x areas (+ pooled) x max dimensionality x cvfolds (not doing CV here, it WOULD have been by object, but here it's just 1)
% 
% counterval = 0;
% h = waitbar(counterval/progressdenom);

for subsampiter = 1:(nssreps+1)
    if subsampiter <= nssreps
        pickinds  = cellfun(@(x) randperm(size(x,2),subsampsize),keptmov,'uniformoutput',false);
        srccounts = cellfun(@(x) size(x,2),keptmov);
        inds2add  = [0;cumsum(srccounts(1:(end-1)))]; % FORMERLY A BUG!!! need to use cumsum here for proper alignment to array indices in the pooled cell!!!
        
        % assemble pickinds, adding srccounts to them, to get the indices corresponding to the pooled dataset
        % (i.e., that thing I mentioned about tripling the neuron count before? I've done it here... in a way that ensures each area should be equally represented! at least in terms of raw numbers of units)
        pooledinds = cellfun(@(x,y) x+y,pickinds,num2cell(inds2add),'uniformoutput',false);
        pooledinds = horzcat(pooledinds{:});
        pickinds{numel(pickinds)+1} = pooledinds;
        
        % and implement the subsampling!
        movEproj  = cellfun(@(x,y) x(:,y),movEproj_,pickinds,'uniformoutput',false);
        movOproj  = cellfun(@(x,y) x(:,y),movOproj_,pickinds,'uniformoutput',false);
        holdEproj = cellfun(@(x,y) x(:,y),holdEproj_,pickinds,'uniformoutput',false);
        holdOproj = cellfun(@(x,y) x(:,y),holdOproj_,pickinds,'uniformoutput',false);
        bothEproj = cellfun(@(x,y) x(:,y),bothEproj_,pickinds,'uniformoutput',false);
        bothOproj = cellfun(@(x,y) x(:,y),bothOproj_,pickinds,'uniformoutput',false);
    else
        % last iteration will forego subsampling
        movEproj  = movEproj_;
        movOproj  = movOproj_;
        holdEproj = holdEproj_;
        holdOproj = holdOproj_;
        bothEproj = bothEproj_;
        bothOproj = bothOproj_;
    end
    
    % and actually, orthogonalize w.r.t. the dimension separating the overall means between the two conditions
    % this way, you don't DISTORT your data with weird affine transformations
    % but rather, you simply ignore dimensions which do not fit well within the explained-variance framework
    % however, in practice, this really shouldn't matter much at all...
    movdeltadim  = cellfun(@(x,y) mean(x) - mean(y),movEproj,movOproj,'uniformoutput',false);
    movdeltadim  = cellfun(@(x) x(:)./norm(x),movdeltadim,'uniformoutput',false);
    holddeltadim = cellfun(@(x,y) mean(x) - mean(y),holdEproj,holdOproj,'uniformoutput',false);
    holddeltadim = cellfun(@(x) x(:)./norm(x),holddeltadim,'uniformoutput',false);
    bothdeltadim = cellfun(@(x,y) mean(x) - mean(y),bothEproj,bothOproj,'uniformoutput',false);
    bothdeltadim = cellfun(@(x) x(:)./norm(x),bothdeltadim,'uniformoutput',false);
    
    movdeltanull  = cellfun(@(x) null((x*x')),movdeltadim,'uniformoutput',false);
    holddeltanull = cellfun(@(x) null((x*x')),holddeltadim,'uniformoutput',false);
    bothdeltanull = cellfun(@(x) null((x*x')),bothdeltadim,'uniformoutput',false);
    
    % and project!
    movEproj = cellfun(@(x,y) x*y,movEproj,movdeltanull,'uniformoutput',false);
    movOproj = cellfun(@(x,y) x*y,movOproj,movdeltanull,'uniformoutput',false);
    holdEproj = cellfun(@(x,y) x*y,holdEproj,holddeltanull,'uniformoutput',false);
    holdOproj = cellfun(@(x,y) x*y,holdOproj,holddeltanull,'uniformoutput',false);
    bothEproj = cellfun(@(x,y) x*y,bothEproj,bothdeltanull,'uniformoutput',false);
    bothOproj = cellfun(@(x,y) x*y,bothOproj,bothdeltanull,'uniformoutput',false);
    
    % and now (safely) de-mean!
    movEmu    = cellfun(@(x) mean(x),movEproj,'uniformoutput',false);
    movOmu    = cellfun(@(x) mean(x),movOproj,'uniformoutput',false); % tested these, they are indeed equal between E and O
    holdEmu   = cellfun(@(x) mean(x),holdEproj,'uniformoutput',false);
    holdOmu   = cellfun(@(x) mean(x),holdOproj,'uniformoutput',false);
    bothEmu   = cellfun(@(x) mean(x),bothEproj,'uniformoutput',false);
    bothOmu   = cellfun(@(x) mean(x),bothOproj,'uniformoutput',false);
    
    movEproj   = cellfun(@(x,y) bsxfun(@minus,x,y),movEproj,movEmu,'uniformoutput',false);
    movOproj   = cellfun(@(x,y) bsxfun(@minus,x,y),movOproj,movOmu,'uniformoutput',false);
    holdEproj  = cellfun(@(x,y) bsxfun(@minus,x,y),holdEproj,holdEmu,'uniformoutput',false);
    holdOproj  = cellfun(@(x,y) bsxfun(@minus,x,y),holdOproj,holdOmu,'uniformoutput',false);
    bothEproj  = cellfun(@(x,y) bsxfun(@minus,x,y),bothEproj,bothEmu,'uniformoutput',false);
    bothOproj  = cellfun(@(x,y) bsxfun(@minus,x,y),bothOproj,bothOmu,'uniformoutput',false);
    
    % PCA preprocessing: insert here!
    movcoef  = cell(numel(arraynames),1);
    holdcoef = cell(numel(arraynames),1);
    bothcoef = cell(numel(arraynames),1);
    
    PCdims   = 30; % you COULD use a variance criterion... or you COULD just set the number to some arbitrarily high number.
    
    for arrayind = 1:numel(arraynames)
        mcoef  = pca([bsxfun(@minus,movEproj{arrayind},mean(movEproj{arrayind}));...
            bsxfun(@minus,movOproj{arrayind},mean(movOproj{arrayind}))]); % subtract task-specific means. we don't want PCA to be dominated by that. (that said, I already de-meaned these data... but yeah, maybe it's wise to make sure to do it again)
        hcoef = pca([bsxfun(@minus,holdEproj{arrayind},mean(holdEproj{arrayind}));...
            bsxfun(@minus,holdOproj{arrayind},mean(holdOproj{arrayind}))]); % also note that here I'm legit looking for a COMMON space, and not just trying to maximize variance captured in the target space...
        bcoef = pca([bsxfun(@minus,bothEproj{arrayind},mean(bothEproj{arrayind}));...
            bsxfun(@minus,bothOproj{arrayind},mean(bothOproj{arrayind}))]);
        
        % allow each area (and pooling!) to work with the same-dimensional space. also, do some subsampling (done!) to make absolutely SURE neuron count isn't the main factor driving dimensionality.
        movcoef{arrayind}  = mcoef(:,1:min(PCdims,size(mcoef,2)));%find( cumsum(movlat)./sum(movlat) >= 0.95,1,'first'));
        holdcoef{arrayind} = hcoef(:,1:min(PCdims,size(mcoef,2)));%find( cumsum(holdlat)./sum(holdlat) >= 0.95,1,'first'));
        bothcoef{arrayind} = bcoef(:,1:min(PCdims,size(mcoef,2)));%find( cumsum(bothlat)./sum(bothlat) >= 0.95,1,'first'));
    end
    
    movEproj   = cellfun(@(x,y) x*y,movEproj,movcoef,'uniformoutput',false);
    movOproj   = cellfun(@(x,y) x*y,movOproj,movcoef,'uniformoutput',false);
    holdEproj  = cellfun(@(x,y) x*y,holdEproj,holdcoef,'uniformoutput',false);
    holdOproj  = cellfun(@(x,y) x*y,holdOproj,holdcoef,'uniformoutput',false);
    bothEproj  = cellfun(@(x,y) x*y,bothEproj,bothcoef,'uniformoutput',false);
    bothOproj  = cellfun(@(x,y) x*y,bothOproj,bothcoef,'uniformoutput',false);
    
    % movEstar   = cellfun(@(x,y) x*y,movEstar,movEcoeff,'uniformoutput',false);
    % movOstar   = cellfun(@(x,y) x*y,movOstar,movOcoeff,'uniformoutput',false);
    % holdEstar  = cellfun(@(x,y) x*y,holdEstar,holdEcoeff,'uniformoutput',false);
    % holdOstar  = cellfun(@(x,y) x*y,holdOstar,holdOcoeff,'uniformoutput',false);
    % bothEstar  = cellfun(@(x,y) x*y,bothEstar,bothEcoeff,'uniformoutput',false);
    % bothOstar  = cellfun(@(x,y) x*y,bothOstar,bothOcoeff,'uniformoutput',false);
    
    maxdims = 20; % make consistent with what you use for classification. %PCdims/2; % seek up to half the total number of dimensions kept by PCA.
    
    % I forget what "C" stands for. But it stores the optimal manifold. (probably "coefficients")
    
    switch lower(lossmode)
        case 'fxve'
            movC  = cell(numel(movEproj),maxdims);
            holdC = cell(numel(holdEproj),maxdims); % relics from when I planned to do both epochs in one fell swoop. which also means "movC" and "movOF" are also misnomers now, too! more for my to-do list, or it would be, were I a developer and not just a scientist who just wants this to happen...
            bothC = cell(numel(bothEproj),maxdims);
            
            movOF  = zeros(numel(movEproj),maxdims);
            holdOF = zeros(numel(holdEproj),maxdims);
            bothOF = zeros(numel(bothEproj),maxdims);
            
            execproj = cell(numel(movEproj),maxdims);
            obsproj  = cell(numel(movEproj),maxdims);
            
            exec_ = cell(numel(movEproj),1);
            obs_  = cell(numel(movEproj),1);
        case 'gscorr'
            movC  = cell(size(movEproj));
            holdC = cell(size(holdEproj));
            bothC = cell(size(bothEproj));
            
            movOF   = zeros(numel(movEproj),maxdims);
            holdOF  = zeros(numel(holdEproj),maxdims);
            bothOF  = zeros(numel(bothEproj),maxdims);
            
            execproj = cell(numel(movEproj),1);
            obsproj  = cell(numel(movEproj),1);
            
            exec_ = cell(numel(movEproj),1);
            obs_  = cell(numel(movEproj),1);
        otherwise
            error('invalid "lossmode" argument: pick one of "FXVE" or "GScorr"')
    end
    
    % don't bother cross-validating, it doesn't fundamentally change the trends and only makes things take forever!!!
    for arrayind = 1:numel(arraynames)
        switch lower(alignmode) % yeah, yeah, I know, it's inefficient to wait until now to choose which one to analyze. put it on my freakin' to-do list, I guess.
            case 'move'
                X_ = movEproj{arrayind};
                Y_ = movOproj{arrayind};
                PCAcoeff = movcoef;
                meannull = movdeltanull;
            case 'hold'
                X_ = holdEproj{arrayind};
                Y_ = holdOproj{arrayind};
                PCAcoeff = holdcoef;
                meannull = holddeltanull;
            case 'both'
                X_ = bothEproj{arrayind};
                Y_ = bothOproj{arrayind};
                PCAcoeff = bothcoef;
                meannull = bothdeltanull;
            otherwise
                error('invalid alignment')
        end
        
        % thankfully, I've done the requisite work (orthogonalizing w.r.t. the mean-separating dimension, then demeaning both arrays) to make sure these data are conveniently de-meaned for statistical analysis WITHOUT distorting the data relative to one another (instead, merely throwing out a single dimension in neuronal state space, a far more tolerable operation from a readout perspective, albeit more lossy one)
        maxdims_ = min(maxdims,size(X_,2));
        PCdims_  = min(PCdims,size(X_,2));
        
        for dimcount = 1:maxdims_
            switch lower(lossmode)
                case 'fxve'
                    X = X_;
                    Y = Y_;
                    
                    clear problem
                    problem.M    = stiefelfactory(PCdims_,dimcount);
                    costfun      = @(XX,YY,V) norm(XX-YY*(V*V'),'fro')^2 + norm(YY-XX*(V*V'),'fro')^2; % again, unlike the hyperpowered alignments used for classification, this is meant to be symmetric - i.e., an inability for obs to explain exe is just as punishing as an inability of exe to explain obs!
                    costgrad     = @(XX,YY,V) -2 * ( ...
                        YY'*(XX-YY*(V*V'))*V + ...
                        (XX'-(V*V')*YY')*YY*V + ...
                        XX'*(YY-XX*(V*V'))*V + ...
                        (YY'-(V*V')*XX')*XX*V );
                    problem.cost  = @(V) costfun(X,Y,V);
                    problem.egrad = @(V) costgrad(X,Y,V);
                    
                    %                     %         check gradients (debug only)
                    %                     close all,clc %#ok<DUALC>
                    %                     checkgradient(problem); pause;
                    
                    % optimize
                    optopts.tolgradnorm = 1e-3;
                    optopts.verbosity   = 0;
                    Mfit = trustregions(problem,[],optopts);
                    costval = problem.cost(Mfit);
                    
                    movC{arrayind,dimcount} = meannull{arrayind}*PCAcoeff{arrayind}*Mfit; % factor in movdeltanull and movcoef to get back into "neuron"-space
                    movOF(arrayind,dimcount) = costval;
                    execproj{arrayind,dimcount} = X*Mfit;
                    obsproj{arrayind,dimcount}  = Y*Mfit;
                    
                    if dimcount == 1
                        exec_{arrayind}    = X;
                        obs_{arrayind}     = Y;
                    else
                        % pass
                    end
                    
                case 'gscorr'
                    % this is gonna be Gram-Schmittified
                    if dimcount == 1
                        projmat = eye(PCdims_);
                    else
                        oldsoln = movC{arrayind};
                        projmat = null(oldsoln * oldsoln');
                    end
                    
                    % project onto previous-step null space
                    X  = X_*projmat;
                    Y  = Y_*projmat;
                    
                    % no special "Xstar" is required, since I already demeaned things. Hooray!
                    problem.M = stiefelfactory(size(X,2),1); % 1 dim at a time, performing gram-schmidt orthogonalization
                    costfun = @(v) 2 * norm( (X-Y)*v,'fro' )^2 / ( norm(X*v,'fro')^2 + norm(Y*v,'fro')^2 );
                    gradfun = @(v) 4/( norm(X*v,'fro')^2 + norm(Y*v,'fro')^2 ) * (X-Y)'*(X-Y)*v - ...
                        4*norm((X-Y)*v,'fro')^2/( norm(X*v,'fro')^2 + norm(Y*v,'fro')^2 )^2 * ...
                        ( (X'*X)*v + (Y'*Y)*v );
                    
                    problem.cost  = costfun;
                    problem.egrad = gradfun;
                    
                    %                     %         check gradients (debug only)
                    %                     close all,clc %#ok<DUALC>
                    %                     checkgradient(problem); pause;
                    
                    % optimize
                    optopts.tolgradnorm = 1e-3;
                    optopts.verbosity   = 0;
                    Mfit = trustregions(problem,[],optopts);
                    costval = problem.cost(Mfit);
                    
                    movC{arrayind} = horzcat(movC{arrayind},projmat * Mfit); % factor in projmat
                    movOF(arrayind,dimcount) = costval;
                    execproj{arrayind} = horzcat( execproj{arrayind}, X*Mfit );
                    obsproj{arrayind}  = horzcat( obsproj{arrayind}, Y*Mfit );
                    
                    if dimcount == 1
                        exec_{arrayind}    = X;
                        obs_{arrayind}     = Y;
                    else
                        % pass
                    end
                    
                otherwise
                    error('invalid "lossmode" argument: pick one of "FXVE" or "GScorr"')
            end
            %             counterval = counterval + 1;
            %             waitbar(counterval/progressdenom,h);
        end
    end
    
    % factor in movdeltanull and movcoef if you used gscorr (because you have already done it by now for FXVE) (note: only works for 'mov', never bothered updating since this is a silly objective function)
    if strcmpi(lossmode,'gscorr')
        movC = cellfun(@(x,y,z) x*y*z,meannull,PCAcoeff,movC,'uniformoutput',false);
    else
        % pass
    end
    
    % and save as part of the subsample cell ("ssrepcell")
    clear tempstruct
    tempstruct.subspacecell  = movC;
    tempstruct.lossfunction  = movOF;
    tempstruct.exec          = execproj; % saving these for further analysis
    tempstruct.obs           = obsproj;
    tempstruct.exec_         = exec_; % save original matrices too! otherwise you have no way to calc captured variance! (should you maybe just calc captured variance here? yeah, that'd be way more efficient... but THEN I wouldn't be able to visualize anything!!!)
    tempstruct.obs_          = obs_;
    
    % not needed: these have already been factored into "subspacecell".
    %     tempstruct.PCAcoeff      = PCAcoeff; % for reconstructing projections of dimensions onto the original neuron-space. mostly important for the "pooled" condition.
    %     tempstruct.DeltaMeanNull = meannull; % order of operations: meannull * PCA * commonspace
    
    ssrepcell{subsampiter}   = tempstruct;
end 

% close(h) % close the waitbar

% package the subsample cell as the output ("commonspace")
commonspace.subsamples   = ssrepcell; % last index foregoes subsampling
commonspace.lossmode     = lossmode;
commonspace.alignmode    = alignmode;
commonspace.subsampsize  = subsampsize; % x 3 for "pooled" is implicit (and will show up in "PCAcoeff" in any case)
commonspace.arraynames   = arraynames; % more metadata! moooooorrreeee!!!!
% not going to save sustainspace and celldata here. too much memory to devote to something you should be tracking anyway.

end


