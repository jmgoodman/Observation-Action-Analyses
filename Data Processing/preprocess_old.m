function preprocesseddata = preprocess(obj,varargin)

%dPCA_for_MirrorData handles pre-processing for and computation of dPCA when applied to MirrorData.
%NOTE: this requires the MirrorData folder to be on the current path to function properly! So make sure to put it on your path in the script you write to call this function!
%
%DESCRIPTION
%   This routine aligns neural data and smooths them to obtain firing rates
%
%SYNTAX
%   outstruct = PlotRaster(obj,varargin)
%
%   outstruct   ... struct containing pre-processing and dPCA results
%   indata      ... MirrorData object, or pre-processed output of a previous call of dPCA_for_MirrorData.
%   varargin    ... Inputs specified in name-value pairs that could include
%   the following:
%       removebaseline          ... true or false. if true, removes baseline firing rates. Default is true.
%       sigma                   ... in ms, the gaussian smoothing parameter. default is 50.
%       alignments              ... names of alignments to include.
%       alignment_realnames     ... names of alignments to use in the output
%       windows                 ... cell of 1 x 2 vectors specifying the beginning and end of bins, with 0 for each bin centered on each alignment.
%       samplingrate            ... in Hz, sampling rate of binning. default is 100.
%       smoothingwindowsize     ... in ms, the width of the window occupied by the gaussian smoothing window. default is 500.
%       normalize               ... true or false. if true, soft-normalize the firing rates. default is true.
%       
%
%AUTHOR
%   Written for MirrorData by James Goodman, 2020 July 22, DPZ

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFAULT PARAMETER BOX

alignments             = {'fixation_achieve_time','cue_onset_time','cue_onset_time','go_phase_start_time','movement_onset_time','hold_onset_time','reward_onset_time'};
alignment_realnames    = alignments;
alignment_realnames{3} = 'cue_offset_time';

wingwidth      = 500;
Wins           = {    [-1,1]*wingwidth,          [-1,1]*wingwidth,   [-1,1]*wingwidth+700,        [-1,1]*wingwidth,      [-1,1]*wingwidth,          [-1,1]*wingwidth,      [-1,1]*wingwidth   };
sr             = 100; % 10ms bins
sws            = 500;
sigma          = 50; % gaussian width parameter
removebaseline = true;
normalizeflag  = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% PARSE VARARGIN
fnames = varargin(1:2:end);
fvals  = varargin(2:2:end);

for ii = 1:numel(fnames)
    fname = fnames{ii};
    fval  = fvals{ii};
    
    switch fname
        case 'removebaseline'
            removebaseline = fval;
        case 'sigma'
            sigma = fval;
        case 'alignments'
            alignments = fval;
        case 'alignment_realnames'
            alignment_realnames = fval;
        case 'windows'
            Wins = fval;
        case 'samplingrate'
            sr = fval;
        case 'smoothingwindowsize'
            sws = fval;
        case 'normalize'
            normalizeflag = fval;
        otherwise
            warning('invalid parameter name %s',fname)
    end 
end


% set up bins for the smoothing window
dt = 1000/sr; % in milliseconds
tv = (0+dt/2):dt:(sws-dt/2);
tv = tv - median(tv);




% grab event times
Etimesmat = [];

for alignind = 1:numel(alignments)
    etimes = arrayfun(@(x) x.(alignments{alignind}),obj.Event);
    
    if strcmpi( alignment_realnames{alignind},'cue_offset_time' )
        etimes = etimes + 700; % cue offset time, even where it isn't normally available (i.e., VGG)
    else
    end
    
    Etimesmat = horzcat(Etimesmat,etimes); %#ok<*AGROW>
end




