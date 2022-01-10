%% Script 1: Creating MirrorData Structs
% step 0: cleanup
restoredefaultpath

clearvars
clc
close all

% hard-coded path
% path2add = '/Users/jgoodman/Dropbox/Mirror Local/Code/James Code/MirrorData Scripts/';

% flexible path:
mfn = mfilename('fullpath');
fs  = filesep;

fslocs = regexpi(mfn,fs);
levels_3up = mfn(1:fslocs(end-4)); % one additional subfolder relative to old path
levels_1up = mfn(1:fslocs(end-2));

path2add = fullfile(levels_1up,'MirrorData Scripts');

addpath(genpath(path2add))

%% step 1: define parameters for ImportData
% update this to include ALL session folders that you want to analyze:

% hard-coded paths
% sesh_folders = {'/Users/jgoodman/Dropbox/Mirror Local/Zara/Recording64/',...
%     '/Users/jgoodman/Dropbox/Mirror Local/Zara/Recording68'};

% ZARA
% more flexible paths
% sesh_folders = {fullfile('Zara','Recording64'),fullfile('Zara','Recording68')};

% MOE
% Moe session 46 & 48 seem to be labeled as "good recordings"
% only session 46 has .sev files though
% session 48 only has the event files! which might mean I have to use a different spike sorter! or ask Ben about a setting for his spike sorter that uses the event files!
% okay but for now let's just work with Moe 46
sesh_folders = {fullfile('Moe','Recording46')};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% THIS PART IS CODE, NOT A PARAMETER %%%%
sesh_folders = cellfun(@(x) fullfile(levels_3up,x),sesh_folders,'uniformoutput',false);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% update this to include the block naming across all folders listed in
% sesh_folders:

% % for Zara:
% block_names = { {'control','active','passive','active','passive','active',...
%     'passive','active','passive'}, ...
%     {'control','active','passive','active','passive','active','passive',...
%     'active','passive'} };

% for Moe:
block_names = {{'control','active','active','passive','active','passive',...
    'active','passive','active','passive'}}; % basing the order (active-passive) on the notes Stefan wrote. In checking the trial start times, one can infer when the blocks begin & end. There does seem to be one "false" block transition before a full ~72 trials have completed (12 trials/object/block, per Stefan's notes); this seems to have been the first "active" block, hence the repetition of "active" the first time it pops up.

% update this chunk of code to specify more parameters that change on a
% session-to-session basis

%% step 2: define a storage folder for these guys

% update this to point to where you would like the MirrorData objects to be
% stored

% hard-coded path
% folder2save = '/Users/jgoodman/Dropbox/Mirror Local/MirrorData Objects/';

% more flexible path:
folder2save = fullfile(levels_3up,'MirrorData Objects');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% the following code is NOT a parameter to be set! do not touch!
% (except to change from "isdir" to "isfolder" for newer matlabs that support it, provided isdir causes problems)
if ~isdir(folder2save)
    mkdir(folder2save);
else
    % pass
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
%% step 3: now we run the actual code
for session_ind = 1:numel(sesh_folders)
    sesh_folder = sesh_folders{session_ind};
    block_name  = block_names{session_ind};
    
    % grab the session number
    fsep    = filesep;
    seplocs = regexpi(sesh_folder,fsep);
    
    if seplocs(end) == numel(sesh_folder) % remove trailing file separators
        lastind = numel(sesh_folder) - 1;
        seplocs(end) = [];
    else
        lastind = numel(sesh_folder);
    end
    
    SessionName = sesh_folder( (seplocs(end)+1):lastind );
    SessionNo   = regexpi(SessionName,'[0-9]+','match');
    
    % go back one folder to get the animal name
    AnimalName   = sesh_folder( (seplocs(end-1)+1):(seplocs(end)-1) );
    AnimalString = regexpi(AnimalName,'[a-zA-Z]+','match'); % trim any unwanted spaces, underscores, or remaining file separators
    
    
    % specify the file name in the folder you defined earlier
    fname = [AnimalString{1},...
        SessionNo{1},'.mat'];
    
    fname_full = fullfile(folder2save,fname);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % check if this session has already been processed
    filecreate_flag = true;
    
    if exist(fname_full,'file') == 2
        h = warndlg('File already created for this session. Observe the command window for further instruction');
        
        waitfor(h)
        
        isok_input = false;
        overwrite_flag = false;
        while ~isok_input
            yn = input('File already created for this session. Okay to overwrite? (y/N): ','s');
            
            if isempty(yn) || ~isempty(regexpi(yn,'^no?$','once'))
                isok_input     = true;
            elseif ~isempty(regexpi(yn,'^y(es)?$','once'))
                isok_input     = true;
                overwrite_flag = true;
            else
                warning('Invalid input. Try another!')
            end
        end
        
        if ~overwrite_flag
            isok_input  = false;
            rename_flag = false;
            while ~isok_input
                yn = input('Care to specify an alternative file name? (y/N): ','s');
                
                if isempty(yn) || ~isempty(regexpi(yn,'^no?$','once'))
                    isok_input  = true;
                elseif ~isempty(regexpi(yn,'^y(es)?$','once'))
                    isok_input  = true;
                    rename_flag = true;
                else
                    warning('Invalid input. Try another!')
                end
            end
            
            if rename_flag
                f2s = folder2save;
                
                % oh, hehe. coulda just used "filesep" here. ah well.
                if ispc
                    if ~strcmpi(f2s(end),'\')
                        f2s = [f2s,'\'];
                    else
                        % pass
                    end
                    
                else
                    if ~strcmpi(f2s(end),'/')
                        f2s = [f2s,'/'];
                    else
                        % pass
                    end
                end
                
                fn = input(sprintf('Specify file name here: %s',f2s),'s');
                
                % check to see if they remembered to add .mat to the end
                if ~strcmpi(fn((end-3):end),'.mat')
                    fn = [fn,'.mat']; %#ok<*AGROW>
                else
                    % pass
                end
                
                fname_full = fullfile(f2s,fn);
            else
                warning('NOT creating file %s',fname_full)
                filecreate_flag = false;
            end
            
        else
            % pass
        end
        
    else
        % pass
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % if you decided not to overwrite AND not to rename, then just skip to
    % the next loop iteration
    if ~filecreate_flag
        continue
    else
        % pass
    end
    
    % NOW we can start importing data!
    M = MirrorData();
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % the key line of code!
    % look up the documentation for this (run the first cell then type "doc
    % MirrorData.ImportData") and use that info to customize this code to your needs.
    
                                             % update this option when
                                             % kinematic processing goes
                                             % online!
                                             % |
                                             % |
                                             % v
    M.ImportData('SessionFolder',sesh_folder,'DataToImport',{'neural','behavioral'},...
        'TrialTypes',block_name,'AmplitudeThreshold',0,'MinSpikeCount',0,'KeepWaveForms',false,...
        'SNR',0,'DisqualifyPositive',false,'ShapeThreshold',0,'TargetChannels',[]);
                                                    %            ^
                                                    %            |
                                                    %            |
                                                    % this option having an 
                                                    % empty array input is 
                                                    % intentional. Empty array,
                                                    % ironically enough, means 
                                                    % "grab ALL units".                                                
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
    % now create the file!
    save(fname_full,'M','-v7.3')
    
    % cleanup
    clear M
    pause(0.1)
end