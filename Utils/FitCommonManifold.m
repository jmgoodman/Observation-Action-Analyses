function CommonManifoldStruct = FitCommonManifold(X,Y,pairedflag)

% this requires manopt to be installed and on the current matlab path
% if it is not, then you may just have a problem
% note: you are trying to find a subspace wherein variance OF Y is maximized by a one-to-one match with X
% in other words, the loss is asymmetric; swapping X and Y will lead to a different answer!
% (making it symmetrically might make it conceptually cleaner, as we no longer assume one [Y] must be a subspace of the other [X])

%%
% if only 2 inputs, assume pairedflag = false
if nargin < 2
    error('FitCommonManifold needs at least 2 inputs, dummy')
elseif nargin == 2
    pairedflag = false;
elseif nargin > 3
    error('FitCommonManifold needs at most 3 inputs, dummy')
else
    % pass
end

% demean X and Y like a normal person. doing it via orthogonalization is uniformly less powerful (because it omits and axis, rather than merely bringing the two repertoires in register along that axis). and you want all the power you can get!!!
% (you may still end up with situations where, for instance, the firing rates converge on movement onset, but have different baselines, and thus seem to DIverge after mean subtraction. But you're going to miss that case if you orthogonalize, too!)
Xmu = mean(X,1);
Ymu = mean(Y,1);

Xdm = bsxfun(@minus,X,Xmu);
Ydm = bsxfun(@minus,Y,Ymu);

% for each dimensionality
ndims = size(Xdm,2);
assert( size(Xdm,2) == size(Ydm,2),'X and Y need to span the same space, dummy' )

% woah, actually, first off, restrict yourself to meaningful PCA space
[coeff,~,latent] = pca(Ydm); % for the symmetric case, concatenate the two
ndims2keep   = find(latent >= mean(var(Ydm)),1,'last'); % all dimensions that are better than the typical neuron

Xproj        = Xdm * coeff(:,1:ndims2keep);
Yproj        = Ydm * coeff(:,1:ndims2keep);

for p = 1:ndims2keep
    
    if pairedflag % loss function when paired = true ("correlation" extended to a multidimensional framework)
        costq        = @(V,XX,YY) norm( (XX-YY)*V,'fro' )^2 / norm( YY*V,'fro' )^2;
        problem.cost = @(V) costq(V,Xproj,Yproj);
        
        problem.egrad = @(V) 2/norm(Y*V,'fro')^2 * ((X-Y)'*(X-Y))*V ...
            - 2*norm( (X-Y)*V,'fro' )^2/norm(Y*V,'fro')^4*(Y'*Y)*V;
    else % loss function when paired = false (KL divergence)
        %         Ex = cov(Xproj);
        %         Ey = cov(Yproj);
        %         % note: you have de-meaned these datasets before running this analysis. This means that any terms relying on mu1-mu0 will be set to zero
        %         % also note: Y takes the role of P here. X takes the role of Q. Q is the proposed distribution (that gleaned from X), and P is the estimate of the "true" or "target" distribution (that gleaned from Y)
        %         % DKL(P||Q) = DKL(Y||X)
        %         % DKL(0||1) = DKL(Y||X)
        %         % thus, E1 = Ex and E0 = Ey
        %         costq = @(V,XX,YY) trace( (V'*Ex*V)\(V'*Ey*V) ) - p + log( det(V'*Ex*V) ) - log( det(V'*Ey*V) ); % come to think of it, this is actually pretty shitty. because if there ARE clusters, this loss function is going to impose a unimodal Gaussian structure on the distribution. UGHHHH guess I gotta do the EMPIRICAL distributions then (fuckin' shit man what a pain in the fuckin' ass i tell you hwat)
        
        % okay let's do it this way
        % compute the empirical P(x) and Q(x) CDFs
        % then interpolate linearly to get a "smooth" cdf
        % which you can then take the derivative of to estimate pdfs
        % and then you can use these interpolated values to compare across the two
        % note: we actually want to compare the re-projection back into original-space against the original data per se. Basically, we are finding a subspace V s.t. KL(Y||XV) is minimized. We don't project Y onto V so that we can avoid optimizing for trivial, near-singular dimensions; XV needs to explain as much of Y as possible.
        costq = @(V,XX,YY) 
    end

    problem.M  = grassmannfactory(ndims,p);
    
    problem.egrad = @(V) 2/norm(Y*V,'fro')^2 * ((X-Y)'*(X-Y))*V ...
        - 2*norm( (X-Y)*V,'fro' )^2/norm(Y*V,'fro')^4*(Y'*Y)*V;

    %     %         check gradients (debug only)
    %     close all,clc %#ok<DUALC>
    %     checkgradient(problem); pause;
end