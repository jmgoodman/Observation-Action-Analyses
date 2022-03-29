function customlegend(legendnames,varargin)

% makes a custom legend with the legend names supplied (as a cell string)
% this legend will not have symbols, but just have colored text for each line being labeled
assert(iscellstr(legendnames),'legendnames needs to be a cell array of strings');

% default parameter names for name-value pairs are given below
opts.xoffset  = 0.025;
opts.yoffset  = 0.000;
opts.ystep    = 0.1; %0.3 / numel(legendnames);
opts.colors   = zeros(numel(legendnames),3);
opts.fontname = get(0,'defaultaxesfontname');
opts.fontsize = get(0,'defaultaxesfontsize');

% parse varargin
for inputind = 1:2:numel(varargin)
    inputname = lower(varargin{inputind});
    
    if isfield(opts,inputname)
        opts.(inputname) = varargin{inputind+1};
    else
        warning('%s is not a valid input name. ignoring this name-value pair',varargin{inputind})
    end
end


% first, establish the location of your legend
% it will be just outside your plot, top-right corner
% xl = get(gca,'xlim');
% yl = get(gca,'ylim');

% xpos = xl(2) + opts.xoffset*range(xl);
% ypos = yl(2) - opts.yoffset*range(yl);

xpos = 1 + opts.xoffset; % for normalized coordinates
ypos = 1 - opts.yoffset;

for stringind = 1:numel(legendnames)
    text(xpos,ypos - opts.ystep*(stringind-1),...
        legendnames{stringind},'fontname',opts.fontname,...
        'fontsize',opts.fontsize,'color',opts.colors(stringind,:),...
        'horizontalalign','left','verticalalign','top',...
        'units','normalized');
end

return


