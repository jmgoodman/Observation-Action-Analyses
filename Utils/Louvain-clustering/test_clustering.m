close all
addpath(genpath('./Community_BGLL_Matlab')) % faster than doing all the stuff with mfilename & fileparts, throws an error if you try to run this outside its home folder.

%%
% % test on the Fisher Iris dataset
% firis = load('fisheriris.mat');
% X = zscore(firis.meas); % standardize columns to avoid prioritizing any one feature too much
% distmat = squareform( pdist(X) );

% % test on carbig
% cbig  = load('carbig.mat');
% X     = horzcat( cbig.MPG, cbig.Cylinders,...
%     cbig.Displacement,cbig.Horsepower,cbig.Weight,...
%     cbig.Acceleration );
% 
% % remove nan-rows
% nanrows = any(isnan(X),2);
% X       = X(~nanrows,:);
% 
% X     = zscore(X); % standardize columns to avoid prioritizing any one feature too much
% distmat = squareform( pdist(X) );

% % test on morse code dataset
% q = load('morse.mat');
% X       = q.Y0;
% distmat = squareform( q.dissimilarities );

% test on kmeansdata
q = load('kmeansdata.mat');
X = q.X; % no need to standardize, the data are designed for testing a scale-sensitive clustering method.
distmat = squareform( pdist(X) );

% we expect 3 clusters to come out of this
% contrast 2 methods
% louvain
% agglomerative ward clustering
% use censorship loss

%% louvain

% calc adjacency matrix (algorithm designed to work on binary yes/no adjacency...)


dthresh = max( min( distmat + diag(nan(size(X,1),1)),[],2 ),[],1 ); % ensure everyone gets a neighbor

A = distmat <= dthresh;
A = A - eye(size(A)); % diagonal elements are zero, points are not adjacent to themselves

community = cluster_jl(A); % use the official louvain method. The implementation I was working with before had a "minimum clusters" parameter, which I always thought was weird... and it indeed was, because the official code does NOT use it!!! The second input, by default, is whether to do recursive computation (1) or not (non-1).

cominds   = community.COM{end};

Q=modularity(A,cominds); % modularity = within community, how many more connections between nodes do you get than you would naively expect given those nodes' degrees? (i.e., are within-community nodes particularly densely interconnected w.r.t. the network as a whole?)

% and plot
figure
gplotmatrix(X,[],cominds)

% % plot the real labels, too
% figure
% gplotmatrix(X,[],firis.species)