function clusterstruct = zara_kinclust()
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
    load(sprintf('%s_datastruct.mat',seshstr)); %#ok<LOAD>
    triallabels = extractlabels(datastruct.cellform);
    
    % grab object labels
    olabstemp = triallabels.objects.names;
    
    % grab context IDs
    ttypecat    = triallabels.trialcontexts.names;
    
    % adjust object names to incporporate context
    activeinds  = ismember(ttypecat,'active');
    %     passiveinds = ismember(ttypecat,'passive');
    
    %     olabstemp(activeinds)  = strcat(olabstemp(activeinds),' active');
    %     olabstemp(passiveinds) = strcat(olabstemp(passiveinds),' passive');
    
    olabstemp = olabstemp( activeinds );
    
    % grab hold-onset postures
    kctemp = squeeze( datastruct.cellform{1}{6}.KinematicData(51,:,:) )';
    kctemp = kctemp( activeinds,: );
    
    kincat = vertcat( kincat, ...
       kctemp );
    
       
    % grab object IDs
    objcat = vertcat( objcat, ...
        olabstemp );

    % make active & passive into separate trial indices, once more to account for systematic errors in "default" postures...
    seshtemp = repmat(kinsessions(ii),numel(ttypecat),1);
    %     seshtemp(activeinds)  = strcat(seshtemp(activeinds),' active');
    %     seshtemp(passiveinds) = strcat(seshtemp(passiveinds),' passive');
    seshtemp              = seshtemp( activeinds );
    
    seshcat = vertcat( seshcat, ...
        seshtemp );
end

%%
% subtract within-session means
X = kincat; % no z-score, joints with low ROMs shouldn't be boosted...

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
X = X(:,7:29);
% X = X(:,7:9); % JUST the wrist, the hand shapes per se are too different...

% next, average across trials within each object
[uobj,~,uind] = unique(char(objcat),'rows');
uobj       = cellstr(uobj);
objcount   = numel(uobj); % get in the habit of doing this. it's (slightly) more efficient!
jointcount = size(X,2);
X_trav = zeros(objcount,jointcount);

for objind = 1:objcount
    thesetrials = uind == objind;
    Xtemp       = X(thesetrials,:);
    Xmu         = mean(Xtemp);
    X_trav(objind,:) = Xmu;
end

%% louvain
% % next, construct the adjacency matrix (do NOT use trial-averaged data anymore!)
% Xdist       = squareform( pdist(X_trav) ); % simple euclidean distance. better than mahalanobis, to avoid over-weighting components with low variance
% Xdist       = Xdist + diag(nan(size(X_trav,1),1)); % censor the diagonals
%
% % set max (is-adjacent) distance equal to the max distance among the specials, which were designed to elicit similar grasps (it's nice to have a reasonable proxy for ground truth)
% specialinds  = cellfun(@(x) ~isempty(regexpi(x,'special','once')),uobj);
% specialdists = Xdist(specialinds,specialinds);
% distthresh   = max(specialdists(:)) + eps;
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
% clors = distinguishable_colors(nclusts); %brewermap(nclusts,'Set3');
% figure,gplotmatrix(Xscores,[],clustinds,clors)
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
specialinds = cellfun(@(x) ~isempty(regexpi(x,'special','once')),uobj);
Zspecial    = linkage(X_trav(specialinds,:),'ward');
specialclustcutoff = max( Zspecial(:,3) ) + 1e-6;

T = clusterdata(X_trav,'criterion','distance','cutoff',specialclustcutoff,'linkage','ward'); % seems to work, although the documentation is actually kinda unclear about how this should work...

% nclusts = numel(unique(T));
% clors = distinguishable_colors(nclusts);
% figure,gplotmatrix(Xscores,[],T,clors)

%% spit out info
clusterstruct.clusterinds = T;
clusterstruct.objnames    = uobj;

%% notes
% louvain sets an adjacency threshold
% agglomerative sets a clustering threshold
% the latter is what I want
return