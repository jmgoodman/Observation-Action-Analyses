function Outcell = crossclassify_refactor(celldata,sustainspace,opts)

% refactored version of crossclassify
% removes unnecessary manifold-alignment, does explicit cross-training instead (consider "full cross-task mix", "cross-task for scaling only", and "no cross-task training")
% also reorganizes function calls & data to make use of MATLAB CPU parallelization
% since for the classifiers I want to run, it doesn't seem like MATLAB supports GPU computation (!!!)

% classout: a struct containing information about the results of classification
% celldata: data in cell format
% sustainspace: a struct containing info about the sustained-activity space (found via "findsustainspace")
% opts: struct containing classification options, determined by the "makeclassifyopts" method.

% TODO:
% * allow input of "commonspace" as ersatz transformation
% * allow input of kinematics to allow transformations to be informed by them (maybe... do the following thing first, THEN deem if something fancy like that is really necessary to learn something interesting)
% * bugfix transforms: disallow reflections by converting stiefelfactory to rotationsfactory

% defaults: sustainspace=[],classopts = default output of "makeclassifyopts"
if nargin < 2
    sustainspace = [];
end

if nargin < 3
    opts = makeclassifyopts();
end

if strcmpi(opts.datamode,'neural')
    triallabels = extractlabels(celldata);
    [pooledarraydatacell,arraynames] = poolarrays(celldata); % alphabet: AIP / F5 / M1
    startcol = 1;
    lastcol  = [];
elseif strcmpi(opts.datamode,'kinematic')
    triallabels         = extractlabels(celldata);
    pooledarraydatacell = celldata(1);
    arraynames          = {'jointkinematics'};
    startcol = 4; % start from floatx
    lastcol  = 29; % end on the last JOINT angle
end

clear celldata

% 1 fixation / 2 light on / 3 light off / 4 cue onset / 5 move onset / 6 hold onset / 7 reward onset


%% pick out (& concatenate) the specified alignments (currently only move & hold are supported, but early and late vis need to be added)
chosenalign = opts.alignment;

% sort
targetaligns  = {'lighton','lightoff','move','hold'};
keepaligninds = ismember(targetaligns,...
    chosenalign);
keepaligns    = targetaligns(keepaligninds);

if strcmpi(opts.datamode,'neural')
    datafield = 'Data';
elseif strcmpi(opts.datamode,'kinematic')
    datafield = 'KinematicData';
end

for ii = 1:numel(keepaligns)
    if isempty(lastcol)
        switch keepaligns{ii}
            case 'move'
                thesedata = cellfun(@(x) x{5}.(datafield)(:,startcol:end,:),...
                    pooledarraydatacell,'uniformoutput',false);
            case 'hold'
                thesedata = cellfun(@(x) x{6}.(datafield)(:,startcol:end,:),...
                    pooledarraydatacell,'uniformoutput',false);
            case 'lighton'
                thesedata = cellfun(@(x) x{2}.(datafield)(:,startcol:end,:),...
                    pooledarraydatacell,'uniformoutput',false);
            case 'lightoff'
                thesedata = cellfun(@(x) x{3}.(datafield)(:,startcol:end,:),...
                    pooledarraydatacell,'uniformoutput',false);
        end
    else
        
        switch keepaligns{ii}
            case 'move'
                thesedata = cellfun(@(x) x{5}.(datafield)(:,startcol:lastcol,:),...
                    pooledarraydatacell,'uniformoutput',false);
            case 'hold'
                thesedata = cellfun(@(x) x{6}.(datafield)(:,startcol:lastcol,:),...
                    pooledarraydatacell,'uniformoutput',false);
            case 'lighton'
                thesedata = cellfun(@(x) x{2}.(datafield)(:,startcol:lastcol,:),...
                    pooledarraydatacell,'uniformoutput',false);
            case 'lightoff'
                thesedata = cellfun(@(x) x{3}.(datafield)(:,startcol:lastcol,:),...
                    pooledarraydatacell,'uniformoutput',false);
        end
        
    end
    
    
    if ~exist('keepdata','var')
        keepdata = thesedata;
    else
        keepdata = cellfun(@(x,y) cat(4,x,y),keepdata,thesedata,'uniformoutput',false); % time x neuron x trial x epoch
    end
    
    clear thesedata
