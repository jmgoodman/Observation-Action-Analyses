% CreateMirrorData_Moe
% ughhhh i gotta spike sort shit
% oh well let's import the behavior at least
restoredefaultpath

clearvars
clc
% close all

%% setup
restoredefaultpath
addpath(genpath('../Analysis-Scripts'))
analysis_setup

% datafolder = 'E:\Dropbox\Mirror Local';
datafolder = '/Users/jgoodman/Dropbox/Mirror Local';

%%
% Moe sessions

anname = 'Moe';
seshno = [32,34];
% sesh_folders = {fullfile(anname,['Recording',num2str(seshno)])};
sesh_folders = cellfun(@(x) fullfile(anname,['Recording',num2str(x)]),num2cell(seshno),'uniformoutput',false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% THIS PART IS CODE, NOT A PARAMETER %%%%
sesh_folders = cellfun(@(x) fullfile(datafolder,x),sesh_folders,'uniformoutput',false);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kin_folders = sesh_folders;

block_names = {{'control'},{'control'}}; % these are "regular" sessions, so all of the blocks are MGG.
 
%%
d2import = {'behaviour','kinematics'};

d2import = {'kinematics'}; % when simply replacing the kinematics field of a session...

% just try one of these sessions for now...
for session_ind = 2%1:numel(sesh_folders)
    sesh_folder = sesh_folders{session_ind};
    kin_folder  = kin_folders{session_ind};

    M = MirrorData();
    M.ImportData('SessionFolder',sesh_folder,'DataToImport',d2import,...
        'Version','normal','TrialTypes',block_names{session_ind},...
        'AmplitudeThreshold',0,'MinSpikeCount',0,'KeepWaveForms',false,...
        'SNR',0,'DisqualifyPositive',false,'ShapeThreshold',0,'TargetChannels',[],...
        'preprocess',true,'kinematracks',true,'scaling',true,'ik',true,...
        'fdir',kin_folder); % 'autosort' is always miserable. don't use it. use 'normal' instead.
    % also make sure to set all these waveform-vetting parameters to 0, otherwise you'll end up with WAY fewer units than you should since the default parameters are VERY restrictive
    
    %     D = dir(fullfile(sesh_folder,'*_presorted.mat'));
    %     fname = fullfile(sesh_folder,D(1).name);
    %     M.ImportData('SessionFolder',fname,'DataToImport',{'behavioural','neural'},'Version','autosort');
    
    % todo:
    % 1) x adjust the path for saving here
    % 2) x modify the blocking part of the behavioural script to only accept 1 block
    % 3) x see if you can't speed up the process of writing to a text file... writetrc is painfully slow, BUT you're also writing 100s of GB to a single file, and this could almost certainly be done more efficiently than you're currently trying to do it (perhaps some efficient low-level functions that you ain't usin') (fprintf, perhaps???) (unfortunately, it can't be binary...)
    save(fullfile('..','MirrorData',[anname,num2str(seshno(session_ind)),'_JUSTKinematics','.mat']),'M','-v7.3')
    pause(1);
end

