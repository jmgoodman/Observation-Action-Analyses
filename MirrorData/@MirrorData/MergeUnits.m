function [newobj,smoothdata] = MergeUnits(obj,oldsmoothdata)

%MERGEUINTS Takes sorted units & merges them if they're similar
%
%DESCRIPTION
%   This routine provides a quick way to "fix" manual spike sorting that
%   errs on the side of too sensitively declaring waveforms to arise from
%   separate units. It doesn't handle "drift" very well, nor does it handle 
%   similar phenomena such as progressively amplitude-reduced "burst" spikes. 
%   But, if you're using an array the former at least shouldn't be too huge 
%   a problem. Basically, this script looks within each channel, sees if the 
%   firing rates, waveforms, and PETHs are similar within an internally 
%   specified threshold, then merges those units if they are. Allows 
%   "daisy-chaining" of similarity: two points that are not similar to each 
%   other but similar to a common neighbor can themselves be merged. This
%   script will also determine which units are SUA or MUA, mark units
%   whose waveforms or spike counts are simply not good enough, and update
%   the Neural field with these details. NOTE: this script assumes you have
%   run ReadNeural with the "keepwaveforms" option turned OFF. If you left
%   it on, this script may still run, but its output will be entirely
%   wrong.
%
%   DOUBLE NOTE: realistically, this script is probably too aggressive with its refusal to trust your spike-sorting.
%   In reality, you should probably just keep the data AS-IS (the positive-negative threshold split is only likely to shave a small fraction of spikes off a high-spiking biphasic waveform, after all)
%   And just apply criteria (e.g., SNR) down the line if you REALLY want to be sure that a unit is, for instance, SUA or MUA or just straight garbage
%
%SYNTAX
%   [newobj,smoothdata] = MergeUnits(obj,BinnedData)
%
%   newobj          ... MirrorData object with updated Neural field. Kept
%   separate from the input "obj" to preserve both copies (in case
%   something looks "funny" with the output "newobj")
%   smoothdata      ... cell array of SMOOTHED obj.BinnedData outputs used in this
%   script.
%   obj             ... MirrorData object (instantiated with obj = MirrorData();)
%   oldsmoothdata   ... Cell array of of SMOOTHED obj.BinnedData outputs (one for each 
%   event to which you want to align), an optional input if you need
%   to run this script multiple times & don't want to wait for BinnedData
%   to complete every time
%
%AUTHOR
%   Written for MirrorData by James Goodman, 2020 April 17, DPZ

%% create BinnedData

fn = fieldnames(obj);
newobj = MirrorData;

for fnind = 1:numel(fn)
    newobj.(fn{fnind}) = obj.(fn{fnind});
end
    
if nargin < 2
    
    event_names   = {'cue_onset_time','go_phase_start_time','movement_onset_time','hold_onset_time','reward_onset_time'};
    BinnedData    = cell(size(event_names));
    targetwin     = 500;
    smoothwid     = 200;
    trimwid_samps = smoothwid / 10;
    
    for event_ind = 1:numel(event_names)
        ename = event_names{event_ind};
        BinnedData{event_ind} = newobj.BinData('Alignment',ename,'Window',targetwin+smoothwid);
    end
    
    
    
    %% SMOOTH it
    sigma = 20; % 20 ms
    tv = -(targetwin+smoothwid):10:(targetwin+smoothwid);
    gv = exp( -tv.^2 ./ (2 * sigma^2) );
    gv = gv(:)./sum(gv);
    
    SmoothedDataTemp = cell(size(BinnedData));
    ntrials = numel( BinnedData{1}.TrialTypes );
    
    for trialind = 1:ntrials
        SmoothedDataTempTemp = cellfun(@(x) conv2(x.Data(:,:,trialind),gv,'same')./...
            conv2(ones(size(x.Data(:,:,trialind))),gv,'same'),BinnedData,'uniformoutput',false);
        SmoothedDataTemp = cellfun(@(x,y) cat(3,x,y),SmoothedDataTemp,SmoothedDataTempTemp,'uniformoutput',false);
    end
    
    SmoothedData = SmoothedDataTemp;
    
    SnippedData  = cellfun(@(x) x((trimwid_samps+1):(end-trimwid_samps),:,:),...
        SmoothedData,'uniformoutput',false);
    
else
    SnippedData = oldsmoothdata;
    
