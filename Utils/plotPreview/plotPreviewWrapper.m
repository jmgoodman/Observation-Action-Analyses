function plotPreviewWrapper(ax)

% a wrapper for plotPreview, for using from the command line
% sets "axes2copy" 
if nargin == 0
    ax = gca;
else
    % pass
end

global axes2Copy
axes2Copy = ax;
plotPreview;

clear axes2Copy