function clusterstruct = kinclust(celldata,mode)
%% "mode":
% 'default' = cluster monkey grips only
% 'cross'   = cluster both human & monkey grips (if available)
% 'passive' = cluster human grips only
if nargin < 2
    mode = 'default';
else
    % pass
end

%% note: I just went ahead and made separate zara & moe methods.

%% kinematics sessions
triallabels = extractlabels(celldata);
kincat      = squeeze( celldata{1}{6}.KinematicData(51,:,:) )';
objcat      = triallabels.objects.names;

% include trial type field...
% can't do this on my mac though, because downloading the data will literally take until I die
ttypecat    = triallabels.trialcontexts.names;
utypenames  = triallabels.trialcontexts.uniquenames;

% look for passive
includespassive = ismember('passive',utypenames);

% if passive is included, split indices
if includespassive
    activeinds  = ismember(ttypecat,'active');
    passiveinds = ismember(ttypecat,'passive');
    
else
    activeinds  = true(size(ttypecat));
    passiveinds = false(size(ttypecat));
end

% how to handle these indices? the "mode" input
switch mode
    case 'default'
        kincat = kincat(activeinds,:);
        objcat = objcat(activeinds);
    case 'passive'
        kincat = kincat(passiveinds,:);
        objcat = objcat(passiveinds);
    case 'cross'
        kincat = kincat(activeinds|passiveinds,:);
        objcat(activeinds)  = strcat(objcat(activeinds),' active');
        objcat(passiveinds) = strcat(objcat(passiveinds),' passive');
        objcat = objcat(activeinds|passiveinds);
end

%%
% only one session, so no need to subtract within-session means
X = kincat; % no z-score, joints with low ROMs shouldn't be boosted...

% ignore the floating orientation coordinates with zero variance, and also the translational coordinates whose scale doesn't match the joint angular ones
X = X(:,7:29);

% here we i

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


%% agglomerative
% Z = linkage(X_trav,'ward');

switch mode
    case 'default'
        specialinds  = cellfun(@(x) ~isempty(regexpi(x,'special','once')),uobj);
        Zspecial = linkage(X_trav(specialinds,:),'ward');
        specialclustcutoff = max(Zspecial(:,3)) + 1e-6;
    case 'cross'
        specialindsa = cellfun(@(x) ~isempty(regexpi(x,'special*active','once')),uobj);
        specialindsp = cellfun(@(x) ~isempty(regexpi(x,'special*passive','once')),uobj);
        Zspeciala    = linkage(X_trav(specialindsa,:),'ward');
        Zspecialp    = linkage(X_trav(specialindsp,:),'ward');
        specialclustcutoff = max( max(Zspeciala(:,3)), max(Zspecialp(:,3)) ) + 1e-6;
end

T = clusterdata(X_trav,'criterion','distance','cutoff',specialclustcutoff,'linkage','ward'); % seems to work, although the documentation is actually kinda unclear...

%% spit out info
clusterstruct.clusterinds = T;
clusterstruct.objnames    = uobj;

%% notes
% louvain sets an adjacency threshold
% agglomerative sets a clustering threshold
% the latter is what I want, as I have a (conservative) "ground truth" on a set of objects that should form a single cluster.
return