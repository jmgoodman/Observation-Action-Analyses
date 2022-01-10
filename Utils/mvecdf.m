function mvcdfvals = mvecdf(X)

% X is some d-dimensional dataset comprising n samples
% mvcdfvals is an n-sample vector comprising the cdf values of those data
% with cdf of X[i,:] being the probability that any sample in X is less than or equal to X[i,:] along ALL cardinal axes
n = size(X,1);
d = size(X,2);

% now pad with infs
Xpad      = vertcat(X,inf(1,d));
mvcdfvals = nan(n,1);

for sampind = 1:n
    Xtemp = Xpad(sampind,:);
    nlt   = sum( all( bsxfun(@le,Xpad,Xtemp),2 ) );
    mvcdfvals(sampind) = nlt / (n+1);
end

% lol this is awful. turns out, the values shrink to laughably low levels as you increase the dimensionality. Due to the super restrictive all-or-nothing criterion.    
    
    
