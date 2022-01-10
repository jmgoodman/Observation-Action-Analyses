% CreateMirrorData_Moe
% ughhhh i gotta spike sort shit
% oh well let's import the behavior at least
restoredefaultpath

clearvars
clc
% close all

mfn = mfilename('fullpath');
fs  = filesep;

fslocs = regexpi(mfn,fs);
levels_3up = mfn(1:fslocs(end-4)); % one extra subfolder relative to old path
levels_1up = mfn(1:fslocs(end-2));

path2add = fullfile(levels_1up,'MirrorData Scripts');

addpath(genpath(path2add))

%%

% Moe experiments
% sesh_folders = {fullfile('Moe','Recording46'),fullfile('Moe','Recording48')};
% sesh_folders = {fullfile('Moe','Recording46')};
anname = 'Zara';
seshno = [64,68,70];
% sesh_folders = {fullfile(anname,['Recording',num2str(seshno)])};
sesh_folders = cellfun(@(x) fullfile(anname,['Recording',num2str(x)]),num2cell(seshno),'uniformoutput',false);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% THIS PART IS CODE, NOT A PARAMETER %%%%
sesh_folders = cellfun(@(x) fullfile(levels_3up,x),sesh_folders,'uniformoutput',false);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kin_folders = sesh_folders;
kin_folders{1} = fullfile( strcat(kin_folders{1},' Kinematics'),'Combined Handtrack' );
kin_folders{2} = kin_folders{2};
kin_folders{3} = fullfile( strcat(kin_folders{3},' Kinematics'),'SortedByTime' );


% % for Zara:
% block_names = { {'control','active','passive','active','passive','active',...
%     'passive','active','passive'}, ...
%     {'control','active','passive','active','passive','active','passive',...
%     'active','passive'} };

% for Moe46:
% block_names = {{'control','active','active','passive','active','passive',...
%     'active','passive','active','passive'}}; % basing the order (active-passive) on the notes Stefan wrote. In checking the trial start times, one can infer when the blocks begin & end. There does seem to be one "false" block transition before a full ~72 trials have completed (12 trials/object/block, per Stefan's notes); this seems to have been the first "active" block, hence the repetition of "active" the first time it pops up.

% for Moe50 (and indeed, under normal conditions):
block_names = {'control','active','passive','active','passive',...
    'active','passive','active','passive'}; % no duplication needed here. there was no big long pause in any of the blocks of THIS session.

%%
d2import = 'all'; % {'behavioral','neural'} % which kinds of data to import. switch to {'behavioural','neural'} when no kinematic data are available.

% just try one of these sessions for now...
for session_ind = 3%1:numel(sesh_folders)
    sesh_folder = sesh_folders{session_ind};
    kin_folder  = kin_folders{session_ind};

    M = MirrorData();
    M.ImportData('SessionFolder',sesh_folder,'DataToImport',d2import,...
        'Version','normal','TrialTypes',block_names,...
        'AmplitudeThreshold',0,'MinSpikeCount',0,'KeepWaveForms',false,...
        'SNR',0,'DisqualifyPositive',false,'ShapeThreshold',0,'TargetChannels',[],...
        'preprocess',true,'kinematracks',true,'scaling',true,'ik',true,...
        'fdir',kin_folder); % 'autosort' is always miserable. don't use it. use 'normal' instead.
    % also make sure to set all these waveform-vetting parameters to 0, otherwise you'll end up with WAY fewer units than you should since the default parameters are VERY restrictive
    
    %     D = dir(fullfile(sesh_folder,'*_presorted.mat'));
    %     fname = fullfile(sesh_folder,D(1).name);
    %     M.ImportData('SessionFolder',fname,'DataToImport',{'behavioural','neural'},'Version','autosort');
    
    save(fullfile(levels_3up,'MirrorData Objects',[anname,num2str(seshno(session_ind)),'_withKinematics','.mat']),'M','-v7.3')
    pause(1);
end