end


if nargout == 2
    smoothdata = SnippedData;
end


%% run through each channel

cID = arrayfun(@(x) x.channelID,newobj.Neural);
uID = arrayfun(@(x) x.unitID,newobj.Neural);
ucnames = unique(cID);

channel_Tvals        = cell(size(ucnames));
channel_kstvals      = cell(size(ucnames));
channel_pethcorrvals = cell(size(ucnames));

for uci = 1:numel(ucnames)
    these_units = cID == ucnames(uci);
    
    if sum(these_units) > 1
        these_PETHs = cellfun(@(x) x(:,these_units,:),SnippedData,'uniformoutput',false);
        catPETHs    = cat(1,these_PETHs{:});
        catPETHs    = permute(catPETHs,[2,1,3]);
        catPETHs    = catPETHs(:,:)';
        
        % determine correlation matrix here
        corrPETHs   = corr(catPETHs,'type','spearman'); % use rank-order correlations to account for "boom-and-bust" dynamics, particularly for lower-spiking neurons that capture only a tiny fraction of what's going on in the "main" unit (linear correlation would be insensitive to such correlations, as it'd scale the modest modulation in the low-spiking neuron)
        corrPETHs(isnan(corrPETHs)) = 0;
        corrPETHs(logical(eye(size(corrPETHs)))) = 1;
        corrPETHs   = 1 - squareform(1-corrPETHs); % this goofs up if we only have 1 unit, but thankfully we have to have at least 2 here for it to matter
        channel_pethcorrvals{uci} = corrPETHs(:);
        
        n_units = sum(these_units);
        these_neurs = newobj.Neural(these_units);
        mu = arrayfun(@(x) x.waveforms(1,:),these_neurs,'uniformoutput',false); % mere cross-correlation is not a great measure
        sd = arrayfun(@(x) x.waveforms(2,:),these_neurs,'uniformoutput',false);
        sc = arrayfun(@(x) x.SpikeCount,these_neurs);
        
        % test for equal ISI distributions via K-S test
        ISIvals     = arrayfun(@(x) diff(x.spiketimes),these_neurs,'uniformoutput',false);
        
        n_pairs        = n_units*(n_units-1)/2;
        Tvals_allpairs = zeros(n_pairs,1);
        pks_allpairs   = zeros(n_pairs,1);
        kstat_allpairs = zeros(n_pairs,1);
        
        pairind = 1;
        for u1 = 1:(n_units-1)
            for u2 = (u1+1):n_units
                mu1 = mu{u1}; sd1 = sd{u1}; sc1 = sc(u1); isi1 = ISIvals{u1};
                mu2 = mu{u2}; sd2 = sd{u2}; sc2 = sc(u2); isi2 = ISIvals{u2};
                
                % first, run a cross-correlation to align the waveforms
                [xcvals,lags] = xcov(mu1,mu2,'coeff');
                [~,maxind] = max(xcvals);
                lagval = lags(maxind);
                
                mu2 = circshift(mu2,[0,lagval]); % okay, this seems to be correct...
                sd2 = circshift(sd2,[0,lagval]); % circshift may not be "correct", but it's close enough (for small shifts...)
                
                % next, de-mean each waveform
                mu1 = mu1 - mean(mu1);
                mu2 = mu2 - mean(mu2);
                
                % compute the largest t-score between waveforms
                % use standard deviations rather than standard errors
                % we're not looking for differences between means
                % but rather, whether those means couldn't have been drawn
                % from the same distribution
                Tvals   = abs(mu1 - mu2) ./ sqrt( (sc1.*sd1.^2 + sc2.*sd2.^2)./(sc1+sc2) );
                
                % also use the kstest to compare ISI distributions
                [~,pks,ksstat] = kstest2(isi1,isi2);
                
                Tvals_allpairs(pairind) = max(Tvals);
                pks_allpairs(pairind)   = pks;        
                kstat_allpairs(pairind) = ksstat;     % the K-S statistic
        
                pairind = pairind + 1;
            end
        end
        channel_Tvals{uci}   = Tvals_allpairs;
        channel_kstvals{uci} = kstat_allpairs;
    else
        % pass
    end
end

% n(n-1)/2 = N
% 2N = n*(n-1)
% n^2 - n - 2N = 0
% 1 (+/-) sqrt(1 + 8N) / 2
% (1 + sqrt(1 + 8N))/2

