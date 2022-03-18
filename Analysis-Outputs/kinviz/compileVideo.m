%% description
% trawls directories
% takes the last frame of each .mot
% puts them all together into a single .mot
% now all you gotta do is make the movie in Opensim and extract the individual frames of that movie

%% setup
restoredefaultpath

mfp = mfilename('fullpath');
[mfd,~,~] = fileparts(mfp);
cd(mfd)

% path setup
old_dir = cd( fullfile('..','..') ); % only way I can figure to convert this to an absoulte path: run cd, then reference pwd

% now add other paths (this is basically analysis_setup absent the manopt stuff)
addpath( genpath( fullfile(pwd,'MirrorData') ) )
addpath( genpath( fullfile(pwd,'Utils') ) )
addpath( genpath( fullfile(pwd,'Data Processing') ) )
cd(old_dir)

%% mot trawler
D = dir(mfd);
kinfolderid = cellfun(@(x) ~isempty( regexpi(x.name,'_pooled$','once') ),D);