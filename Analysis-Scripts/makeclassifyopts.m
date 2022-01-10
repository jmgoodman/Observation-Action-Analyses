function opts = makeclassifyopts(varargin)
% "opt" is a struct with the following fields:
% alignment: string reading 'move', 'hold', 'lighton', 'lightoff', or a cell array with several of these. default 'move'.
% binwidth: positive double specifying how large, in ms, the bin size should be. default 500.
% binshift: positive double specifying how large, in ms, the shift between different bins should be. default 250.
% transform: linear transform used to align the action & observation data prior to classification. a string reading 'cca', 'pls', 'nonuniform-rescale', 'noscale-procrustes', or 'alignspace', or 'none'. default 'none'.
% pcadims: number of dimensions to take when running PCA for preprocessing. can be a positive integer (for number of PCs). (Plans HAD BEEN to support arguments including: a number from 0 (inclusive) to 1 (exclusive) indicating the target variance fraction to be kept, OR just a string reading 'all' But I decided against this, since my use case only had need for the fixed # of components). Default = 30.
% transformdims: number of dimensions to keep after transformation. can be a +ve integer (for # of dims), OR a string reading 'all' for all dimensions following PCA preprocessing. Default = 12.
% kfold: number of cross-validation folds. default 5.
% datamode: string reading 'neural' or 'kinematic'. Default is 'neural'.
% targetcontexts: which task contexts to compare. include 'control','passive',and/or 'active' as either a single individual string or a cell array thereof. Default {'active','passive'}.
% nssreps: number of subsample repetitions. If "0", do not perform subsampling. Default 20.
% subsampsize: fraction or number of neurons (from the smallest subpopulation) to keep per subsample. float greater than 0 and less than 1 specifies fraction, integer from 1 onward (inclusive) specifies count. Default 0.9.
% mediansplit: default empty array. alternatively, can be struct output of Clustering_ExternalCall (actually, the contraststruct subfield thereof). If not empty, prompts the classifier to first be restricted to the set of neurons with supra-median active-passive index.
% commonspace: default empty array. alternatively, can be a struct output of findcommonspace.m. If not empty, prompts classifier to use the transformation specified by its input (which is symmetrically applied to both obs & exe activity)

%%
% TODO: add subsample size & # of subsamples to parameter set (...or not)

%%
nameinds = 1:2:nargin;
valinds  = 2:2:nargin;

namevals = varargin(nameinds);
valvals  = varargin(valinds);

% *could* use "inputparser", but in any case I have to pack everything into a struct anyway, so doing it like this keeps it all transparent, at the very least.

opts.alignment      = 'move';
opts.binwidth       = 500;
opts.binshift       = 250;
opts.transform      = 'none';
opts.pcadims        = 30;
opts.transformdims  = 12;
opts.kfold          = 5;
opts.datamode       = 'neural';
opts.targetcontexts = {'active','passive'};
opts.nssreps        = 20;
opts.subsampsize    = 0.9;
opts.mediansplit    = [];
opts.commonspace    = [];

legalopts.alignment         = @(x) ( ischar(x) && ismember(lower(x),{'move','hold','lighton','lightoff'}) ) || ...
    ( iscellstr(x) && all(ismember(lower(x),{'move','hold','lighton','lightoff'})) );
legalopts.binwidth          = @(x) isnumeric(x) && numel(x)==1 && x > 0;
legalopts.binshift          = @(x) isnumeric(x) && numel(x)==1 && x > 0;
legalopts.transform         = @(x) ischar(x) && ismember(lower(x),{'pls','nonuniform-rescale','uniform-rescale','procrustes','alignspace','none'});
legalopts.pcadims           = @(x) (isnumeric(x) && x>0 && x==round(x)); %(x == round(x) || x < 1)) || (ischar(x) && strcmpi(x,'all')); % doesn't support all this nice stuff, only +ve integers
legalopts.transformdims     = @(x) ( isnumeric(x) && x>0 && (x == round(x)) ) || (ischar(x) && strcmpi(x,'all'));
legalopts.kfold             = @(x) ischar(x) && ismember(lower(x),{'shuffle','generate','keeptrue'});
legalopts.datamode          = @(x) ischar(x) && ismember(lower(x),{'neural','kinematic'});
legalopts.targetcontexts    = @(x) ( ischar(x) && ismember(lower(x),{'control','passive','active'}) ) || ...
    ( iscellstr(x) && all( ismember( lower(x),{'control','active','passive'} ) ) );
legalopts.nssreps           = @(x) isnumeric(x) && (x==round(x)) && (x>=0);
legalopts.subsampsize       = @(x) isnumeric(x) && ( (x>0 && x<1) || (x==round(x) && x>=1) ); 
legalopts.mediansplit       = @(x) ( isempty(x) || ( isstruct(x) && isfield(x,'pooledneuronIDs') ) );
legalopts.commonspace       = @(x) ( isempty(x) || ( isstruct(x) && isfield(x,'subsamples') ) );

for ii = 1:numel(namevals)
    thisname = lower(namevals{ii});
    thisval  = valvals{ii};
    
    if isfield(opts,thisname)
        checkfun = legalopts.(thisname);
        
        try % there are three results for each typecheck: true, false, and error. try-catch here asserts that 'error' should be treated as 'false'.
            result = checkfun(thisval);
        catch
            result = false;
        end
        
        if result
            opts.(thisname) = thisval;
        else
            warning('Input ''%s'' failed type check and this field therefore remained the default value.',thisname);
        end
        
    else
        warning('Input ''%s'' is not a valid field and was therefore ignored.',thisname)
    end
end
    
end