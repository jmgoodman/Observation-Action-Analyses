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
kinfolders = D(kinfolderid);
nfolders   = numel(kinfolders)

% don't need to implement a stack or queue or anything for a full tree traversal. We just have one level here
for folderind = 1:kinfolders
	% find all the .mot files
	% use motRead to read them
	% pull out the last frame (& the formatting / metadata / column names)
	% use motWrite to make the new video
end