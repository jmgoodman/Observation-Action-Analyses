function pairsstruct = PAIRStest(X,k,d,niter,parallelflag)
% sensitive to skewness or kurtosis (for euclidean distances only though)

if nargin == 1
    k     = 3; % # nearest neighbors
    d     = 8; % # dims
    niter = 1e4; % # resamplings of your null
    parallelflag = true;
elseif nargin == 2
    d     = 8;
    niter = 1e4;
    parallelflag = true;
elseif nargin == 3
    niter = 1e4;
    parallelflag = true;
elseif nargin == 4
    parallelflag = true;
else
    % pass
end

%% set up parallel stuff
if parallelflag
    ncores = feature('numcores');
    ncores_touse = max(ncores - 2,1); % leave a couple of buffer cores to do other normal things / prevent crashes
    
    pc = parcluster('local');
    
    try
        p = parpool(pc,ncores_touse);
    catch err
        delete(gcp('nocreate'))
        p = parpool(pc,ncores_touse);
    end
    
    % windows hack to get around weird parallelization bugs on non-C drives
    currentDir = pwd;
    if ispc && ~strcmpi(currentDir(1),'C')
        oldDir = cd('C:\');
    else
        oldDir = currentDir;
    end
else
    % pass
end
    
%% timing
tic
%% now for the method itself
% apply PCA to X, take the first k components
% (note: PCA automatically centers the data)
[~,score,latent] = pca(X);

scored  = score(:,1:d);
varexp  = sum( latent(1:d) )./sum(latent);

nrows   = size(scored,1); % keep this number for later

datatheta = thetacomp(scored,k,parallelflag); % centered data aligned on axes of most variance (note: not consistent with the original philosophy of PAIRS, where the centrality per se was important)
% datatheta = euccomp(scored,k); % misnomer now that we're trying this with nearest euclidean distances (density-based clustering criterion)
datatheta = median(datatheta);

noisetheta = zeros(nrows,niter);

if parallelflag
    parfor iterc = 1:niter
        noisevals  = mvnrnd( mean(scored), cov(scored), nrows );
        noisescore = bsxfun(@minus,noisevals,mean(noisevals)); % center the data to increase the median angles of your null (and thereby increase the power of your test)
        % you don't need to apply a full PCA over again; rotating ALL the data won't change ANY relative angles or distances, after all. The only important thing is to enforce the same centering on the null as that enforced on the data proper
        % realistically, this shouldn't matter too much, but for small sample sizes this can be an important power-maximizing step!
        
        noisetheta(:,iterc) = thetacomp(noisescore,k,parallelflag);
        %     noisetheta(:,iterc) = euccomp(noisescore,k); % misnomer now that we're using euclidean distances
    end
else
    for iterc = 1:niter
        noisevals  = mvnrnd( mean(scored), cov(scored), nrows );
        noisescore = bsxfun(@minus,noisevals,mean(noisevals)); % center the data to increase the median angles of your null (and thereby increase the power of your test)
        % you don't need to apply a full PCA over again; rotating ALL the data won't change ANY relative angles or distances, after all. The only important thing is to enforce the same centering on the null as that enforced on the data proper (which should act to limit the PAIRS statistic IN the null)
        
        noisetheta(:,iterc) = thetacomp(noisescore,k,parallelflag);
        %     noisetheta(:,iterc) = euccomp(noisescore,k); % misnomer now that we're using euclidean distances
    end
end

dPAIRS = zeros(niter,1);
nPAIRS = zeros(niter,1);

if parallelflag
    parfor iterc = 1:niter
        dt      = datatheta;
        
        fake_dt = noisetheta(:,iterc);
        fake_dt = median(fake_dt);
        
        nt      = noisetheta( :,[1:(iterc-1),(iterc+1):end] ); % probably a more memory-efficient way to do this...
        nt      = median(nt(:)); % grand median, as described in Raposo et al.
        
        dPAIRS(iterc) = (nt - dt)/nt; % PAIRS computation as given in Raposo et al. Denominator doesn't feel super necessary, but I suppose it helps to counteract dependence of the statistic on the quirks of the null sample and instead make it more dependent on the properties of the data per se. In any case, this really, really shouldn't matter unless you're taking a laughably small number of resamplings for a permutation test; that denominator should be pretty constant.
        nPAIRS(iterc) = (nt - fake_dt)/nt;
    end
else
    for iterc = 1:niter
        dt      = datatheta;
        
        fake_dt = noisetheta(:,iterc);
        fake_dt = median(fake_dt);
        
        nt      = noisetheta( :,[1:(iterc-1),(iterc+1):end] );
        nt      = median(nt(:)); % grand median, as descripted in Raposo et al.
        
        dPAIRS(iterc) = (nt - dt)/nt; % PAIRS computation as given in Raposo et al. Denominator doesn't feel super necessary, but I suppose it helps to counteract dependence of the statistic on the quirks of the null sample and instead make it more dependent on the properties of the data per se. In any case, this really, really shouldn't matter unless you're taking a laughably small number of resamplings for a permutation test; that denominator should be pretty constant.
        nPAIRS(iterc) = (nt - fake_dt)/nt;
    end
end
    

pairsstruct.dataPAIRS              = dPAIRS;
pairsstruct.nullPAIRS              = nPAIRS;
pairsstruct.PCA_variance_explained = varexp;
toc

if parallelflag
    cd(oldDir);
    
    % and turn off parallel
    delete(p)
end

%% subfunctions (don't play nice with parallelization, unfort.)

%     function theta = thetacomp(X,k)
%         pdX    = pdist(X,'cosine'); % gives 1-cos
%         cosX   = 1-squareform(pdX); % 1 - (1 - cos) = cos
%         thetaX = acos(cosX);
%         
%         sorttheta = zeros(size(thetaX,1),k);
%         
%         for ii = 1:size(thetaX,1)
%             sortthetatemp   = sort(thetaX(ii,:),'ascend');
%             sorttheta(ii,:) = sortthetatemp(2:(k+1)); % ignore the "self" distance
%         end
%         
%         meantheta   = mean(sorttheta,2);
%         
%         theta = meantheta; % keep all the mean theta values
%     end
% 
%     function euc = euccomp(X,k) % reports nearest euclidean distances rather than nearest neighbor angles
%         pdX = pdist(X,'euclidean'); % this is inefficient. this "exhaustive search" approach to finding nearest-neighbors, that is. use "knnsearch", which does the heavy lifting of transforming your data into a tree structure, and which therefore lets you find nearest neighbors in O(n log n) time rather than O(n^2) time
%         sortdist = zeros(size(pdX,1),k); 
%         
%         for ii = 1:size(pdX,1)
%             sortdisttemp   = sort(pdX(ii,:),'ascend');
%             sortdist(ii,:) = sortdisttemp(2:(k+1));
%         end
%         
%         meandist = mean(sortdist,2);
%         
%         euc      = meandist;
%     end

%% fin
end