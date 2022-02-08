function h = PlotPETH(obj,varargin)

%PLOTPETH makes a peri-event time histogram (PETH) plot.
%
%DESCRIPTION
%   This routine aligns the neural data to the specified event(s) and plots
%   PETHs of a specified neuron. Supports multiple alignments.
%
%SYNTAX
%   h = PlotPETH(obj,varargin)
%
%   h           ... figure handle for the resulting PETH plot.
%   obj         ... MirrorData object (can be empty, instantiated with obj
%   = MirrorData();)
%   varargin    ... Inputs specified in name-value pairs that could include
%   the following:
%       'Alignment'         ... String or cell array of strings specifying
%       which events to align to. Can also be 'all', which uses
%       every event time. Default is {'cue_onset_time','go_phase_start_time',
%       'movement_onset_time','hold_onset_time','reward_onset_time'}.
%       'Neuron'            ... A two-element vector specifying the channelID
%       and unitID of the unit you wish to plot, respectively. Default
%       value is an empty array, which automatically plots the first unit
%       in obj.Neural. This function does not support plotting multiple
%       rasters with a single call, so you cannot pass an N x 2 matrix into
%       this field, and must instead call this function in a for loop to
%       produce multiple rasters.
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
%       'SortFactor'        ... A string specifying whether to sort by
%       'TrialType','Object', 'TurntableIndex', or 'TrialIndex'.
%       Can also be a cell array of strings to indicate a nested sort,
%       e.g., the cell {'TrialType','Object'} sorts first by TrialType, and
%       then within each TrialType, then sorts by object. Only supports
%       nesting of 2 levels, however, so the cell can have at most 2
%       elements. Also only supports nestings where one of the elements is
%       'TrialType', and no nestings including "TrialIndex" (as sorting by
%       trial index is assumed).
%       'SortColors'        ... An N x 3 matrix specifying the colors of the
%       traces assigned to each group. In the event of nested sorting,
%       this matrix applies to the most granular sort (i.e., the second
%       element of the 'SortFactor' variable), with colors being repeated
%       across coarser sort levels. Default is an empty array, which
%       defaults to parula(N). Note that this can also be a cell array of
%       Nx3 matrices, in which case each cell corresponds to a separate
%       coarse sort factor (in case you want to separate conditions by
%       different color schemes, e.g., pastel vs. saturated).
%       'SortStyles'        ... a string or cell array of strings indicating
%       the line style(s) for PETHs associated with each level of the coarse
%       sorting factor. Only applies when using a coarse sort factor; traces
%       will have different colors and maintain similar line styles (solid)
%       in the event of only one sort factor being present. Default is an
%       empty array, which defaults to a repeating {'-','--',':'} array.
%       'LevelsToKeep'      ... A cell array of strings specifying which
%       levels of each factor to keep, or in the event of TurntableIndex, a
%       vector of indices to keep. May also be a single string or value
%       specifying a single level of the SortFactor to plot, or 'all'
%       (default) indicating that all levels should be plotted. In the
%       event of nested factors, if not 'all', must be a 2x1 cell array,
%       the contents of each cell being a valid input to the one-factor case
%       for the coarse and granular sort factors, respecitvely. This
%       specification is useful if you only want to plot a raster for a
%       single object, or want to, say, plot a raster for all objects,
%       but only from a particular TrialType.
%       'PlotScaleBar'      ... a logical value indicating whether or not to
%       plot a (time) scale bar. Default is true. Can only be set to false
%       for single-alignment raster plots; returns an error if set to false
%       for multi-alignment plots. This option also indicates whether to
%       use alignment names or times from alignment as x-tick labels. If
%       on, alignment names are used as x-tick labels. If off, times are
%       used.
%       'AlignmentNames'    ... a string or cell array of strings
%       indicating the names to use for alignments when plotting them
%       (because the underscore-heavy event names of MirrorData are not
%       friendly for human eyes). Default is an empty array, which defaults
%       to the field names used in 'Alignment'.
%       'ScaleBarLocation'  ... a string specifying one of
%       'top','topleft','bottomleft','bottom','bottomright', for where to
%       place the scale bar. Default is 'topright'. Unused if
%       'PlotScaleBar' is false.
%       'ScaleBarDuration'  ... a positive scalar indicating, in
%       milliseconds, the length of the scale bar. Default is 500.
%       'DrawAlignment'     ... a logical value indicating whether or not
%       to draw a vertical line at each alignment. Default is "true".
%       'EpochSpacing'      ... a positive scalar indicating, in milliseconds,
%       the separation between epochs in a multi-alignment raster. Goes
%       unused if only one alignment is specified. Default is 50.
%       'BinSize'           ... a positive scalar indicating, in ms, the
%       bin size. Default is 10. Note that if this does not evenly tile the
%       interval specified by Window, then the left and right wings get
%       "pinched" to the nearest BinSize-sized intervals prior to binning.
%       A ceil operation is applied to the left bound of the interval, and
%       a floor operation to the right bound. This "pinch" is done to
%       preserve the lack of overlap between windows aligned to subsequent
%       events, should one specify settings that should guarantee this
%       property when using the 'auto' Window setting.
%       'SmoothKernel'      ... A user-specified vector of values
%       indicating the smoothing kernel applied to the neural data when
%       estimating firing rates. This vector should have the same sampling
%       rate as that associated with the 'BinSize' argument. If one plans
%       to use a strictly causal window, one should precede that window
%       with a vector of (N-1) zeros, with N being the length of the
%       smoothing kernel prior to this zero-padding. I figured doing it
%       this way would ultimately be less frustrating than being locked
%       into pre-set smoothing options. Note that this function
%       automatically adjusts the sum of elements in the vector to be equal
%       to one, and returns an error if any negative or nonreal elements
%       are present. Default is an empty vector, which defaults to a
%       Gaussian kernel with sigma = 20 ms and which spans an interval from
%       -200ms to +200ms.
%       ErrorShadeAlpha     ... A scalar between 0 and 1 (inclusive)
%       indicating the transparency of the shading around each PETH, which
%       indicates variability. Default is 0.08.
%       ErrorShadeMode      ... A string reading one of 'SEM','SD', or
%       'none', indicating whether to use standard error, standard
%       deviation, or not to plot error shading at all, respectively.
%       Default is 'SEM'.
%AUTHOR
%   Written for MirrorData by James Goodman, 2020 March 19, DPZ

