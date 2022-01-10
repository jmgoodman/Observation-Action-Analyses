%% MergeUnits usage example (do NOT apply this, it's dumb)
restoredefaultpath

%% add paths (robust to platform)
mfn = mfilename('fullpath');
fs  = filesep;

% go up three levels
fslocs = regexpi(mfn,fs);
levels_3up = mfn(1:fslocs(end-4)); % extra subfolder relative to old path

addpath(genpath(levels_3up))

%% actually load in the data processed by MirrorData.ImportData and apply the MergeUnits script
% load('Zara64.mat');
% M64 = M;
% N64 = M64.MergeUnits; % it's as simple as that!
% save('Zara64_MergedUnits.mat','N64','-v7.3')
% 
% load('Zara68.mat');
% M68 = M;
% N68 = M68.MergeUnits; % it's as simple as that!
% save('Zara68_MergedUnits.mat','N68','-v7.3')

load('Moe46.mat')
M46 = M;
N46 = M46.MergeUnits;
save('Moe46_MergedUnits.mat','N46','-v7.3')

%% easy as that! (of course, you gotta know how to run ImportData first...)