end

clear pooledarraydatacell

%% below, we process the cellform data to only include trials from the target conditions
targetcontexts = opts.targetcontexts; %{'active','passive'};

keeptrials  = ismember(triallabels.trialcontexts.names,targetcontexts);


%% make sure to only include objects which are used across all target contexts, too
keptobjects = triallabels.objects.names(keeptrials);
[~,~,ucontexts] = unique(triallabels.trialcontexts.names(keeptrials)); % active / (control) / passive in alphabetical order

objcell = cell(max(ucontexts),1);

for ii = 1:numel(objcell)
    thisobjset  = keptobjects(ucontexts==ii);
    
    uobjs       = cellstr( unique(char(thisobjset),'rows') );
    
    objcell{ii} = uobjs;
end

allobjs = vertcat(objcell{:});
uniqueallobjs = cellstr( unique(char(allobjs),'rows') );

keepobjinds = cellfun(@(x) ismember(uniqueallobjs(:),x(:)),objcell,'uniformoutput',false);
keepobjinds = all( horzcat(keepobjinds{:}),2 );

keepobjnames = uniqueallobjs(keepobjinds); % this makes sure that no contexts have objects that other contexts don't have. important for "control" classification!!!

keeptrials   = keeptrials & ismember(triallabels.objects.names,keepobjnames);


%%
keptlabels = triallabels;
fn         = fieldnames(triallabels);

for fnind = 1:numel(fn)
    keptlabels.(fn{fnind}).names      = keptlabels.(fn{fnind}).names(keeptrials);
    keptlabels.(fn{fnind}).uniqueinds = keptlabels.(fn{fnind}).uniqueinds(keeptrials);
end

keptlabels.trialcontexts.uniquenames      = targetcontexts;
keptlabels.trialcontexts.nunique          = numel(targetcontexts);
[~,~,keptlabels.trialcontexts.uniqueinds] = unique(keptlabels.trialcontexts.uniqueinds);

keptmov  = cellfun(@(x) x(:,:,keeptrials,:),keepdata,'uniformoutput',false); % "keptmov" is now a misnomer, because the user can define the alignment(s) of their choosing. not just "mov".
clear keepdata

% pool
if strcmpi(opts.datamode,'neural')
    keptmov{ numel(keptmov)+1 }       = horzcat(keptmov{:});
    arraynames{ numel(arraynames)+1 } = 'all';
else
    % pass; no pooling required for kinematic data
end

% find commonspace and extract it to prep for restriction to that space
if ~isempty( opts.commonspace )
    commonarraynames = opts.commonspace.arraynames;
    commonlosses     = opts.commonspace.subsamples{end}.lossfunction;
    [~,minlossinds]  = min( commonlosses,[],2 );
    commonspaces     = cell(size(minlossinds));
    for areaind = 1:numel(commonspaces)
        commonspaces{areaind} = ...
            opts.commonspace.subsamples{end}.subspacecell{areaind,minlossinds(areaind)};
    end
    commonflag = true;
    
    newcommonspaces = cell(size(commonspaces));
    
    for areaind = 1:numel(newcommonspaces)
        thisarrayname   = arraynames{areaind};
        whichcommonname = find( ismember(commonarraynames,thisarrayname) );
        newcommonspaces{areaind} = commonspaces{whichcommonname}; %#ok<FNDSB>
    end
    
    % rearrange commonspaces to match the array order here
    
else
    commonflag = false;
end