combined_metrics = cellfun(@(x,y,z) [x,y,z],channel_Tvals,channel_kstvals,channel_pethcorrvals,'uniformoutput',false);
channelID        = cellfun(@(x,y) x*ones(size(y,1),1),num2cell(ucnames),combined_metrics,'uniformoutput',false);
nunits           = cellfun(@(x) (1 + sqrt(1 + 8*size(x,1)))/2,combined_metrics);

unitID           = cell(size(channelID));

for cind = 1:numel(channelID)
    nunits_ = nunits(cind);
    
    if nunits_ > 1
        unit_pairs   = nchoosek(1:nunits_,2);
        unitID{cind} = unit_pairs;
    else
        % pass
    end
end

cmcat  = vertcat(combined_metrics{:});
cIDcat = vertcat(channelID{:});
uIDcat = vertcat(unitID{:});


% % let's peep a multivariate distribution of these dudes
% figure,plot3(cmcat(:,1),cmcat(:,2),cmcat(:,3),'k.'),box off, axis tight, grid on
% xlabel('T'),ylabel('ksstat'),zlabel('r')
% set(gca,'xscale','log') % put the T stat on a log scale so that closeness gets magnified

% compute cdfs of each of these
[f1,x1] = ecdf(cmcat(:,1));
[f2,x2] = ecdf(cmcat(:,2));
[f3,x3] = ecdf(cmcat(:,3));

% re-sort
cmcdf = zeros(size(cmcat));

for rowind = 1:size(cmcat,1)
    thesevals = cmcat(rowind,:);
    
    f1_ = max(f1(x1 == thesevals(1)));
    f2_ = max(f2(x2 == thesevals(2)));
    f3_ = max(f3(x3 == thesevals(3)));
    
    cmcdf(rowind,:) = [f1_,f2_,f3_];
end

% set bounds on your cdf: don't let them go all the way to 1 or 0!
cmcdf = 1/size(cmcat,1) + (1-2/size(cmcat,1))*cmcdf;

% let's flip things so that smaller cdf values = more similar
% T naturally does this
% ks statistic naturally does this
% correlation does NOT naturally do this, so flip it
cmcdf(:,3) = 1 - cmcdf(:,3);

% use rank-order correlation to estimate the underlying correlation matrix
rho = corr(cmcdf,'type','spearman');

% now compute the copula cdf values
% okay, the copula method here seems to be VERY sensitive.
nu = size(cmcdf,1)-1;
mvcdfvals = copulacdf('t',cmcdf,rho,nu);

% % let's just go with the max value
% mvcdfvals = max(cmcdf,[],2);

% these cdf values should tell you which points are outliers (in terms of
% being "too similar").

% find the points that you're pretty confident should not have arisen from
% this sample
% go for a 5% FDR method: 10%, while standard, seems way too sensitive
% and a FWER type of method seems to not be sensitive enough
[pvals_sorted,sortinds] = sort(mvcdfvals,'ascend');
FDR      = 0.05;
critvals = (1:numel(pvals_sorted))'./numel(pvals_sorted) .* FDR;

aresig = pvals_sorted < critvals;
lastsig = find(aresig,1,'last');
sigvals = false(size(aresig));
sigvals(1:lastsig) = true;
siginds = sortinds(sigvals);

channels_tomerge   = cIDcat(siginds);
units_tomerge      = uIDcat(siginds,:);
metricvals_tomerge = cmcat(siginds,:);



