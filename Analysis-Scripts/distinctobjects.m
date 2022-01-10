%% cleanup
% clear,clc,close all
% 
% %% setup
% restoredefaultpath
% analysis_setup
% 
% %% kinematics sessions
% % kinsessions = {'Moe32_JUSTKinematics.mat','Moe34_JUSTKinematics.mat'};
% kinsessions = {'Moe32','Moe34'};
% kincat  = [];
% objcat  = {};
% seshcat = {};
% 
% for ii = 1:numel(kinsessions)
%     tempdstruct = dataload(kinsessions{ii});
%     % load( [kinsessions{ii},'_datastruct.mat'] ); tempdstruct = datastruct;
%     triallabels = extractlabels(tempdstruct.cellform);
%     
%     % grab hold-onset postures
%     kincat = vertcat( kincat, ...
%         squeeze( tempdstruct.cellform{1}{6}.KinematicData(51,:,:) )' );
%     
%     % grab object IDs
%     objcat = vertcat( objcat, ...
%         triallabels.objects.names );
%     
%     seshcat = vertcat( seshcat, ...
%         repmat(kinsessions(ii),numel(triallabels.objects.names),1) );
% end

%%
% subtract within-session means (as systematic between-session inaccuracies in postural estimation may give rise to "false" clusters)
X = kincat; % no z-score, joints with low ROMs shouldn't be boosted...

muvals = [];
for ii = 1:numel(kinsessions) % inefficient but only slightly so, not the bottleneck at all
    thesetrials = ismember(seshcat,kinsessions(ii));
    mu = mean( kincat(thesetrials,:) );
    X(thesetrials,:) = bsxfun(@minus,kincat(thesetrials,:),mu);
    
    muvals = vertcat(muvals,mu); %#ok<*AGROW>
end
deltamu = diff(muvals); % max positional difference = ~5 mm, max angular difference = ~6 degrees

% ignore the floating orientation coordinates with zero variance, and also the translational coordinates whose scale doesn't match the joint angular ones (and the time axis of course...)
X = X(:,7:29);
% X = X(:,10:29); % if you also wanna ignore the wrist, focusing on hand shape at the expense of hand orientation (probably not something you wanna be doing) (also remember: you lock the floatyawrollpitch dims during IK, so the "wrist" does indeed tell you about hand orientation & isn't obfuscated by the shoulder DOFs!!!)

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

[~,Xscores] = pca(X_trav);

% % remove 35+mm cylinders
% objs2remove = [24,25,30,31];
% X_trav(objs2remove,:) = [];
% uobj(objs2remove) = [];
% objcount = objcount - numel(objs2remove);
% Xscores(objs2remove,:) = [];
%% initial guess: make it an intelligent one
Xdist      = pdist(X_trav);
Xdist      = squareform(Xdist);
meandists  = mean(Xdist);
[~,maxind] = max(meandists); % start with the one point furthest (on average) from all other points

guessinds = maxind;

solutionnodes = 6;
for ii = 2:solutionnodes
    % next, take the one that's furthest from all the current guessinds, on average
    tempdist   = Xdist;
    tempdist(guessinds,:) = nan;
    mindists  = nanmin( tempdist(:,guessinds),[],2 );
    [~,maxind] = max(mindists);
    guessinds  = vertcat(guessinds,maxind);
end

%% show the initial guess of the best network
allindpairs = nchoosek(guessinds,2);
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

totalnodes    = size(Xdist,1);
max2swap      = floor(sqrt(solutionnodes));

currentsolution = guessinds; %1:solutionnodes;

currentloss     = summinloss(Xdist,currentsolution); % varloss(X_trav,currentsolution); % varloss sucks
% currentloss     = maxvolloss(X_trav,currentsolution); % this is okay but prioritizes factors other than separation per se... mindist is better
% "variance" loss blows, it tends to find two "clusters" instead of object sets which every single object pair is distinct

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
    %     candidateloss                = maxvolloss(X_trav,candidatesolution); % this is okay but prioritizes factors other than separation per se... mindist is better
    % "variance" loss blows, it tends to find two "clusters" instead of object sets which every single object pair is distinct
    
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

view([-37 30])

%% todo:
% set this up to find a whole HOST of maximally distinct turntables...
% i.e., you not only want a maximally distinct set of like 18 grips, but also want to arrange those distinct grips s.t. every group of 6 is ALSO maximally distinct within that group!
