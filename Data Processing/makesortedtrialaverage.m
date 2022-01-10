function sortedtrialaverage = makesortedtrialaverage(timeXneurXtrialtensor,trialsortlabels)

% this takes a 3d time x neur x trial tensor (like those in the individual "Data" fields of the cell structure that "preprocess" outputs)
% and converts it into a time x neur x condition tensor of trial-averaged firing rates

[~,~,uinds] = unique(trialsortlabels);

sortedtrialaverage = nan( size(timeXneurXtrialtensor,1),...
    size(timeXneurXtrialtensor,2),...
    max(uinds) );

for uind = 1:max(uinds)
    thesetrials = uinds == uind;
    sortedtrialaverage(:,:,uind) = nanmean( ...
        timeXneurXtrialtensor(:,:,thesetrials),3 );
end

return