%% Step 1: parse inputs

% I'm going to skip error-checking this time, so use at your own peril!
% (okay turn the warning itself off though, it's annoying as fuck)
% warning('No error checking on inputs, so use with the understanding that errors may arise without helpful feedback!')

assert(mod(numel(varargin),2)==0,'Wrong number of inputs: must come in name-value pairs')

pNames = varargin(1:2:(end-1));
pVals  = varargin(2:2:end);

% establish default values
Alignment             = {'fixation_achieve_time','cue_onset_time','go_phase_start_time',...
    'movement_onset_time','hold_onset_time','reward_onset_time'};
AlignmentNames        = [];
Neuron                = [];
Window                = 'auto';
Overlap               = 0;
MinimumWindow         = 100;
MaximumWindow         = 500;
SortFactor            = {'TrialType','Object'};
SortColors            = [];
SortStyles            = [];
LevelsToKeep          = 'all';
PlotScaleBar          = true;
ScaleBarLocation      = 'topright';
ScaleBarDuration      = 500;
DrawAlignment         = true;
EpochSpacing          = 50;
BinSize               = 10;
SmoothKernel          = [];
ErrorShadeAlpha       = 0.08;
ErrorShadeMode        = 'SEM';

InputNames = {'Alignment','Neuron','Window','Overlap','MinimumWindow','MaximumWindow',...
    'SortFactor','SortColors','SortStyles','LevelsToKeep',...
    'PlotScaleBar','ScaleBarLocation','ScaleBarDuration','DrawAlignment',...
    'EpochSpacing','AlignmentNames','BinSize','SmoothKernel',...
    'ErrorShadeAlpha','ErrorShadeMode'};

for name_ind = 1:numel(pNames)
    pName = pNames{name_ind};
    pVal  = pVals{name_ind};
    
    if ismember(pName,InputNames)
        eval(sprintf('%s = pVal;',pName));
    else
        warning('%s is not a valid input name. ignoring this name-value pair.',pName)
    end
end

%% assign AlignmentNames before you forget
if isempty(AlignmentNames)
    AlignmentNames = Alignment;
else
    % enforce that Alignment and AlignmentNames are similar
    are_both_strings = isstr(Alignment) && isstr(AlignmentNames);
    are_both_cellstr = iscellstr(Alignment) && iscellstr(AlignmentNames) && ...
        numel(Alignment) == numel(AlignmentNames);
    
    assert(are_both_strings || are_both_cellstr,'Alignment and AlignmentNames need to be the same type (string or cellstr) and, in the case of cellstr, the same size!')
end

%% step 2: determine the target windows
% we want to create BinnedData that actually extend a little bit beyond
% what we want, so that smoothing doesn't get "funny" at the edges of
% windows

if isempty(SmoothKernel)
    tvals = -(200-BinSize/2):BinSize:(200-BinSize/2); % BOUND your intervals by [-200 200], rather than CENTERING them on values within that range...
    tvals = tvals - mean(tvals); % make sure tvals is actually centered
    
    gvals = exp( -tvals.^2 ./ (2*20^2) );
    gvals = gvals(:)./sum(gvals);
    
    SmoothKernel = gvals;
else
    if any(SmoothKernel < 0)
        error('no negative values allowed in SmoothKernel!')
    else
    end
    
    SmoothKernel = SmoothKernel(:)./sum(SmoothKernel);
end

nsamps_smooth = numel(SmoothKernel);
ms_to_append_to_wing = (nsamps_smooth/2) * BinSize;

% if an odd number of elements, the central bin is CENTERED on 0
% so we add half a bin plus the duration associated with (N-1)/2
% which works out to N/2
%
% if an even number of elements, there is no central bin and the two that
% are CLOSEST to center are BOUNDED by 0. So just add the duration
% associated with N/2 bins.

% okay, to determine the expanded ranges, we should probably just... run
% BinData

if isstr(Alignment) %#ok<*DISSTR>
    if strcmpi(Alignment,'all')
        Alignment = fieldnames(obj.Event);
    elseif ~ismember(Alignment,fieldnames(obj.Event))
        error('invalid Alignment input')
    else
        Alignment = {Alignment}; % convert string into cell array
    end
else
    % pass
end

if isstr(AlignmentNames) %#ok<*DISSTR>
    AlignmentNames = {AlignmentNames}; % convert string into cell array
else
    % pass
end

% if the "Neuron" argument is empty, just take the first neuron, whatever
if isempty(Neuron)
    Neuron = [obj.Neural(1).channelID,...
        obj.Neural(1).unitID];
else
end

% get your "initial" alignments first
bdata = cell(size(Alignment));

for align_ind = 1:numel(Alignment) % should now be a cell array of strings
    alignment_ = Alignment{align_ind};
    
    bdata{align_ind} = obj.BinData('Alignment',alignment_,...
        'Neuron',Neuron,'Window',Window,'Overlap',Overlap,...
        'MinimumWindow',MinimumWindow,'MaximumWindow',...
        MaximumWindow,'BinSize',BinSize);
end

% now get your "expanded" alignments
bdata_expanded = cell(size(Alignment));
for align_ind = 1:numel(Alignment)
    alignment_ = Alignment{align_ind};
    
    new_win = [min( bdata{align_ind}.BinEdges ),...
        max( bdata{align_ind}.BinEdges )];
    
    new_win = new_win + [-1,1]*ms_to_append_to_wing;
    
    bdata_expanded{align_ind} = obj.BinData('Alignment',alignment_,...
        'Neuron',Neuron,'Window',new_win,'Overlap',Overlap,...
        'MinimumWindow',MinimumWindow+ms_to_append_to_wing,'MaximumWindow',...
        MaximumWindow+ms_to_append_to_wing,'BinSize',BinSize);
end

% now we smooth the spike count data to estimate the underlying firing
% rates
convert_to_Hz_factor = 1/(BinSize/1000); % convert BinSize from ms to s to convert to Hz
% spikes / bin * bins/s = (spikes/bin) / (seconds/bin) = spikes/s

FRdata_expanded = cell(size(bdata_expanded));

for align_ind = 1:numel(FRdata_expanded)
    SC = bdata_expanded{align_ind}.Data;
    SC = squeeze(SC); % BinData is built to handle multi-neuronal populations, so the 2nd dimension is normally neurons.
    % However, when plotting a PETH, you only work with 1 neuron at a time, so you should just squeeze this dimension out in this context.
    
    FR = conv2(SC,SmoothKernel(:),'same');
    
    FR = FR * convert_to_Hz_factor;
    
    FRdata_expanded{align_ind} = FR;
end

% and we interpolate within the *original* range to finalize things
FRdata = cell(size(FRdata_expanded));
        
for align_ind = 1:numel(FRdata)
    target_times   = bdata{align_ind}.BinTimes;
    expanded_times = bdata_expanded{align_ind}.BinTimes;
    
    FRdata{align_ind} = interp1(expanded_times,...
        FRdata_expanded{align_ind},target_times);
end


%% extract trials worth plotting (just like for the Raster script)

if isstr(LevelsToKeep) %#ok<*DISSTR>
    if strcmpi(LevelsToKeep,'all')
        keepTrials = true(numel(obj.Event),1);
    else
        if strcmpi(SortFactor,'TrialType')
            keepTrials = ismember(obj.TrialType.names,LevelsToKeep);
        elseif strcmpi(SortFactor,'Object')
            keepTrials = ismember(obj.Object.names,LevelsToKeep);
        else
            error('LevelsToKeep is incompatible with SortFactor')
        end
    end
    
elseif iscell(LevelsToKeep) && ~iscell(SortFactor)
    if strcmpi(SortFactor,'TrialType')
        keepTrials = ismember(obj.TrialType.names,LevelsToKeep);
    elseif strcmpi(SortFactor,'Object')
        keepTrials = ismember(obj.Object.names,LevelsToKeep);
    else
        error('LevelsToKeep is incompatible with SortFactor')
    end
    
elseif isnumeric(LevelsToKeep) && ~iscell(SortFactor)
    if strcmpi(SortFactor,'TurntableIndex')
        keepTrials = ismember(obj.Object.TurntableIndex,LevelsToKeep);
    else
        error('LevelsToKeep is incompatible with SortFactor')
    end
    
elseif iscell(SortFactor) && numel(SortFactor) == 2
    keepTrials    = true(numel(obj.Event),1);
    for ii = 1:2
        LevelsToKeep_ = LevelsToKeep{ii};
        SortFactor_   = SortFactor{ii};
        
        if isstr(LevelsToKeep_)
            if strcmpi(LevelsToKeep_,'all')
                keepTrials_ = true(numel(obj.Event),1);
            else
                if strcmpi(SortFactor_,'TrialType')
                    keepTrials_ = ismember(obj.TrialType.names,LevelsToKeep_);
                elseif strcmpi(SortFactor_,'Object')
                    keepTrials_ = ismember(obj.Object.names,LevelsToKeep_);
                else
                    error('LevelsToKeep is incompatible with SortFactor')
                end
            end
            
        elseif iscell(LevelsToKeep_) && ~iscell(SortFactor_)
            if strcmpi(SortFactor_,'TrialType')
                keepTrials_ = ismember(obj.TrialType.names,LevelsToKeep_);
            elseif strcmpi(SortFactor_,'Object')
                keepTrials_ = ismember(obj.Object.names,LevelsToKeep_);
            else
                error('LevelsToKeep is incompatible with SortFactor')
            end
            
        elseif isnumeric(LevelsToKeep_) && ~iscell(SortFactor_)
            if strcmpi(SortFactor_,'TurntableIndex')
                keepTrials_ = ismember(obj.Object.TurntableIndex,LevelsToKeep_);
            else
                error('LevelsToKeep is incompatible with SortFactor')
            end
            
        else
            error('LevelsToKeep is incompatible with SortFactor')
        end
        
        keepTrials = keepTrials & keepTrials_;
    end
    
else
    error('SortFactor is not valid') 
end
                
ObjectNames      = char(obj.Object.names(keepTrials));
TrialTypes       = char(obj.TrialType.names(keepTrials));
TurnTableIndices = obj.Object.TurntableIndex(keepTrials); %#ok<*NASGU>

EventTimes       = obj.Event(keepTrials);

FRdata           = cellfun(@(x) x(:,keepTrials),FRdata,'uniformoutput',false);

%% now generate your list of event centers (for multi-alignment PETHs)
center_vals  = zeros(numel(Alignment),1);
left_bounds  = zeros(numel(Alignment),1);
right_bounds = zeros(numel(Alignment),1);

left_bounds(1)  = min(0,min(bdata{1}.BinTimes));
right_bounds(1) = max(0,max(bdata{1}.BinTimes));

for align_ind = 2:numel(Alignment)
    previous_rightbound = max(0,max(bdata{align_ind-1}.BinTimes));
    current_leftbound   = -min(0,min(bdata{align_ind}.BinTimes)); % remember to SUBTRACT this!!!
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % potential to-do item: adjust this to allow overlapping PETHs to be,
    % quite literally, visually overlapping. As it stands, re-alignments
    % are marked as "breaks" in the graph, with no support for separate,
    % re-aligned traces that can overlap with one another. This can give
    % the impression that the re-aligned PETHs do not overlap with one
    % another (and therefore do not double-count spikes), when in fact,
    % they almost always DO overlap to some extent.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    center_vals(align_ind)  = center_vals(align_ind-1) + ...
        previous_rightbound + current_leftbound + EpochSpacing;
    left_bounds(align_ind)  = min(0,min(bdata{align_ind}.BinTimes)) + center_vals(align_ind);
    right_bounds(align_ind) = max(0,max(bdata{align_ind}.BinTimes)) + center_vals(align_ind);
end

%% now sort using the same code from the Raster plot

if isstr(SortFactor)
    sortvals = cell(2,1);
    unique_sortvals = cell(2,1);
    
    ltk_flag = false;
    if isstr(LevelsToKeep)
        if strcmpi(LevelsToKeep,'all')
            ltk_flag = true;
        else
        end
    end
    
    switch SortFactor
        case 'TrialType'
            sortvals{2} = TrialTypes;
            
            if ltk_flag
                unique_sortvals{2} = cellstr(unique(char(sortvals{2}),'rows'));
            else
                unique_sortvals{2} = LevelsToKeep;
            end
        case 'Object'
            sortvals{2} = ObjectNames;
            
            if ltk_flag
                unique_sortvals{2} = cellstr(unique(char(sortvals{2}),'rows'));
            else
                unique_sortvals{2} = LevelsToKeep;
            end
        case 'TurntableIndex'
            sortvals{2} = TurnTableIndices;
            
            if ltk_flag
                unique_sortvals{2} = unique(sortvals{2});
            else
                unique_sortvals{2} = LevelsToKeep;
            end
        case 'TrialIndex'
            sortvals{2} = ones(size(TurnTableIndices));
            
            if ltk_flag
                unique_sortvals{2} = unique(sortvals{2});
            else
                unique_sortvals{2} = {1};
            end
    end
    
    % we will always do two-factor sorting
    % here, we set the default to TrialIndex sorting
    sortvals{1}        = ones(size(TurnTableIndices));
    unique_sortvals{1} = {1};
    
elseif iscellstr(SortFactor)
    sortvals = cell(2,1);
    unique_sortvals = cell(2,1);
    for ii = 1:2
        
        ltk_flag = false;
        if isstr(LevelsToKeep)
            if strcmpi(LevelsToKeep,'all')
                ltk_flag = true;
            else
            end
        elseif iscell(LevelsToKeep)
            if isstr(LevelsToKeep{ii})
                if strcmpi(LevelsToKeep{ii},'all')
                    ltk_flag = true;
                else
                end
            else
            end
        else
        end
        
        switch SortFactor{ii}
            case 'TrialType'
                sortvals{ii} = TrialTypes;
                
                if ltk_flag
                    unique_sortvals{ii} = cellstr(unique(char(sortvals{ii}),'rows'));
                else
                    unique_sortvals{ii} = LevelsToKeep{ii};
                end
            case 'Object'
                sortvals{ii} = ObjectNames;
                
                if ltk_flag
                    unique_sortvals{ii} = cellstr(unique(char(sortvals{ii}),'rows'));
                else
                    unique_sortvals{ii} = LevelsToKeep{ii};
                end
            case 'TurntableIndex'
                sortvals{ii} = TurnTableIndices;
                
                if ltk_flag
                    unique_sortvals{ii} = unique(sortvals{ii});
                else
                    unique_sortvals{ii} = LevelsToKeep{ii};
                end
            case 'TrialIndex'
                sortvals{ii} = ones(size(TurnTableIndices));
                
                if ltk_flag
                    unique_sortvals{ii} = unique(sortvals{ii});
                else
                    unique_sortvals{ii} = {1};
                end
        end
    end
    
else
    error('something is wrong with SortFactor')
end

n_coarse_factors = numel(unique_sortvals{1});
n_fine_factors   = numel(unique_sortvals{2});

%% establish colors & line styles

if isempty(SortColors)

    SortColors = cell(n_coarse_factors,1);
    for ii = 1:n_coarse_factors
        SortColors{ii} = parula(n_fine_factors);
    end
        
elseif isnumeric(SortColors) && size(SortColors,1) == n_fine_factors && size(SortColors,2) == 3
    SC = cell(n_coarse_factors,1);
    
    for ii = 1:n_coarse_factors
        SC{ii} = SortColors;
    end
    
    SortColors = SC;
    
elseif iscell(SortColors) && numel(SortColors) == n_coarse_factors
    % pass
    % note here that this part supports selecting different color sets for
    % different 
else
    error('SortColors is not right')
end


if isempty(SortStyles)
    lstyles = {'-','--',':'};
elseif iscell(SortStyles)
    lstyles = SortStyles;
elseif isstr(SortStyles)
    lstyles = {SortStyles};
else
    error('SortStyles is not correct')
end

keepstyles = {};

currentind = 1;
for coarseind = 1:n_coarse_factors
    thisind = mod(currentind-1,numel(lstyles))+1;
    keepstyles = horzcat(keepstyles,lstyles(thisind)); %#ok<*AGROW>
    currentind = currentind + 1;
end

%% establish the figure handle
if nargout == 1
    h = gcf;
else
end 

%% we should now have everything we need to begin plotting

textspace_vertical   = 0.02;
textspace_horizontal = 0.02; % just gonna hard-code these in
                             % matlab is weirdly cagey about the default
                             % text offset between axis tick labels & the
                             % axis itself! Why?!?!? I'm basing 0.02 off a
                             % matlab exchange file that seems to pick it
                             % arbitrarily as a default... super weird

% use the same loop structure as the Raster plotting script
for coarse_level = 1:n_coarse_factors
    clors  = SortColors{coarse_level};
    styl   = keepstyles{coarse_level};
    
    for granular_level = 1:n_fine_factors
        clor = clors(granular_level,:);
        
        these_trials = ismember(sortvals{1},unique_sortvals{1}{coarse_level},'rows') & ...
            ismember(sortvals{2},unique_sortvals{2}{granular_level},'rows');
        
        FR_thesetrials = cellfun(@(x) x(:,these_trials),...
            FRdata,'uniformoutput',false);
        
        for align_ind = 1 %:numel(Alignment) % only do the first alignment for now...
            FR_thisalign = FR_thesetrials{align_ind};
            
            tvals         = bdata{align_ind}.BinTimes;
            tvals         = tvals + center_vals(align_ind);
            muFR          = mean(FR_thisalign,2);
            
            hold all
            plot(tvals,muFR,'linewidth',1,'linestyle',styl,...
                'color',clor);
        end
    end
end

%% plot legend
legend_cell = {};
legend_flag = true;

if n_coarse_factors == 1 && n_fine_factors == 1
    legend_flag = false; % don't plot a legend
else
    
    for coarse_ind = 1:n_coarse_factors
        coarsename = unique_sortvals{1}{coarse_ind};
        
        if isnumeric(coarsename)
            coarsename = num2str(coarsename);
        else
        end
        
        for granular_ind = 1:n_fine_factors
            granularname = unique_sortvals{2}{granular_ind};
            
            if isnumeric(granularname)
                granularname = num2str(granularname);
            else
            end
            
            if n_coarse_factors == 1
                legend_cell = vertcat(legend_cell,...
                    {granularname});
            elseif n_fine_factors == 1
                legend_cell = vertcat(legend_cell,...
                    {coarsename});
            else
                newname = [coarsename,': ',granularname];
                legend_cell = vertcat(legend_cell,...
                    {newname});
            end
        end
    end
end

if legend_flag
    legend(legend_cell,'location','northeastoutside')
    legend boxoff
else
    % pass
end

%% NOW plot the REST of the alignments
if numel(Alignment) > 1
    for coarse_level = 1:n_coarse_factors
        clors  = SortColors{coarse_level};
        styl   = keepstyles{coarse_level};
        
        for granular_level = 1:n_fine_factors
            clor = clors(granular_level,:);
            
            these_trials = ismember(sortvals{1},unique_sortvals{1}{coarse_level},'rows') & ...
                ismember(sortvals{2},unique_sortvals{2}{granular_level},'rows');
            
            FR_thesetrials = cellfun(@(x) x(:,these_trials),...
                FRdata,'uniformoutput',false);
            
            for align_ind = 2:numel(Alignment) % only do the first alignment for now...
                FR_thisalign = FR_thesetrials{align_ind};
                
                tvals         = bdata{align_ind}.BinTimes;
                tvals         = tvals + center_vals(align_ind);
                muFR          = mean(FR_thisalign,2);
                
                hold all
                plot(tvals,muFR,'linewidth',1,'linestyle',styl,...
                    'color',clor);
            end
        end
    end
else
    % pass
end

%% NOW plot error shading
if ~strcmpi(ErrorShadeMode,'none')
    for coarse_level = 1:n_coarse_factors
        clors  = SortColors{coarse_level};
        styl   = keepstyles{coarse_level};
        
        for granular_level = 1:n_fine_factors
            clor = clors(granular_level,:);
            
            these_trials = ismember(sortvals{1},unique_sortvals{1}{coarse_level},'rows') & ...
                ismember(sortvals{2},unique_sortvals{2}{granular_level},'rows');
            
            FR_thesetrials = cellfun(@(x) x(:,these_trials),...
                FRdata,'uniformoutput',false);
            
            for align_ind = 1:numel(Alignment)
                FR_thisalign = FR_thesetrials{align_ind};
                
                tvals         = bdata{align_ind}.BinTimes;
                tvals         = tvals + center_vals(align_ind);
                muFR          = mean(FR_thisalign,2);
                plotErrorFlag = true;
                
                switch ErrorShadeMode
                    case 'SEM'
                        spreadFR = std(FR_thisalign,0,2)./sqrt(size(FR_thisalign,2)); % remember to add the "0" as an argument to std! (I always fucking HATED that...)
                    case 'SD'
                        spreadFR = std(FR_thisalign,0,2);
                end
                
                hold all
                patch([tvals(:);flipud(tvals(:))],...
                    [muFR(:)+spreadFR(:);flipud(muFR(:)-spreadFR(:))],...
                    clor,'edgealpha',0,'facealpha',ErrorShadeAlpha)
                
            end
        end
    end
else
    % pass
end
 
%% and prettify this plot
box off, axis tight

xl = get(gca,'xlim');
yl = get(gca,'ylim');

ylabel('Firing rate (Hz)')

% axis labels & scale bar
if ~PlotScaleBar && iscellstr(Alignment) && numel(Alignment) > 1
    error('Alignment and PlotScaleBar inputs are incompatible! Multi-alignment plots require the scale bar to be plotted!')
elseif ~PlotScaleBar
    if iscellstr(AlignmentNames)
        xlabel(sprintf('Time from %s (ms)',AlignmentNames{1}))
    elseif isstr(AlignmentNames) && ~iscell(AlignmentNames)
        xlabel(sprintf('Time from %s (ms)',AlignmentNames)) %#ok<PFCEL>  % ah. this is actually inaccessible due to an earlier input where Alignment is forcibly converted into a 1-element cell array of strings. oh well, let's keep it for completeness.
    else
        error('Alignment or AlignmentNames is an invalid type')
    end
elseif PlotScaleBar % if plotting the scale bar, you don't need an x axis per se
    set(gca,'xtick',center_vals,'xticklabel',AlignmentNames,...
        'xticklabelrotation',45,'ticklabelinterpreter','none')
    
    is_top    = ~isempty(regexpi(ScaleBarLocation,'top','once'));
    is_bottom = ~isempty(regexpi(ScaleBarLocation,'bottom','once'));
    is_left   = ~isempty(regexpi(ScaleBarLocation,'left','once'));
    is_right  = ~isempty(regexpi(ScaleBarLocation,'right','once'));
    
    if is_top
        ypos_line   = min(yl) + (1+textspace_vertical)*range(yl);
        ypos_text   = min(yl) + (1+textspace_vertical)*range(yl);
        textal_vert = 'bottom';
    elseif is_bottom
        ypos_line   = max(yl) - (1+textspace_vertical)*range(yl);
        ypos_text   = max(yl) - (1+textspace_vertical)*range(yl);
        textal_vert = 'top';
    else
        warning('unrecognized vertical position. defaulting to "top".')
        ypos_line   = min(yl) + (1+textspace_vertical)*range(yl);
        ypos_text   = min(yl) + (1+textspace_vertical)*range(yl);
        textal_vert = 'bottom';
        is_top = true;
    end
    
    if is_left
        xpos_line1  = min(xl);
        xpos_line2  = min(xl) + ScaleBarDuration;
        xpos_text   = min(xl);
        textal_horz = 'left';
    elseif is_right
        xpos_line1  = max(xl)-ScaleBarDuration;
        xpos_line2  = max(xl);
        xpos_text   = max(xl);
        textal_horz = 'right';
    else
        xpos_line1  = median(xl)-ScaleBarDuration/2;
        xpos_line2  = median(xl)+ScaleBarDuration/2;
        xpos_text   = median(xl);
        textal_horz = 'center';
    end
    
    % 2pt black line for the scale bar
    hold all
    line([xpos_line1,xpos_line2],ypos_line*[1 1],...
        'linewidth',2,'color',[0 0 0],'linestyle','-')
    
    % and add the text underneath
    text(xpos_text,ypos_text,sprintf('%i ms',ScaleBarDuration),...
        'fontsize',8,'fontname','helvetica','horizontalalign',textal_horz,...
        'verticalalign',textal_vert,'color',[0 0 0])
    
    axis tight
    
    yl_ = get(gca,'ylim');
    
    if is_bottom
        ylim([yl_(1),yl(2)])
    elseif is_top
        ylim([yl(1),yl_(2)])
    end
    
end

xl = get(gca,'xlim');
yl = get(gca,'ylim');

% NOW draw alignments
if DrawAlignment
    % for each event name
    for event_ind = 1:numel(Alignment)
        left_wing      = left_bounds(event_ind);
        right_wing     = right_bounds(event_ind);
        overall_center = center_vals(event_ind);
        
        % black 1pt line at each alignment
        hold all
        line(overall_center*[1 1],yl,'linewidth',1,'linestyle','-','color',[0 0 0])
        
        % gray 0.5pt lines at each bound
        hold all
        line(left_wing*[1 1],yl,'linewidth',0.5,'linestyle','-','color',[0.5 0.5 0.5])
        hold all
        line(right_wing*[1 1],yl,'linewidth',0.5,'linestyle','-','color',[0.5 0.5 0.5])
    end
else
end

% remove the background, too
set(gca,'color','none')

% finally, place some separation between the y axis and the epoch divider
new_xmin = -textspace_horizontal*range(xl) + min(xl);
xlim([new_xmin,max(xl)])

end