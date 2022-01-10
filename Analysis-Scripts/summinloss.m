function loss = summinloss(distmat,soln)

dtemp = distmat(soln,soln);

% dtemp = dtemp + diag( inf(numel(soln),1) );
% mindists = min(dtemp,[],2);
% loss     = sum(mindists); % alternatively, you could choose a loss that takes the overall minimum edge length in your graph. (although this will mean that, among the "terminally far away" points, you don't end up picking up on guys that further expand your repertoire, since they don't affect the global minimum! with a sum of minima, you COULD pick that up!)

% % alternatively, make this the sum of log edge lengths
% % (this way, edges are guided away from "clusters" should they form)
% dtemp = dtemp + diag( inf(numel(soln),1) );
% dlog  = log(dtemp);
% dlog  = min(dlog,[],2); % use the MINIMUM side lengths only!
% loss  = sum(dlog(:)); % yeah, so there's some redundancy in this computation that could be eliminated to speed it up by a factor of two. but in the end, the output should be equivalent, and I'm not doing anything SUPER fancy... yet...

% alternatively: softmin (maximize the minimum distance overall)
% equal to softmax(-x)

% % softmin-weighted sum (i.e., a proper softmin, not a soft-ARG-min!!!)
% % making it SOFT-min means we still give weight to the other distances, but still apply higher weight to especially close grips! we do NOT want any to be close!!!)
% dtemp = dtemp + diag( inf(numel(soln),1) );
% mindists = min(dtemp,[],2);
% softargmin = exp(-mindists) ./ sum( exp(-mindists) );
% softmin    = sum( softargmin.*mindists );
% loss       = softmin;

% softmin-weighted sum OVERALL (of LOG distances, since distances per se are already limited to be greater than 0 so we don't need to exp them)
dtemp = squareform(dtemp); % convert into vector with no duplicates
softargmin = (1./dtemp) ./ sum( (1./dtemp) );
softmin    = sum( softargmin .* log(dtemp) );
loss       = softmin;

return