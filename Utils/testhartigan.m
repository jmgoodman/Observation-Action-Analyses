%% testhartigan
clearvars
clc
close all
restoredefaultpath
addpath(genpath(fullfile('.','hartigan')))

iterC = 5e2;

ecell = cell(iterC,1);
skew_ = struct('dip',ecell,'null',ecell,'p',ecell);
kurt_ = struct('dip',ecell,'null',ecell,'p',ecell);
both_ = struct('dip',ecell,'null',ecell,'p',ecell);
none_ = struct('dip',ecell,'null',ecell,'p',ecell);
twoc_ = struct('dip',ecell,'null',ecell,'p',ecell);

%%
ncores = feature('numcores');
ncores_touse = ncores - 1; % leave a buffer core to do other normal things

pc = parcluster('local');

try
    p = parpool(pc,ncores_touse);
catch err
    delete(gcp('nocreate'))
    p = parpool(pc,ncores_touse);
end

%%
Niter = 2e3;

parfor iterc = 1:iterC
    N   = 500;
    d   = 8;
    mu  = 0;
    sig = 1;
    kurtvals = [3 50];
    skewvals = [0 0.95]; % for reference, skewness = 1 is EVEN MORE SKEWED than just a straight-up pure exponential distribution. Wild. And indeed, the exponential distribution fails miserably at triggering a "significantly clustered" determination from the test against the matched-gaussian distributions.
    
    ec    = cell(Niter,1);
    
    % skewpear = exprnd(1,N,1);
    skewpear = pearsrnd(mu,sig,skewvals(2),kurtvals(1),N,1);
    kurtpear = pearsrnd(mu,sig,skewvals(1),kurtvals(2),N,1);
    bothpear = pearsrnd(mu,sig,skewvals(2),kurtvals(2),N,1);
    nonepear = pearsrnd(mu,sig,skewvals(1),kurtvals(1),N,1);
    twoclust = vertcat(randn(N/2,1),4+randn(N/2,1));
    
    % test the 8D case
    % make variance-based SNR = 2
    skewpear = horzcat(skewpear,sig/sqrt((d-1)*2) * randn(N,d-1)); %#ok<*AGROW>
    kurtpear = horzcat(kurtpear,sig/sqrt((d-1)*2) * randn(N,d-1));
    bothpear = horzcat(bothpear,sig/sqrt((d-1)*2) * randn(N,d-1));
    nonepear = horzcat(nonepear,sig/sqrt((d-1)*2) * randn(N,d-1));
    twoclust = horzcat(twoclust,sig/sqrt((d-1)*2) * randn(N,d-1));
    
    
    % normally pdist because that's what scales up to higher dimensions. but let's just try it with the distributions as-is, see if that improves sensitivity/specificity of the test
    % indeed, working with the distributions per se results in a much more SPECIFIC test.
    % unfortunately, it doesn't scale to the high-dimensional case
    % (not without performing a routine to seek out the "best" dimension, but if you do that, you also need to apply that same routine to your null distribution, which weakens the test substantially)
    tempskew = struct('dip',cell(1,1),'null',cell(1,1),'p',cell(1,1));
    tempkurt = struct('dip',cell(1,1),'null',cell(1,1),'p',cell(1,1));
    tempboth = struct('dip',cell(1,1),'null',cell(1,1),'p',cell(1,1));
    tempnone = struct('dip',cell(1,1),'null',cell(1,1),'p',cell(1,1));
    temptwoc = struct('dip',cell(1,1),'null',cell(1,1),'p',cell(1,1));
    
    tempskew.dip = ...
        HartigansDipTest(pdist(skewpear));
    
    tempkurt.dip = ...
        HartigansDipTest(pdist(kurtpear));
    
    tempboth.dip = ...
        HartigansDipTest(pdist(bothpear));
    
    tempnone.dip = ...
        HartigansDipTest(pdist(nonepear));
    
    temptwoc.dip = ...
        HartigansDipTest(pdist(twoclust));
    
    tempskew.null = struct('dip',ec);
    tempkurt.null = struct('dip',ec);
    tempboth.null = struct('dip',ec);
    tempnone.null = struct('dip',ec);
    temptwoc.null = struct('dip',ec);
    
    for ii = 1:Niter
        % use rand, not gaussian, distributions
        % and for that matter, don't do pairwise distances; just contrast against the uniform random distribution, raw.
        % the uniform random distribution is uniformly the worst comparison
        
        %     NN       = N*(N-1)/2; % but man, these are WAYYYY too conservative. The two-cluster case is, like, BARELY significant. But it's so obviously clustered...
        %     skewnull = rand(NN,1);
        %     kurtnull = rand(NN,1);
        %     bothnull = rand(NN,1);
        %     nonenull = rand(NN,1);
        %     twocnull = rand(NN,1);
        
        % maybe contrast against the gaussian pairwise, rather than uniform, distribution? let's see (and keep the parameterization consistent, lest it lead to weird shit when estimating the dip statistic, which already relies on parameter estimates...)
        % perhaps you need to do a permutation of the data as your null distribution, rather than some parametric estimate of the distribution whence it came? This only works for multi-D data, tho... where's the single-D case?
        % (this is the distribution of the pairwise difference between two identical gaussians)
        % (perhaps I should sample differences with replacement rather than merely listing them all exhaustively? so that this null distribution actually applies? since the independent-samples assumption is fucked when listing all pairwise distances exhaustively)
        % (but let's test it out before getting too hasty)
        NN       = N*(N-1)/2;
        skewnull = raylrnd(1,NN,1);
        kurtnull = raylrnd(1,NN,1);
        bothnull = raylrnd(1,NN,1);
        nonenull = raylrnd(1,NN,1);
        twocnull = raylrnd(1,NN,1);
        
        %     skewnull = pdist(rand(N,1)); % these are even MORE permissive than the matched-gaussians approach!
        %     kurtnull = pdist(rand(N,1));
        %     bothnull = pdist(rand(N,1));
        %     nonenull = pdist(rand(N,1));
        %     twocnull = pdist(rand(N,1));
        
        %     skewnull = pdist( mvnrnd(mean(skewpear),cov(skewpear),N) ); % ( mean(skewpear) + std(skewpear)*randn(N,d) ); % these null distributions make the most sense. They allow some VERY skewed distributions to register as "significantly clustered", but by and large they act as a perfectly-balanced sieve, allowing the obviously multimodal data to cruise through easily and keeping all the stress-test unimodal data out (with the exception, again, of the most EXTREMELY skewed distributions imaginable, which admittedly can look a bit like multimodal data where the second mode comes from a smaller, more diffuse source than the first)
        %     kurtnull = pdist( mvnrnd(mean(kurtpear),cov(kurtpear),N) ); % ( mean(kurtpear) + std(kurtpear)*randn(N,d) ); % ...while perhaps perfectly straddling the line between permissive & conservative, this metric is ass. Primarily because it depends upon parameter estimates to construct the null distributions, which can be noisy, fit the data with varying degrees of success, and generally make it obvious that the test is more about having a good null model than it is actually a good determination of the phenomenon you're seeking to demonstrate per se
        %     bothnull = pdist( mvnrnd(mean(bothpear),cov(bothpear),N) ); % ( mean(bothpear) + std(bothpear)*randn(N,d) ); % i.e., do NOT do this.
        %     nonenull = pdist( mvnrnd(mean(nonepear),cov(nonepear),N) ); % ( mean(nonepear) + std(nonepear)*randn(N,d) );
        %     twocnull = pdist( mvnrnd(mean(twoclust),cov(twoclust),N) ); % ( mean(twoclust) + std(twoclust)*randn(N,d) );
        
        [tempskew.null(ii).dip] = ...
            HartigansDipTest((skewnull)); % Although the pairwise-distance computation is similar between this and PAIRS, I prefer the Hartigan statistic to the median-mean-knn approach to computing a statistic that PAIRS introduced.
        
        [tempkurt.null(ii).dip] = ...
            HartigansDipTest((kurtnull));
        
        [tempboth.null(ii).dip] = ...
            HartigansDipTest((bothnull));
        
        [tempnone.null(ii).dip] = ...
            HartigansDipTest((nonenull)); % Although everything seems mostly good, these null distributions are worryingly prone to declaring regular old normal distributions as "nearly significant" (p < 0.2). That makes me feel uncomfortable and could be caused by the same thing ripping what should be similar p values between p=0.01 and p=0.90 across animals & sessions.
        
        [temptwoc.null(ii).dip] = ...
            HartigansDipTest((twocnull));
    end
    
    % compute p values
    % the real data should have a larger value
    % so we test whether the NULL is actually larger
    tempskew.p = mean(arrayfun(@(x) x.dip > tempskew.dip,tempskew.null));
    tempkurt.p = mean(arrayfun(@(x) x.dip > tempkurt.dip,tempkurt.null));
    tempboth.p = mean(arrayfun(@(x) x.dip > tempboth.dip,tempboth.null));
    tempnone.p = mean(arrayfun(@(x) x.dip > tempnone.dip,tempnone.null));
    temptwoc.p = mean(arrayfun(@(x) x.dip > temptwoc.dip,temptwoc.null));
    
    skew_(iterc) = tempskew;
    kurt_(iterc) = tempkurt;
    both_(iterc) = tempboth;
    none_(iterc) = tempnone;
    twoc_(iterc) = temptwoc;
    
    fprintf('done! iterc = %i\n',iterc)
end

%% now we test the distribution of p-values (and hartigan dip statistics per se) across the different samples of the TESTED (read: NOT NULL) distributions
% spoiler: these are ALSO SUPER DUPER finnicky...
% ...indeed, I think sampling pairwise distances with replacement might be the appropriate test, to avoid interdependent samples & all that
% PLUS, it gives me a way to factor in the uncertainty in my estimate of the dip statistic per se (just resample it a bunch), rather than being married to one estimate and hoping that my sampling of the null distribution can do the necessary heavy lifting...

%% OH SHIT
% I never ACTUALLY tested the PAIRS statistic!
% only a precursor (the median distance) to it!
% I still needed to compute the ratio w.r.t. the randomly-generated datasets!
% and compare against (meta-)pairwise associations among those randomly-generated datasets! (as opposed to simply finding the distribution of median distances across your samples and finding where your dataset ranks among them - this is sensitive to noisy parameter estimates? I think? I think the more critical piece comes from having a better estimate of how much the PAIRS stat can vary, rather than the ratio-based PAIRS stat per se...)
% Long story short: I HAVE to revisit this and give it a fair shake!!! Maybe even add a process where I bootstrap PAIRS statistic estimates of my DATA PER SE, rather than relying on each dataset to have a reliable single estimate!
% Indeed, the Hartigan statistic is proving to be both conservative AND finnicky... I think I dismissed PAIRS too soon!!! Especially because I was actually doing it wrong... geez how embarrassing
