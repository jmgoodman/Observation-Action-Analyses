function obj = ImportData(obj,varargin)

%IMPORTDATA imports all data (behavioural, kinematic, and neural)
%associated with a given session.
%
%DESCRIPTION
%   This routine calls all of ReadBehaviour, ReadKinematics, and ReadNeural,
%   using the same metadata for each to reliably bind this information and
%   allow for accurate population of the SessionMetadata field. As one may
%   reasonably want to change binning & alignment on the fly, that method
%   (BinData) remains an entirely separate method.
%
%SYNTAX
%   obj = ImportData(obj,varargin)
%
%   obj         ... MirrorData object (can be empty, instantiated with obj
%   = MirrorData();)
%   varargin    ... Inputs specified in name-value pairs that could include
%   the following:
%       'SessionFolder'         ... contains a path to a folder that contains
%       all associated data. Default is empty. If empty, a GUI helps direct
%       selection of the appropriate folder.
%       
%       'DataToImport'          ... String or cell array of strings indicating
%       which types of data to try to import. Default is 'all'. Useful if
%       you want to ignore kinematic data for a session in which kinematics
%       were not recorded (in which case, the input would be
%       {'behaviour','neural'}, omitting the 'kinematics' option).
%
%       'TrialTypes'            ... Cell array of the names of blocks, for use
%       when importing behavioural data.
%
%       'SNR'                   ... SNR threshold, for use when importing
%       neural data.
%
%       'MinSpikeCount'         ... Minimum spike count, for use when importing
%       neural data.
%
%       'AmplitudeThreshold'    ... Minimum peak-to-peak amplitude of a
%       mean waveform, to be used when importing neural data.
%
%       'DisqualifyPositive'    ... Whether or not to disqualify positive
%       waveforms, for use when importing neural data.
%
%       'ShapeThreshold'        ... How gamma-distributed versus
%       gaussian-distributed a unit's ISI distribution needs to be, for use
%       when importing neural data.
%
%       'TargetChannels'        ... Vector of channel names to target when
%       importing neural data
%
%       'KeepWaveForms'         ... logical value indicating whether or
%       not to keep waveform shapes. Default is 'false' to save memory (by
%       a factor of, like, 100, so it's totally worth it in 99% of cases).
%       When 'false', the "waveforms" field, which would normally be
%       populated by all the individual waveforms, is replaced by a 2x128
%       matrix where the first row is the mean waveform and the second is
%       the standard deviation at each sample time across waveforms.
%
%       'Version'                   ... string that reads "normal" or "autosort".
%       The latter is for when you want to work with pre-sorted neural data processed by Stefan. 
%       The former for when you want to use your own spike sorts.
%       
%       'preprocess'
%       'kinematracks'
%       'scaling'
%       'ik'                        ... four options that can take true/false inputs.
%       these are switches that determine what parts of the inverse kinematics pipeline to perform
%       (if kinematics are even processed at all).
%
%       'fnames'
%       'fdir'                      ... two options that take a cell array of file name strings
%       and a path string, respectively. by default, these are empty. These indicate
%       what file names to use for processed kinematics files (empty automatically names them)
%       and what directory contains your desired kinematics for processing (and also
%       where your kinematic processing outputs will be dumped), respectively.
%
%       TODO:
% 
%       VARIOUS OPTIONS RELATED TO SPIKE SORTER INTEGRATION, TO BE ADDED IN
%       THE FUTURE (UNTIL THIS IS ADDED, ONE MUST RUN A SEPARATE SPIKE
%       SORTER BEFORE CALLING IMPORTDATA!) (as of 04.03.2020, this is still
%       unsupported)
%
%       VARIOUS OPTIONS THAT ALLOW READBEHAVIOUR TO WORK DIFFERENTLY (as of
%       04.03.2020, this script locks the user into using settings that are
%       appropriate for Zara and Moe only, with the exception of allowing some
%       flexibility with the condition names)
%
%EXAMPLE
%   MyMirror =
%   ImportData(MyMirror,'DataToImport',{'behaviour','neural'})
%
%AUTHOR
%   Written for MirrorData by James Goodman, 2020 March 04, DPZ

%% step 1: parse the inputs

assert(mod(numel(varargin),2)==0,'Wrong number of inputs: must come in name-value pairs')

pNames = varargin(1:2:(end-1));
pVals  = varargin(2:2:end);

% establish default values
SessionFolder         = [];
DataToImport          = 'all'; %#ok<*NASGU>
which_types           = true(3,1);
TrialTypes            = [];
SNR_                  = 5;
MinSpikeCount         = 1000;
AmpThreshold          = 80;
DQpositive            = true;
ShapeThresh           = 1.1;
TargetChannels        = [];
kwf                   = false;
version_              = 'normal';
preprocess_           = false;
kinematracks_         = false;
scaling_              = false;
ik_                   = false;
fnames_               = [];
fdir_                 = [];
invertfingerorder_    = false;




regexps_types = {'^behav.*$','^neur.*$','^kinematic.*$'};


for name_ind = 1:numel(pNames)
    pName = pNames{name_ind};
    pVal  = pVals{name_ind};
    
    if strcmpi(pName,'SessionFolder')
        SessionFolder = pVal;
        
        % assert that the input is a string
        assert(ischar(SessionFolder) | isempty(SessionFolder),'SessionFolder must be a string specifying the full location of the folder containing your spike-sorted data files!')
        
    elseif strcmpi(pName,'DataToImport')
        DataToImport = pVal;
        
        % assert that the input is a string or cell array of strings
        if ischar(DataToImport)
            isvalid = strcmpi(DataToImport,'all') | ...
                any( cellfun( @(x) ~isempty( regexpi(DataToImport,x,'once') ),...
                regexps_types ) );
            
            if strcmpi(DataToImport,'all')
                which_types = true(3,1);
            else
                which_types = cellfun( @(x) ~isempty( regexpi(DataToImport,x,'once') ),...
                    regexps_types );
            end
            
        elseif iscellstr(DataToImport)
            which_types = false(3,1);
            for ind_ = 1:numel(DataToImport)
                this_str = DataToImport{ind_};
                current_type = cellfun( @(x) ~isempty( regexpi(this_str,x,'once') ),...
                    regexps_types );
                which_types  = which_types(:) | current_type(:);
            end
            
            isvalid = any(which_types);
        else
            isvalid = false;
        end
        
        assert(isvalid,'DataToImport must be a string reading ''all'', ''behavioural'', ''neural'', or ''kinematics'', OR a cell array containing any combination of the latter 3 strings')
        
    elseif strcmpi(pName,'TrialTypes')
        TrialTypes = pVal;
        
        if isstr(TrialTypes) %#ok<DISSTR> % was "isstring" but older versions of matlab wanna use this (or preferably "ischar") instead
            TrialTypes = {TrialTypes};
        end
        
        % assert that the input is a cell array of strings or empty
        assert(iscellstr(TrialTypes) | isempty(TrialTypes),...
            'TrialTypes input must be a cell array of strings specifying block names (or an empty array)!') %#ok<*ISCLSTR>
        
    elseif strcmpi(pName,'SNR')
        SNR_ = pVal;
        
        % assert that the input is a positive scalar
        assert(isscalar(SNR_),'SNR input must be a positive scalar specifying the SNR threshold!')
        assert(SNR_ >= 0,'SNR input must be a positive scalar specifying the SNR threshold!')
        
    elseif strcmpi(pName,'MinSpikeCount')
        MinSpikeCount = pVal;
        
        % assert that the input is a positive integer
        assert(isscalar(MinSpikeCount),'MinSpikeCount must be a positive scalar integer specifying the minimum number of spikes for a unit!')
        assert(mod(MinSpikeCount,1)==0,'MinSpikeCount must be a positive scalar integer specifying the minimum number of spikes for a unit!')
        assert(MinSpikeCount >= 0,'MinSpikeCount must be a nonnegative scalar integer specifying the minimum number of spikes for a unit!')
        
    elseif strcmpi(pName,'AmplitudeThreshold')
        AmpThreshold = pVal;
        
        % assert that the input is a positive scalar
        assert(isscalar(AmpThreshold),'AmplitudeThreshold input must be a positive scalar specifying the amplitude threshold!')
        assert(AmpThreshold >= 0,'AmplitudeThreshold input must be a positive scalar specifying the amplitude threshold!')
        
    elseif strcmpi(pName,'DisqualifyPositive')
        DQpositive = pVal;
        
        % if the input is a zero or a one, convert it to logical
        if isscalar(DQpositive)
            if DQpositive == 1
                DQpositive = true;
            elseif DQpositive == 0
                DQpositive = false;
            else
            end
        else
        end
        
        % assert that the input is logical
        assert(islogical(DQpositive),'DisqualifyPositive must be a logical (true/false) value that specifies whether or not to instantly disqualify waveforms whose positive deflections are their strongest!')
        
    elseif strcmpi(pName,'ShapeThreshold')
        ShapeThresh = pVal;
        
        % assert that the input is a positive scalar
        assert(isscalar(ShapeThresh),'ShapeThreshold input must be a positive scalar specifying the ratio of the likelihood ratio of a gamma:normal distribution to fit a unit''s ISI distribution!')
        assert(ShapeThresh >= 0,'ShapeThreshold input must be a positive scalar specifying the ratio of the likelihood ratio of a gamma:normal distribution to fit a unit''s ISI distribution!')
        
    elseif strcmpi(pName,'TargetChannels')
        TargetChannels = pVal;
        
        % assert that the input is an array of positive integer values
        assert(isnumeric(TargetChannels),'TargetChannels must be a vector of positive integers specifying channel names!')
        assert(all(TargetChannels > 0) && all(mod(TargetChannels,1)==0),'TargetChannels must be a vector of positive integers specifying channel names!')
    
    elseif strcmpi(pName,'KeepWaveForms')
        kwf = pVal;
        assert(islogical(kwf),'KeepWaveForms must be a logical (true/false) value that specifies whether or not to keep spike waveforms!')

    elseif strcmpi(pName,'Version')
        version_ = pVal;
        assert(ischar(version_),'Version must be a string that reads "normal" or "autosort"!')
        
    elseif ismember(lower(pName),{'preprocess','kinematracks','scaling','ik','invertfingerorder'})
        if pVal == 1
            pVal = true;
        elseif pVal == 0
            pVal = false;
        else
            % pass
        end
        assert(islogical(pVal),'inverse kinematics options need to be logical true/false values')
        eval( sprintf('%s_ = pVal;',lower(pName)) );
        
    elseif ismember(lower(pName),{'fnames','fdir'})
        assert(iscellstr(pVal) | ischar(pVal),'input must be a cell array of strings (fnames) or a string (fdir)')
        eval( sprintf('%s_ = pVal;',lower(pName)) );
        
    else
        warning('%s is not a valid input name. ignoring this name-value pair.',pName)
    end
end

%%
% first, if SessionFolder is empty, prompt the user to find the folder
if isempty(SessionFolder)
    disp('Find desired folder containing dataspikes / tsq files') % hack so that this offers SOME instruction on macs
    path_ = uigetdir([],'Find desired folder containing dataspikes / tsq files');
    
    if isnumeric(path_)
        error('No path selected, cannot continue')
    else
        SessionFolder = path_;
    end
else
end

%% this routine will... literally just call other routines
% starting with ReadBehaviour!
% regexps_types = {'^behav.*$','^neur.*$','^kinematic.*$'};

D = dir(fullfile(SessionFolder,'*.tsq')); % we will need this info later to extract metadata

% seek the location of the tsq file
if numel(D) == 1
    tsq_filename = fullfile(SessionFolder,D.name);
else
    warning('either no tsq or multiple tsq files are located in the folder specified. please specify the desired .tsq files via the GUI')
    disp('Find and select the target .tsq data stream file.')
    [file,path] = uigetfile(fullfile(SessionFolder,'*.tsq'),'Find and select the target .tsq data stream file.');
    tsq_filename = fullfile(path,file);
end

if which_types(1)
    % now, run ReadBehaviour
    obj = obj.ReadBehaviour('LoadFile',tsq_filename,'TrialTypes',TrialTypes,...
        'ShouldSave',false);
else
end

%% next, run neural data collection

if which_types(2)
    obj = obj.ReadNeural('LoadPath',SessionFolder,'SNR',SNR_,'MinSpikeCount',MinSpikeCount,...
        'AmplitudeThreshold',AmpThreshold,'DisqualifyPositive',DQpositive,...
        'ShapeThreshold',ShapeThresh,'ShouldSave',false,...
        'TargetChannels',TargetChannels,'KeepWaveForms',kwf,...
        'Version',version_);
else
end

%% next, kinematics

if which_types(3)
    % seek path where kinematic data live
    % old way: hard coded
    %     Dfilespath = 'E:\Dropbox\Mirror Local\Code\James Code\MirrorData Scripts\KinematicsProcessing';
    %     Dfilespath = '/Users/jgoodman/Dropbox/Mirror Local/Code/James Code/MirrorData Scripts/KinematicsProcessing';
    if isempty(fdir_)
        disp('Find desired folder containing kinematics files')
        path_ = uigetdir([],'Find desired folder containing kinematics files');
        
        if isnumeric(path_)
            error('No path selected, cannot continue')
        else
            fdir_ = path_;
        end
    else
        % pass
    end
    
    Dfilespath = fdir_;
    
    obj = obj.ReadKinematics('preprocess',preprocess_,'kinematracks',kinematracks_,...
        'scaling',scaling_,'ik',ik_,'fdir',fdir_,'fnames',fnames_,'invertfingerorder',invertfingerorder_);
    
    % here, we implement proper registration
    transtimes = obj.KinematicFileTransitionTimes.transitiontimes; % this field captures transition times breaking up the KINEMATIC files
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % honestly the code that populates this field probably needs to be updated
    % you see, it's only tested on Zara68
    % although Moe doesn't have many kinematic sessions, he has a *few*
    % and as it's currently written, it won't work because I assume I delineated "control" from "active" using the onset of "NaN" in the cue offset event, which is not how Moe's sessions do it.
    % WHATEVER, I HACKED A WORKAROUND IN: 27.08.2021
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    D     = dir(fullfile(Dfilespath,'DataFile*.mat'));
    
    for ii = 1:numel(D)
        fname = fullfile(Dfilespath,sprintf('DataFile%i.mat',ii)); % ensure that they're read in proper numeric order, and not the bookkeeping order that would put 1 and 10 together, for instance. We're imparting a lot of trust in the process here, though... i.e., no skipped indices or anything like that
        q = load(fname);
        timeslice = squeeze( q.recording(:,1,:) );
        time0 = timeslice(1,2); % for Zara's recordings, the first row of kinematics always had the time index repeated everywhere along this slice. For Moe, the "true" time is only included in the second column (the first seems to be "block" time, the second seems to be "true" time, and indeed, the internal KinemaTracks routines seem to pick out this second column to act as the "time" coordinates, as evidenced by the .osim files using times equal to or very close to this value!!!)
        
        % why do we need to do it this way? because the IK routine implicitly interpolates & shaves off the first few samples... ergo, the first time index in the IK files does NOT correspond exactly with the first time index of the KinemaTracks output!!! But the raw data file DOES have this info. (Note: NOT registering w.r.t. the raw data file results in an alignment error on the order of 20ms)
        obj.Kinematic(ii).JointStruct.data(:,1) = ...
            1000 * ( obj.Kinematic(ii).JointStruct.data(:,1) - ...
            time0 ) + transtimes(ii);
        
        obj.Kinematic(ii).MarkerStruct.data(:,2) = ...
            1000 * ( obj.Kinematic(ii).MarkerStruct.data(:,2) - ...
            time0 ) + transtimes(ii);
    end
    
    %% now, interpolate
    for ii = 1:numel(D)
        % cut out the nan values, first
        obj.Kinematic(ii).JointStruct.data = ...
            obj.Kinematic(ii).JointStruct.data(...
            ~any(isnan(obj.Kinematic(ii).JointStruct.data),2),:);
        obj.Kinematic(ii).MarkerStruct.data = ...
            obj.Kinematic(ii).MarkerStruct.data(...
            ~any(isnan(obj.Kinematic(ii).MarkerStruct.data),2),:);
        
        % establish tvals and new-tvals
        tvalsj = obj.Kinematic(ii).JointStruct.data(:,1);
        tvalsm = obj.Kinematic(ii).MarkerStruct.data(:,2);
        newtvals = min([tvalsj(:);tvalsm(:)]):10:max([tvalsj(:);tvalsm(:)]);
        
        obj.Kinematic(ii).JointStruct.data = ...
            interp1(tvalsj(:),obj.Kinematic(ii).JointStruct.data,...
            newtvals(:));
        obj.Kinematic(ii).MarkerStruct.data = ...
            interp1(tvalsm(:),obj.Kinematic(ii).MarkerStruct.data,...
            newtvals(:));
    end
    
else
end


%% now, the metadata
% note: this relies heavily on the file structure of Zara's recordings
% any new animals with slightly different file structures may well require
% a change here to correctly extract metadata
% the folder name should give this information
% get the last folder name
fsep = filesep;

% grab the session number
seplocs = regexpi(SessionFolder,fsep);

if seplocs(end) == numel(SessionFolder) % remove trailing file separators
    lastind = numel(SessionFolder) - 1;
    seplocs(end) = [];
else
    lastind = numel(SessionFolder);
end

SessionName = SessionFolder( (seplocs(end)+1):lastind );
SessionNo   = regexpi(SessionName,'[0-9]+','match');

% go back one folder to get the animal name
AnimalName   = SessionFolder( (seplocs(end-1)+1):(seplocs(end)-1) );
AnimalString = regexpi(AnimalName,'[a-zA-Z]+','match'); % trim any unwanted spaces, underscores, or remaining file separators

% now grab creation date of the tsq via system commands
systemfile  = tsq_filename;
sans_spaces = regexpi(systemfile,'\s','split');

% add spaces at the end of all but the very last one
sans_spaces(1:(end-1)) = cellfun(@(x) [x,'\ '],sans_spaces(1:(end-1)),'uniformoutput',false);
systemfile_corrected   = horzcat(sans_spaces{:});

[a,b]=system(sprintf('GetFileInfo %s',systemfile_corrected)); s=strfind(b,'created: ')+9; crdat=b(s:s+18);
% note that crdat is given in the American format. Month-Date-Year.

tempstruct.AnimalName           = AnimalString{1};
tempstruct.SessionNumber        = str2double(SessionNo{1});
tempstruct.RecordingDateAndTime = crdat;
tempstruct.RecordingSystem      = 'TDT'; % the base assumption for now is that you're using a TDT system. You'll need to throw in some sleuthing code if you ever incorporate Blackrock data into this pipeline.

obj.SessionMetadata = tempstruct;

% use this to populate the Array field & the array names in the NeuralData
% field.
AO = arrayobj();
AO = AO.loadarray(lower(obj.SessionMetadata.AnimalName));
obj.Array = AO;

array_names    = AO.name;
array_channels = AO.channelmap;

if ~isempty(obj.Neural)
    for ii = 1:numel(obj.Neural)
        for jj = 1:numel(array_names)
            if ismember(obj.Neural(ii).channelID,array_channels{jj}(:))
                obj.Neural(ii).array = array_names{jj};
                continue
            else
            end
        end
    end
end



end