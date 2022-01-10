%% this script calls the data packaging methods
% namely because they use the signal processing toolbox, and I need that...

%% cleanup
clear,clc,close all

%% setup
restoredefaultpath
analysis_setup

%%
% sesh_strs = {'Zara70_withKinematics','Zara68_withKinematics','Zara64_withKinematics','Moe46','Moe50'};
sesh_strs = {'Zara70','Zara68','Zara65','Zara64','Moe50','Moe46','Moe34','Moe32'};

%%
for sesh_ind = 1:numel(sesh_strs)
    seshstr    = sesh_strs{sesh_ind};
    datastruct = dataload(seshstr,'softnorm','none');
    save(sprintf('../MirrorData/%s_datastruct.mat',seshstr),'datastruct','-v7.3')
end