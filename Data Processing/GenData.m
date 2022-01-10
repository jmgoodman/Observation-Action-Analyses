restoredefaultpath
clearvars
clc

%% setup
restoredefaultpath
addpath(genpath('../Analysis-Scripts'))
analysis_setup

% datafolder = '/Users/jgoodman/Dropbox/Mirror Local/';
datafolder = 'E:\Dropbox\Mirror Local\';

%%
% Moe sessions

anname = {'Moe','Moe','Moe','Moe','Zara','Zara','Zara','Zara'};
seshno = [32,34,46,50,64,65,68,70];
sesh_folders = cellfun(@(x,y) fullfile(x,['Recording',num2str(y)]),anname,num2cell(seshno),'uniformoutput',false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% THIS PART IS CODE, NOT A PARAMETER %%%%
sesh_folders = cellfun(@(x) fullfile(datafolder,x),sesh_folders,'uniformoutput',false);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kin_folders = sesh_folders;

kin_folders{5} = fullfile( strcat(kin_folders{5},' Kinematics'),'Combined Handtrack' ); % Zara64
kin_folders{8} = fullfile( strcat(kin_folders{8},' Kinematics'), 'SortedByTime' ); % Zara70


block_names = { {'control'},... % Moe32
    {'control'},... % Moe34
    {'control','active','active','passive','active','passive','active','passive','active','passive'},... % Moe46
    {'control','active','passive','active','passive','active','passive','active','passive'},... % Moe50
    {'control','active','passive','active','passive','active','passive','active','passive'},... % Zara64
    {'passive'},... % Zara65
    {'control','active','passive','active','passive','active','passive','active','passive'},... % Zara68
    {'control','active','passive','active','passive','active','passive','active','passive'} }; % Zara70

%%
d2import = {{'behaviour','kinematics'},... % Moe32
    {'behaviour','kinematics'},... % Moe34
    {'behaviour','neural'},... % Moe46
    {'behaviour','neural'},... % Moe50
    'all',... % Zara64
    {'behaviour','kinematics'},... % Zara65
    'all',... % Zara68
    'all'}; % Zara70
invertfingerorder = false; % DO NOT SET TO TRUE

for session_ind = 1:numel(sesh_folders) % normally starts from 1, but you can change it in case of crashes / debugging
    sesh_folder = sesh_folders{session_ind};
    kin_folder  = kin_folders{session_ind};

    M = MirrorData();
    M.ImportData('SessionFolder',sesh_folder,'DataToImport',d2import{session_ind},...
        'Version','normal','TrialTypes',block_names{session_ind},...
        'AmplitudeThreshold',0,'MinSpikeCount',0,'KeepWaveForms',false,...
        'SNR',0,'DisqualifyPositive',false,'ShapeThreshold',0,'TargetChannels',[],...
        'preprocess',true,'kinematracks',true,'scaling',true,'ik',true,...
        'fdir',kin_folder,'invertfingerorder',invertfingerorder);
    
    % todo:
    % 1) x adjust the path for saving here
    % 2) x modify the blocking part of the behavioural script to only accept 1 block
    % 3) x see if you can't speed up the process of writing to a text file... writetrc is painfully slow, BUT you're also writing 100s of GB to a single file, and this could almost certainly be done more efficiently than you're currently trying to do it (perhaps some efficient low-level functions that you ain't usin') (fprintf, perhaps???) (unfortunately, it can't be binary...)
    save(fullfile('..','MirrorData',[anname{session_ind},num2str(seshno(session_ind)),'.mat']),'M','-v7.3')
    pause(1);
end

