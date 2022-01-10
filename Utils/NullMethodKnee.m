function [n,latent,null_latent] = NullMethodKnee(data2permute,Niter)
% VERY conservative method.
% n = number of components to keep (where the "knee" is)
% latents = variances of regular pca components
% null_latents = variances of permuted data over niter iterations
% orig_data = the data to perform the analysis on
% Niter = number of permutations to run

[~,~,latent] = pca(data2permute);

% null distribution method
null_latent = zeros(Niter,numel(latent));

for itercount = 1:Niter
    permuteddata = nan(size(data2permute));
    for colind = 1:size(data2permute,2)
        tempcol  = data2permute(:,colind);
        perminds = randperm( numel(tempcol) );
        permcol  = tempcol(perminds);
        permuteddata(:,colind) = permcol;
    end
    [~,~,permlatent] = pca(permuteddata);
    null_latent(itercount,:) = permlatent(:)';
end

% plot bonferroni-corrected percentile (95th)
null95  = prctile(null_latent,100 - 5/numel(latent),1); % being verrrry conservative about what we decide to keep
n       = find(latent(:) < null95(:),1,'first')-1; % find the first index where the curve drops below the null distribution. there might be "knees" after this first one, but we take the first to be maximally conservative.

return