function obj = ReadNeural(obj,varargin)

%READNEURAL Imports and parses data from spike sorted neural data files
%
%DESCRIPTION
%   This routine imports the spike timing and waveform data from an
%   appropriately organized Wave_Clus folder of a desired session. One must
%   first import the .sev files of a TDT recording or the .nev files of a
%   Blackrock recording, apply spike sorting, and dump the resulting data
%   with the appropriate organization that Ben's Wave_Clus program spits out 
%   before they can use this script (a MirrorData-native method for performing these
%   prerequisite steps is forthcoming as of 2020.02.03). This method is
%   planned to be hidden, with a single overarching data import method in
%   the works (to be implemented in the future). Hopefully, the future also
%   portends integration with the Wave_Clus spike sorter so that, instead
%   of having to first sort your spikes and THEN run this script, you can
%   just run this script and have it call the spike sorter if you have yet
%   to do that step (with sanity-checking and steps such as merging units
%   performed automatically as well. Make MirrorData your one-stop-shop for
%   all this low-level data processing crap!)
%
%SYNTAX
%   obj = ReadBehaviour(obj,varargin)
%
%   obj         ... MirrorData object
%   varargin    ... Inputs specified in name-value pairs that could include
%   the following:
%       'LoadPath'                  ... Full path specifying location of
%       folder containing all your dataspikes files. Default value is empty. 
%       If empty, a user interface guides the selection of the folder.
%       'SaveFile'                  ... Full path of file being saved. Default value is an
%       empty array. If empty, a user interface guides file selection. Saved file contains the
%       updated MirrorData object.
%       'SNR'                       ... Positive scalar that specifies the SNR
%       threshold for a unit to save in the MirrorData structure. Default
%       value is 5 (the Rose criterion). SNR is defined here as the ratio
%       of the peak-to-peak amplitude of the mean waveform against the
%       standard deviation of the noise (computed using the method of
%       plus-minus averaging). Note that this criterion is already applied
%       by Ben's code to the raw voltage traces, so it's unlikely that this
%       criterion will cull anything beyond what has already been culled.
%       'MinSpikeCount'             ... Nonnegative integer that specifies the minimum
%       number of spikes a unit must have to be saved in the MirrorData
%       structure. Default value is 1000.
%       'AmplitudeThreshold'        ... Positive scalar that specifies the
%       minimum peak-to-peak threshold a (mean) waveform should have to be counted
%       as such (in microvolts). Default value is 80.
%       'DisqualifyPositive'        ... Logical that specifies whether or
%       not to immediately disqualify any waveforms whose positive
%       deflections are their main source of signal power. Default value is true.
%       'ShapeThreshold'            ... Positive scalar that specifies how
%       many times more likely each inter-spike interval is to have been
%       drawn from a Gamma distribution than from a Gaussian. Default
%       value is 1.1 (10% more likely). Note that this threshold is in 
%       terms of the typical ISI's likelihood, rather than the likelihood 
%       of the entire distribution of ISIs. We actually don't like Gaussian
%       ISI distributions because highly peaked ISI distributions could be
%       some artifact. (That said, we don't like exponential distributions
%       because they imply multi-units, but that's different from "totally
%       not signal at all", but rather "cruddy signal that we could keep if
%       we wanted to". Consider adding an option for gamma-vs-exponential
%       distribution testing as well, to allow users to test for & filter
%       by SUA).
%       'TargetChannels'            ... Vector of positive integers that
%       specify the names of the channels to be loaded. Default value is
%       empty. If empty, ReadNeural defaults to reading ALL channels.
%       Specify TargetChannels to save time and avoid loading channels that
%       are known to be poor / known not to have a unit.
%       'KeepWaveForms'             ... logical value indicating whether or
%       not to keep waveform shapes. Default is 'false' to save memory (by
%       a factor of, like, 100, so it's totally worth it in 99% of cases).
%       When 'false', the "waveforms" field, which would normally be
%       populated by all the individual waveforms, is replaced by a 2x128
%       matrix where the first row is the mean waveform and the second is
%       the standard deviation at each sample time across waveforms.
%       'ObjectName'                ... String that specifies the variable
%       name given to the updated MirrorData object when saving it to file.
%       Default is 'MirrorObj'.
%       'ShouldSave'                ... Logical value that determines
%       whether or not to attempt to save an updated version of the struct
%       to file. Default is true.
%       'Version'                   ... string that reads "normal" or "autosort".
%       The latter is for when you want to work with pre-sorted neural data processed by Stefan. 
%       The former for when you want to use your own spike sorts.
%
%
%EXAMPLE
%   MyMirror =
%   ReadNeural(MyMirror,'LoadPath','/Users/Me/MyMirror/Wave_Clus','SaveFile',...
%       '/Users/Me/MyMirror/MyMirror.mat');
%
%AUTHOR
%   written for MirrorData by James Goodman, 2020 January 02, DPZ
%   edited by James Goodman, 2020 February 03, DPZ, to handle a directory
%   full of "dataspikes" files rather than a "Wave_Clus" directory with
%   subdirectories for each channel
%   (should edit again to permit reading in the old version of the
%   "Wave_Clus" data, for past sessions in which that old automatic spike
%   sorter was run!)

%% step 1: parse the inputs
assert(mod(numel(varargin),2)==0,'Wrong number of inputs: must come in name-value pairs')

pNames = varargin(1:2:(end-1));
pVals  = varargin(2:2:end);

% establish default values
LoadPath         = [];
SaveFile         = [];
SNR_             = 5;
MinSpikeCount    = 1000;
AmpThreshold     = 80;
DQpositive       = true;
ShapeThresh      = 1.1;
TargetChannels   = [];
Obj_name         = 'MirrorObj';
ShouldSave       = true;
kwf              = false;
version_         = 'normal';




for name_ind = 1:numel(pNames)
    pName = pNames{name_ind};
    pVal  = pVals{name_ind};
    
    if strcmpi(pName,'LoadPath')
        LoadPath = pVal;
        
        % assert that the input is a string
        %         assert(ischar(LoadPath) | isempty(LoadPath),'LoadPath must be a string specifying the full location of the WaveClus folder (including the /WaveClus at the end)!')
        assert(ischar(LoadPath) | isempty(LoadPath),'LoadPath must be a string specifying the full location of the folder containing your spike-sorted data files!')
        
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
    
    elseif strcmpi(pName,'KeepWaveForms')
        kwf = pVal;
        assert(islogical(kwf),'KeepWaveForms must be a logical (true/false) value that specifies whether or not to keep spike waveforms!')
        
    elseif strcmpi(pName,'Version')
        version_ = pVal;
        assert(ischar(version_),'Version must be a string that reads "normal" or "autosort"!')

        
    else
        warning('%s is not a valid input name. ignoring this name-value pair.',pName)
    end
end

%% step 2: specify the path containing all the sorted waveforms, then load in the data files

switch version_
    case 'normal'
        
        if ~isempty(LoadPath)
        else
            path_ = uigetdir([],'Find desired folder containing dataspikes files');
            
            if isnumeric(path)
                error('No path selected, cannot continue')
            else
                LoadPath = path_;
            end
        end
        
        
        % load in the neural data files
        
        
        D               = dir(LoadPath);
        % istarget        = arrayfun(@(x) x.isdir & ~isempty(regexpi(x.name,'^Channel(\d)+$','once')),D);
        istarget        = arrayfun(@(x) ~isempty(regexpi(x.name,'^dataspikes_ch(\d)+_(pos|neg)thr.mat$','once')),D);
        Dtarg           = D(istarget);
        channel_numbers = arrayfun(@(x) str2double(regexpi(x.name,'(\d)+','match')),Dtarg);
        
        % if TargetChannels is empty, set it to be equal to channel_numbers
        if isempty(TargetChannels)
            TargetChannels = channel_numbers;
        else
        end
        
        % see if any target channels are not included in channel_numbers, and if
        % so, issue a warning
        are_channels = ismember(TargetChannels,channel_numbers);
        
        if any(~are_channels)
            bad_channel_nums = TargetChannels(~are_channels);
            input_string = '';
            for invalid_channel_index = 1:numel(bad_channel_nums)
                bad_channel_ind = bad_channel_nums(invalid_channel_index);
                input_string = horzcat(input_string,num2str(bad_channel_ind));
                
                if invalid_channel_index < (numel(bad_channel_nums)-1)
                    input_string = horzcat(input_string,', ');
                elseif invalid_channel_index == (numel(bad_channel_nums)-1) && numel(bad_channel_nums) == 2
                    input_string = horzcat(input_string,' and ');
                elseif invalid_channel_index == (numel(bad_channel_nums)-1) && numel(bad_channel_nums) > 2
                    input_string = horzcat(input_string,', and ');
                end
            end
            
            if numel(bad_channel_nums) == 1
                warning('Channel %s is not valid and will therefore not be imported.',input_string);
            elseif numel(bad_channel_nums) > 1
                warning('Channels %s are not valid and will therefore not be imported.',input_string);
            end
            
            TargetChannels(~are_channels) = [];
        else
        end
        
        % sort TargetChannels
        TargetChannels = sort(TargetChannels(:),'ascend');
        
        spike_info      = cell(size(TargetChannels));
        n_channels      = numel(channel_numbers);
        
        tic
        fprintf('Loading neural data from %i channels.\nThis can take a while, so be patient: ',numel(TargetChannels))
        dotcounter  = 38;
        for ii = 1:n_channels
            clear wf_data st_data
            
            if ~ismember(channel_numbers(ii),TargetChannels) % skip non-target channels
                continue
            else
            end
            
            %     current_channel_dir = fullfile(LoadPath,Dtarg(ii).name);
            %     Dtemp = dir(current_channel_dir);
            %
            %     waveform_file_ind   = find(arrayfun(@(x) ~isempty(regexpi(...
            %         x.name,'(?<!times).*Ch(\d)+','once')),Dtemp),1,'first');
            %     spiketime_file_ind  = find(arrayfun(@(x) ~isempty(regexpi(...
            %         x.name,'(?<=times).*Ch(\d)+','once')),Dtemp),1,'first');
            %
            %     waveform_file_name  = Dtemp(waveform_file_ind).name;
            %     spiketime_file_name = Dtemp(spiketime_file_ind).name;
            %
            %     wf_data = load(fullfile(current_channel_dir,waveform_file_name));
            %     pause(0.001)
            %
            %     st_data = load(fullfile(current_channel_dir,spiketime_file_name));
            %     pause(0.001)
            
            current_channel_file = fullfile(LoadPath,Dtarg(ii).name);
            wf_data              = load(current_channel_file);
            pause(0.001)
            st_data              = wf_data;
            pause(0.001)
            
            
            % cluster 0 = no spike
            % check the other clusters for their waveforms
            nclusters = max(st_data.cluster_class(:,1));
            
            this_channel = cell(nclusters,1);
            
            for jj = 1:nclusters
                this_waveform = st_data.cluster_class(:,1) == jj;
                these_spikes  = wf_data.spikes(this_waveform,:);
                
                % create a struct
                clear tempstruct
                tempstruct.waveforms    = these_spikes;
                tempstruct.spiketimes   = st_data.cluster_class(this_waveform,2);
                tempstruct.channelID    = channel_numbers(ii);
                tempstruct.unitID       = jj;
                
                % and insert it into the cell
                this_channel{jj} = tempstruct;
            end
            
            % find location of channel number in the sorted TargetChannels vector
            % alternatively, just let the metadata do the talking for you
            ind_to_fill             = ii; %find(channel_numbers(ii) == TargetChannels,1,'first');
            spike_info{ind_to_fill} = this_channel;
            
            dotcounter = dotcounter + 1;
            if dotcounter <= 100
                fprintf('.')
            else
                fprintf('\n.')
                dotcounter = 1;
            end
        end
        telapsed = toc;
        fprintf('\nCompleted loading data. Elapsed time: %i seconds\n',round(telapsed))
        
        
    case 'autosort'
        
        % ignore the path input, go straight to user input
        [ff_,pp_] = uigetfile('','Find desired file containing the spkobj with the sorted waveforms');

        if isnumeric(ff_) || isnumeric(pp_)
            error('No path selected, cannot continue')
        else
            LoadPath = fullfile(pp_,ff_);
        end
        
        %         if ~isempty(LoadPath)
        %         else
        %             [ff_,pp_] = uigetfile('','Find desired file containing the spkobj with the sorted waveforms');
        %
        %             if isnumeric(ff_) || isnumeric(pp_)
        %                 error('No path selected, cannot continue')
        %             else
        %                 LoadPath = fullfile(pp_,ff_);
        %             end
        %         end
        
        load(LoadPath)
        channelinds = unique(SPK.channelID);
        n_channels  = numel(channelinds);
        
        spike_info      = cell(0,1);
        
        for ii = 1:n_channels
            thischannel = channelinds(ii);
            
            thischaninds = SPK.channelID == thischannel;
            
            % cluster 0 = no spike
            % check the other clusters for their waveforms
            theseclusters = SPK.sortID(thischaninds);
            thesewf       = SPK.waveforms(thischaninds,:);
            thesest       = SPK.spiketimes(thischaninds) * 1000; % convert from s to ms, as the "auto-sorted" files save spike times in SECONDS! ughhhh this is annoying
            nclusters     = max(theseclusters);
            
            this_channel = cell(nclusters,1);
            
            for jj = 1:nclusters
                this_cluster  = theseclusters == jj;
                this_wf       = thesewf(this_cluster,:);
                this_st       = thesest(this_cluster,:);
                
                % create a struct
                clear tempstruct
                tempstruct.waveforms    = this_wf;
                tempstruct.spiketimes   = this_st;
                tempstruct.channelID    = thischannel;
                tempstruct.unitID       = jj;
                
                % and insert it into the cell
                this_channel{jj} = tempstruct;
            end
            
            ind_to_fill             = ii;
            spike_info{ind_to_fill} = this_channel;
        end
        
        spike_info = spike_info(:);
        
    otherwise
        % pass
end
        

%% step 4: start evaluating each unit's waveforms for signs of being fishy

% SNR_             = 4;
% MinSpikeCount    = 1000;
% AmpThreshold     = 80;
% DQpositive       = true;
% ShapeThresh      = 2;

% question: do we disqualify on a waveform-by-waveform basis?
% answer: probably not, and if we do, the thresholds better be ultra
% conservative to avoid "sculpting" units.
%
% Yeah, the more I think about it, the more I realize that going
% waveform-by-waveform is a stupid fucking idea. Separating waveforms from
% noise needs to happen at the SPIKE SORTING phase. This is just QA!
%
% checking for units that are erroneously split, however, should NOT just
% be left to the spike-sorting phase. there are sooooo many ways that we
% can see "ghosts" during that process, we really should have an objective
% way to re-merge units from the same channel that are not substantially
% different in terms of waveform shape. I wanted to do a classification
% criterion, but this turns out to be way too sensitive. Alignment of
% waveforms via cross-correlation prior to classification is probably the
% ticket, I'll have to try it sometime. Regardless, such classification
% methods take a long time to run, and I need to work out this & other
% kinks before it's ready for action. As such, no double-checking of
% whether separate units from the same channel are indeed separate is yet
% implemented.

clear kept_units
for channel_ind = 1:numel(spike_info)
    si = spike_info{channel_ind};
    
    for unit_ind = 1:numel(si)
        wf = si{unit_ind}.waveforms;
        st = si{unit_ind}.spiketimes;
        
        % test 1: spike count
        % if spike count is not up to snuff, discard this unit
        if numel(st) < MinSpikeCount
            continue
        else
        end
        
        % test 2: amplitude
        mu_wf = mean(wf);
        amp_val = range(mu_wf); % peak-to-peak
        
        % if amplitude is not up to snuff, discard this unit
        if amp_val < AmpThreshold
            continue
        else
        end
        
        % test 3: positive waveform
        % if it's a positive waveform and the switch to exclude them is on,
        % discard this unit
        overall_mu = median(mu_wf); % compute w.r.t. the median rather than the mean
        maxneg = min(mu_wf - overall_mu);
        maxpos = max(mu_wf - overall_mu);
        
        if maxpos > (-maxneg) && DQpositive
            continue
        else
        end
        
        % test 4: SNR
        even_ind = floor(size(wf,1)/2)*2;
        wf_even_number = wf(1:even_ind,:);
        
        % use sturge's rule to keep CPU cycles under control (even though that's a method for selecting histogram bin counts and not... uh, iteration counts for bootstrapping)
        Niter = round(1 + log2(even_ind));
        
        pp_avg = mean(wf_even_number);
        pm_avg = zeros(Niter,size(pp_avg,2));
        
        for iter_ind = 1:Niter
            neg_inds = randperm(even_ind,even_ind/2);
            pos_inds = setdiff(1:even_ind,neg_inds);
            
            wfpos = wf_even_number(pos_inds,:);
            wfneg = -wf_even_number(neg_inds,:);
            
            pm_avg_thisiter = mean(vertcat(wfpos,wfneg));
            pm_avg(iter_ind,:) = pm_avg_thisiter;
        end
        
        std_ppavg = std(pp_avg(:)); % std(signal) + std(noise)/sqrt(N)
        std_pmavg = std(pm_avg(:)); % std(noise)/sqrt(N)
        
        % signal std turns out not to be anywhere remotely close to
        % sensitive enough (although the fact that it's a threshold
        % crossing already suggests that peak-to-peak measures are
        % worthless; after all, checking peak-to-peak against noise has
        % ALREADY BEEN DONE!!!)
        signal_std = sqrt(std_ppavg^2 - std_pmavg^2); % admittedly, you "Averaged away" most of the noise variance; this gets rid of the last remaining bit. Follows rules of variance addition/subtraction (hence the root-sum-squares approach).
        noise_std  = std_pmavg * sqrt(even_ind); % undo the "Averaging away"
        
        SNRval = amp_val / noise_std; % the expected contribution of the noise to the peak-to-peak amplitude is 0. It is just as likely to hurt as to help it.
        
        % if SNR value is not up to snuff, discard this unit
        if SNRval < SNR_
            continue
        else
        end
        
        % test 5: ISI distribution
        isivals = diff(st);
        isivals = double(isivals);
        
        % fit a gamma distribution
        gammahat = gamfit(isivals);
        NLLgamma = gamlike(gammahat,isivals);
        
        % fit a gaussian distribution
        [muhat,sigmahat]  = normfit(isivals);
        NLLnorm           = normlike([muhat,sigmahat],isivals);
        
        % log likelihood ratio: LLgamma - LLnorm
        % express in per-ISI terms
        LLR = -(NLLgamma - NLLnorm) / numel(isivals);
        
        % if this ratio is below the threshold, discard this unit
        if LLR < log(ShapeThresh)
            continue
        else
        end
        
        clear tempstruct
        tempstruct                                 = si{unit_ind};
        tempstruct.SpikeCount                      = numel(st);
        tempstruct.PeakToPeakAmplitudeInMicrovolts = amp_val;
        tempstruct.NegativePhaseAmplitude          = -maxneg;
        tempstruct.PositivePhaseAmplitude          = maxpos;
        tempstruct.SNR                             = SNRval;
        tempstruct.SignalStandardDeviation         = signal_std;
        tempstruct.NoiseStandardDeviation          = noise_std;
        tempstruct.GammaVersusGaussianLLR_PerISI   = LLR;
        tempstruct.array                           = []; % to be filled in later with metadata from ImportData
        
        % go thru and change the waveforms field of tempstruct if kwf is false
        if ~kwf
            tempstruct.waveforms = ...
                [mean(tempstruct.waveforms);...
                std(tempstruct.waveforms)]; % note that this is std and not sem
        else
        end
        
        % all tests have been passed: keep this unit
        if exist('kept_units','var')
            kept_units = vertcat(kept_units,tempstruct);
        else
            kept_units = tempstruct;
        end
    end
