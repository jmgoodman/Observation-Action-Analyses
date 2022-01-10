function [] = vizkins(X,binlabels,collabels,triallabels,dir2save)

% given a set of marker positions, visualize the hand that they describe
% (might also wanna spit out .mot files)
% X will contain the 2s (or so) long trajectories which end 500ms after hold onset (both joint angular and marker positions)
% this script will plot the marker positions of the final postures
% and also spit out .mots of the trajectories

%% X will be a tensor of data
% dim 1 = time (10ms bins), with elements corresponding with binlabels. Assumption: we're taking a 2s window from -1.5s to +0.5s w.r.t. hold onset.
% dim 2 = joints OR marker XYZ coordinates, with elements corresponding to collabels
% dim 3 = object x trial-type combination from which the AVERAGED hand trajectory arises, corresponding with triallabels.

%% first off, find the hold-onset bin and plot those marker positions
[~,HOB] = min(abs(binlabels));
HOX = squeeze(X(HOB,:,:));

% only take the marker positions
% go from D1 - tip-to-MCP, then D2 - tip-to-MCP, THEN wrist
D1mkr = [39:41;36:38;33:35;30:32];
D2mkr = D1mkr + 12;
D3mkr = D2mkr + 12;
D4mkr = D3mkr + 12;
D5mkr = D4mkr + 12;
Wmkr  = 90:92;

allmkr = vertcat(D1mkr,D2mkr,D3mkr,D4mkr,D5mkr,Wmkr);

named_mkrs = [1:4:17,21];
mkr_names  = {'D1','D2','D3','D4','D5','Wrist'};
n_named    = numel(mkr_names);

% adjacency for line plotting
n_mkr = size(allmkr,1);
adj_pairs = [1,2;2,3;3,4]; % D1, distal-to-proximal
adj_pairs = vertcat(adj_pairs,adj_pairs+4,adj_pairs+8,adj_pairs+12,adj_pairs+16);
adj_pairs = vertcat( adj_pairs,[4,8;8,12;12,16;16,20;4,21;8,21;12,21;16,21;20,21] ); % add mcp interconnections and, of course, the wrist itself
n_edge    = size(adj_pairs,1);

% xyz coords for plotting
x = HOX(allmkr(:,1),:);
y = HOX(allmkr(:,3),:); % flip the y and z axes to match intuition better 
z = HOX(allmkr(:,2),:); % this does, however, amount to a mirroring about the unity line on the Y-Z plane, so left hands will turn into right hands. not a *huge* deal, but you should be aware...

% get lims
getlims = @(x) [nanmin(x(:)), nanmax(x(:))];
xl = getlims(x);
yl = getlims(y);
zl = getlims(z);

% now plot for each object-condition
for condind = 1:numel(triallabels)
    figure
    xx = x(:,condind);
    yy = y(:,condind);
    zz = z(:,condind);
        
    scatter3(xx,yy,zz,36,[0 0 0],'filled')
    hold all
    
    % also plot "shadows"
    scatter3(xx,yy,min(zl)*ones(size(xx)),36,[0 0 0],'filled','markerfacealpha',0.2,'markeredgealpha',0.2)
    scatter3(min(xl)*ones(size(xx)),yy,zz,36,[0 0 0],'filled','markerfacealpha',0.2,'markeredgealpha',0.2)
    scatter3(xx,max(yl)*ones(size(xx)),zz,36,[0 0 0],'filled','markerfacealpha',0.2,'markeredgealpha',0.2)
    
    % add marker names where needed
    for ii = 1:n_named
        mkrind = named_mkrs(ii);
        hold all
        text(xx(mkrind),...
            yy(mkrind),...
            zz(mkrind),...
            mkr_names{ii},...
            'horizontalalign','left')
        
        % label the shadows too
        hold all
        text(min(xl),...
            yy(mkrind),...
            zz(mkrind),...
            mkr_names{ii},...
            'horizontalalign','left',...
            'color',[0.8 0.8 0.8])
        hold all
        text(xx(mkrind),...
            max(yl),...
            zz(mkrind),...
            mkr_names{ii},...
            'horizontalalign','left',...
            'color',[0.8 0.8 0.8])
        hold all
        text(xx(mkrind),...
            yy(mkrind),...
            min(zl),...
            mkr_names{ii},...
            'horizontalalign','left',...
            'color',[0.8 0.8 0.8])
    end
    
    % add lines between points where needed
    for ii = 1:n_edge
        edgeinds = adj_pairs(ii,:);
        hold all
        plot3(xx(edgeinds),...
            yy(edgeinds),...
            zz(edgeinds),...
            'k-','linewidth',0.5)
    end
    
    % add their shadows, too
    for ii = 1:n_edge
        edgeinds = adj_pairs(ii,:);
        hold all
        plot3(xx(edgeinds),...
            yy(edgeinds),...
            min(zl)*ones(size(xx(edgeinds))),...
            'k-','linewidth',0.5,'color',[0 0 0 0.2])
        hold all
        plot3(xx(edgeinds),...
            max(yl)*ones(size(xx(edgeinds))),...
            zz(edgeinds),...
            'k-','linewidth',0.5,'color',[0 0 0 0.2])
        hold all
        plot3(min(xl)*ones(size(xx(edgeinds))),...
            yy(edgeinds),...
            zz(edgeinds),...
            'k-','linewidth',0.5,'color',[0 0 0 0.2])
    end
    
    title(triallabels{condind})
    xlabel('x')
    ylabel('y')
    zlabel('z')
    box off, grid on, axis equal % note to self: do NOT subtract marker-by-marker mean positions as preprocessing! this works for joint angles, but NOT for positions, and will create WEIRD SHIT because you'll be destroying spatial structure! (odd how much structure DID get preserved, tho...)
    xlim(xl)
    ylim(yl)
    zlim(zl)
    view([30 30])
    
    % save figures
    savefigs(fullfile(dir2save,triallabels{condind}))
end

% your own pipeline is fine :)

%% now to spit out .mots
cols2keep = cellfun(@(x) isempty( regexpi(x,'_(X|Y|Z)$','once') ),collabels);

for ii = 1:numel(triallabels)
    Xtemp = X(:,cols2keep,ii);
    Xtemp = [binlabels(:)/1000,Xtemp]; %#ok<*AGROW> % binlabels are given in ms, need to convert to s!!!
    motWrite(fullfile(dir2save,triallabels{ii}),horzcat('time',collabels(cols2keep(:))'),Xtemp);
end
    
%% TODO:
% overlay "clustered" grips, in both video & static posture form
% just make sure the "clustered" grips are indeed kept together
% (use the Stefan method for clustering grips - that is, keep clusters that are *as* clustered or moreso than the special turntable objects)
