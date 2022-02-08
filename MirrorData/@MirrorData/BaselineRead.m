function BaselineRead(obj,rawdir,varargin)

%BASELINEREAD Takes raw data from each channel and estimates the baseline level of noise

%DESCRIPTION
%   Between conditions (e.g., active and passive), there may well have been different noise levels.
%   To help detect & account for this, this script allows one to determine how much noise,
%   in terms of standard deviation in uV, each channel has in each type of block of trials.
%   This script saves the results as .mat files
%
%SYNTAX
%   baseline_stats = BaselineRead(obj,rawfile,varargin)
%   obj                 ... MirrorData object
%   rawdir              ... directory containing the .sev and spike sorted .mat files.
%   varargin            ... Inputs specified in name-value pairs that could include the following:
%       'Method'             ... Accepts a string or cell array of strings of 'between-nofilter','between-filter','between-filter2','plus-minus',and 'all'.
%                                Default is 'all'.
%
%EXAMPLE
%   MyBaseline = BaselineRead(MyMirror,'My/Path/','between')
%
%AUTHOR
%   written for MirrorData by James Goodman, 2020 May 25, DPZ

%% step 1: parse the inputs

assert(mod(numel(varargin),2)==0,'Wrong number of inputs: must come in name-value pairs')

pNames = varargin(1:2:(end-1));
pVals  = varargin(2:2:end);

% establish default values
TypeOfBaseline = {'all'};

% settings
modes_cell = {'between-nofilter','between-filter','between-filter2','plus-minus','all'};

for name_ind = 1:numel(pNames)
    pName = pNames{name_ind};
    pVal  = pVals{name_ind};
    
    if strcmpi(pName,'Method')
        TypeOfBaseline = pVal;
        
        assert(ischar(TypeOfBaseline) | iscellstr(TypeOfBaseline),...
            'Mode must be a string or cell array of strings reading ''between-nofilter'',''between-filter'',''plus-minus'',or ''all''!') %#ok<ISCLSTR>
        
        if ischar(TypeOfBaseline) && ~iscellstr(TypeOfBaseline) %#ok<ISCLSTR>
            TypeOfBaseline = {TypeOfBaseline};
        else
            % pass
        end
    else
        warning('%s is not a valid input name. ignoring this name-value pair.',pName)
    end
end

%% Listen, I didn't feel like coding up the GUI navigator again this time. So you're just gonna have to specify the path name yourself.
% if anything, this tells me that the SessionMetadata field needs to be populated with directories from which the data are loaded... or at least a standardized method by which to find such a directory!

%% fname
fname_ = [obj.SessionMetadata.AnimalName,num2str(obj.SessionMetadata.SessionNumber)];

