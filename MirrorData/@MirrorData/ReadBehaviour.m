function obj = ReadBehaviour(obj,varargin)

%READBEHAVIOUR Imports and parses data from raw .tsq files
%
%DESCRIPTION
%   This routine imports the binary data in a .tsq file associated with a
%   session, parses it, and places intelligible data into the Object, TrialType, and
%   Event fields of MirrorData. This method is planned to be hidden, to be
%   called by the ImportData method, which will handle the import of kinematic,
%   neural, and event data in one fell swoop (and permits the use of inputs
%   to load only a subset of those, if desired).
%
%SYNTAX
%   obj = ReadBehaviour(obj,varargin)
%
%   obj         ... MirrorData object
%   varargin    ... Inputs specified in name-value pairs that could include
%   the following:
%       'LoadFile'                  ... Full path of file being loaded. Default value is an
%       empty array. If empty, a user interface guides file selection.
%       'SaveFile'                  ... Full path of file being saved. Default value is an
%       empty array. If empty, a user interface guides file selection. Saved file contains the
%       updated MirrorData object.
%       'TrialTypes'                ... Cell array of the names of blocks. Default
%       value is an empty array, which results in the TrialType array being
%       populated by block indices (this script automatically seeks blocked
%       structure regardless of whether the user specifies the names of the
%       blocked conditions). If there are fewer elements in TrialTypes than
%       there are discovered blocks, a warning is issued and the first X
%       blocks receive all X names present in TrialTypes, with the
%       following blocks receiving numeric indices starting from X+1. If
%       there are more elements in TrialTypes than there are discovered
%       blocks, a warning is issued and the first X elements of TrialTypes
%       are assigned to the X discovered blocks, with the remaining
%       elements of TrialTypes being unused.
%       'Setup' or 'Specification'  ... String that specifies the name of the setup.
%       Default is 'Setup1a'. For use with Stefan's getgripname.m as the
%       'specification' field.
%       'ObjectName'                ... String that specifies the variable
%       name given to the updated MirrorData object when saving it to file.
%       Default is 'MirrorObj'.
%       'ShouldSave'                ... Logical value that determines
%       whether or not to attempt to save an updated version of the struct
%       to file. Default is true.
%
%EXAMPLE
%   MyMirror =
%   ReadBehaviour(MyMirror,'LoadFile','MyMirror.tsq','SaveFile','MyMirror.mat');
%
%AUTHOR
%   by Andrej Fillipow
%   adapted for MirrorData by James Goodman, 2019 December 31, DPZ
%   functions to extract behavioural data for both Zara 64 and Zara 68
%   still need to test on Moe's data, however (as of 05.02.2020)

%% step 1: parse the inputs
assert(mod(numel(varargin),2)==0,'Wrong number of inputs: must come in name-value pairs')

pNames = varargin(1:2:(end-1));
pVals  = varargin(2:2:end);

LoadFile = [];
SaveFile = [];
trial_type_names = [];
Setup_name = 'Setup1a';
Obj_name   = 'MirrorObj';
ShouldSave = false;

