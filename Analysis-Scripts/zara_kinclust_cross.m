function clusterstruct = zara_kinclust_cross()
%% cleanup

%% setup
% restoredefaultpath
% analysis_setup

%% kinematics sessions
addpath('../MirrorData/')
kinsessions = {'Zara64','Zara68','Zara70'};
kincat  = [];
objcat  = {};
seshcat = {};

for ii = 1:numel(kinsessions)
    %     tempdstruct = dataload(kinsessions{ii});
    seshstr = kinsessions{ii};
    load(sprintf('%s_datastruct.mat',seshstr));
    triallabels = extractlabels(datastruct.cellform);
    
    % grab object labels
    olabstemp = triallabels.objects.names;
    
    % grab context IDs
    ttypecat    = triallabels.trialcontexts.names;
    
    % adjust object names to incporporate context
    activeinds  = ismember(ttypecat,'active');
    passiveinds = ismember(ttypecat,'passive');
    
    olabstemp(activeinds)  = strcat(olabstemp(activeinds),' active');
    olabstemp(passiveinds) = strcat(olabstemp(passiveinds),' passive');
    
    olabstemp = olabstemp( activeinds|passiveinds );
    
    % grab hold-onset postures
    kctemp = squeeze( datastruct.cellform{1}{6}.KinematicData(51,:,:) )';
    kctemp = kctemp( activeinds|passiveinds,: );
    
    kincat = vertcat( kincat, ...
       kctemp );
    
       
    % grab object IDs
    objcat = vertcat( objcat, ...
        olabstemp );

    % make active & passive into separate trial indices, once more to account for systematic errors in "default" postures...
    seshtemp = repmat(kinsessions(ii),numel(ttypecat),1);
    seshtemp(activeinds)  = strcat(seshtemp(activeinds),' active');
    seshtemp(passiveinds) = strcat(seshtemp(passiveinds),' passive');
    seshtemp              = seshtemp( activeinds|passiveinds );
    
    seshcat = vertcat( seshcat, ...
        seshtemp );
end

%%
% subtract within-session means
X  = kincat; % no z-score, joints with low ROMs shouldn't be boosted...
XX = kincat;

uks = unique( char( seshcat ),'rows' );
uks = cellstr(uks);

muvals = [];
for ii = 1:numel(uks) % inefficient but only slightly so, not the bottleneck at all
    thesetrials = ismember(seshcat,uks(ii));
    mu = mean( kincat(thesetrials,:) );
    X(thesetrials,:) = bsxfun(@minus,kincat(thesetrials,:),mu);
    
    muvals = vertcat(muvals,mu); %#ok<*AGROW>
end
deltamu = diff(muvals); % max positional difference = ~5 mm, max angular difference = ~6 degrees

% ignore the floating orientation coordinates with zero variance, and also the translational coordinates whose scale doesn't match the joint angular ones
% X = X(:,7:29); full kinematics (very weak, only one cross-context cluster, not enough to do classification)
% X = X(:,7:9); % JUST the wrist (focus on orientation, not hand shape) (four cross-context clusters)
X = X; % IGNORE the wrist (focus on hand shape, not orientation) (very weak, only 2 cross-context clusters come out)

% next, average across trials within each object
[uobj,~,uind] = unique(char(objcat),'rows');
uobj       = cellstr(uobj);
objcount   = numel(uobj); % get in the habit of doing this. it's (slightly) more efficient!
jointcount = size(X,2);
X_trav = zeros(objcount,jointcount);
XX_trav = zeros(objcount,jointcount);

for objind = 1:objcount
    thesetrials = uind == objind;
    Xtemp       = X(thesetrials,:);
    Xmu         = mean(Xtemp);
    X_trav(objind,:) = Xmu;
    
    XXtemp       = XX(thesetrials,:);
    XXmu         = mean(XXtemp);
    XX_trav(objind,:) = XXmu;
end

% maybe use louvain clustering for this particular problem???
% the idea being you don't want to be too conservative with your cutoff for what constitutes a "cluster"