%% reading the raw sev files
if any(cellfun(@(x) any(strcmpi(x,{'between-nofilter','all'})),TypeOfBaseline))
    % get your vector of target times (in SECONDS)
    trialstarts = arrayfun(@(x) x.trial_start_time, obj.Event);
    trialends   = arrayfun(@(x) x.trial_end_time,obj.Event);
    
    trialstarts = vertcat(trialstarts(:),inf);
    trialends   = vertcat(1,trialends(:)); % remember to index from 1 ding-dong
    
    targetwindows = [trialends';trialstarts']./1000; % convert back to seconds, ding-dong
    
    % now find all the sev files
    sev_files = dir(fullfile(rawdir,'*.sev'));
    
    spectra_by_cell = cell(size(sev_files));
    %     cat_noisetrace  = cell(size(sev_files)); % debug
    for file_ind = 1:numel(sev_files)
        fullsevpath = fullfile(rawdir,sev_files(file_ind).name);
        
        tic
        clear datatemp
        pause(0.01)
        datatemp         = SEV2mat(fullsevpath,'RANGES',targetwindows);
        toc
        
        betweentrialdata = datatemp.xWav.data;
        fs               = datatemp.xWav.fs;
        
        
        ttypes = obj.TrialType.names;
        utt    = obj.TrialType.unique_names;
        uti    = obj.TrialType.indices;
        
        beforetrialinds = [uti;nan];
        aftertrialinds  = [nan;uti];
        
        keepinds = beforetrialinds == aftertrialinds; % ignore inter-trial intervals that straddle blocks
        
        betweentrials_sameblock_data = betweentrialdata(keepinds);
        betweentrials_sameblock_inds = beforetrialinds(keepinds);
        
        % demean each inter-trial interval individually, to counteract any slow drift that isn't being filtered out
        % we don't care about that drift
        betweentrials_double   = cellfun(@(x) double(x),betweentrials_sameblock_data,'uniformoutput',false);
        betweentrials_demeaned = cellfun(@(x) x - mean(x),betweentrials_double,'uniformoutput',false);
        
        % now sort into blocks
        data_byblock = cell(size(utt));
        for blockind = 1:numel(utt)
            these_gaps = betweentrials_sameblock_inds == blockind;
            these_data = betweentrials_demeaned(these_gaps);
            data_byblock{blockind} = these_data;
        end
        
        % now get a power spectrum for each (rather than merely reporting the variance... break it up by different frequencies' contributions!)
        data_spectra = cell(size(utt));
        %         data_trace   = cell(size(utt)); % debug
        for blockind = 1:numel(utt)
            these_data = data_byblock{blockind};
            %             data_trace{blockind} = horzcat(these_data{:})'; % debug
            
            % let's shoot for roughly-1Hz frequency resolution when interpolating
            % also, only interpolate values up to fs/2, the nyquist frequency
            fvals_interp = linspace(0,fs/2,floor(fs/2)+1);
            stacked_spectra = zeros(numel(these_data),numel(fvals_interp));
            nsamps_spectra  = zeros(numel(these_data),1);
            for tweenind = 1:numel(these_data)
                this_tween = these_data{tweenind};
                fvals = linspace(0,fs,numel(this_tween));
                THIS_TWEEN = fft(this_tween);
                THIS_TWEEN = THIS_TWEEN * sqrt(sum(this_tween.^2) ./ sum(abs(THIS_TWEEN).^2)); % energy-preserving transformation, works out to roughly 1/sqrt(N)
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 % for debugging only
                %                 nyquistfreq = fs / 2;
                %                 fvals_keep = fvals <= nyquistfreq;
                %                 THIS_TWEEN_lessthannyquist = THIS_TWEEN(fvals_keep);
                %                 fvals_kept = fvals(fvals_keep);
                %
                %
                %                 THIS_TWEEN_POWER = 2 * abs(THIS_TWEEN_lessthannyquist).^2; % Multiply by 2 to account for the fact that you're rolling aliased frequencies into one
                %                 THIS_TWEEN_POWER = THIS_TWEEN_POWER * sum(this_tween.^2) ./ sum(THIS_TWEEN_POWER); % adjust the totals because math with squares is very hard for doubles to keep precise
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                THIS_TWEEN_INTERP_POWER = interp1(fvals,abs(THIS_TWEEN).^2,fvals_interp); % linear interpolation for now. consider getting fancy with splines if this looks weird. 
                THIS_TWEEN_INTERP_POWER = THIS_TWEEN_INTERP_POWER * sum(this_tween.^2) / sum(THIS_TWEEN_INTERP_POWER); % Also, adjust the denominator under the assumption that the energy in the signal remains equivalent across different sample durations. (conversion to a proper spectral density function may be required for interpolation to make sense, i.e., divide by the frequency step) (but in the end, we can't estimate true continuous PSD, only PSM clumped into and normalized by ever smaller bins. So our PSD estimate would just be proportional to our PSM, so in reality... we change nothing and just re-normalize the way I have done)
                
                % I linearly interpolate the power rather than interpolating the signal then estimating the power. Is that appropriate? I understand that interpolating in the time domain ends up being multiplying the (latent) TRUE spectrum by a sinc function in the frequency domain
                % BUT I don't know what interpolating the SPECTROGRAM does...
                % ...oh well! as long as I'm not over/undersampling by some ridiculous margin...
                % no need to set the power of the f=0 component to 0. We already de-meaned.
                

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 % debug only
                %                 figure
                %                 plot(fvals_kept(1:end),THIS_TWEEN_POWER(1:end))
                %                 hold all
                %                 plot(fvals_interp(1:end),THIS_TWEEN_INTERP_POWER(1:end))
                %                 box off, axis tight, grid on
                %                 legend('raw','interp')
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                stacked_spectra(tweenind,:) = THIS_TWEEN_INTERP_POWER;
                nsamps_spectra(tweenind)   = numel(this_tween);
            end
            
            % okay, so let's lump all power beyond 1000 Hz into a single "high frequency" bin
            % otherwise we end up with files that are too damn big!
            % and you don't really care about the frequency composition of the spikes per se, but rather the subthreshold fluctuations that might render a spike more detectable (pretty sure Ben's code handles this though, but just to assuage Stefan's concerns, and they are reasonable or Ben wouldn't have written code to deal with it, I'll run this...)
            toohigh = fvals_interp > 1000;
            sspectra = zeros(size(stacked_spectra,1),sum(~toohigh)+1);
            sspectra(:,1:(end-1)) = stacked_spectra(:,~toohigh);
            sspectra(:,end) = sum(stacked_spectra(:,toohigh),2);
            
            data_spectra{blockind}.energyspectra = sspectra; % to distinguish from "power" spectra, which are normalized
            data_spectra{blockind}.nsamps        = nsamps_spectra;
            data_spectra{blockind}.blocktype     = utt{blockind};
            data_spectra{blockind}.frequency     = [fvals_interp(~toohigh),max(fvals_interp)];
        end
        
        %         cat_noisetrace{file_ind} = data_trace; % for debugging only. the variance in these traces is equivalent to the sum of all (UN-normalized) energy spectra (i.e., spectra with sample count weighting built-in) divided by the total number of samples across all trials.
        
        spectra_by_cell{file_ind}.channelID    = datatemp.xWav.channels;
        spectra_by_cell{file_ind}.dataspectra  = data_spectra;
        
    end
    save(sprintf('%s_spectra_raw_%s.mat',fname_,date),'spectra_by_cell','-v7.3') % oml why is the file size so ridiculous...
end


%% reading the datafilt files from the spike sorting stage
% these ones simply had a high-pass filter applied (technically, it subtracts out a wide-windowed median filter rather than applying a linear filter, with the aim being to avoid distorting spike waveform shape)
% there was still the cross-channel PCA subtraction that Ben did to remove common artifacts present across all channels, so this still isn't *quite* what was used to spike sort. But this *does* capture what the nonlinear filter itself did to the signal.

if any(cellfun(@(x) any(strcmpi(x,{'between-filter','all'})),TypeOfBaseline))
    % get your vector of target times (in SECONDS)
    trialstarts = arrayfun(@(x) x.trial_start_time, obj.Event);
    trialends   = arrayfun(@(x) x.trial_end_time,obj.Event);
    
    trialstarts = vertcat(trialstarts(:),inf);
    trialends   = vertcat(1,trialends(:)); % remember to index from 1 ding-dong
    
    targetwindows = [trialends';trialstarts']./1000; % convert back to seconds, ding-dong
    
    % now find all the sev files
    datafilt_files = dir(fullfile(rawdir,'datafilt_*.mat'));
    datafilt_channelnames = arrayfun(@(x) str2double(regexpi(x.name,'\d\d\d','match')),datafilt_files);

    spectra_by_cell = cell(size(datafilt_files));
    for file_ind = 1:numel(datafilt_files)
        fullsevpath = fullfile(rawdir,datafilt_files(file_ind).name);
        
        tic
        clear datatemp
        pause(0.01)
        datatemp         = load(fullsevpath);
        toc
        
        totaldata        = datatemp.data;
        fs               = 24414.0625;
        
        tvals = (1:numel(totaldata))./fs; % in s, to match the conversion & be consistent with the SEV extraction tools
        
        betweentrialdata = cell(size(targetwindows,2),1);
        
        tic % this loop takes way too long to process...
        for tweenind = 1:numel(betweentrialdata)
            keepinds = tvals >= targetwindows(1,tweenind) & tvals <= targetwindows(2,tweenind);
            betweentrialdata{tweenind} = totaldata(keepinds);
            toc
        end
        
        
        ttypes = obj.TrialType.names;
        utt    = obj.TrialType.unique_names;
        uti    = obj.TrialType.indices;
        
        beforetrialinds = [uti;nan]; % there might be "off-by-one" errors here, because I think the "filtered" data use the derivative or something like that. Still, with a high enough sampling rate, off-by-1 equates to off-by-40 microseconds, a tiny fraction of a single spike's waveform.
        aftertrialinds  = [nan;uti]; % and keep in mind, this isn't even for neural data processing. this is just for determining the amount of noise in the damn signal
        
        keepinds = beforetrialinds == aftertrialinds; % ignore inter-trial intervals that straddle blocks
        
        betweentrials_sameblock_data = betweentrialdata(keepinds);
        betweentrials_sameblock_inds = beforetrialinds(keepinds);
        
        % demean each inter-trial interval individually, to counteract any slow drift that isn't being filtered out
        % we don't care about that drift
        betweentrials_double   = cellfun(@(x) double(x),betweentrials_sameblock_data,'uniformoutput',false);
        betweentrials_demeaned = cellfun(@(x) x - mean(x),betweentrials_double,'uniformoutput',false);
        
        % now sort into blocks
        data_byblock = cell(size(utt));
        for blockind = 1:numel(utt)
            these_gaps = betweentrials_sameblock_inds == blockind;
            these_data = betweentrials_demeaned(these_gaps);
            data_byblock{blockind} = these_data;
        end
        
        % now get a power spectrum for each (rather than merely reporting the variance... break it up by different frequencies' contributions!)
        data_spectra = cell(size(utt));
        for blockind = 1:numel(utt)
            these_data = data_byblock{blockind};
            
            % let's shoot for roughly-1Hz frequency resolution when interpolating
            % also, only interpolate values up to fs/2, the nyquist frequency
            fvals_interp = linspace(0,fs/2,floor(fs/2)+1);
            stacked_spectra = zeros(numel(these_data),numel(fvals_interp));
            nsamps_spectra  = zeros(numel(these_data),1);
            for tweenind = 1:numel(these_data)
                this_tween = these_data{tweenind};
                fvals = linspace(0,fs,numel(this_tween));
                THIS_TWEEN = fft(this_tween);
                THIS_TWEEN = THIS_TWEEN * sqrt(sum(this_tween.^2) ./ sum(abs(THIS_TWEEN).^2)); % energy-preserving transformation, works out to roughly 1/sqrt(N)
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 % for debugging only
                %                 nyquistfreq = fs / 2;
                %                 fvals_keep = fvals <= nyquistfreq;
                %                 THIS_TWEEN_lessthannyquist = THIS_TWEEN(fvals_keep);
                %                 fvals_kept = fvals(fvals_keep);
                %
                %
                %                 THIS_TWEEN_POWER = 2 * abs(THIS_TWEEN_lessthannyquist).^2; % Multiply by 2 to account for the fact that you're rolling aliased frequencies into one
                %                 THIS_TWEEN_POWER = THIS_TWEEN_POWER * sum(this_tween.^2) ./ sum(THIS_TWEEN_POWER); % adjust the totals because math with squares is very hard for doubles to keep precise
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                THIS_TWEEN_INTERP_POWER = interp1(fvals,abs(THIS_TWEEN).^2,fvals_interp); % linear interpolation for now. consider getting fancy with splines if this looks weird. 
                THIS_TWEEN_INTERP_POWER = THIS_TWEEN_INTERP_POWER * sum(this_tween.^2) / sum(THIS_TWEEN_INTERP_POWER); % Also, adjust the denominator under the assumption that the energy in the signal remains equivalent across different sample durations. (conversion to a proper spectral density function may be required for interpolation to make sense, i.e., divide by the frequency step) (but in the end, we can't estimate true continuous PSD, only PSM clumped into and normalized by ever smaller bins. So our PSD estimate would just be proportional to our PSM, so in reality... we change nothing and just re-normalize the way I have done)
                % I linearly interpolate the power rather than interpolating the signal then estimating the power. Is that appropriate? I understand that interpolating in the time domain ends up being multiplying the (latent) TRUE spectrum by a sinc function in the frequency domain
                % BUT I don't know what interpolating the SPECTROGRAM does...
                % ...oh well! as long as I'm not over/undersampling by some ridiculous margin...
                % no need to set the power of the f=0 component to 0. We already de-meaned.
                

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 % debug only
                %                 figure
                %                 plot(fvals_kept(1:end),THIS_TWEEN_POWER(1:end))
                %                 hold all
                %                 plot(fvals_interp(1:end),THIS_TWEEN_INTERP_POWER(1:end))
                %                 box off, axis tight, grid on
                %                 legend('raw','interp')
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                stacked_spectra(tweenind,:) = THIS_TWEEN_INTERP_POWER;
                nsamps_spectra(tweenind)   = numel(this_tween);
            end
            
            % okay, so let's lump all power beyond 1000 Hz into a single "high frequency" bin
            % otherwise we end up with files that are too damn big!
            toohigh = fvals_interp > 1000;
            sspectra = zeros(size(stacked_spectra,1),sum(~toohigh)+1);
            sspectra(:,1:(end-1)) = stacked_spectra(:,~toohigh);
            sspectra(:,end) = sum(stacked_spectra(:,toohigh),2);
            
            data_spectra{blockind}.energyspectra = sspectra; % to distinguish from "power" spectra, which are normalized
            data_spectra{blockind}.nsamps        = nsamps_spectra;
            data_spectra{blockind}.blocktype     = utt{blockind};
            data_spectra{blockind}.frequency     = [fvals_interp(~toohigh),max(fvals_interp)];
        end
                
        spectra_by_cell{file_ind}.channelID    = datafilt_channelnames(file_ind);
        spectra_by_cell{file_ind}.dataspectra  = data_spectra;
    end
    save(sprintf('%s_spectra_filt1_%s.mat',fname_,date),'spectra_by_cell','-v7.3')
end



%% reading the datafilt2 files from the spike sorting stage
% these ones incorporate the cross-channel PCA subtraction that Ben implemented, and are therefore precisely what Ben based his spike sorter upon.

if any(cellfun(@(x) any(strcmpi(x,{'between-filter2','all'})),TypeOfBaseline))
    % get your vector of target times (in SECONDS)
    trialstarts = arrayfun(@(x) x.trial_start_time, obj.Event);
    trialends   = arrayfun(@(x) x.trial_end_time,obj.Event);
    
    trialstarts = vertcat(trialstarts(:),inf);
    trialends   = vertcat(1,trialends(:)); % remember to index from 1 ding-dong
    
    targetwindows = [trialends';trialstarts']./1000; % convert back to seconds, ding-dong
    
    % now find all the sev files
    datafilt_files = dir(fullfile(rawdir,'datafilt2_*.mat'));
    datafilt_channelnames = arrayfun(@(x) str2double(regexpi(x.name,'\d\d\d','match')),datafilt_files);
    
    spectra_by_cell = cell(size(datafilt_files));
    for file_ind = 1:numel(datafilt_files)
        fullsevpath = fullfile(rawdir,datafilt_files(file_ind).name);
        
        tic
        clear datatemp
        pause(0.01)
        datatemp         = load(fullsevpath);
        toc
        
        totaldata        = datatemp.data;
        fs               = 24414.0625;
        
        tvals = (1:numel(totaldata))./fs; % in s, to match the conversion & be consistent with the SEV extraction tools
        
        betweentrialdata = cell(size(targetwindows,2),1);
        
        tic % this loop takes way too long to process...
        for tweenind = 1:numel(betweentrialdata)
            keepinds = tvals >= targetwindows(1,tweenind) & tvals <= targetwindows(2,tweenind);
            betweentrialdata{tweenind} = totaldata(keepinds);
            toc
        end
        
        
        ttypes = obj.TrialType.names;
        utt    = obj.TrialType.unique_names;
        uti    = obj.TrialType.indices;
        
        beforetrialinds = [uti;nan]; % there might be "off-by-one" errors here, because I think the "filtered" data use the derivative or something like that. Still, with a high enough sampling rate, off-by-1 equates to off-by-40 microseconds, a tiny fraction of a single spike's waveform.
        aftertrialinds  = [nan;uti]; % and keep in mind, this isn't even for neural data processing. this is just for determining the amount of noise in the damn signal
        
        keepinds = beforetrialinds == aftertrialinds; % ignore inter-trial intervals that straddle blocks
        
        betweentrials_sameblock_data = betweentrialdata(keepinds);
        betweentrials_sameblock_inds = beforetrialinds(keepinds);
        
        % demean each inter-trial interval individually, to counteract any slow drift that isn't being filtered out
        % we don't care about that drift
        betweentrials_double   = cellfun(@(x) double(x),betweentrials_sameblock_data,'uniformoutput',false);
        betweentrials_demeaned = cellfun(@(x) x - mean(x),betweentrials_double,'uniformoutput',false);
        
        % now sort into blocks
        data_byblock = cell(size(utt));
        for blockind = 1:numel(utt)
            these_gaps = betweentrials_sameblock_inds == blockind;
            these_data = betweentrials_demeaned(these_gaps);
            data_byblock{blockind} = these_data;
        end
        
        % now get a power spectrum for each (rather than merely reporting the variance... break it up by different frequencies' contributions!)
        data_spectra = cell(size(utt));
        for blockind = 1:numel(utt)
            these_data = data_byblock{blockind};
            
            % let's shoot for roughly-1Hz frequency resolution when interpolating
            % also, only interpolate values up to fs/2, the nyquist frequency
            fvals_interp = linspace(0,fs/2,floor(fs/2)+1);
            stacked_spectra = zeros(numel(these_data),numel(fvals_interp));
            nsamps_spectra  = zeros(numel(these_data),1);
            for tweenind = 1:numel(these_data)
                this_tween = these_data{tweenind};
                fvals = linspace(0,fs,numel(this_tween));
                THIS_TWEEN = fft(this_tween);
                THIS_TWEEN = THIS_TWEEN * sqrt(sum(this_tween.^2) ./ sum(abs(THIS_TWEEN).^2)); % energy-preserving transformation, works out to roughly 1/sqrt(N)
                
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 % for debugging only
                %                 nyquistfreq = fs / 2;
                %                 fvals_keep = fvals <= nyquistfreq;
                %                 THIS_TWEEN_lessthannyquist = THIS_TWEEN(fvals_keep);
                %                 fvals_kept = fvals(fvals_keep);
                %
                %
                %                 THIS_TWEEN_POWER = 2 * abs(THIS_TWEEN_lessthannyquist).^2; % Multiply by 2 to account for the fact that you're rolling aliased frequencies into one
                %                 THIS_TWEEN_POWER = THIS_TWEEN_POWER * sum(this_tween.^2) ./ sum(THIS_TWEEN_POWER); % adjust the totals because math with squares is very hard for doubles to keep precise
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                
                THIS_TWEEN_INTERP_POWER = interp1(fvals,abs(THIS_TWEEN).^2,fvals_interp); % linear interpolation for now. consider getting fancy with splines if this looks weird. 
                THIS_TWEEN_INTERP_POWER = THIS_TWEEN_INTERP_POWER * sum(this_tween.^2) / sum(THIS_TWEEN_INTERP_POWER); % Also, adjust the denominator under the assumption that the energy in the signal remains equivalent across different sample durations. (conversion to a proper spectral density function may be required for interpolation to make sense, i.e., divide by the frequency step) (but in the end, we can't estimate true continuous PSD, only PSM clumped into and normalized by ever smaller bins. So our PSD estimate would just be proportional to our PSM, so in reality... we change nothing and just re-normalize the way I have done)
                % I linearly interpolate the power rather than interpolating the signal then estimating the power. Is that appropriate? I understand that interpolating in the time domain ends up being multiplying the (latent) TRUE spectrum by a sinc function in the frequency domain
                % BUT I don't know what interpolating the SPECTROGRAM does...
                % ...oh well! as long as I'm not over/undersampling by some ridiculous margin...
                % no need to set the power of the f=0 component to 0. We already de-meaned.
                

                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                %                 % debug only
                %                 figure
                %                 plot(fvals_kept(1:end),THIS_TWEEN_POWER(1:end))
                %                 hold all
                %                 plot(fvals_interp(1:end),THIS_TWEEN_INTERP_POWER(1:end))
                %                 box off, axis tight, grid on
                %                 legend('raw','interp')
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                
                stacked_spectra(tweenind,:) = THIS_TWEEN_INTERP_POWER;
                nsamps_spectra(tweenind)   = numel(this_tween);
            end
            
            % okay, so let's lump all power beyond 1000 Hz into a single "high frequency" bin
            % otherwise we end up with files that are too damn big!
            toohigh = fvals_interp > 1000;
            sspectra = zeros(size(stacked_spectra,1),sum(~toohigh)+1);
            sspectra(:,1:(end-1)) = stacked_spectra(:,~toohigh);
            sspectra(:,end) = sum(stacked_spectra(:,toohigh),2);
            
            data_spectra{blockind}.energyspectra = sspectra; % to distinguish from "power" spectra, which are normalized
            data_spectra{blockind}.nsamps        = nsamps_spectra;
            data_spectra{blockind}.blocktype     = utt{blockind};
            data_spectra{blockind}.frequency     = [fvals_interp(~toohigh),max(fvals_interp)];
        end
                
        spectra_by_cell{file_ind}.channelID    = datafilt_channelnames(file_ind);
        spectra_by_cell{file_ind}.dataspectra  = data_spectra;
    end
    save(sprintf('%s_spectra_filt2_%s.mat',fname_,date),'spectra_by_cell','-v7.3')
end


%% (sorted) spike waveforms & plus-minus method
% this will probably be the fastest method...
if any(cellfun(@(x) any(strcmpi(x,{'plus-minus','all'})),TypeOfBaseline))
    
    % find all the dataspikes files
    dataspikes_files = dir(fullfile(rawdir,'dataspikes*.mat'));
    
    dataspikes_channelinds = arrayfun(@(x) str2double( regexpi( ...
        x.name,'\d\d\d','match') ),dataspikes_files);
    
    uci = unique(dataspikes_channelinds);
    
    ttypes = obj.TrialType.names;
    utt    = obj.TrialType.unique_names;
    uti    = obj.TrialType.indices;
    
    noise_by_file = cell(size(uci));
    for file_ind = 1:numel(dataspikes_files)
        fullsevpath = fullfile(rawdir,dataspikes_files(file_ind).name); % misnomer, not an sev, but oh well
        channelind  = dataspikes_channelinds(file_ind);
        
        tic
        clear datatemp
        pause(0.01)
        datatemp         = load(fullsevpath);
        toc
        
        spk_wf = datatemp.spikes;
        spk_t  = datatemp.cluster_class(:,2); % we can keep these in ms
        spk_l  = datatemp.cluster_class(:,1); % cluster labels
        
        ulabels = unique(spk_l);
        
        block_begin_inds = vertcat(1,find(diff(uti) ~= 0)+1);
        block_end_inds   = vertcat(block_begin_inds(2:end)-1,numel(uti));
        
        block_begin_times = arrayfun(@(x) x.trial_start_time,obj.Event(block_begin_inds)); % in ms
        block_end_times   = arrayfun(@(x) x.trial_end_time,obj.Event(block_end_inds)); % in ms
        block_id          = uti(block_begin_inds);
        
        blocked_noise = cell(numel(utt),1);
        
        for blockind = 1:numel(utt)
            these_blocks = block_id == blockind;
            
            btimes = block_begin_times(these_blocks);
            etimes = block_end_times(these_blocks);
            
            unitnoisecat = [];
            % for each unit
            for unitind = 1:numel(ulabels)
                this_unit_ind = spk_l == unitind;
                
                spk_cat = [];
                % for each subblock
                for subblockind = 1:numel(btimes)
                    btime = btimes(subblockind);
                    etime = etimes(subblockind);
                    
                    these_spikes = this_unit_ind & ...
                        spk_t >= btime & ...
                        spk_t <= etime;
                    
                    spk_cat = vertcat(spk_cat,...
                        spk_wf(these_spikes,:));
                end
                
                spkcat_dm = bsxfun(@minus,spk_cat,mean(spk_cat));
                spkcat_unbiased = spkcat_dm * sqrt( size(spkcat_dm) / (size(spkcat_dm)-1) );
                
                unitnoisecat = vertcat(unitnoisecat,spkcat_unbiased);
            end
            
            blocked_noise{blockind}     = unitnoisecat; % note: these are unbiased, which means you should just be able to take the mean square of all these numbers to get the variance...
        end
        noise_by_file{file_ind} = blocked_noise;
    end
    
    % now group by channel & combine +ve & -ve waveform data
    noise_by_channel = cell(numel(uci),1);
    
    for chanind = 1:numel(noise_by_channel)
        these_files = dataspikes_channelinds == uci(chanind);
        
        these_cells = noise_by_file(these_files);
        
        combined_cells = cell(numel(utt),1);
        
        for fileind = 1:numel(these_cells)
            this_cell = these_cells{fileind};
            
            for cellind = 1:numel(this_cell) % which condition? active / control / passive?
                combined_cells{cellind} = vertcat(...
                    combined_cells{cellind},...
                    this_cell{cellind});
            end
        end
        
        noise_by_channel{chanind} = combined_cells;
    end
    
    % now let's go thru and calc the variance
    % (because the spike waveform encompasses a mere 3 ms, meaning we only recover frequency information of at least 300 Hz... in other words, pretty silly)
    var_by_channel = cellfun(@(x) cellfun(@(y) mean(y(:).^2),x),...
        noise_by_channel,'uniformoutput',false); % remember: you already applied a "de-biasing" transformation to each noise trace, so just compute the variance (after subtracting the spike waveform of course!) as the mean of the squared residuals!!!
    var_by_channel = horzcat(var_by_channel{:});
    
    channelinds = uci;
        
    % no, you're not dreaming. The output of this script really *IS* this small.
    save(sprintf('%s_spectra_plusminus_%s.mat',fname_,date),'var_by_channel','channelinds','-v7.3')
    
end

end