for name_ind = 1:numel(pNames)
    pName = pNames{name_ind};
    pVal  = pVals{name_ind};
    if strcmpi(pName,'LoadFile')
        LoadFile = pVal;
        
        % assert that the input is a string
        assert(ischar(LoadFile) | isempty(LoadFile),'LoadFile input must be a string specifying a full file path (or an empty array)!')
        
        % check for an extension
        if ~isempty(LoadFile)
            has_extension = ~isempty(regexpi(LoadFile,'\.{1}[^\.]+$','once'));
            
            if ~has_extension
                % if the file name lacks an extension, append it
                LoadFile = [LoadFile,'.tsq']; %#ok<*AGROW>
            else
                % if the file name has an extension, assert that it is, indeed, a tsq file
                assert(~isempty(regexpi(pVal,'\.tsq$','once')),'LoadFile must specify a .tsq file!')
            end
        else
        end
        
    elseif strcmpi(pName,'SaveFile')
        SaveFile = pVal;
        
        % assert that the input is a string or empty
        assert(ischar(SaveFile) | isempty(SaveFile),'SaveFile input must be a string specifying a full file path (or an empty array)!')
        
        % check for an extension
        if ~isempty(SaveFile)
            has_extension = ~isempty(regexpi(LoadFile,'\.{1}[^\.]+$','once'));
            
            if ~has_extension
                % if the file name lacks an extension, append it
                SaveFile = [SaveFile,'.mat']; %#ok<*AGROW>
            else
                % if the file name has an extension, assert that it is, indeed, a mat file
                assert(~isempty(regexpi(pVal,'\.mat$','once')),'SaveFile must specify a .mat file!')
            end
        else
        end
        
    elseif strcmpi(pName,'TrialTypes')
        trial_type_names = pVal;
        
        % assert that the input is a cell array of strings or empty
        assert(iscellstr(trial_type_names) | isempty(trial_type_names),...
            'TrialTypes input must be a cell array of strings specifying block names (or an empty array)!')
        
    elseif strcmpi(pName,'setup') || strcmpi(pName,'specification')
        Setup_name = pVal;
        
        % assert that the input is a string
        assert(ischar(Setup_name),'Setup or Specification must be a string specifying the name of the experimental setup! If in doubt, just omit this input or use ''Setup1a''!')
        
    elseif strcmpi(pName,'ObjectName')
        Obj_name = pVal;
        
        % assert that input is a string and valid MATLAB variable name
        assert(isvarname(Obj_name),'ObjectName must be a string specifying a valid MATLAB variable name!')
    
    elseif strcmpi(pName,'ShouldSave')
        ShouldSave = pVal;
        
        % if the input is a zero or a one, convert it to logical
        if isscalar(ShouldSave)
            if ShouldSave == 1
                ShouldSave = true;
            elseif ShouldSave == 0
                ShouldSave = false;
            else
            end
        else
        end
        
        % assert that the input is logical
        assert(islogical(ShouldSave),'ShouldSave must be a logical (true/false) value that specifies whether or not to attempt to save the updated MirrorData object to file!')
        
    else
        warning('%s is not a valid input name. ignoring this name-value pair.',pName)
    end
end

%% step 2: specify the target file
if ~isempty(LoadFile)
else
    [file,path] = uigetfile('*.tsq','Find and select the target .tsq data stream file. It should be in a folder with the name of a monkey and the number of a session (e.g., Zara68/).');
    if isnumeric(file) || isnumeric(path) || islogical(file) || islogical(path) % i.e., if "cancel" is pressed
        error('No file selected, cannot continue')
    else
        LoadFile = fullfile(path,file);
    end
end

%% step 3: load & begin parsing the target file

% instantiate a waiting dialog
disp('Loading data: please be patient, this could take a couple minutes')
try
    tsq = fopen(LoadFile); fseek(tsq,0,'eof'); ntsq = ftell(tsq)/40; fseek(tsq,0,'bof');
    
    % read from tsq
    data = struct;
    data.size      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  4, 'bof');
    data.type      = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq,  8, 'bof');
    data.name      = fread(tsq, [ntsq 1], 'uint32', 36); fseek(tsq, 12, 'bof');
    data.chan      = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 14, 'bof');
    data.sortcode  = fread(tsq, [ntsq 1], 'ushort', 38); fseek(tsq, 16, 'bof');
    data.timestamp = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 24, 'bof');
    data.fp_loc    = fread(tsq, [ntsq 1], 'int64',  32); fseek(tsq, 24, 'bof');
    data.strobe    = fread(tsq, [ntsq 1], 'double', 32); fseek(tsq, 32, 'bof');
    data.format    = fread(tsq, [ntsq 1], 'int32',  36); fseek(tsq, 36, 'bof');
    data.frequency = fread(tsq, [ntsq 1], 'float',  36);
    
    % change the unit of timestamps from sec to millisec
    data.timestamp(3:end-1) = (data.timestamp(3:end-1) - data.timestamp(2)) * 1000;
    
    %     % testing for possible names, not needed per se but kept as a comment to help
    %     % debugging should the need arise
    %     possibleNames = unique(data.name);
    %     translatedNames = char(zeros(numel(possibleNames),4));
    %     for j = 1:numel(possibleNames)
    %         for i = 0:3
    %             translatedNames(j,i+1) = char(sum(power(2,find(bitget(possibleNames(j),(1:8)+i*8))-1)));
    %
    %         end
    %     end
    %     disp(translatedNames);
    
