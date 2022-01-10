function datastruct = dataload(seshstr,normalizeflag,tensorflag)

% seshstr is the string associated with the session you want to load.
%
% normalizeflag can be one of 'softnorm', 'sqrt', or 'none'.
% default is softnorm, which uses the built-in normalization of preprocess.
% 'softnorm' is nice for REALLY making sure you don't overweight high-spiking neurons
% 'sqrt' is another transform which should hopefully prohihibit the "noise" of high-spiking neurons from having outsize influence on their manifold weighting & variance contribution. Namely, by holding the variance of the distribution constant (at roughly 1/4) for large values of the mean. 
%   That said, I also don't want the amplitude of task-dependent fluctuations, which will vary idiosyncratically at least in part due to sampling considerations, to have an outsize effect on manifold weighting. Nonetheless, I implement the sqrt transform here for completeness.
% 'none' is nice for plotting PETHs.
%
% tensorflag can be one of 'alltasks', 'allturntables', or 'none'. default is 'allturntables'.

if nargin < 2
    normalizeflag = 'softnorm';
else
    % pass
end

datastruct.normalization = normalizeflag;

if nargin < 3
    tensorflag = 'allturntables';
else
    % pass
end

datastruct.tensortype = tensorflag;

if isempty(regexpi(seshstr,'\.mat$','once'))
    seshfile = strcat(seshstr,'.mat');
else
    seshfile = seshstr;
    seshstr  = seshstr(1:(end-4));
end

datastruct.session = seshstr;

M = load(seshfile);

fn = fieldnames(M);
M = M.(fn{1});

if strcmpi(normalizeflag,'softnorm')
    [ppd,nfacs] = preprocess(M,'removebaseline',false,'normalize',true); % NEVER remove baseline, though. Note, this normalization uses trial-averaged structure to determine soft-normalization factors in an attempt to get a more stable estimate of the "max" firing rate. Such are the compromises one must make when using non-robust statistics...
else
    [ppd,nfacs] = preprocess(M,'removebaseline',false,'normalize',false);
end

if strcmpi(normalizeflag,'sqrt') || ~isempty(regexpi(normalizeflag,'root','once'))
    for ii = 1:numel(ppd)
        for jj = 1:numel(ppd{ii})
            ppd{ii}{jj}.Data = sqrt( ppd{ii}{jj}.Data ); % here, we just apply sqrt transformation to the raw data.
        end
    end
else
    % pass
end

% now the datatensor
% there are two flavors of tensorize:
% alltask: allows one to include MGG, but only use one turntable of objects (albeit the most diverse one)
% allturntable: allows one to include all turntables, but only includes VGG and Obs.
% default is regular.

if strcmpi(tensorflag,'allturntables')
    [dt,al,lstruct] = tensorize(ppd);
    goodtensor = true;
elseif strcmpi(tensorflag,'alltasks')
    [dt,al,lstruct] = tensorizeTT1(ppd);
    goodtensor = true;
elseif strcmpi(tensorflag,'none')
    goodtensor = false;
else % skip tensor-making otherwise. it's a pretty lengthy operation, all things considered!
    warning('invalid tensorflag given, defaulting to ''none'' flag');
    goodtensor = false;
end

datastruct.cellform           = ppd;
datastruct.normalizefactors   = nfacs;

if goodtensor
    datastruct.tensorform          = dt;
    datastruct.tensorarraylabels   = al;
    datastruct.tensorepochnames    = {'fixation','light on','light off','go cue','move start','hold start','reward'};
    datastruct.tensorepochbininds  = num2cell(bsxfun(@plus,repmat(1:100,7,1),(0:100:600)'),2);
    datastruct.tensorepochbincenters_inmilliseconds = num2cell(10*bsxfun(@minus,repmat(1:100,7,1),50.5),2);
    datastruct.tensordimlabels     = {'neuron','object','context','time','trial'};
    datastruct.tensorobjectlabels  = lstruct.objects;
    datastruct.tensorcontextlabels = lstruct.contexts;
else
    % pass
end