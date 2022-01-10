function [h,a] = ErrorRegion(x,y,yup,ydown,varargin)

% varargin will be name-value pairs according to these options:
opts.facecolor = [0 0 0];
opts.edgecolor = [0 0 0];
opts.linecolor = [0 0 0];
opts.linewidth = 1;
opts.facealpha = 0.2;
opts.edgealpha = 0;
opts.linestyle = '-';

for ii = 1:2:numel(varargin)
    varname = lower( varargin{ii} );
    varval  = varargin{ii+1};
    
    fn = fieldnames(opts);
    
    if ismember(varname,fn)
        opts.(varname) = varval;
    else
        warning('%s is not a valid field name',varname)
    end
end

h = gcf;
a = gca;
patch( [x(:);flipud(x(:))],[y(:)+yup(:);flipud(y(:)-ydown(:))],opts.facecolor,...
    'edgecolor',opts.edgecolor,'facealpha',opts.facealpha,'edgealpha',opts.edgealpha,...
    'linestyle',opts.linestyle )
hold all
plot( x(:), y(:), 'linewidth',opts.linewidth, 'color',opts.linecolor,...
    'linestyle',opts.linestyle )

return

