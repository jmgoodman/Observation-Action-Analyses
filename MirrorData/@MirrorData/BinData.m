function BinnedData = BinData(obj,varargin)

%BINDATA Aligns neural data & bins the spike counts.
%
%DESCRIPTION
%   This routine aligns the data to some event, captures all spikes within
%   a specified window of that event (for the selected neurons), and
%   captures spike times within a series of bins of a specified size. A
%   useful step for creating a data "loaf". Separate routines can then be
%   used to smooth the data or further "sort" the data into a cell array
%   where each cell corresponds with an experimental condition.
%
%SYNTAX
%   BinnedData = PlotRaster(obj,varargin)
%
%   BinnedData  ... Struct containing the binned data. Contains the
%   following fields:
%       Data            ... T x N x R array, where T is the number of samples
%       within the window specified, N is the number of neurons, and R is
%       the number of trials.
%       NeuronIDs       ... N x 2 array, where the first column specifies the
%       channel ID and the second column the unit ID of every column in
%       "Data".
%       ArrayIDs        ... N x 1 cell array, specifying the array ID of each
%       column in "Data".
%       Alignment       ... The name of the event to which "Data" are aligned.
%       String.
%       BinTimes        ... The centroids of the bins into which "Data" are
%       sampled. T x 1 vector. Values in milliseconds.
%       BinEdges        ... The edges of the bins into which "Data" are
%       sampled. (T+1) x 1 vector. Values in milliseconds.
%       Objects         ... R x 1 cell array, indicating the name of each
%       object for each trial, or each "slice" of "Data".
%       TrialTypes      ... R x 1 cell array, indicating the name of each
%       condition for each trial, or each "slice" of "Data".
%       TurnTableIDs    ... R x 1 vector, indicating the turntable ID
%       number for each trial, or each "slice" of "Data".
%   obj         ... MirrorData object (instantiated with obj = MirrorData();)
%   varargin    ... Inputs specified in name-value pairs that could include
%   the following:
%       'Alignment'         ... String specifying to which event to align the data.
%       Default is 'movement_onset_time'.
%       'Neuron'            ... A N x 2 array with each row specifying the
%       channel ID and unit ID of each unit to be binned, respectively. May
%       also be a string specifying either 'all' or the name of an array to
%       include. The former including ALL units across ALL arrays, the
%       latter including only units from the specified array. May also be a
%       cell array of strings specifying all arrays to include - useful for
%       when one only wants to consider, say, F5 as a whole rather than
%       considering the medial and lateral arrays separately. Default is
%       'all'.
%       'Window'            ... a positive scalar indicating how far into the
%       past and future a window centered on each event extends, in ms. Can
%       alternatively be a two-element vector, first element indicating the
%       "past" wing, second the "future" wing, relative to each event. Can
%       also be a string reading 'auto' (defualt), which automatically
%       determines window sizes based on inter-event durations and defaults
%       to 'MaximumWindow' for events without a preceding or subsequent
%       event.
%       'Overlap'           ... a positive scalar between 0 and 1 indicating
%       the fraction of trials for which a window set by 'auto' can contain
%       a subsequent or preceding event. Default is 0. Only matters when
%       'Window' is set to 'auto'.
%       'MinimumWindow'     ... a positive scalar indicating, in ms, the
%       minimum size of a "wing" of a window set by 'auto'. Default is 100.
%       Note that the minimum window *duration* is twice this number. Only
%       matters if 'Window' is set to 'auto'.
%       'MaximumWindow'     ... a positive scalar indicating, in ms, the
%       maximum size of a "wing" of a window set by 'auto'. This is also
%       the default "wing" size when setting 'Window' to 'auto' and no
%       previous or subsequent event can be found. Default is 500. Only
%       matters if 'Window' is set to 'auto'.
%       'BinSize'           ... a positive scalar indicating, in ms, the
%       bin size. Default is 10. Note that if this does not evenly tile the
%       interval specified by Window, then the left and right wings get
%       "pinched" to the nearest BinSize-sized intervals prior to binning.
%       A ceil operation is applied to the left bound of the interval, and
%       a floor operation to the right bound. This "pinch" is done to
%       preserve the lack of overlap between windows aligned to subsequent
%       events, should one specify settings that should guarantee this
%       property when using the 'auto' Window setting. Regardless, the
%       exact bins & windows settled upon will be stored as metadata in BinnedData.
%       'DoKinematics'    ... boolean. true = process kinematics if available.
%       false = don't. Default = true.
%       'DoMarker'        ... boolean. true = concatenates marker positions with joints
%       false = don't. warning: this is VERY unstable. Default = false;
%
%AUTHOR
%   Written for MirrorData by James Goodman, 2020 March 19, DPZ

