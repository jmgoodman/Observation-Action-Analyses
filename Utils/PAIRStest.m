function pairsstruct = PAIRStest(X,k,d,niter)
% sensitive to skewness or kurtosis (for euclidean distances only though)

if nargin == 1
    k     = 3; % # nearest neighbors
    d     = 8; % # dims
    niter = 1e4; % # resamplings of your null
elseif nargin == 2
    d     = 8;
    niter = 1e4;
elseif nargin == 3
    niter = 1e4;
else
    % pass
end

% apply PCA to X, take the first k components
[~,score,latent] = pca(X);

scored  = score(:,1:d);
varexp  = sum( latent(1:d) )./sum(latent);

nrows   = size(scored,1); % keep this number for later

datatheta = thetacomp(scored,k); % centered data aligned on axes of most variance
% datatheta = euccomp(scored,k); % misnomer now that we're trying this with nearest euclidean distances (density-based clustering criterion)
datatheta = median(datatheta);

noisetheta = zeros(nrows,niter);

for iterc = 1:niter
    noisevals  = mvnrnd( mean(scored), cov(scored), nrows );
    noisescore = bsxfun(@minus,noisevals,mean(noisevals)); % center the data to increase the median angles of your null (and thereby increase the power of your test)
    % you don't need to apply a full PCA over again; rotating ALL the data won't change ANY relative angles or distances, after all. The only important thing is to enforce the same centering on the null as that enforced on the data proper (which should act to limit the PAIRS statistic IN the null)
    
    noisetheta(:,iterc) = thetacomp(noisescore,k);
    %     noisetheta(:,iterc) = euccomp(noisescore,k); % misnomer now that we're using euclidean distances
end

dPAIRS = zeros(niter,1);
nPAIRS = zeros(niter,1);

for iterc = 1:niter
    dt      = datatheta;
    
    fake_dt = noisetheta(:,iterc);
    fake_dt = median(fake_dt);
    
    nt      = noisetheta( :,[1:(iterc-1),(iterc+1):end] );
    nt      = median(nt(:)); % grand median, as descripted in Raposo et al.
    
    dPAIRS(iterc) = (nt - dt)/nt; % PAIRS computation as given in Raposo et al. Denominator doesn't feel super necessary, but I suppose it helps to counteract dependence of the statistic on the quirks of the null sample and instead make it more dependent on the properties of the data per se. In any case, this really, really shouldn't matter unless you're taking a laughably small number of resamplings for a permutation test; that denominator should be pretty fucking constant.
    nPAIRS(iterc) = (nt - fake_dt)/nt;
end

pairsstruct.dataPAIRS              = dPAIRS;
pairsstruct.nullPAIRS              = nPAIRS;
pairsstruct.PCA_variance_explained = varexp;


%% subfunctions

    function theta = thetacomp(X,k)
        pdX    = pdist(X,'cosine'); % gives 1-cos
        cosX   = 1-squareform(pdX); % 1 - (1 - cos) = cos
        thetaX = acos(cosX);
        
        sorttheta = zeros(size(thetaX,1),k);
        
        for ii = 1:size(thetaX,1)
            sortthetatemp   = sort(thetaX(ii,:),'ascend');
            sorttheta(ii,:) = sortthetatemp(2:(k+1)); % ignore the "self" distance
        end
        
        meantheta   = mean(sorttheta,2);
        
        theta = meantheta; % keep all the mean theta values
    end

    function euc = euccomp(X,k) % reports nearest euclidean distances rather than nearest neighbor angles
        pdX = pdist(X,'euclidean'); % this is inefficient. this "exhaustive search" approach to finding nearest-neighbors, that is. use "knnsearch", which does the heavy lifting of transforming your data into a tree structure, and which therefore lets you find nearest neighbors in O(n log n) time rather than O(n^2) time
        sortdist = zeros(size(pdX,1),k); 
        
        for ii = 1:size(pdX,1)
            sortdisttemp   = sort(pdX(ii,:),'ascend');
            sortdist(ii,:) = sortdisttemp(2:(k+1));
        end
        
        meandist = mean(sortdist,2);
        
        euc      = meandist;
    end

%% fin
end