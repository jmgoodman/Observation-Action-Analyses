function [transformX,transformY] = datatransform(X,Y,ndims,kind,pcdims)
% fit a data transform that maximizes the alignment of X onto Y using only ndims dimensions. "Y" functions as the "target" data, "X" as the "source".
% "kind" can be one of:
%   'procrustes' - a procrustes modelto fit X to Y.
%   'PLS' - just fit a PLS model to fit X to Y.
%   'procrustes' - find an optimal subspace that minimizes the procrustes distance (which allows uniform scaling, rotation, and reflection). Notably, this eliminates arbitrary scaling as a factor and focuses instead on just allowing rotations (i.e., the idea that the mirror mechanism is actually false and the 'anti-mirror' mechanism reigns, namely, that information is preserved but explicitly shunted into orthogonal dimensions)
%   'nonuniform-rescale' - find an optimal subspace and strictly-nonnegative set of scaling weights that capture the most variance in Y using X. No rotations or reflections allowed!
%   'uniform-rescale' - find an optimal subspace and a single strictly-nonnegative scaling factor that capture the most variance in Y using X.
%   'alignspace' - find an optimal subspace (with no rescaling) that captures the most variance in Y using data from X
%   'none' - the null transform
%

% prior to all these steps, both X and Y are de-meaned and projected onto the top pcdims (default 30, or all dimensions if X and Y are fewer than 30-D) PCs of Y.
% note that X and Y need to have the same shape or this script won't work!!! PLS and null transform would technically work without X and Y having the same column counts, but for philosophical reasons (and compatibility with other methods), they will not when invoking this function.

%% step 0: assertion
assert( all( size(X) == size(Y) ),'X and Y must be the same size (the same data from different contexts')

%% step 1: preprocess
muX = nanmean(X,1);
muY = nanmean(Y,1);
ndims_total = size(muY,2);

% we only want origin-preserving transformations, so the dimensions which contain the global mean & those which contain the differences among means will be removed
if norm(muX) < 1e-6
    if norm(muY) < 1e-6
        meannull = eye(ndims_total);
    else
        meannull = null(muY);
    end
else
    if norm(muY) < 1e-6
        meannull = null(muX);
    elseif norm(muX - muY) < 1e-6
        mumu = mean([muX;muY],1);
        meannull = null(mumu); % if the two means are nonzero, but not different, don't make it a two-axis affair: just get your best estimate of their shared mean & orthogonalize w.r.t. that
    else
        meannull = null([muX;muY]); % orthogonalize w.r.t. the plane defined by the triangle formed by the origin, the mean in condition 1, and the mean in condition 2.
    end
end


X_ = X * meannull; % being orthogonal to the means should render these to be zero-mean matrices.
Y_ = Y * meannull;

if norm(mean(X_)) >1e-6 || norm(mean(Y_)) > 1e-6
    warning('means are somehow nonzero after orthogonalizing w.r.t. them. help!')
end


% next, apply PCA
% focus on "Y", i.e., the "target" context
pcd = min( [pcdims, size(X_,2),size(X_,1)-1] );
[coeff,Ypca] = pca(Y_,'numcomponents',pcd);
Xpca = X_*coeff;

% reassign X and Y
X = Xpca;
Y = Ypca;

warning('off', 'manopt:getHessian:approx')

% NOW we get to fit a model
nc = min( ndims, pcd );
switch lower(kind)
    case 'procrustes' % reflection & scaling enabled. as powerful as we can get without going full nonuniform scaling or linear with it
        [~,~,transform] = procrustes(Ypca,Xpca,'scaling',true,'reflection',true); % X is being transformed to match Y. procrustes transforms the second input to match the first.
        transformX = @(X) transform.b*(X*meannull*coeff)*transform.T + transform.c;
        transformY = @(Y) Y*meannull*coeff;
        return
        
    case 'pls'
        [~,~,~,~,BETA] = plsregress(Xpca,Ypca,nc);
        transformX = @(X) [ones(size(X,1),1),X*meannull*coeff]*BETA;
        transformY = @(Y) Y*meannull*coeff; % be sure to remember to put the preprocessing into the set of transformations,too!
        return
        
    case 'nonuniform-rescale'
        elements.V = stiefelfactory(pcd,nc);
        elements.b = positivefactory(nc,1);
        problem.M  = productmanifold(elements);
        
        problem.cost  = @(P) norm( X*P.V*diag(P.b)*P.V' - Y,'fro' )^2; % maximize variance capture
        problem.egrad = @(P) struct('V',2*X'*(X*P.V*diag(P.b)*P.V'-Y)*P.V*diag(P.b) + ...
            2*(P.V*diag(P.b)*P.V'*X' - Y')*X*P.V*diag(P.b),...
            'b',diag( 2*(X*P.V)'*( (X*P.V)*diag(P.b)*P.V'-Y )*P.V ) );
        
        optopts.tolgradnorm = 1e-3;
        optopts.verbosity   = 0;
        Mfit = trustregions(problem,[],optopts);
        
        transformX = @(X) X*meannull*coeff*Mfit.V*diag(Mfit.b)*Mfit.V';
        transformY = @(Y) Y*meannull*coeff;
        return
        
    case 'uniform-rescale'
        elements.V = stiefelfactory(pcd,nc);
        elements.b = positivefactory(1,1);
        problem.M  = productmanifold(elements);
        
        problem.cost  = @(P) norm( X*P.V*P.b*P.V' - Y,'fro' )^2;
        problem.egrad = @(P) struct('V',2*P.b*X'*(P.b*X*P.V*P.V'-Y)*P.V + ...
            2*P.b*(P.b*P.V*P.V'*X'-Y')*X*P.V,...
            'b',2*trace(X*P.V*P.V'*( P.b*P.V*P.V'*X'-Y' )) );
        
        optopts.tolgradnorm = 1e-3;
        optopts.verbosity   = 0;
        Mfit = trustregions(problem,[],optopts);
        
        transformX = @(X) X*meannull*coeff*Mfit.V*Mfit.b*Mfit.V';
        transformY = @(Y) Y*meannull*coeff;
        return
        
    case 'alignspace'
        problem.M  = stiefelfactory(pcd,nc);
        
        
        problem.cost  = @(V) norm( X*V*V' - Y,'fro' )^2;
        problem.egrad = @(V) 2*X'*(X*V*V'-Y)*V + ...
            2*(V*V'*X' - Y')*X*V;
        
        optopts.tolgradnorm = 1e-3;
        optopts.verbosity   = 0;
        Mfit = trustregions(problem,[],optopts);
        
        transformX = @(X) X*meannull*coeff*(Mfit*Mfit');
        transformY = @(Y) Y*meannull*coeff;
        return
        
    case 'none' % which is a lie, we still apply the "mean-null" and PCA dimensionality reductions. But importantly, the difference between the X and Y transforms is zilch. ALSO, we *DO* reduce the number of PCs kept to the number of TRANSFORM dimensions at this stage, for consistency with other transforms.
        transformX = @(X) X*meannull*coeff(:,1:nc);
        transformY = @(Y) Y*meannull*coeff(:,1:nc);
        return
        
end

warning('on', 'manopt:getHessian:approx')


end