tic
Activity_SpikeCounts = cell(6,1);
gv = exp( -tv.^2 ./ (2*sigma^2) );
gv = gv(:)./sum(gv);
% M1med, M1lat, F5med, F5lat, AIPmed, AIPlat
for ii = 1:6
    switch ii
        case 1
            arnames = {'M1-med'};
        case 2
            arnames = {'M1-lat'};
        case 3
            arnames = {'F5-med'};
        case 4
            arnames = {'F5-lat'};
        case 5
            arnames = {'AIP-med'};
        case 6
            arnames = {'AIP-lat'};
    end
    
    try
        Allunitinds = arrayfun(@(x) ~x.is_bad_unit & ismember(x.array,arnames),...
            obj.Neural); % exclude the "bad" units...
    catch % if no "bad units" field
        Allunitinds = arrayfun(@(x) ismember(x.array,arnames),...
            obj.Neural);
    end
    
    AllunitIDs  = arrayfun(@(x) [x.channelID,x.unitID],...
        obj.Neural(Allunitinds),'uniformoutput',false);
    AllunitIDs  = vertcat(AllunitIDs{:});
    
    MultiAlignCell = cell(numel(alignments),1);
    for jj = 1:numel(alignments)
        tempaligncell = obj.BinData('Alignment',alignments{jj},'Window',Wins{jj} + [-sws/2,sws/2],...
            'BinSize',10,'Neuron',AllunitIDs);
        
        % smooth to obtain firing rate estimates
        for kk = 1:size(tempaligncell.Data,3)
            dtemp = tempaligncell.Data(:,:,kk);
            dsmooth = conv2(dtemp,gv,'same')./conv2(ones(size(dtemp)),gv,'same');
            tempaligncell.Data(:,:,kk) = dsmooth;
        end
        
        % multiply by sampling rate to convert from spikes/bin to spikes/s
        tempaligncell.Data = tempaligncell.Data * sr;
        
        % now slice off everything outside the target windows
        keeptimes = tempaligncell.BinTimes >= Wins{jj}(1) & tempaligncell.BinTimes <= Wins{jj}(2);
        keepedges = tempaligncell.BinEdges >= Wins{jj}(1) & tempaligncell.BinEdges <= Wins{jj}(2);
        
        tempaligncell.Data     = tempaligncell.Data(keeptimes,:,:);
        tempaligncell.BinTimes = tempaligncell.BinTimes(keeptimes);
        tempaligncell.BinEdges = tempaligncell.BinEdges(keepedges);
        
        for realalignind = 1:numel(alignment_realnames)
            relativealigntimesstruct.(alignment_realnames{realalignind}) = ...
                Etimesmat(:,realalignind) - Etimesmat(:,jj);
        end
        
        tempaligncell.RelativeTimingsOfOtherAlignments = relativealigntimesstruct;
        
        if strcmpi( alignment_realnames{alignind},'cue_offset_time' ) % hard-coded exception for cue OFFset timing
            tempaligncell.BinTimes  = tempaligncell.BinTimes - 700;
            tempaligncell.BinEdges  = tempaligncell.BinEdges - 700;
            tempaligncell.Alignment = 'cue_offset_time';
        else
            tempaligncell.Alignment = alignments{jj};
        end
        
        MultiAlignCell{jj} = tempaligncell;
        toc
    end
    
    % now go thru and soft-normalize
    if normalizeflag
        dvals = cellfun(@(x) x.Data,MultiAlignCell,'uniformoutput',false);
        dcat  = vertcat(dvals{:});
        dperm = permute(dcat,[2,1,3]); % neuron x time x trial
        dflat = dperm(:,:)'; % get neuron back in the columns
        
        % these are already in Hz
        maxrates = max(dflat); %#ok<UDIM>
        
        softmaxrates = maxrates + 5; % add 5 Hz
        
        dnormalized  = cellfun(@(x) bsxfun(@times,x,1./softmaxrates),dvals,'uniformoutput',false);
        
        for cellind = 1:numel(dnormalized)
            MultiAlignCell{cellind}.Data = dnormalized{cellind};
        end
    else
        % pass
    end
    
    Activity_SpikeCounts{ii} = MultiAlignCell;
end
    

% now go thru and subtract baselines
if removebaseline
    
    % find the "fixation" epoch
    Activity_SpikeCountsTemp = Activity_SpikeCounts;
    for ii = 1:numel(Activity_SpikeCounts)
        ASC = Activity_SpikeCounts{ii};
        
        anames = cellfun(@(x) x.Alignment,ASC,'uniformoutput',false);
        
        has_fix = cellfun(@(x) ~isempty(regexpi(x,'fixat','once')),anames);
        
        % assume the first index is the earliest one
        has_fix = find(has_fix,1,'first');
        
        if ~isempty(has_fix)
            ASCfix = ASC{has_fix};
            
            ttinds = floor(ASCfix.TurnTableIDs/10);
            taskconds = ASCfix.TrialTypes;
            
            [utt,~,utti] = unique(ttinds);
            [utc,~,utci] = unique(char(taskconds),'rows');
            
            prefixationbins = ASCfix.BinTimes < 0;
            
            ASCtemp = ASC;
            for ttidx = 1:numel(utt) % for each TT and task context, assign a unique baseline (pre-fixation) firing rate and subtract it out
                for tcidx = 1:size(utc,1)
                    thesetrials = utti == ttidx & utci == tcidx;
                    
                    SCdata = ASCfix.Data(prefixationbins,:,thesetrials);
                    FRBL   = mean(mean(SCdata,1),3);
                    
                    for jj = 1:numel(ASCtemp)
                        ASCtemp{jj}.Data(:,:,thesetrials) = bsxfun(@minus,ASCtemp{jj}.Data(:,:,thesetrials),FRBL);
                    end
                end
            end
            
            Activity_SpikeCountsTemp{ii} = ASCtemp;
                
            
        else
            warning('no fixation epoch! cannot subtract baseline!')
        end
        
    end
    
    Activity_SpikeCounts = Activity_SpikeCountsTemp;    
    
else
    % pass
end


preprocesseddata = Activity_SpikeCounts;