% remove the sustained space
if ~isempty(sustainspace)
    keptproj = cell(size(keptmov));
    
    susman   = arrayfun(@(x) x.regular.coeff(:,1:x.regular.ncomp),... % use "regular" to squeeze more dimensions out... then use a 95% variance criterion if that still doesn't work (indeed, it didn't)...
        sustainspace,'uniformoutput',false); % time averaged & non-time-averaged give very similar results, so it doesn't matter (at least when using a conservative cutoff; non-time-averaged give substantially larger dimensionalities when using an aggressive cutoff)
    
    orthosusman = cellfun(@(x) eye(size(x,1)) - (x*x'),...
        susman,'uniformoutput',false); % we compute the projection-reprojection matrix where we project the data onto the "sustained" space
    
    % also restrict to the common space determined externally
    if commonflag
        orthosusman = cellfun(@(x,y) x*(y*y'),orthosusman(:),newcommonspaces(:),'uniformoutput',false); % again, a project-reproject routine to fit within the framework of subsampling.
    else
        % pass
    end
    
    for ii = 1:numel(keptmov)
        tempdata     = keptmov{ii};
        permdata     = permute(tempdata,[2,1,3,4]); % time x neuron x trial x align -> neuron x time x trial x align
        clear tempdata
        flatdata     = permdata(:,:)'; % neuron x time x trial x align -> (time x trial x align) x neuron
        flatproj     = flatdata * orthosusman{ii}; % no dimredux
        clear flatdata
        unflatproj   = reshape( flatproj',size(permdata) ); % neuron x (time x trial x align) -> neuron x time x trial x align
        clear permdata
        clear flatproj
        unpermproj   = permute( unflatproj,[2,1,3,4] ); % neuron x time x trial x align -> time x neuron x trial x align
        clear unflatproj
        keptproj{ii} = unpermproj;
        clear unpermproj
    end
else
    % also restrict to the common space determined externally
    if commonflag
        keptproj = cell(size(keptmov));
        orthosusman = cellfun(@(y) (y*y'),newcommonspaces,'uniformoutput',false); % again, a project-reproject routine to fit within the framework of subsampling.
        
        for ii = 1:numel(keptmov)
            tempdata     = keptmov{ii};
            permdata     = permute(tempdata,[2,1,3,4]); % time x neuron x trial x align -> neuron x time x trial x align
            flatdata     = permdata(:,:)'; % neuron x time x trial x align -> (time x trial x align) x neuron
            flatproj     = flatdata * orthosusman{ii}; % no dimredux
            unflatproj   = reshape( flatproj',size(permdata) ); % neuron x (time x trial x align) -> neuron x time x trial x align
            unpermproj   = permute( unflatproj,[2,1,3,4] ); % neuron x time x trial x align -> time x neuron x trial x align
            keptproj{ii} = unpermproj;
        end
    else
        keptproj = keptmov;
    end
end

clear keptmov

% remove submedian neurons (if this argument is nonempty)
% note: submedian w.r.t. a passive-active index, where +ve = prefers observation and -ve = prefers movement.
if ~isempty(opts.mediansplit)
    for ii = 1:(-1+numel(keptproj))
        arrayname    = arraynames{ii};
        contrastvals = opts.mediansplit.(arrayname);
        supramedianinds = contrastvals >= nanmedian(contrastvals); % note: we have some nan values because I excluded neurons without a baseline level of modulation. So, there's actually two filters at play here.
        keptproj{ii}    = keptproj{ii}(:,supramedianinds,:,:);
    end
    
    kptemp = keptproj(1:(end-1));
    keptproj{end} = horzcat(kptemp{:}); % we ultimately apply separate filters on a per-area basis, even when pooling them. This is done because refactoring the code just so we can use the pooled median does NOT sound worth it, and in the end would likely just result in a median-split "pooled" classifier which looked almost exactly like the non-median-split AIP classifier, since this index varies systematically across areas. So it'd probably just give us redundant information anyway to use a pooled-specific median instead of concatenating separately median-split areas.
end

% NOW subsample (if neuronal data)
if strcmpi(opts.datamode,'neural')
    if opts.nssreps > 0
        sss         = opts.subsampsize;
        if (sss > 0 && sss < 1)
            subsampsize = round( sss * min( cellfun(@(x) size(x,2),keptproj) ) ); % equalize # of neurons per sample with this, so that info content / projection onto one area isn't a trivial consequence of neuron count
        elseif sss >= 1
            sss_safe = min(cellfun(@(x) size(x,2),keptproj));
            if sss_safe < sss
                warning('subsampsize too big, defaulting to lowest subpopulation size')
                sss = sss_safe;
            else
                % pass
            end
            subsampsize = sss;
        end
        nssreps     = opts.nssreps;
        ssflag      = true;
    else
        subsampsize = 1;
        nssreps     = 1;
        ssflag      = false;
    end
else
    subsampsize = size(keptproj{1},2);
    nssreps     = 1;
end

%%

% at this stage, consider 2 for-loops
%   1 to generate the data partitions you need
%   1 PARFOR to actually run your classification routine on all those data partitions

ssdatacell = cell(nssreps,1);
for subsampiter = 1:nssreps
    if strcmpi(opts.datamode,'neural')
        if ssflag
            pickinds  = cellfun(@(x) randperm(size(x,2),subsampsize),keptproj(1:(end-1)),'uniformoutput',false); % exclude the pooled cell... for now
            % pickinds  = cellfun(@(x) 1:size(x,2),keptproj(1:(end-1)),'uniformoutput',false); % a test to see if classification performance gets sufficiently high when the population is maximized (i.e., when subsampling is disabled).
            srccounts = cellfun(@(x) size(x,2),keptproj(1:(end-1)));
            inds2add  = [0;cumsum(srccounts(1:(end-1)))];
            
            % assemble pickinds, adding srccounts to them, to get the indices corresponding to the pooled dataset
            pooledinds = cellfun(@(x,y) x+y,pickinds,num2cell(inds2add),'uniformoutput',false);
            pooledinds = horzcat(pooledinds{:});
            pickinds{numel(pickinds)+1} = pooledinds; % and now the index & data cells match in size again
            
            % and implement the subsampling!
            keptss    = cellfun(@(x,y) x(:,y,:,:),keptproj,pickinds,'uniformoutput',false);
            
        else % don't subsample if user specifies 0 subsample count
            keptss = keptproj;
        end
    else
        keptss    = keptproj; % don't bother with splitting off a pooled cell or worrying about subsampling at all. just keep everything.
    end
    
    ssdatacell{subsampiter} = keptss;
end

clear keptproj

%%
% bin the data
binwidth    = opts.binwidth;
binshift    = opts.binshift;

binsamps    = round(binwidth / 10); % x ms / (10ms / sample) = y samples
shiftsamps  = (binshift / 10);

nsamps      = size(keptss{1},1);

% if neuronal, establish a window over which to count spikes
if strcmpi(opts.datamode,'neural')
    binstarts   = 1:shiftsamps:(nsamps-binsamps+1); % super stupid simple. no sanity checking on the input, so it's up to you to specify a binwidth-binshift pairing that spans exactly a full second.
    binends     = binstarts + binsamps - 1;
else % otherwise, just take the edges of all the bins (instantaneous kinematic postures, in other words)
    binstarts   = 1:shiftsamps:(nsamps-shiftsamps+1); % here, we just use binshift, as kinematic classification uses instantaneous postures and thus does not require a bin width parameter.
    binends     = binstarts + shiftsamps - 1; % the idea is to define a 1- or 2-element range that lies atop or straddles the set of bin edges defined by the binshift parameter.
    
    binstarts   = [binstarts,binends(end)];
    binends     = [1,binends];
    
    % and flip them so that binstarts are always less than binends. your padding of the edge matrices has screwed that up!
    bs = min([binstarts;binends],[],1);
    be = max([binstarts;binends],[],1);
    
    binstarts = bs;
    binends   = be;
end


binneddatacell    = cell(size(ssdatacell));

for jj = 1:numel(ssdatacell)
    keptss = ssdatacell{jj};
    binnedss    = cell(size(keptss));
    
    for ii = 1:numel(keptss)
        thismat = keptss{ii};
        sz      = size(thismat);
        newsz   = sz;   newsz(1) = numel(binstarts);
        newmat  = nan(newsz);
        
        for binind = 1:numel(binstarts)
            thischunk = thismat(binstarts(binind):binends(binind),:,:,:);
            meanrates = nanmean(thischunk,1);
            
            newmat(binind,:,:,:) = meanrates;
        end
        
        binnedss{ii} = newmat;
    end
    
    binneddatacell{jj} = binnedss;
end

% break up into conext, alignment, and subalignment pairs
ncontexts       = numel(keptlabels.trialcontexts.uniquenames);
naligns         = numel(keepaligns);
nsubaligns      = numel(binstarts);
conditionedcell = cell( nssreps,ncontexts,ncontexts,naligns,naligns,nsubaligns,nsubaligns );

%% too redundant
% for repind = 1:nssreps
%     dtemp = binneddatacell{repind};
%     for context1ind = 1:ncontexts
%         for context2ind = 1:ncontexts
%             keepers1 = ismember(keptlabels.trialcontexts.names,keptlabels.trialcontexts.uniquenames{context1ind});
%             keepers2 = ismember(keptlabels.trialcontexts.names,keptlabels.trialcontexts.uniquenames{context2ind});
%
%             for align1ind = 1:naligns
%                 for align2ind = 1:naligns
%                     for subalign1ind = 1:nsubaligns
%                         for subalign2ind = 1:nsubaligns
%                             clear tempstruct
%                             tempstruct.data1 = cellfun(@(x) squeeze( x(subalign1ind,:,keepers1,align1ind) )',...
%                                 dtemp,'uniformoutput',false );
%                             tempstruct.data2 = cellfun(@(x) squeeze( x(subalign2ind,:,keepers2,align2ind) )',...
%                                 dtemp,'uniformoutput',false );
%
%                             tempstruct.objects1 = keptlabels.objects.names(keepers1);
%                             tempstruct.objects2 = keptlabels.objects.names(keepers2);
%
%                             conditionedcell{repind,context1ind,context2ind,align1ind,align2ind,subalign1ind,subalign2ind} = tempstruct;
%                         end
%                     end
%                 end
%             end
%         end
%     end
% end

%% make binneddatacell sliceable by a single index
Incell = cell( nssreps,ncontexts,ncontexts,naligns,naligns,nsubaligns,nsubaligns );

namen  = keptlabels.trialcontexts.names;
unamen = keptlabels.trialcontexts.uniquenames;

onamen = keptlabels.objects.names;

clear tempstruct
for repind = 1:nssreps
    dtemp = binneddatacell{repind};
    
    for c1 = 1:ncontexts
        keepers1 = ismember(namen,unamen{c1});
        tempstruct.o1 = onamen(keepers1);
        for a1 = 1:naligns
            for s1 = 1:nsubaligns
                tempstruct.d1 = cellfun(@(x) squeeze( x(s1,:,keepers1,a1) )',...
                    dtemp,'uniformoutput',false );
                
                for c2 = 1:ncontexts
                    keepers2 = ismember(namen,unamen{c2});
                    tempstruct.o2 = onamen(keepers2);
                    for a2 = 1:naligns
                        for s2 = 1:nsubaligns % SUBaligns!!
                            tempstruct.d2 = cellfun(@(x) squeeze( x(s2,:,keepers2,a2) )',...
                                dtemp,'uniformoutput',false );
                            
                            Incell{repind,c1,c2,a1,a2,s1,s2} = tempstruct;
                        end
                    end
                end
                
            end
        end
    end
    
end

%% now set up parallel pool
% olddir = cd('C:\Users\User\Documents\GitHub'); % (maybe not?!?!?) % gotta go to the C drive, otherwise parallel processing doesn't work. I know, it's weird.
ncores = feature('numcores');
ncores_touse = max(ncores - 2,1); % leave a couple of buffer cores to do other normal things / prevent crashes

pc = parcluster('local');

try
    p = parpool(pc,ncores_touse);
catch err
    delete(gcp('nocreate'))
    pause(5) % give it time to cool off? is that what needs to happen?
    p = parpool(pc,ncores_touse);
end

%% begin considering cross-classification problems one-by-one
% the output cell is organized: subsamps - contextXcontext - alignmentXalignment - subalignmentXsubalignment - fold - area (with chance-level loss at end)

Outcell = cell( nssreps,ncontexts,ncontexts,naligns,naligns,nsubaligns,nsubaligns );
ncell   = numel(Outcell);
ocsize  = size(Outcell);

namen  = keptlabels.trialcontexts.names;
unamen = keptlabels.trialcontexts.uniquenames;

onamen = keptlabels.objects.names;

nfolds = opts.kfold;
tk     = opts.transform;
td     = opts.transformdims;
pd     = opts.pcadims;

clearvars -except Outcell Incell keptlabels opts uobjs ocsize ncell namen unamen onamen nfolds tk td pd p pc ncores ncores_touse olddir
% make this parfor after you've tested things
tic
parfor ii = 1:ncell
    try
        [repind,context1ind,context2ind,align1ind,align2ind,subalign1ind,subalign2ind] = ...
            ind2sub(ocsize,ii);
        
        d1 = Incell{ii}.d1; % me want pointers :( :( :(
        d2 = Incell{ii}.d2; 
        o1 = Incell{ii}.o1; 
        o2 = Incell{ii}.o2; 
        
        %     keepers1 = ismember(namen,unamen{context1ind}); %#ok<PFBNS> % this inefficient communication overhead is NOT as big a problem. just a 500-or-so cellstring of labels.
        %     keepers2 = ismember(namen,unamen{context2ind});
        %
        %     d1 = cellfun(@(x) squeeze( x(subalign1ind,:,keepers1,align1ind) )',...
        %         dtemp,'uniformoutput',false );
        %     d2 = cellfun(@(x) squeeze( x(subalign2ind,:,keepers2,align2ind) )',...
        %         dtemp,'uniformoutput',false );
        %
        %     o1 = onamen(keepers1); %#ok<PFBNS> % same here. these labels are NOT the bottleneck.
        %     o2 = onamen(keepers2);
        
        %     o1 = conditionedcell{ii}.objects1;
        %     o2 = conditionedcell{ii}.objects2;
        %     [uo1,~,ui1] = unique( char(o1),'rows' );
        %     [uo2,~,ui2] = unique( char(o2),'rows' );
        %     uo1 = cellstr(uo1);
        %     uo2 = cellstr(uo2);
        %     nobjs = numel(uo1);
        %     d1 = conditionedcell{ii}.data1;
        %     d2 = conditionedcell{ii}.data2;
        
        if context1ind == context2ind
            % stratified crossval for both train & test (since they're paired and likely to have overlapping info, even when considering different alignments)
            cvp = cvpartition(o1,'KFold',nfolds); % objects1 == objects2
            pairedsamps = true;
        else
            % stratified crossval just for test (to allow the transform to be fit on a separate dataset than what we use to evaluate the model)
            cvp = cvpartition(o2,'KFold',nfolds); % When you supply group as the first input argument to cvpartition, then the function implements stratification by default.
            pairedsamps = false;
        end
        
        lossfold = cell(nfolds,1);
        for foldind = 1:nfolds
            try
                testset  = test(cvp,foldind);
                trainset = training(cvp,foldind);
                
                if pairedsamps
                    traindata          = cellfun(@(x) x(trainset,:),d1,'uniformoutput',false);
                    testdata_classify  = cellfun(@(x) x(testset,:), d2,'uniformoutput',false);
                    testdata_transform = cellfun(@(x) x(trainset,:),d2,'uniformoutput',false);
                    
                    trainobjects          = o1(trainset);
                    testobjects_classify  = o2(testset);
                    testobjects_transform = o2(trainset);
                else
                    traindata          = d1;
                    testdata_classify  = cellfun(@(x) x(testset,:), d2,'uniformoutput',false);
                    testdata_transform = cellfun(@(x) x(trainset,:),d2,'uniformoutput',false);
                    
                    trainobjects          = o1;
                    testobjects_classify  = o2(testset);
                    testobjects_transform = o2(trainset);
                end
                
                % calc trial averages of each
                trainmu          = cell(size(traindata));
                testmu_transform = cell(size(testdata_transform)); % don't bother taking trial averages of testobjects_classify
                
                for objind = 1:numel(uobjs)
                    thesetraintrials = ismember(trainobjects,uobjs{objind});
                    thesetesttrials  = ismember(testobjects_transform,uobjs{objind});
                    
                    thistrainmu      = cellfun(@(x) mean(x(thesetraintrials,:)),traindata,'uniformoutput',false);
                    thistestmu       = cellfun(@(x) mean(x(thesetesttrials,:)),testdata_transform,'uniformoutput',false);
                    
                    trainmu          = cellfun(@(x,y) vertcat(x,y),trainmu,thistrainmu,'uniformoutput',false);
                    testmu_transform = cellfun(@(x,y) vertcat(x,y),testmu_transform,thistestmu,'uniformoutput',false);
                end
                
                transformsX = cell(size(trainmu));
                transformsY = cell(size(testmu_transform));
                
                if ~(context1ind == context2ind && ...
                        align1ind == align2ind && ...
                        subalign1ind == subalign2ind)
                    transformkind = tk;
                else
                    transformkind = 'none'; % save some time...
                end
                
                for cc = 1:numel(trainmu)
                    [tX,tY] = datatransform( trainmu{cc},...
                        testmu_transform{cc},...
                        td,...
                        transformkind,...
                        pd );
                    
                    transformsX{cc} = tX;
                    transformsY{cc} = tY;
                end
                
                Xproj = cellfun(@(transformfun,x) transformfun(x),transformsX,traindata,'uniformoutput',false);
                Yproj = cellfun(@(transformfun,y) transformfun(y),transformsY,testdata_classify,'uniformoutput',false);
                
                mdlcell  = cellfun(@(x) fitcdiscr(x,trainobjects,'discrimtype','pseudoLinear'),Xproj,'uniformoutput',false);
                lossvals = cellfun(@(x,y) 1-loss(x,y,testobjects_classify),mdlcell,Yproj); % 1-loss = accuracy (since classiferror is the default lossfun) (ergo 1 - accuracy = loss)
                
                % append chance levels
                [~,~,uoind] = unique(char(testobjects_classify),'rows');
                maxchance = 0;
                for uoindval = 1:max(uoind)
                    currentval = sum( uoind == uoindval );
                    if currentval > maxchance
                        maxchance = currentval;
                    else
                        % pass
                    end
                end
                
                nullloss = maxchance / numel(testobjects_classify); % don't need to 1-loss here, I can just calc the probability directly.
                lossvals = vertcat( lossvals(:),nullloss ); % note also that, yeah, "loss" is a misnomer here: I'm actually computing the "objective" (i.e., classification probability)
                
                lossfold{foldind} = lossvals; % remember: final lossval is CHANCE level in the test set!!! 
            catch err
                % no plan
                lossfold{foldind} = err; % save a record of the error that caused this
            end
        end
        
        Outcell{ii} = lossfold;
    catch err
        Outcell{ii} = err; % again, store the error here.
    end
end
toc
% cd(olddir)

end