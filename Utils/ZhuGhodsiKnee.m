function [n,LL] = ZhuGhodsiKnee(latent)
% n      = number of components to keep (where the "knee" is)
% LL     = log likelihoods of the data given i=index is the "pivot"
% latent = vector of pca component variances

% Zhu & Ghodsi 2006
% Automatic dimensionality selection from the scree plot via the use of profile likelihood
% Computational Statistics & Data Analysis
p = numel(latent);
llvals = zeros(p-1,1);
for q = 1:(p-1)
    L1 = latent(1:q);
    L2 = latent( (q+1):end );
    
    mu1 = mean(L1);
    mu2 = mean(L2);
    
    s12 = var(L1);
    s22 = var(L2);
    
    sigma2 = ( (q-1)*s12 + (p-q-1)*s22 )/(p-2);
    
    llfun = @(d,mu,sigma2) log( 1/sqrt(2*pi*sigma2) * exp(-(d - mu)^2 / (2*sigma2)) );
    
    llfunvals = zeros(p,1);
    for ind1 = 1:q
        llfunvals(ind1) = llfun(L1(ind1),mu1,sigma2);
    end
    
    for ind2 = (q+1):p
        llfunvals(ind2) = llfun(L2(ind2-q),mu2,sigma2);
    end
    
    llvals(q) = sum(llfunvals);
end

[~,n] = max(llvals);
LL    = llvals;

return