%% louvain
% % next, construct the adjacency matrix (do NOT use trial-averaged data anymore!)
% keepcols = 10:29; % 10:29: ignore orientation (since humans & monkeys grasp from different locations), instead focus on hand shape (get 2 cross-context clusters this way)
% Xdist       = squareform( pdist(X_trav(:,keepcols)) ); % simple euclidean distance. better than mahalanobis, to avoid over-weighting components with low variance
% Xdist       = Xdist + diag(nan(size(X_trav,1),1)); % censor the diagonals
% 
% % set max (is-adjacent) distance equal to the max distance among the specials, which were designed to elicit similar grasps (it's nice to have a reasonable proxy for ground truth)
% specialinds  = cellfun(@(x) ~isempty(regexpi(x,'special.*active','once')),uobj);
% specialdists = Xdist(specialinds,specialinds);
% specialinds2  = cellfun(@(x) ~isempty(regexpi(x,'special.*passive','once')),uobj);
% specialdists2 = Xdist(specialinds2,specialinds2);
% distthresh   = max(vertcat(specialdists(:),specialdists2(:))) + eps;
% A            = Xdist < distthresh;
% A(isnan(A))  = 0; % de-censor the diagonal. points are not their own neighbors, so we put 0 here.
% 
% % do clustering, but only after subtracting out within-session means (again, more powerful than orthogonalizing w.r.t. the task-separating dimension, but something I feel uneasy about implementing in neural data since it can't be supported with a mere linear readout)
% community = cluster_jl(A);
% clustinds = community.COM{end};
% 
% % perform PCA
% [~,Xscores] = pca(X_trav,'numcomponents',10); % do 10 dimensions, whatever
% 
% % now plot!
% nclusts = numel(community.SIZE{end});
% % clors = distinguishable_colors(nclusts); %brewermap(nclusts,'Set3');
% % figure,gplotmatrix(Xscores,[],clustinds,clors)
% 
% % now see how cluster IDs capture object IDs
% clustered_objnames = cell( nclusts,1 );
% 
% for clustind = 1:nclusts
%     theseinds = clustinds == clustind;
%     onames    = uobj(theseinds);
%     %     onames = unique(char(objcat),'rows');
%     onames = cellstr(onames);
%     clustered_objnames{clustind} = onames;
% end

%% agglomerative
% Z = linkage(X_trav,'ward');
keepcols = 10:29; % 10:29: ignore orientation (since humans & monkeys grasp from different locations), instead focus on hand shape (get 2 cross-context clusters this way)

specialindsa = cellfun(@(x) ~isempty(regexpi(x,'special.*active','once')),uobj);
specialindsp = cellfun(@(x) ~isempty(regexpi(x,'special.*passive','once')),uobj);
Zspeciala    = linkage(X_trav(specialindsa,keepcols),'ward');
Zspecialp    = linkage(X_trav(specialindsp,keepcols),'ward');
specialclustcutoff = max( max(Zspeciala(:,3)), max(Zspecialp(:,3)) ) + 1e-6;

T = clusterdata(X_trav(:,keepcols),'criterion','distance','cutoff',specialclustcutoff,'linkage','ward'); % seems to work, although the documentation is actually kinda unclear about how this should work...

% nclusts = numel(unique(T));
% clors = distinguishable_colors(nclusts);
% figure,gplotmatrix(Xscores,[],T,clors)

%% find clusters that pool across contexts
[sortinds,sorti] = sort(T);
sortnames = uobj(sorti);
sortcat   = horzcat(num2cell(sortinds),sortnames);
Xt        = XX_trav; %(sorti,:);

crosscontextclusters = [];

for clusterind = 1:max(T)
    thisclust  = sortinds==clusterind;
    thesenames = sortnames(thisclust);
    isactive   = any( cellfun(@(x) ~isempty(regexpi(x,'active','once')),thesenames) );
    ispassive  = any( cellfun(@(x) ~isempty(regexpi(x,'passive','once')),thesenames) );
    
    if isactive && ispassive
        crosscontextclusters = vertcat(...
            crosscontextclusters, clusterind );
    else
        % pass
    end
end

keepclusters = ismember(sortinds,crosscontextclusters);

Xkeep = Xt; %Xt(keepclusters,:);

timevals = (1:size(Xkeep,1))';

colnames = vertcat('time',datastruct.cellform{1}{6}.KinematicColNames);

addpath( fullfile('..','MirrorData','KinematicsProcessing','tools') )
fname = fullfile('..','Analysis-Outputs','crosspostures');
motWrite(fname,colnames,[timevals,Xkeep])

%% spit out info
clusterstruct.clusterinds = T; % write a visualization script to confirm that the grouped sets of cross-context grips are indeed similar
clusterstruct.objnames    = uobj;
clusterstruct.sortcat     = sortcat;
clusterstruct.sortcat_onlycrosscontextclusters = sortcat(keepclusters,:);

% hmmm... agglomerative and louvain tell me that roughly the same sets of objects are similarly grasped across contexts
% (if anything louvain is less conservative and brings more objects into the fold, BUT IMPORTANTLY it still only identifies two cross-context clusters, and the objects which formed separate cross-context clusters during agglomerative STILL DO SO during louvain...)

%% notes
% louvain sets an adjacency threshold
% agglomerative sets a clustering threshold
% the latter is what I want
return