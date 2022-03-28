function axisHandle = pairedColorBar(axisHandle,titleString,varargin)

% oldAxisHandle     (optional) axis handle to give a colorbar
% newAxisHandle     axis handle with colorbar info paired with it
% varargin          the set of inputs you would normally give the colorbar function

% this function creates a colorbar and adds its handle to the UserData
% field of the axis handle with which it is bound.
%
% it also has bonus functionality 

if nargin == 0
    axisHandle = gca;
else
    % pass
end

colorbarHandle = colorbar(varargin{:});

if exist('titleString','var')
    set(colorbarHandle.Title,'Units','normalized');
    set(colorbarHandle.Title,'Position',[3 0.5 0],'Rotation',90,...
        'String',titleString);
else
    % pass
end

axisHandle.UserData.ColorBar = colorbarHandle;

return