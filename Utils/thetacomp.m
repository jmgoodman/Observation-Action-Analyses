function theta = thetacomp(X,k,parallelflag)
% subfunction of PAIRStest
%
% I seem to recall that Euclidean distances was a bad idea, but I don't
% remember why.
%
% In any case, the PAIRS paper has a similar use case (i.e., not JUST
% preferred directions in 2D space) and still uses cosine distance to test
% clustering, so in order to just say "we used the PAIRS test", I should...
% just use the dang PAIRS test.

pdX    = pdist(X,'cosine'); % gives 1-cos
cosX   = 1-squareform(pdX); % 1 - (1 - cos) = cos
thetaX = acos(cosX);

sorttheta = zeros(size(thetaX,1),k);

if parallelflag
    parfor ii = 1:size(thetaX,1)
        sortthetatemp   = sort(thetaX(ii,:),'ascend');
        sorttheta(ii,:) = sortthetatemp(2:(k+1)); % ignore the "self" distance
    end
else
    for ii = 1:size(thetaX,1)
        sortthetatemp   = sort(thetaX(ii,:),'ascend');
        sorttheta(ii,:) = sortthetatemp(2:(k+1)); % ignore the "self" distance
    end
end
    
meantheta   = mean(sorttheta,2);

theta = meantheta; % keep all the mean theta values

end