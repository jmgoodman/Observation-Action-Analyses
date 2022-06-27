function supplementalAnalysis(sessionName)
% supplement to Call for control analyses I only thought to do later

%% setup
restoredefaultpath
analysis_setup

%% params
subsampleFractions = logspace(log10(0.1),log10(0.9),10); % exponentially increase the fraction - the difference between 80% and 90% is a lot less significant than that between 10% and 20%
subsampleReps      = 100; % higher than the "canonical" subsample count, since we are now trying to estimate the effect of subsample size and it'd really stink to have a bad estimate of a particular subsample's performance...
alignments         = {'lighton','move','hold'};
contextSets        = {{'active'},{'passive'},{'active','control'}}; % nominally, the only thing that REALLY matters here is how classification accuracy scales in the active context. That said, it's nice to have numbers on how the passive context scales, too.

% sessionsList       = {'Moe46','Moe50','Zara64','Zara70'}; % ignore Zara68, too few units to start with...
sessionsList       = {sessionName};
orthoState         = {'none','aggro'}; % other ortho conditions ain't so important.

%% init
outputsize = [ numel(sessionsList),numel(orthoState),numel(contextSets),numel(subsampleFractions) ];
outputs = struct('sessionName',cell(outputsize),...
    'contextSet',cell(outputsize),...
    'orthoState',cell(outputsize),...
    'subsampleFraction',cell(outputsize),...
    'classificationAccuracyCell',cell(outputsize),...
    'classificationOptions',cell(outputsize));

%% loop
for seshind = 1:numel(sessionsList)
    thisSesh    = sessionsList{seshind};
    dataFile    = fullfile('..','MirrorData',sprintf('%s_datastruct.mat',thisSesh));
    sustainFile = fullfile('..','Analysis-Outputs',thisSesh,...
        sprintf('sustainspace_results_%s.mat',thisSesh));
    
    load(dataFile,'datastruct');
    load(sustainFile,'sustainspace_aggressive');
    
    % get the animal name from the session name - this is important for
    % later
    animalName = regexpi(thisSesh,'\d+','split');
    animalName = animalName{1};
    
    for orthoind = 1:numel(orthoState)        
        if orthoind == 1
            sustainspace = [];
        else
            sustainspace = sustainspace_aggressive;
        end
        
        for ctxind = 1:numel(contextSets)
            theseContexts = contextSets{ctxind};
            contextName   = theseContexts{1};
            
            % implement kinematic clustering
            switch contextName
                case 'active'
                    switch animalName
                        case 'Moe'
                            kc = load('moeClusters.mat');
                            kc = kc.clusterstruct;
                            % kc = moe_kinclust;
                        case 'Zara'
                            kc = load('zaraClusters.mat');
                            kc = kc.clusterstruct;
                            % kc = zara_kinclust;
                    end
                    
                case 'passive'
                    kc = load('humanClusters.mat');
                    kc = kc.clusterstruct;
                    % kc = human_kinclust;
            end
            
            % kinclust: replace object names with cluster IDs
            tempdatacell = datastruct.cellform;
            for ii = 1:numel(tempdatacell) % for each array
                for jj = 1:numel(tempdatacell{ii}) % for each alignment
                    for kk = 1:numel(kc.objnames) % for each object, replace the object name with the cluster label
                        theseinds = ismember( ...
                            tempdatacell{ii}{jj}.Objects,...
                            kc.objnames{kk} );
                        tempdatacell{ii}{jj}.Objects(theseinds) = {num2str(kc.clusterinds(kk))};
                    end
                end
            end
            
            for fracind = 1:numel(subsampleFractions)
                outputs(seshind,orthoind,ctxind,fracind).sessionName = thisSesh;
                outputs(seshind,orthoind,ctxind,fracind).contextSet  = theseContexts;
                outputs(seshind,orthoind,ctxind,fracind).orthoState  = orthoState{orthoind};
                outputs(seshind,orthoind,ctxind,fracind).subsampleFraction = subsampleFractions(fracind);
                opts = makeclassifyopts('transform','none','alignment',alignments,...
                    'targetcontexts',contextSets{ctxind},'PCAdims',30,'transformdims',20,...
                    'nssreps',subsampleReps,'subsampsize',subsampleFractions(fracind));
                outputs(seshind,orthoind,ctxind,fracind).classificationOptions = opts;
                
                cout = crossclassify_refactor(tempdatacell,sustainspace,opts);
                outputs(seshind,orthoind,ctxind,fracind).classificationAccuracyCell = cout;
            end
        end
    end
end

%% export
file2save = fullfile('..','Analysis-Outputs',sprintf('%s-subsample-size-control-%s.mat',sessionName,date));
save(file2save,'outputs','-v7.3')
        