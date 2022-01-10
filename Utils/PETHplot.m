function h = PETHplot(muvals,sevals,optionstruct)

ncols = size(muvals,2);
nrows = size(muvals,1);

if nargin == 1
    sevals = [];
else
    assert( all(size(muvals) == size(sevals)),'mean and error must be equal-sized matrices' );
end

if nargin == 2
    optionstruct.colors = lines(ncols);
    optionstruct.tvals  = (1:nrows)';
    optionstruct.linestyles = repmat({'-'},ncols,1);
else
    fn = fieldnames(optionstruct);
    
    if ~ismember('colors',fn)
        optionstruct.colors = lines(ncols);
        warning('optionstruct given, but it had no "colors" field')
    end
    
    if ~ismember('tvals',fn)
        optionstruct.tvals  = (1:nrows)';
        warning('optionstruct given, but it had no "tvals" field')
    end
    
    if ~ismember('linestyles',fn)
        optionstruct.linestyles  = repmat({'-'},ncols,1);
        warning('optionstruct given, but it had no "linestyles" field')
    end
    
    assert(numel(optionstruct.tvals) == nrows,'time axis values do not match number of rows of firing rates!')
end

if nargout == 1
    h = gcf;
else
end

tvals = optionstruct.tvals;

for ii = 1:ncols
    hold all
    plot(tvals,muvals(:,ii),'linewidth',1,'color',optionstruct.colors(ii,:),...
        'linestyle',optionstruct.linestyles{ii})
    
    if ~isempty(sevals)
        hold all
        patch( [tvals;flipud(tvals)],...
            [muvals(:,ii)+sevals(:,ii);...
            flipud( muvals(:,ii) - sevals(:,ii) )],...
            optionstruct.colors(ii,:),...
            'facealpha',0.1,...
            'edgealpha',0 )

    else
        % pass
    end
    
end

return
    

    