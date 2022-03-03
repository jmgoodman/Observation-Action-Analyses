%% comment/uncomment below depending on whether you do or do not need to load in the data
%% cleanup
clear,clc,close all

%% setup
restoredefaultpath
analysis_setup

%% load data

% kinsessions = {'Moe32.mat','Moe34.mat'};
kinsessions = {'Zara64.mat','Zara68.mat','Zara70.mat'};
kincat      = [];
kintracecat = [];
objcat  = {};
seshcat = {};
for ii = 1:numel(kinsessions)
    load(kinsessions{ii}); % imports M
    ppd = preprocess(M,'removebaseline',false,...
        'alignments',{'hold_onset_time'},...
        'alignment_realnames',{'hold_onset_time'},...
        'windows',{[-1500 500]},...
        'normalize',false,...
         'domarker',true); % allow markers to be visualized and assessed here! only possible for Moe's data, Zara's data have preprocessing issues with the marker kinematics (long stretches of NaN that bookend trial blocks, which breaks NaN detection and interpolation routines) that preclude dealing with them using the standard preprocess routine.
    triallabels = extractlabels(ppd);
    
    % pick your subject
    %     keeptrials = ismember(triallabels.trialcontexts.names,{'control','active'}); % monkey
    keeptrials = ismember(triallabels.trialcontexts.names,{'passive'}); % hooman
    
    % grab hold-onset postures
    B0 = find( ppd{1}{1}.BinTimes >= 0,1,'first' );
    kincat = vertcat( kincat, ...
        squeeze( ppd{1}{1}.KinematicData(B0,:,keeptrials) )' );
    
    % grab traces
    kintracecat = cat(3,kintracecat,ppd{1}{1}.KinematicData(:,:,keeptrials));
    
    if ii == 1
        bincat = ppd{1}{1}.BinTimes;
        colcat = ppd{1}{1}.KinematicColNames;
    else
        % pass (should be equal for session 2)
    end
    
    % grab object IDs
    objcat = vertcat( objcat, ...
        triallabels.objects.names(keeptrials) );
    
    seshcat = vertcat( seshcat, ...
        repmat(kinsessions(ii),sum(keeptrials),1) );
end

%% port the important parts of test_kinclust here
% for starters: port the louvain & agglomerative clustering methods without all the tertiary visualization

X = kincat; % no z-score, joints with low ROMs shouldn't be boosted...

% find the session-specific means and subtract them
muvals = [];
for ii = 1:numel(kinsessions) % inefficient but only slightly so, not the bottleneck at all
    thesetrials = ismember(seshcat,kinsessions(ii));
    mu = mean( kincat(thesetrials,:) );
    X(thesetrials,:) = bsxfun(@minus,kincat(thesetrials,:),mu);
    
    muvals = vertcat(muvals,mu); %#ok<*AGROW>
end
% deltamu = diff(muvals); % for testing. max positional difference = ~5 mm, max angular difference = ~6 degrees


% only look at the joint angles (and the non-floating coordinates at that!)
% ignore the floating orientation coordinates with zero variance, and also the translational coordinates whose scale doesn't match the joint angular ones
X = X(:,7:29); %X(:,[30:92,96:98]); %X(:,7:29); %X(:,[30:92,96:98]); % marker positions! 7:29 gives joint angles... [93:95,99:119] give the elbow & shoulder (the former I don't trust, the latter is always 0) and "helper" points

% next, average across objects
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

% next, construct the adjacency matrix (do NOT use trial-averaged data anymore!)
Xdist       = squareform( pdist(X_trav) ); % euclidean distance. also consider chebychev, or max coordinate difference, to get distances in terms of max joint angle deviation
Xdist       = Xdist + diag(nan(size(X_trav,1),1)); % censor the diagonals

% distthresh  = max( min( Xdist,[],2 ),[],1 ) + eps; % everyone gets at least one neighbor
% set max distance equal to the max distance among the specials, which were designed to elicit similar grasps (it's nice to have a reasonable proxy for ground truth)
specialinds  = cellfun(@(x) ~isempty(regexpi(x,'special','once')),uobj);
specialdists = Xdist(specialinds,specialinds);
distthresh   = max(specialdists(:)) + eps;
A            = Xdist < distthresh; % question: should every joint actually be weighted equally by ROM? should we not weight MCP more heavily, since it has such an outsize impact on the fingertip positions and thus, also, the other joints' angles?
A(isnan(A))  = 0; % de-censor the diagonal. points are not their own neighbors, so we put 0 here.

% do clustering, but only after subtracting out within-session means (again, more powerful than orthogonalizing w.r.t. the task-separating dimension, but something I feel uneasy about implementing in neural data since it can't be supported with a mere linear readout)
community = cluster_jl(A);
clustinds = community.COM{end};

% now see how cluster IDs capture object IDs
nclusts = numel(community.SIZE{end});
clustered_objnames = cell( nclusts,1 );

for clustind = 1:nclusts
    theseinds = clustinds == clustind;
    onames    = uobj(theseinds);
    onames = cellstr(onames);
    clustered_objnames{clustind} = onames;
end

%% contrast with agglomerative
Z = linkage(X_trav,'ward');
Zspecial = linkage(X_trav(specialinds,:),'ward');
specialclustcutoff = max(Zspecial(:,3)) + 1e-6;
% figure,dendrogram(Z,0,'labels',uobj,'orientation','right','colorthreshold',specialclustcutoff) % this captures the link defined by the "special" turntable, which we take for granted to be a clustered grip (because it's SUPPOSED to be, by design). anything as (or more) clustered than the specials is, in turn, also clustered. Anything less clustered? Let's not get too carried away!

T = clusterdata(X_trav,'criterion','distance','cutoff',specialclustcutoff,'linkage','ward'); % seems to work, although the documentation is actually kinda unclear about how this should work...

agg_clustered_objnames = cell(max(T),1);
for clustind = 1:max(T)
    theseinds = T == clustind;
    onames    = uobj(theseinds);
    onames = cellstr(onames);
    agg_clustered_objnames{clustind} = onames;
end

%% and now, the maximally separated objects (based on the final joint angular postures)
%% initial guess: make it an intelligent one
% estimate new Xdists WITHOUT the wrist joint angles!!! (which means indices 4:end)
% allowing wrist orientation to change results in 6 very clearly different grips: 3 orientations (0, 45, and 90 degrees), and 2 apertures (big & small)
% preventing wrist orientation changes results in 6 more subtly-different grasps:
%   cube25 (fingers wrapped around, thumb perched atop the axis orthogonal to and circumscribed by the fingertips)
%   special3 (finger and thumb tips pointed at each other)
%   precision (really more "keypinch", thumb tip meets side of index finger, the other fingers curl along with the index, but the index MCP is more extended than the others')
%   bar40 (huge aperture, thumb tip is 45 degrees incident to all the other digit tips)
%   cylv40 (also huge aperture, thumb is now 90 degrees incident to the digit tips & also is closer to the MCP joints than to the tips)
%   ring60 (fingers all curled up, thumb 90 degrees incident to fingertips, quite similar to precision EXCEPT that the ulnar digits are more extended for this grip)

Xdist       = squareform( pdist(X_trav(:,1:end)) ); % euclidean distance. also consider chebychev, or max coordinate difference, to get distances in terms of max joint angle deviation
Xdist       = Xdist + diag(nan(size(X_trav,1),1)); % censor the diagonals

meandists  = nanmean(Xdist);
[~,maxind] = max(meandists); % start with the one point furthest (on average) from all other points

guessinds = maxind;

for ii = 2:6
    % next, take the one that's furthest from all the current guessinds, on average
    tempdist   = Xdist;
    tempdist(guessinds,:) = nan;
    mindists  = nanmin( tempdist(:,guessinds),[],2 );
    [~,maxind] = max(mindists);
    guessinds  = vertcat(guessinds,maxind);
end

%% show the initial guess of the best network
allindpairs = nchoosek(guessinds,2);
[~,Xscores] = pca(X_trav(:,1:end),'numcomponents',3);
figure
scatter3(Xscores(:,1),Xscores(:,2),Xscores(:,3))
hold all
line( [Xscores(allindpairs(:,1),1),Xscores(allindpairs(:,2),1)]',...
    [Xscores(allindpairs(:,1),2),Xscores(allindpairs(:,2),2)]',...
    [Xscores(allindpairs(:,1),3),Xscores(allindpairs(:,2),3)]',...
    'linewidth',0.5,'color',[0 0 0 0.2] )
hold all
scatter3(Xscores(guessinds,1),Xscores(guessinds,2),Xscores(guessinds,3),144,[0 0 0],'filled','markerfacealpha',0.2)
box off, axis tight, grid on, axis equal
drawnow
pause(0.1)


%% not actually necessary? the initial guess is actually pretty darn good???
% nah, it's necessary. this implementation was just bugged before.
T0       = 100;
coolrate = 1 - 1e-5;
maxstag  = 1e5;
maxtotal = 1e6;

solutionnodes = 6;
totalnodes    = size(Xdist,1);
max2swap      = floor(sqrt(solutionnodes));

currentsolution = guessinds; %1:solutionnodes;
Xdist(isnan(Xdist)) = 0; % uncensor diag to be 0s
currentloss     = summinloss(Xdist,currentsolution); % varloss(X_trav,currentsolution); % varloss sucks
bestsolution    = currentsolution;
bestloss        = currentloss; % we actually wanna MAXIMIZE this
T               = T0;

stagnationcount = 0;

for ii = 1:maxtotal
    ntoswap   = randi(max2swap);
    inds2swap = randperm(solutionnodes,ntoswap);
    validinds = setdiff(1:totalnodes,currentsolution); % don't include the former members - we're defining a combo, not a permutation here
    
    candidatesolution = currentsolution;
    whichvalids       = randperm( numel(validinds),ntoswap );
    candidatesolution(inds2swap) = validinds(whichvalids);
    candidateloss                = summinloss(Xdist,candidatesolution);
    %     candidateloss     = varloss(X_trav,candidatesolution); % varloss sucks, it has no qualms about picking out "clusters" since those move the mean and, thus, can increase the variance!!!
    
    % now do the annealing thing
    if candidateloss > currentloss
        currentloss     = candidateloss;
        currentsolution = candidatesolution;
        stagnationcount = 0;
    else
        randdraw = rand;
        tempval  = exp( (candidateloss - currentloss)/T ); % for when candidateloss is less than currentloss (and thus the exponent is negative)
        if randdraw < tempval % at first, T is high, so tempval is always close to 1
            currentloss     = candidateloss;
            currentsolution = candidatesolution;
            stagnationcount = 0;
        else
            stagnationcount = stagnationcount + 1;
            if mod(stagnationcount,1000)==0
                fprintf('stagnated for %i iterations\n',stagnationcount)
            else
                % pass
            end 
        end
    end
    
    if candidateloss > bestloss
        bestloss     = candidateloss;
        bestsolution = candidatesolution;
        fprintf('new solution: loss = %0.2f, iter = %i\n',bestloss,ii)
        
        % also: plot the new best solution!
        allindpairs = nchoosek(bestsolution,2);
        cla
        scatter3(Xscores(:,1),Xscores(:,2),Xscores(:,3))
        hold all
        line( [Xscores(allindpairs(:,1),1),Xscores(allindpairs(:,2),1)]',...
            [Xscores(allindpairs(:,1),2),Xscores(allindpairs(:,2),2)]',...
            [Xscores(allindpairs(:,1),3),Xscores(allindpairs(:,2),3)]',...
            'linewidth',0.5,'color',[0 0 0 0.2] )
        hold all
        scatter3(Xscores(bestsolution,1),Xscores(bestsolution,2),Xscores(bestsolution,3),144,[0 0 0],'filled','markerfacealpha',0.2)
        box off, axis tight, grid on, axis equal
        drawnow
        pause(0.1)
    end
    
    T = T*coolrate;
    
    if stagnationcount > maxstag
        break
    else
    end
    
end

disp( uobj(bestsolution) )

for ii = 1:numel(uobj)
    txt = uobj{ii};
    if ismember(ii,bestsolution)
        sz = 12;
    else
        sz = 6;
    end
    text(Xscores((ii),1), Xscores((ii),2),...
        Xscores((ii),3), txt, 'fontname','helvetica', 'fontsize',sz,...
        'horizontalalignment','left')
end

%% now visualize each grip
% first, we gotta get TRAJECTORIES, not just the hold-onset positions!

% get averaged trajectories for each object
Xtraj = kintracecat;

% center differently
% the joint angles, center column-by-column
% the marker positions, center globally
% (note: sessions are good, confirmed in Opensim, you just had a bug before!!!)
Xinds = cellfun(@(x) ~isempty(x),regexpi(colcat,'_X$','once'));
Yinds = cellfun(@(x) ~isempty(x),regexpi(colcat,'_Y$','once'));
Zinds = cellfun(@(x) ~isempty(x),regexpi(colcat,'_Z$','once'));
otherinds = ~(Xinds | Yinds | Zinds);

mu_ = [];
for ii = 1:numel(kinsessions)
    thesetrials = ismember(seshcat,kinsessions(ii));
    
    Xtemp = Xtraj(:,:,thesetrials);
    
    tempmu = mean( mean( Xtemp(:,otherinds,:),3 ),1 );
    
    Xtemp(:,otherinds,:) = bsxfun(@minus,Xtemp(:,otherinds,:),...
        mean( mean( Xtemp(:,otherinds,:),3 ),1 ) ); % can do sequential instead of flattened averaging, since we don't have an imbalance
    
    Xtemp(:,Xinds,:) = bsxfun(@minus,Xtemp(:,Xinds,:),...
        mean( mean( mean( Xtemp(:,Xinds,:),3 ),2 ),1 ) ); % again, sequential averaging. Also we include dim=2 here since we want to average over ALL X coordinates, and not on a column-by-column basis like for the joint angles
    
    Xtemp(:,Yinds,:) = bsxfun(@minus,Xtemp(:,Yinds,:),...
        mean( mean( mean( Xtemp(:,Yinds,:),3 ),2 ),1 ) ); % again, sequential averaging. Also we include dim=2 here since we want to average over ALL X coordinates, and not on a column-by-column basis like for the joint angles
    
    Xtemp(:,Zinds,:) = bsxfun(@minus,Xtemp(:,Zinds,:),...
        mean( mean( mean( Xtemp(:,Zinds,:),3 ),2 ),1 ) ); % again, sequential averaging. Also we include dim=2 here since we want to average over ALL X coordinates, and not on a column-by-column basis like for the joint angles
    
    Xtraj(:,:,thesetrials) = Xtemp;
    
    mu_ = vertcat(mu_,tempmu);
    
    % note: marker positions offer better classification WITHIN session...
    % ...but what if you need to classify ACROSS sessions???
    % (based on KINEMATICS, not talking about neural data here...)
end

% always plots a right hand.


% take the OVERALL average and replace within-sessions averages with those (when considering joint angles)
% (after all, without the proper base posture, that shit's gonna look weird...)
mu = mean(mu_,1);
Xtraj(:,otherinds,:) = bsxfun(@plus,Xtraj(:,otherinds,:),mu);
    

% next, average across objects
[uobj,~,uind] = unique(char(objcat),'rows');
uobj       = cellstr(uobj);
objcount   = numel(uobj); % get in the habit of doing this. it's (slightly) more efficient!
jointcount = size(Xtraj,2);
bincount   = size(Xtraj,1);
X_trav = zeros(bincount,jointcount,objcount);

% uind = uind(keepinds(:)); % keepinds does not exist...

for objind = 1:objcount
    thesetrials = uind == objind;
    Xtemp       = Xtraj(:,:,thesetrials);
    Xmu         = mean(Xtemp,3); % yeah, we're gonna preserve the time axis in this average...
    X_trav(:,:,objind) = Xmu;
end

%% NOW we get to call vizkins!
mkdir('../Analysis-Outputs/kinviz/')

%%
% swap depending on subject
% mkdir('../Analysis-Outputs/kinviz/Moe_32_34_HoldAligned_pooled')
% dir2save = '../Analysis-Outputs/kinviz/Moe_32_34_HoldAligned_pooled';

% mkdir('../Analysis-Outputs/kinviz/Zara_AllSessions_HoldAligned_pooled')
% dir2save = '../Analysis-Outputs/kinviz/Zara_AllSessions_HoldAligned_pooled';

mkdir('../Analysis-Outputs/kinviz/Alex_AllSessions_HoldAligned_pooled')
dir2save = '../Analysis-Outputs/kinviz/Alex_AllSessions_HoldAligned_pooled';

%%
addpath(genpath(fullfile('..','MirrorData','KinematicsProcessing')))
vizkins(X_trav,bincat,colcat,uobj,dir2save)