end

%% now that you've included positive waveform files, go thru and fix the unitID numbers so EVERY unit has a unique ID!
% this messes with their correspondence with the spike-sorted values,
% however. Just be sure to check the relative heights of the positive and
% negative halves of the waveform and know that the positive waveforms
% start counting AFTER the last negative one. So positive waveform #1
% becomes channel X unit 6 if channel X already had 5 negative waveforms (unless some units were "skipped" for not satisfying amplitude or spike count thresholds...)

CID  = arrayfun(@(x) x.channelID,kept_units);
uCID = unique(CID);

for ii = 1:numel(uCID)
    these_neurs = find(CID == uCID(ii));
    these_UID   = (1:numel(these_neurs))';
    
    for jj = 1:numel(these_neurs)
        kept_units( these_neurs(jj) ).unitID = ...
            these_UID(jj);
    end
end
        
%% now, if there's anything present in "event", let's bin spike times
% otherwise, leave well enough alone

obj.Neural = kept_units;

if ~isempty(obj.Event)
    % place here a call to a function that bins spike counts
    % you will also want to call it at the end of ReadBehavioural (and
    % ReadKinematic)
else
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
        

%% TODO:
% implement a way to read raw data streams from the .sev files or the
% unsorted event waveforms from the .tev file.
%
% you might want to accomplish this with an entirely different function, in
% fact, to distinguish it from a procedure that reads in already-sorted
% data.
%
% a function that incorporates a spike-sorting (and, in the case of reading
% the raw data stream, waveform-detection) routine! Likely by bringing
% Wave_Clus into your folder & simply calling that (the way you're trying
% to make KinemaTracks & Opensim work for processing the kinematics).









end