catch err
    fclose(tsq); % the whole reason for the try statement: in case of errors, close the file so bad, weird things don't happen.
    rethrow(err)
end

fclose(tsq); % always close files you open!
disp('Data successfully extracted')

%% step 4: parse out the bits of data that you care about

labvcode = sum(256.^(0:3).*double('Labv'));

handcode = sum(256.^(0:3).*double('Hand')); % doesn't seem to work for Moe. As in, he *has* no "Hand" field. No other fields in the data stream contain block information. I think I recall that the turntable indices differentiate between active & passive here, so maybe rely on those for Moe. At the very least, his data don't have a "Hand" field in the data stream, period. So there's nothing to confound you here.
% I think I just have to rely on the fact that he probably 

tickcode = sum(256.^(0:3).*double('Stim')); % testing for Moe

emg_code = sum(256.^(0:3).*double('EMG_')); % testing for Zara70

% % MOE FIELD NAMES:
% unamevals = unique(data.name);
% 
% unamebybyte = zeros(numel(unamevals),4);
% 
% for ii = 1:numel(unamevals)
%     unv = unamevals(ii);
%     for jj = 1:4 % 4 bytes
%         thisbyte = mod(unv,256);
%         unamebybyte(ii,jj) = thisbyte;
%         unv = (unv - thisbyte)./256;
%     end
% end
% 
% unames_bychar = char(unamebybyte);

labvindices = data.name == labvcode;
handindices = data.name == handcode;
tickindices = data.name == tickcode;
emg_indices = data.name == emg_code;

subdata = struct;
subdata.size = data.size(labvindices);
subdata.fp_loc = data.fp_loc(labvindices);
subdata.strobe = data.strobe(labvindices);
subdata.type = data.type(labvindices);
subdata.name = data.name(labvindices);
subdata.timestamp = data.timestamp(labvindices);

% also pull from the field "hand", this contains block information (as
% notes toward the bottom indicate)
% note: these indicate nothing about kinematics.
handdata = struct;
handdata.size = data.size(handindices);
handdata.fp_loc = data.fp_loc(handindices);
handdata.strobe = data.strobe(handindices);
handdata.type = data.type(handindices);
handdata.name = data.name(handindices);
handdata.timestamp = data.timestamp(handindices);


% also pull from the field "tick"
tickdata = struct;
tickdata.size = data.size(tickindices);
tickdata.fp_loc = data.fp_loc(tickindices);
tickdata.strobe = data.strobe(tickindices);
tickdata.type = data.type(tickindices);
tickdata.name = data.name(tickindices);
tickdata.timestamp = data.timestamp(tickindices);


% and from the field "EMG_"
emg_data = struct;
emg_data.size = data.size(emg_indices);
emg_data.fp_loc = data.fp_loc(emg_indices);
emg_data.strobe = data.strobe(emg_indices);
emg_data.type = data.type(emg_indices);
emg_data.name = data.name(emg_indices);
emg_data.timestamp = data.timestamp(emg_indices);