%% now it's time to start classifying units as SUA / MUA
% (do we need to delete "garbage" units? answer: yeah, we probably should)
% 
% (but what should count as "garbage"? lack of modulation during the task?
% maybe we do this later on in the analysis, but at this stage we should
% keep those so we can report the fraction of units that actually responded
% during the task)
% 
% (units with not enough spikes? Yes, but we should be careful to make this
% criterion *quite* lenient!)
%
% (units with supra-criterion variance, ISI harmonics, or waveform
% harmonics? YES.)
%
% (units with infrathreshold spike amplitude? no... this is SUPER electrode
% dependent and a particularly low-impedance electrode with a great unit
% might be unfairly DQ'd for this)
%
% (units that cut out/in abruptly in a manner predicted by block sequence? YES
% absolutely, this ruins your PETHs)
%
% (units whose firing rate is correlated at a supra-threshold level with
% time per se? YES this kind of drift ALSO ruins your PETHs, although
% thankfully passive & active are interleaved, so this sort of thing mostly
% hurts estimates of object selectivity)
%% SUA:
% criterion 1: peak-to-peak amplitude has to be pretty high (> 80 uA) (granted, this is
% electrode-dependent, but at this stage we're talking about MEGA
% confidence that this is ONE cell, not REASONABLE confidence that we're
% talking about neural activity of *some* sort)
%
% criterion 2: needs to be well-separated from its channel mates (a harsher
% criterion than simply not being merged according to the previous step:
% this one says they have to be actively VERY different!)
%
% criterion 3: standard deviation must be within criterion value
%
% criterion 4: ISI histogram needs to be peaked without harmonics (and NOT
% an exponential distribution!)
%
% (don't put a modulation depth criterion, that bakes in "functional
% relevance" and you want something that lets that fall out without
% accounting for it in advance!)
%
% (don't put a waveform shape criterion, i.e., negative peak only or
% biphasic only, as e.g. dendritic spikes would be unfairly excluded then!)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% implement "bad unit" and "single unit" automatic checks, and
% implement the actual merging of units declared to be artificially split!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% "single unit" checks

% crit1_threshold = 80; % 80 uA peak-to-peak. I should probably make it 100uA instead, buuuuut that might only be reasonable for M1...
% criterion1 = arrayfun(@(x) x.PeakToPeakAmplitudeInMicrovolts > crit1_threshold,...
%     newobj.Neural);
% % IGNORE this one! it's too electrode dependent and you already have a
% % criterion (the variance one) that bakes the amplitude into it anyway!
% 
% % crit2_threshold = 0.05; % definitively non-significant difference, no correction required
% criterion2 = false(size(newobj.Neural));
% 
% for neurind = 1:numel(newobj.Neural)
%     cID_ = newobj.Neural(neurind).channelID;
%     uID_ = newobj.Neural(neurind).unitID;
%     
%     target_inds = cIDcat == cID_ & any(uIDcat == uID_,2);
%     
%     if any(target_inds)
%         criterion2(neurind) = ~any(ismember(find(target_inds),siginds)); % min(mvcdfvals(target_inds)) > crit2_threshold;
%     else
%         criterion2(neurind) = true;
%     end
% end
%     
% 
% crit3_threshold = 5; % keep this as the rose criterion
% criterion3      = arrayfun(@(x) max(abs(x.waveforms(1,:)./sqrt(...
%     max(x.waveforms(2,:)).^2 + x.waveforms(2,:).^2))) > 5,...
%     newobj.Neural);
% 
% % the 4th criterion involves testing against the hypothesis that the
% % ISIs are drawn from a mere exponential distribution
% pvals_crit4 = zeros(size(newobj.Neural));
% 
% for neurind = 1:numel(newobj.Neural)
%     ISIvals   = diff(newobj.Neural(neurind).spiketimes);
%     muhat     = expfit(ISIvals);
%     ISIsortvals = unique(sort(ISIvals,'ascend'));
%     hyp_pvals = expcdf(ISIsortvals,muhat);
%     [~,pvals_crit4(neurind)] = kstest(ISIvals,'cdf',[ISIsortvals(:),hyp_pvals]);
% end
% 
% [sortpvals_,sortpinds_] = sort(pvals_crit4,'ascend');
% FDR      = 0.05;
% critvals_ = (1:numel(sortpvals_))'./numel(sortpvals_) .* FDR; % looking for stuff that's significantly different from an exponential distro, using a FDR-based (as opposed to FWER-based) correction for multiple comparisons (so a little more sensitive than it perhaps ought to be, but in practice I seriously doubt it really, REALLY matters)
% 
% aresig_ = sortpvals_ < critvals_;
% lastsig_ = find(aresig_,1,'last');
% sigvals_ = false(size(aresig_));
% sigvals_(1:lastsig_) = true;
% siginds_ = sortpinds_(sigvals_);
% 
% criterion4 = false(size(sortpvals_));
% criterion4(siginds_) = true;
% 
% % SUAinds = criterion1 & criterion2 & criterion3 & criterion4;
% SUAinds = criterion2 & criterion3 & criterion4; % ignore the arbitrary criterion1
% 
% SUA_ids = [cID(SUAinds),uID(SUAinds)];
% 
% % I *could* test more strictly for things like whether it's a sufficiently
% % GAMMA-distributed ISI distro... or if it's a "weird" distribution e.g. a
% % "uniform" distribution... but let's see first if such measures are even
% % necessary
% %
% % ...okay. this is NOT going well. It's either way too sensitive or way too
% % exclusive. i should probably rely on manual annotation after all...
% % except I think that will be far too exclusive, too...

% % ok, let's use the Rouse & Schieber 2016 J Neurosci criteria... 
% % just to have SOME standard against which to compare... 
% % and we'll use the "probable SUA" - "multiunit" - "garbage" distinctions that they do
% 
% % first criterion: ISI violations (assuming the spike sorter doesn't
% % automatically kick these out...)
% tmax    = 1; % refractory period setting
% vISI    = arrayfun(@(x) sum( diff(x.spiketimes) < tmax ),...
%     newobj.Neural);
% STextr  = arrayfun(@(x) [min(x.spiketimes),max(x.spiketimes)],newobj.Neural,'uniformoutput',false);
% STexcat = vertcat(STextr{:});
% T       = max(STexcat(:,2)) - min(STexcat(:,1));
% 
% % i am going to assume "tmin" is 0, because we obviously do get SOME
% % violations even though the spike waveform captures data roughly 1.8 ms
% % after the peak detection (88 samples post-crossing, which are upsampled 
% % by a factor of 2 from 24414.0625 Hz, gives ~1.8ms post-crossing for each
% % waveform... there are also 40 pre-crossing samples taken)
% tmin = 0;
% N = arrayfun(@(x) numel(x.spiketimes),newobj.Neural);
% 
% fF = real(1 - ( sqrt( (1/4) - (vISI.*T ./ (2*(tmax - tmin)*N.^2)) ) + (1/2) )); % i mean... this metric is not terribly useful... if you have too many violations, it gives imaginary numbers! what the heck?!?

% UGHHHH okay so maybe I just lean on RAW violation counts (NONE
% allowed!!!), my other criteria, and a more strict amplitude / noise
% criterion that uses the variance at both the peak AND the baseline!

%% Violation count criterion (use the "hard" criterion from Rouse & Schieber 2016 J Neurosci)

tmax    = 1; % refractory period setting
vISI    = arrayfun(@(x) sum( diff(x.spiketimes) < tmax ),...
    newobj.Neural);
Violation_Criterion = vISI == 0; % we cannot allow ourselves any "impossible" spikes. this seems to disqualify as SUA one otherwise really good unit from Zara64's data, but that unit is admittedly a little fishy (it has a bimodal ISI histogram?!?), so this seems to be an assay capable of accounting for such peculiarities.

%% separable from other units criterion (because obviously if there's 2 of the same-looking waveform, there's gotta be cross-contamination, yet enough of a qualitative difference to have separated them in the first place to think they might be more than 1 unit...)

Separable_Criterion = true(size(newobj.Neural));

for neurind = 1:numel(newobj.Neural)
    cID_ = newobj.Neural(neurind).channelID;
    uID_ = newobj.Neural(neurind).unitID;
    
    if ismember(cID_,channels_tomerge)
        these_units = units_tomerge(channels_tomerge==cID_,:);
        
        if ismember(uID_,these_units(:))
            Separable_Criterion(neurind) = false;
        else
            Separable_Criterion(neurind) = true;
        end
        
    else
        Separable_Criterion(neurind) = true;
    end
end

%% substantially supra-noise peak threshold (use the one from Rouse & Schieber 2016 J Neurosci... the harsh one)

% Peak_Criterion_Value = 3; % The "definite" SUA threshold per Rouse &
% Schieber 2016 J Neurosci. Note that I have since switched to a method
% that does proper variance addition (multiply std by sqrt(2) instead of
% 2), so a new criterion is needed for that.
Peak_Criterion_Value = 5; % Rose criterion for "absolutely certain" visual discrimination of a signal from background noise. Is more strict than Rouse & Schieber's criterion (3*sqrt(2) < 5), but in the same order of magnitude.
Peak_Criterion       = arrayfun(@(x) max(abs(x.waveforms(1,:)))./ ...
    (sqrt(2)*median(x.waveforms(2,:))) > Peak_Criterion_Value,...
    newobj.Neural); % median noise taken as a proxy for baseline noise, as more samples constitute baseline signal than not, and taking the "max" risks excluding waveforms that happen to just spike a lot and therefore include the next spike in the present waveform (which is bad)

%% gamma distributed ISI distro
% % or maybe not... this criterion is proving to be VERY complicated to
% % implement properly... too complicated to really be worth it, really...
% %
% % the idea being that it should have a single peak & everything
% % focus on the 0-100ms range
% % also test against the exponential distribution
% 
% exp_testvals = zeros(size(newobj.Neural));
% gam_testvals = zeros(size(newobj.Neural));
% 
% kstat_exp = zeros(size(exp_testvals));
% kstat_gam = zeros(size(gam_testvals));
% 
% for neurind = 1:numel(newobj.Neural)
%     ISIvals   = diff(newobj.Neural(neurind).spiketimes);
%     
%     if numel(ISIvals) > 100 % let's be real, if you don't have this many, you can't REALLY do this test
%         muhat     = expfit(ISIvals);
%         phat      = gamfit(ISIvals);
%         ISIsortvals = unique(sort(ISIvals,'ascend'));
%         exp_pvals = expcdf(ISIsortvals,muhat);
%         gam_pvals = gamcdf(ISIsortvals,phat(1),phat(2));
%         [~,exp_testvals(neurind),kstat_exp(neurind)] = kstest(ISIvals,'cdf',[ISIsortvals(:),exp_pvals(:)]);
%         [~,gam_testvals(neurind),kstat_gam(neurind)] = kstest(ISIvals,'cdf',[ISIsortvals(:),gam_pvals(:)]);
%     else
%         exp_testvals(neurind) = nan;
%         gam_testvals(neurind) = nan;
%     end
% end
% 
% % okay so the gamma tests are unreliable because there's just so damn many
% % ISIs even for the good units, so a "significant" difference gets found

%% SUAs
SUA_inds  = Violation_Criterion & Peak_Criterion & Separable_Criterion;

% SUA_units = [cID(SUA_inds),uID(SUA_inds)]; % these look... pretty good, actually. there's one unit that gets cut out because of the violation criterion, but honestly it seems like a borderline case anyway, and the violation criterion is probably rightfully picking up on something "fishy" about its SUA case (it comes from a channel with 4 other units, and seems to have a bimodal ISI histogram). This might be too conservative a criterion, but hey. it's bona fide SUAs we're trying to isolate here. It SHOULD be conservative!
% % honestly, like 90% of what's right here is the Peak Criterion, though.
% % The other two criteria simply rule out edge cases.
% % so... in the end... is it actually just a SNR issue? yeah, probably...

SUA_cellinds = num2cell(SUA_inds);

[newobj.Neural.is_SUA] = SUA_cellinds{:};

%% now we merge the units
% we want to update this field and just... delete all the "diagnostic"
% fields at this point, too

NewNeur = newobj.Neural;

NewNeur = rmfield(NewNeur,{'PeakToPeakAmplitudeInMicrovolts','NegativePhaseAmplitude',...
    'PositivePhaseAmplitude','SNR','SignalStandardDeviation','NoiseStandardDeviation',...
    'GammaVersusGaussianLLR_PerISI'});

channels_withmerge = unique(channels_tomerge);
units_2_delete     = false(size(NewNeur));

for c2m_ind = 1:numel(channels_withmerge)
    unit_inds      = (channels_tomerge == channels_withmerge(c2m_ind));
    unit_labels    = units_tomerge(unit_inds,:);
    
    units_2combine = unique(unit_labels(:));
    
    unit_inds = cID == channels_withmerge(c2m_ind) & ismember(uID,units_2combine);
    unit_inds = find(unit_inds);
    units_    = NewNeur(unit_inds);
    
    % average out the waveforms
    Ex = arrayfun(@(x) x.waveforms(1,:)*x.SpikeCount,units_,'uniformoutput',false);
    
    N = arrayfun(@(x) x.SpikeCount,units_);
    
    sigma2 = arrayfun(@(x) x.waveforms(2,:).^2,units_,'uniformoutput',false);
    
    % sigma2 = (1/(N-1)) * ( Ex2 - (1/N)*(Ex)^2 )
    Ex2    = cellfun(@(n,s2,ex) (n-1)*s2 + (1/n)*ex.^2,num2cell(N),sigma2,Ex,'uniformoutput',false);
    
    % concatenate spike times
    ST     = arrayfun(@(x) x.spiketimes,units_,'uniformoutput',false);
    
    new_Ex  = sum(vertcat(Ex{:}));
    new_Ex2 = sum(vertcat(Ex2{:}));
    new_N   = sum(N);
    
    new_mu  = new_Ex / new_N;
    new_std = sqrt((new_Ex2 - (1/new_N)*new_Ex.^2) / (new_N-1)); % remember to take the square root of the variance to get back to std units!
    new_wf  = [new_mu;new_std];
    
    new_ST  = sort(vertcat(ST{:}),'ascend');
    
    NewNeur(unit_inds(1)).waveforms  = new_wf;
    NewNeur(unit_inds(1)).spiketimes = new_ST;
    NewNeur(unit_inds(1)).channelID  = channels_withmerge(c2m_ind);
    NewNeur(unit_inds(1)).unitID     = min(unit_labels);
    NewNeur(unit_inds(1)).original_unitID = unit_labels; % preserve the multiple unit labels to make it easier to register against the Wave_Clus output files
    NewNeur(unit_inds(1)).SpikeCount = new_N;
    NewNeur(unit_inds(1)).is_SUA     = false; % listen, if you merge two units you had at one point considered separate, there's no way it can be SUA. There's considerable doubt there. We should be conservative with what we call "SUA".
    
    units_2_delete(unit_inds(2:end)) = true;  % remove the rest
end

NewNeur(units_2_delete) = [];

% fill the empty original_unitID fields
empties = arrayfun(@(x) isempty(x.original_unitID),NewNeur);
emptyinds = find(empties);
for ei = 1:numel(emptyinds)
    NewNeur(emptyinds(ei)).original_unitID = ...
        NewNeur(emptyinds(ei)).unitID;
end

% for each channel, re-number the *current* unit IDs (preserve
% "original_unitID" for registering with the output of wave_clus, where +ve
% units come after -ve ones rather than being labeled & numbered
% separately, i.e., if a unit has 3 -ve and 2 +ve waveforms, the -ve
% waveforms get labels 1-3 and the +ve ones get 4-5)
channelNos = arrayfun(@(x) x.channelID,NewNeur);
ucn = unique(channelNos);

for unique_channel_ind = 1:numel(ucn)
    theseunits    = channelNos == ucn(unique_channel_ind);    
    theseunitinds = find(theseunits);
    
    for unit_ind = 1:numel(theseunitinds)
        NewNeur(theseunitinds(unit_ind)).unitID = unit_ind;
    end
end

newobj.Neural = NewNeur;
        
        
%% seek & destroy awful units (also still in progress!)
% too few spikes criterion
spike_count_threshold = 1000; % 1000 spikes is the minimum. any fewer and it frankly just is not worth analyzing. It'll throw off your single-unit analyses and require some aggressive softening of your rate normalizations at the population level. So better to just head those complications off at the pass. I checked through all SUA that end up getting cut by this criterion and of all of them, maybe ONE had a response worth a damn - and it wasn't even task related (to be specific, it responded to reward delivery, but not during hand movement or object presentation). In other words, this criterion is *fine* and will probably pay off in spades once we start having to worry about normalizing firing rates during analysis.
too_few_spikes = arrayfun(@(x) x.SpikeCount < spike_count_threshold, newobj.Neural);


% amplitude / variance criterion
% SNR_criterion       = 1.5; % the "discard" threshold according to Rouse & Schieber 2016 J Neurosci, wherein this particular metric was used & for which criteria with precedent are already published (note that I have since changed from their metric to one that performs proper variance addition: multiplying noise standard deviation by sqrt(2) instead of 2, namely)
SNR_criterion       = 2; % new criterion for a new measure. Based on the threshold at which 95% of waveforms can be correctly discriminated from noise (assuming a two-sided criterion applied to the noise distribution). Based on sufficient mathematical confidence, unlike the absolute perceptual confidence of the Rose criterion. More lenient than Rouse & Schieber's cutoff (1.5*sqrt(2) > 2), but in the same ballpark.
SNR_vals            = arrayfun(@(x) max(abs(x.waveforms(1,:))) ./ (sqrt(2)*median(x.waveforms(2,:))),newobj.Neural); % same computation as that underlying the peak criterion for SUA determination
too_noisy           = SNR_vals < SNR_criterion;
% using the max noise variance unfairly punishes units that spike too
% quickly (and therefore sometimes have 2 waveforms captured). So, I'm
% using the median to get to the baseline noise. This has also been changed
% in the earlier usage of this metric.
% you can tell it really bothers me to use this metric instead of the
% proper variance addition calculation (sqrt(2) * sigma, rather than
% 2*sigma). But then, whereas I could use the Rose criterion to determine
% SUA, I would not be able to easily determine a good SNR cutoff to remove
% units from consideration. So, I'll just be consistent & appeal to *A*
% precedent by using this metric.
%
% Perhaps a criterion of sigma = 2 is required to be considered *A* unit at
% ALL??? (i.e., p = 0.05 for statistical significance) That might be a good
% equivalent & matches up roughly with the Rouse & Schieber criterion of
% 1.5 (although it is a little more lenient)

%%
% units that abruptly cut out/in (or gradually but substantially change
% waveform shape & firing rate over time)
%
% hmmmm this might be a tricky thing to figure out. I'd better consult my
% manual notes & play around with some of the more egregious unit(s) to
% figure out how to go about detecting & removing them.
%
% ughhh there's also the one pair of units from Zara64 that are EXACTLY the same &
% therefore probably reflect some weird electrical artifact rather than
% neural signal per se... i also want to be able to automatically detect
% that kind of error! nobody wants artifacts!
%
% hmmm... I think for stuff like this, we might actually need the raw
% waveform data. to see if the waveform changes shape for some extended
% period of time.
%
% ...but at the same time, getting this rejection criterion up & running
% may well take AGES. let's just settle for SUA-vs-MUA-vs-trash
% distinctions on the basis of SNR criteria and worry about the little
% refinements of automatic trash detection at a later juncture (with a
% different script!)
%
% YOU HEAR THAT?!? I GIVE UP on trying to make the PERFECT automated unit
% assessor. It's just too goddamn much, and there are too many little
% things that can pop up & go wrong, I'm sure I'll miss a few cases even if
% I spend weeks on end trying to automatically detect the 2 or 3 units that
% exhibit substantial enough drift or cross-talk or sudden unexplained
% increases in baseline spiking while at the same time being very
% permissive with my criteria to avoid simply "molding" the population
% response on the basis of my pre-conceived notions of how it should look.
% What I'm saying is, that it's more time than it's worth to seek out these
% edge cases, and in the end, any good neural analysis is a numbers game
% that will hold true in aggregate even if there is an "error" unit here or
% there. It's like cropping images for histological segmentation: you COULD
% spend weeks getting it right, or you COULD just do a quick & dirty job
% and just get some damn results that are likely to hold true no matter
% what!

%% drop the "bad" neurons

bad_neur_inds = too_noisy | too_few_spikes;
bad_neur_inds = num2cell(bad_neur_inds);

[newobj.Neural.is_bad_unit] = bad_neur_inds{:}; % don't outright delete your discarded units, as you ***might*** want to report these deleted units when mentioning unit counts in your paper (if for no other reason than to give other researchers a number to put on their own spike sorting statistics). Just remember to have this criterion override the SUA criterion!!!

% to do:
% add subfields that return the sub-criteria for SUA & bad units. in case
% you ever want to change the definitions of good & bad units.

%% and we're done!
% this is a heavily annotated script but here's what it does:
% 1) detects very obviously similar units from the same channel & merges
% them (has to be obvious though - deference is given to initial sorts in
% this regard)
%
% 2) units are declared SUA by virtue of their SNR, lack of pre-refractory
% spiking, and differentiability from other units in the channel
%
% 3) bad units are removed by virtue of their spike counts and SNR (yes,
% spike counts. low spike count units will throw off single-unit analysis
% and require aggressive softening of normalization in population analyses.
% so just... don't torture yourself with those problems. even if the odd
% "good" unit gets caught. your analyses should still hold in aggregate)
%
% Nothing more is done, as those would require complex operations and
% likely months of work, all toward the end of removing maybe a dozen edge
% cases that would end up averaging out in the end anyway. Plus, I have the
% SUA detector function, which works pretty well despite its simplicity. If
% ever I fear that myriad "junk" has contaminated my results that include 
% MUA, I can always shift all my analyses to "only SUA mode" to see if 
% general trends still hold.

return