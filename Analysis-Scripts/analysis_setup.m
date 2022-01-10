% analysis_setup
% this just sets the matlab search path to what you need for this batch of analyses
restoredefaultpath

mfp = mfilename('fullpath');
[mfd,~,~] = fileparts(mfp);
cd(mfd)

% path setup
old_dir = cd( fullfile('..') ); % only way I can figure to convert this to an absoulte path: run cd, then reference pwd

% setup manifold path (which itself calls restoredefaultpath, so any redundant-looking lines after setup_manifold_env are on purpose)
addpath( genpath( fullfile(pwd,'Utils') ) )
setup_manifold_env

% now add the paths to other non-manopt stuff
addpath( fullfile(pwd,'MirrorData') )
addpath( genpath( fullfile(pwd,'Utils') ) )
addpath( genpath( fullfile(pwd,'Data Processing') ) )
cd(old_dir)