startData = find(subdata.strobe == 253);
startIndices = find(subdata.strobe == 255);
trialCorrect = strfind(subdata.strobe', double('Trial correct	1'))';
gripIndices = strfind(subdata.strobe', double('Grip Type'))';
endIndices = find(subdata.strobe == 254);

% make sure that each header start is followed by a success,
% a grip, then an end
% also start on an end to make sure the epoch data is complete
allIndices = [endIndices; startData; startIndices; trialCorrect; gripIndices; endIndices-0.5];
allValues = [zeros(size(endIndices)); ...
    ones(size(startData));...
    2*ones(size(startIndices));...
    3*ones(size(trialCorrect));...
    4*ones(size(gripIndices));...
    5*ones(size(endIndices))];
[sortedIndices, sortingIndex] = sort(allIndices,'ascend');
sortedIndices = ceil(sortedIndices);
sortedValues = allValues(sortingIndex);
completeTrialIndices = strfind(sortedValues', [0 1 2 3 4 5])'; %% all char(254)
completeTrialIndices = sort([completeTrialIndices; completeTrialIndices+1; completeTrialIndices+2; completeTrialIndices+3; completeTrialIndices+4; completeTrialIndices+5]);
completeTrialIndices = sortedIndices(completeTrialIndices);
% cue is 5 go is 8, hold is 9
% object interaction events: 31 34 36 38 43
% handrest L / R open 40 42
numtimestamps = numel(completeTrialIndices)/6;

% initialize as nan arrays, that way it's obvious when something goes wrong
trial_start_time = nan(numtimestamps,1);
cue_onset_time   = nan(numtimestamps,1);
cue_remove_time  = nan(numtimestamps,1);

fixation_time    = nan(numtimestamps,1);

reaction_phase_time = nan(numtimestamps,1);
go_phase_time       = nan(numtimestamps,1);
movement_onset_time = nan(numtimestamps,1);
hold_time           = nan(numtimestamps,1);

post_hold_time = nan(numtimestamps,1);
trial_end_time = nan(numtimestamps,1);
object_kind    = nan(numtimestamps,1);

for i = 1:numtimestamps
    start_index = completeTrialIndices((i-1)*6+1); % (post-hoc interpretation: the DATA comes BETWEEN headers; therefore you want to look between "end" and "start")
    end_index = completeTrialIndices((i-1)*6+3);
    
    % get trial start, cue onset and cue extinguish
    tsindex = find(subdata.strobe(start_index:end_index) == 0);
    trial_start_time(i) = subdata.timestamp(start_index+tsindex-1);
    
    cueonindex = find(subdata.strobe(start_index:end_index) == 5);
    cue_onset_time(i) = subdata.timestamp(start_index+cueonindex-1);
    try % sometimes, these data aren't present.
        cueoffindex = find(subdata.strobe(start_index:end_index) == 6);
        cue_remove_time(i) = subdata.timestamp(start_index+cueoffindex-1);
    catch
        if ~isempty(cueoffindex) % for debugging purposes: if there's multiple entries, that's a funny case that needs to be resolved, not swept under the rug!
            warning('add a breakpoint to line 292 please!')
        end
        cue_remove_time(i) = nan; % i prefer this way of handling it. that way you know when something went wrong.
    end
    
    % also fixation start
    fixindex         = find(subdata.strobe(start_index:end_index) == 4);
    fixation_time(i) = subdata.timestamp(start_index + fixindex - 1);
    
    % reaction, go and hold
    try % again, this sometimes isn't present
        reactionindex = find(subdata.strobe(start_index:end_index) == 7); % what is "reaction" phase and how does it differ from the onset of "memory" phase (and thus, the offset of the cue)?
        reaction_phase_time(i) = subdata.timestamp(start_index+reactionindex-1); % it's not the introduction of the "go" cue, because that comes later (albeit only SLIGHTLY later in this paradigm. an average of 10ms worth of time difference). Could it be the earliest possible time at which a go cue COULD have been introduced? Could it have something to do with when the monkey establishes fixation? Is it simply a machine command that mere mortals don't care about (i.e., machine initiates "go" cue presentation, but requires 10ms to deliver it to the monkey, and this field helps track that delay?) v. peculiar.
    catch
        if ~isempty(reactionindex) % for debugging purposes: if there's multiple entries, that's a funny case that needs to be resolved, not swept under the rug!
            warning('add a breakpoint to line 303 please!')
        end
        reaction_phase_time(i) = nan;
    end
    
    goindex = find(subdata.strobe(start_index:end_index) == 8); % "go" phase indeed starts BEFORE start of movement, which is good. I assume this is the onset of the "go" cue, as opposed to "cue", which is where the object identity is signaled. 
    go_phase_time(i) = subdata.timestamp(start_index+goindex-1); 
    
    holdindex = find(subdata.strobe(start_index:end_index) == 9);
    hold_time(i) = subdata.timestamp(start_index+holdindex-1); % I have to imagine the onset of "hold" corresponds with the point at which the object is "lifted" off its pedastal (thereby triggering a light barrier). But what about object *contact*?
    
    % move onset, defined as the final hand rest off event before hold event
    moveindex = find(subdata.strobe(start_index:(start_index+holdindex-1)) == 40 |...
        subdata.strobe(start_index:(start_index+holdindex-1)) == 42); % lifting arm off handrest: a simple digital switch trigger, not a state code
    try
        movement_onset_time(i) = subdata.timestamp(start_index+moveindex(end)-1);
    catch err
        movement_onset_time(i) = nan;
    end
    
    postholdindex = find(subdata.strobe(start_index:end_index) == 10); % note: "post hold" just means "reward". 
    post_hold_time(i) = subdata.timestamp(start_index+postholdindex-1);
    
    trialendindex = find(subdata.strobe(start_index:end_index) == 13);
    trial_end_time(i) = subdata.timestamp(start_index+trialendindex-1);
    
    grip = char(subdata.strobe(completeTrialIndices((i-1)*6+5)+(10:11))');
    object_kind(i) = str2double(grip);
end

% now look for the timestamps that signal block transitions
if ~isempty(handdata.strobe)
    block_transition_signal = diff(handdata.strobe); % has 1 fewer index than handdata.strobe.
    thresh = -5000;
else % for moe, this field is empty. use trial start times instead
    block_transition_signal = -diff(trial_start_time);
    thresh = -4e4; % needed to reduce from -5e4 to -4e4 to let this work for Moe 50 (-5e4 worked perfectly for Moe 46, although -4e4 also works).
end 
    
block_transition_inds   = find(block_transition_signal < thresh)+1; % accounts for the off-by-1 error of using diff (which might actually be INTRODUCING an off-by-one error?!? Noted as of 08.11.2020: double-check the SAMPLE TIMES between the final and pentultimate strobe indices of a given block. Turns out, the biggest number corresponds with "sample 0" of the NEXT block (i.e., the time between those two samples is MASSIVE, way more than the 5-20 ms that typifies sampling WITHIN a block!!!) (in other words, you WANT to be using the indices provided by diff!!!)
% signal_vals             = handdata.strobe(block_transition_inds) % check to make sure all the values are low, indicating the reset I wanted to detect

if ~isempty(handdata.strobe)
    block_transition_timestamps = handdata.timestamp(block_transition_inds);
    kinfile_transition_inds       = vertcat( handdata.strobe(block_transition_inds(:)-1),handdata.strobe(end) );
    kinfile_transition_timestamps = vertcat(handdata.timestamp(1),block_transition_timestamps); % (added 08.11.2020, allows one to register kinematic file times to behavioural and, by extension, neural times)
    % note that there's a weird thing going on here: generally, the "control" blocks blend seamlessly into the first "active" blocks, in terms of both the strobe signal AND the partitioning of the kinematic files. So if you only see 8 transitions (because I do include the session start time as a "transition") but know you have 9 blocks, well, that's what is going on.
else
    block_transition_timestamps = (trial_start_time(block_transition_inds) + trial_end_time(block_transition_inds-1))./2;
    kinfile_transition_inds       = [];
    kinfile_transition_timestamps = [];
end


% seek out any additional signs of transitions: namely, the sudden and
% sustained dropping of event names
%
% this is only appropriate for Zara, who uses the strobe field of "hand" to determine block structure
% this importantly LACKS the transition between "control" and "active", hence the need for this check.
% for Moe's data, however, we have all the information we need from the trial start time gaps.

if ~isempty(handdata.strobe)
    are_nan = isnan(cue_onset_time) | ...
        isnan(cue_remove_time) | isnan(reaction_phase_time) | isnan(go_phase_time) | ...
        isnan(movement_onset_time) | isnan(hold_time) | isnan(post_hold_time) | ...
        isnan(trial_end_time);
    nan_derivatives = diff(are_nan);
    transition_candidates = find(nan_derivatives == 1)+1; % undo off-by-1 error
    
    additional_transition_times = trial_start_time(transition_candidates);
    
    block_transition_timestamps = sort(vertcat(block_transition_timestamps(:),...
        additional_transition_times(:)),'ascend');
else
    % pass
end


% now create a NEW metadata field: block index! 
% we index from one, unfortunately, so we start here with an array of ones.
block_index = ones(size(object_kind));
for ii = 1:numel(block_transition_timestamps)
    add_to_these_inds = trial_start_time >= block_transition_timestamps(ii); % make it greater than OR equal to!!! transition indices mark the INSTANTS it transitions to a new block!
    block_index(add_to_these_inds) = block_index(add_to_these_inds)+1; %++
end

% now assign block names, if they are specified
if ~isempty(trial_type_names)
    if max(block_index) == numel(trial_type_names)
        block_names = trial_type_names(block_index);
    elseif max(block_index) < numel(trial_type_names)
        block_names = trial_type_names(block_index);
        warning('Number of given block names exceeds the number of detected blocks. Using only the first %i block names',max(block_index))
    elseif max(block_index) > numel(trial_type_names)
        block_inds  = mod(block_index-1,numel(trial_type_names))+1; % cycle!
        block_names = trial_type_names(block_inds);
        warning('Number of given block names is fewer than the number of detected blocks. Block name assignments will cycle by default (this is done so that single-block sessions can be handled trivially by assigning every block to 1, and so that alternating block sessions can be handled just by specifying the repeating pattern).')
    else
        error('what the fucking hell how did non-integer numbers get in my block indices?!?!?!?')
    end
else
    block_names = num2cell(block_index); % convert to a cell array, just to keep it consistent with the specified case
    block_names = cellfun(@(x) num2str(x),block_names,'uniformoutput',false);
end

[ubn,~,ubi] = unique(char(block_names),'rows');
ubn = cellstr(ubn);

% convert object indices into names, too.
% this requires the use of Stefan's code
% hope you did the path setup at the top of this script!
object_names = MirrorData.getgripname(Setup_name,object_kind);
[uon,~,uoi]  = unique(char(object_names),'rows');
uon = cellstr(uon);

%% now format to fit the MirrorData struct!
obj.Event = struct('trial_start_time',num2cell(trial_start_time),...
    'fixation_achieve_time',num2cell(fixation_time),...
    'cue_onset_time',num2cell(cue_onset_time),...
    'cue_offset_time',num2cell(cue_remove_time),... % only valid for "control" trials, where the light eventually did turn off. always came exactly 700ms after cue onset.
    'reaction_phase_start_time',num2cell(reaction_phase_time),... % only valid for "control" trials. Not sure why or what this timestamp really "means". Has substantial variance in start time relative to cue onset, but hovers around 1.5s after it. More tightly coupled to it is the subsequent "go onset", which is almost always 10 ms after "reaction phase onset". I have to imagine this event is related to the need to hold the hand on the handrest for some threshold number of milliseconds, which was set to a mere 10ms for this particular session. What exactly is happening between cue offset and "reaction onset", however, I'm not entirely sure of. In this task, probably nothing, but it may be a legacy setting to permit rotation of the turntable during this period. Or it may pertain to the lack of cue, which indicates to the animal that they must hold still. The "reaction phase onset" may then be the onset of the "set" cue (following cue offset's "ready" cue), and "go onset" the onset of the "go" cue.
    'go_phase_start_time',num2cell(go_phase_time),... % in other words: the previous event may be the second in a series of 3 cues (ready-set-go), of which only "ready" (cue offset, and even then only in "control" trials) and "go" (the LED going off) are present (the "set" cue indicating to the animal to prepare to move)
    'movement_onset_time',num2cell(movement_onset_time),... % OR, actually, the "reaction phase start" may be related to Jonathan's experiments with varying "set" times. With "reaction phase start" being when the go cue WOULD have been delivered in the "reaction time (i.e., 0 wait)" condition, to permit registration of trials with progressively longer wait times against that time (to show that cortical activity is maintained until delivery of the go cue) (see the J Neurosci 2018 paper for what I mean...)
    'hold_onset_time',num2cell(hold_time),... % !!! yeah of all those explanations, the "it was to allow registration of preparatory dynamics to a common START time in Jonathan's experiment" seems the most likely. (note that given the extremely short delay between reaction & go onsets, this task was essentially carried out in "reaction time" mode)
    'reward_onset_time',num2cell(post_hold_time),...
    'trial_end_time',num2cell(trial_end_time));

obj.Object                 = struct;
obj.Object.names           = object_names(:);
obj.Object.unique_names    = uon;
obj.Object.indices         = uoi;
obj.Object.TurntableIndex  = object_kind; % keep the turntable labels for reconstructing condition from Moe (& for detecting odd turntable specificity for Zara)

obj.TrialType              = struct;
obj.TrialType.names        = block_names(:);
obj.TrialType.unique_names = ubn;
obj.TrialType.indices      = ubi;

% one more field which will help synchronize the kinematics: add this to time 0 for each kinematic file
% (added 08.11.2020)

if numel(ubn) > 1
    obj.KinematicFileTransitionTimes.transitiontimes = kinfile_transition_timestamps;
    obj.KinematicFileTransitionTimes.blockdurationsinsamplecounts = kinfile_transition_inds;
    obj.KinematicFileTransitionTimes.strobeinds = handdata.strobe;
    obj.KinematicFileTransitionTimes.timestamps = handdata.timestamp;
else
    obj.KinematicFileTransitionTimes.transitiontimes = kinfile_transition_timestamps(1);  % if only one block, just put in the first timestamp, ignore the rest, as they are likely artifactual transition times
    obj.KinematicFileTransitionTimes.blockdurationsinsamplecounts = kinfile_transition_inds; % this also never gets used...
    obj.KinematicFileTransitionTimes.strobeinds = handdata.strobe; % just for reference / sanity checking when there is more than one block. never actually used.
    obj.KinematicFileTransitionTimes.timestamps = handdata.timestamp;
end

%% now save to a file, if one is specified

if ShouldSave
    eval(sprintf('%s = obj;',Obj_name));
    if ~isempty(SaveFile)
        save(SaveFile,Obj_name,'-v7.3');
        fprintf('Saved updated MirrorData object (named "%s") to: %s\n',Obj_name,SaveFile)
    else
        [Fname,Pname] = uiputfile('*.mat','Specify location and name of file to which to save the updated MirrorData object.');
        
        if isnumeric(Fname) || isnumeric(Pname) || islogical(Fname) || islogical(Pname) % i.e., if "cancel" is pressed
            warning('No file will be saved')
        else
            ffname = fullfile(Pname,Fname);
            save(ffname,Obj_name,'-v7.3')
            fprintf('Saved updated MirrorData object (named "%s") to: %s\n',Obj_name,ffname)
        end
    end
    
else
    fprintf('No file was saved because ShouldSave was set to "false".\n')
end
    
end