%% Step 1: parse inputs
% I'm going to skip error-checking this time, so use at your own peril!
% (okay turn the warning itself off though, it's annoying)
% warning('No error checking on inputs, so use with the understanding that errors may arise without helpful feedback!')

assert(mod(numel(varargin),2)==0,'Wrong number of inputs: must come in name-value pairs')

pNames = varargin(1:2:(end-1));
pVals  = varargin(2:2:end);

% establish default values
Alignment             = 'movement_onset_time';
Neuron                = 'all';
Window                = 'auto';
Overlap               = 0;
MinimumWindow         = 100;
MaximumWindow         = 500;
BinSize               = 10;
DoKinematics          = true;
DoMarker              = false;

InputNames = {'Alignment','Neuron','Window','Overlap','MinimumWindow','MaximumWindow','BinSize','DoKinematics','DoMarker'};


for name_ind = 1:numel(pNames)
    pName = pNames{name_ind};
    pVal  = pVals{name_ind}; %#ok<*NASGU>
    
    if ismember(pName,InputNames)
        eval(sprintf('%s = pVal;',pName));
    else
        warning('%s is not a valid input name. ignoring this name-value pair.',pName)
    end
end

%% check if there even is neural data: perhaps you just want to process kinematics
if ~isempty(obj.Neural)
    %% step 2: collect the desired neurons
    ST  = arrayfun(@(x) x.spiketimes,obj.Neural,'uniformoutput',false);
    cID = arrayfun(@(x) x.channelID,obj.Neural);
    uID = arrayfun(@(x) x.unitID,obj.Neural);
    aID = arrayfun(@(x) x.array,obj.Neural,'uniformoutput',false);
    
    if isstr(Neuron) %#ok<*DISSTR>
        if strcmp(Neuron,'all')
            these_neurs = true(size(ST));
        else
            these_neurs = cellfun(@(x) strcmpi(x,Neuron),aID);
        end
        
    elseif iscellstr(Neuron)
        these_neurs = ismember(aID,Neuron);
    elseif isnumeric(Neuron)
        nID         = [cID(:),uID(:)];
        these_neurs = ismember(nID,Neuron,'rows');
    end
    
    if ~any(these_neurs)
        error('no neurons to bin! check your array name!')
    else
        % pass
    end
    
    ST  = ST(these_neurs);
    cID = cID(these_neurs);
    uID = uID(these_neurs);
    aID = aID(these_neurs);
    
else
    cID = [];
    uID = [];
    aID = [];
end
%% step 3: make the appropriate alignment & collect data within the appropriate window with the appropriate bins

align_times = arrayfun(@(x) x.(Alignment),obj.Event);

if isstr(Window)
    % when setting window to 'auto', perform the following to avoid window overlaps
    if strcmpi(Window,'auto')
        all_align_names = fieldnames(obj.Event);
        all_align_times = zeros(numel(obj.Event),numel(all_align_names));
        
        for align_ind = 1:numel(all_align_names)
            all_align_times(:,align_ind) = arrayfun(@(x) ...
                x.(all_align_names{align_ind}),obj.Event);
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % only keep events that are present across ALL trials. Before running this
        % code, make sure to remove any "bad" trials that for some reason did not
        % record some particular event, as leaving it in will delete that event
        % entirely when running this script, which could lead to unexpected
        % behavior! Alternatively, just avoid the 'auto' option when running this
        % script if you're worried about that. Spike times for "bad" trials will
        % show up as "nan" when aligning to the "problem" event. It just
        % means you'll need to set up the window manually.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        events_to_nix = any(isnan(all_align_times),1)' | ...
            ismember(all_align_names,{'trial_start_time','trial_end_time'}); % also, do NOT include the arbitrary trial-start and trial-stop times.
        
        all_align_names = all_align_names(~events_to_nix);
        all_align_times = all_align_times(:,~events_to_nix);
        
        all_align_times = bsxfun(@minus,all_align_times,...
            all_align_times(:,1)); % align to the first listed event by default
        
        typical_align_times = median(all_align_times);
        
        [~,sorted_event_inds] = sort(typical_align_times,'ascend');
        
        sorted_align_times = all_align_times(:,sorted_event_inds);
        sorted_align_names = all_align_names(sorted_event_inds);
        
        this_event = ismember(sorted_align_names,Alignment);
        this_event_ind = find(this_event);
        
        if this_event(1)
            leftwing = -MaximumWindow;
        else
            % do the overlap calculation w.r.t. the previous event
            delta_etimes  = sorted_align_times(:,this_event_ind) - sorted_align_times(:,this_event_ind-1);
            
            prctile_delta = prctile(delta_etimes/2,100*Overlap); % divide by 2 so that subsequent runs of this script with subsequent events do not pull overlapping windows (provided overlap is set to 0 and minimumwindow doesn't override anything)
            leftwing      = -min( max(prctile_delta,MinimumWindow),...
                MaximumWindow);
        end
        
        if this_event(end)
            rightwing = MaximumWindow;
        else
            % do the overlap calculation w.r.t. the following event
            delta_etimes  = sorted_align_times(:,this_event_ind+1) - sorted_align_times(:,this_event_ind);
            
            prctile_delta = prctile(delta_etimes/2,100*Overlap); % divide by 2 so that subsequent runs of this script with subsequent events do not pull overlapping windows (provided overlap is set to 0 and minimumwindow doesn't override anything)
            rightwing     = min( max(prctile_delta,MinimumWindow),...
                MaximumWindow);
        end
        
    else
        error('Invalid "Window" input!')
    end
    
elseif isnumeric(Window)
    % here, you handle numeric arguments for window
    if numel(Window) == 1
        leftwing  = -Window;
        rightwing = Window;
    elseif numel(Window) == 2
        leftwing = Window(1); % yes, the sign is preserved in this case. do NOT give an input of [500,500]! Use [-500,500], specify a RANGE rather than "wing" sizes! Doing it this way lets you more easily specify windows that are not centered on the event time!
        rightwing = Window(2);
    else
        error('Invalid "Window" input!')
    end
    
else
    error('Invalid "Window" input!')
end

%%
% round the wings to the nearest BinSize
% use a "pinch" rounding that cannot increase the size of the window,
% meaning apply ceil to the left and floor to the right bound. If windows
% are too small, no data binning may occur as a result of this rounding,
% but if the intervals are that small you have bigger problems anyway. Such
% a "pinch" is performed (and its downsides tolerated) so that when using
% the 'auto' Window setting with other settings that should guarantee no
% two intervals' windows should overlap, this guarantee is preserved. Naive
% rounding may expand the window size, which in turn would lead to
% unintended overlap between intervals.
leftwing  = ceil(leftwing/BinSize)*BinSize;
rightwing = floor(rightwing/BinSize)*BinSize;

bin_edges = leftwing:BinSize:rightwing;
bin_centers = bin_edges(1:(end-1)) + BinSize/2;

if ~isempty(obj.Neural)
    data_mat = zeros(numel(bin_centers),numel(ST),numel(align_times));
    
    % for each trial
    for trialind = 1:numel(align_times)
        
        % for each neuron
        for neurind = 1:numel(ST)
            ST_shifted = ST{neurind} - align_times(trialind);
            
            binned_spikecounts = histcounts(ST_shifted,bin_edges);
            
            data_mat(:,neurind,trialind) = binned_spikecounts(:);
        end
    end
    
else
    data_mat = [];
end

%% added 28.06.2021
% kinematic data processing (this not only bins, but filters, too)
% ONLY apply to joint angles; raw marker positions end up telling the story of larger/smaller hands and little else!
% this ain't the most efficient way to do things (I end up repeating the filtering multiple times by bundling it in the bindata script), but it really ought not be such a huge deal, right?
% okay I hacked a way to make it more efficient. basically just tell it to ignore kinematics with a name-value pair (which is case-sensitive unfort.)

if ~isempty(obj.Kinematic) && DoKinematics
    % get sampling rate
    SR = 1000 / median( diff( obj.Kinematic(1).JointStruct.data(:,1) ) );
    
    % apply a low-pass filter (but a fairly relaxed cutoff: say, 12 Hz)
    filterorder  = 4;
    filtercutoff = 12/(SR/2);
    [b,a] = butter(filterorder,filtercutoff,'low');
        
    jcolnames = obj.Kinematic(1).JointStruct.columnNames; % USED to just keep the last 28 columns... but this was from before I cleaned up the model! (a NECESSARY step to properly track the human kinematics!!!!!)
    JD = arrayfun(@(x) x.JointStruct.data,obj.Kinematic,'uniformoutput',false);
    JDfilt = cell(size(JD));
    
    mcolnames = obj.Kinematic(1).MarkerStruct.header(4,[1,2,3:3:end]);
    mcolnames = mcolnames(:)';
    tempcolnames = vertcat( strcat(mcolnames(3:end),'_X'),...
        strcat(mcolnames(3:end),'_Y'),...
        strcat(mcolnames(3:end),'_Z') );
    mcolnames = horzcat( mcolnames(1:2), tempcolnames(:)' );
        
    MD = arrayfun(@(x) x.MarkerStruct.data,obj.Kinematic,'uniformoutput',false);
    MDfilt = cell(size(MD));
    
    for ii = 1:numel(JD)
        JDtemp = JD{ii};
        JDfilttemp = zeros(size(JDtemp));
        
        for jj = 1:size(JDtemp,2)
            if jj == 1
                JDfilttemp(:,1) = JDtemp(:,1);
            else
                % first, interpolate to remove any NaN values
                tempcol = JDtemp(:,jj);
                naninds = isnan(tempcol);
                
                nonnaninds = find(~naninds);
                nonnandata = tempcol(nonnaninds);
                
                newcol  = interp1( nonnaninds(:),nonnandata(:),(1:numel(tempcol))' );
                
                % now filter the values
                JDfilttemp(:,jj) = filtfilt(b,a,newcol);
            end
        end
        
        JDfilt{ii} = JDfilttemp;
    end
        
    % concatenate
    JDcat = vertcat(JDfilt{:});
    
    % make a tensor similar to that for the neuronal data
    jkindata = zeros(numel(bin_centers),numel(jcolnames)-1,numel(align_times)); % bins x joints x trials
    
    % next, assign kinematic chunks to various trials
    % for each trial
    for trialind = 1:numel(align_times)
        JAT_shifted = JDcat(:,1) - align_times(trialind);
        
        tempmat = interp1(JAT_shifted(:),JDcat(:,2:end),bin_centers(:));
        
        jkindata(:,:,trialind) = tempmat;
    end
    
    jcolnames = jcolnames(2:end); % finally, remove the "time" column.
    
    if DoMarker
        % now do the same but for the marker data
        % (or just ignore if you pass the right option through - NaN handling is NOT clean with these!!!)
        for ii = 1:numel(MD) %#ok<UNRCH>
            MDtemp = MD{ii};
            
            % delete nan rows, then interpolate
            removeinds = isnan(MDtemp(:,1));
            MDtemp(removeinds,:) = [];
            
            MDtemp(:,1) = round(MDtemp(:,1)); % get to int
            
            MDtemp = interp1(MDtemp(:,1),MDtemp,( min(MDtemp(:,1)):max(MDtemp(:,1)) )'); % default linear
            
            MDfilttemp = zeros(size(MDtemp));
            
            for jj = 1:size(MDtemp,2)
                if jj < 3
                    MDfilttemp(:,jj) = MDtemp(:,jj);
                else
                    % first, interpolate to remove any NaN values
                    tempcol = MDtemp(:,jj);
                    naninds = isnan(tempcol);
                    
                    nonnaninds = find(~naninds);
                    nonnandata = tempcol(nonnaninds);
                    
                    newcol  = interp1( nonnaninds(:),nonnandata(:),(1:numel(tempcol))' );
                    
                    % now filter the values
                    MDfilttemp(:,jj) = filtfilt(b,a,newcol);
                end
            end
            
            MDfilt{ii} = MDfilttemp;
        end
        
        % concatenate
        MDcat = vertcat(MDfilt{:});
        
        % make a tensor similar to that for the neuronal data
        mkindata = zeros(numel(bin_centers),numel(mcolnames)-2,numel(align_times)); % bins x joints x trials
        
        % next, assign kinematic chunks to various trials
        % for each trial
        for trialind = 1:numel(align_times)
            MAT_shifted = MDcat(:,2) - align_times(trialind);
                        
            tempmat = interp1(MAT_shifted(:),MDcat(:,3:end),bin_centers(:));
            
            mkindata(:,:,trialind) = tempmat;
        end
        
        mcolnames = mcolnames(3:end); % finally, remove the "time" and "samples" columns.
    else
        mcolnames = [];
        mkindata  = [];
    end

else
    jcolnames = [];
    jkindata  = [];
    mcolnames = [];
    mkindata  = [];
end
%% pack into BinnedData

BinnedData.Data         = data_mat;
BinnedData.NeuronIDs    = [cID(:),uID(:)];
BinnedData.ArrayIDs     = aID;
BinnedData.Alignment    = Alignment;
BinnedData.BinTimes     = bin_centers(:);
BinnedData.BinEdges     = bin_edges(:);
BinnedData.Objects      = obj.Object.names;
BinnedData.TrialTypes   = obj.TrialType.names;
BinnedData.TurnTableIDs = obj.Object.TurntableIndex;

BinnedData.KinematicData      = horzcat(jkindata,mkindata);
BinnedData.KinematicColNames  = vertcat(jcolnames(:),mcolnames(:));

%   BinnedData  ... Struct containing the binned data. Contains the
%   following fields:
%       Data            ... T x N x R array, where T is the number of samples
%       within the window specified, N is the number of neurons, and R is
%       the number of trials.
%       NeuronIDs       ... N x 2 array, where the first column specifies the
%       channel ID and the second column the unit ID of every column in
%       "Data".
%       ArrayIDs        ... N x 1 cell array, specifying the array ID of each
%       column in "Data".
%       Alignment       ... The name of the event to which "Data" are aligned.
%       String.
%       BinTimes        ... The centroids of the bins into which "Data" are
%       sampled. T x 1 vector.
%       BinEdges        ... The edges of the bins into which "Data" are
%       sampled. (T+1) x 1 vector.
%       Objects         ... R x 1 cell array, indicating the name of each
%       object for each trial, or each "slice" of "Data".
%       TrialTypes      ... R x 1 cell array, indicating the name of each
%       condition for each trial, or each "slice" of "Data".
%       TurnTableIDs    ... R x 1 vector, indicating the turntable ID
%       number for each trial, or each "slice" of "Data".

end
