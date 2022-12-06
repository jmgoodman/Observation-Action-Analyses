function reducedClassificationProblems(sessionName)
% supplement to Call for control analyses I only thought to do later

%% setup
restoredefaultpath
analysis_setup

%% params
gripCounts    = unique( round( logspace(log10(2),log10(21),10) ) ); % 21 is the grip count in Moe's data
gripCountReps = 100;

subsampleFraction = 0.9; % use the full data
subsampleReps     = 100;
alignments        = {'lighton','move','hold'};
contextSets       = {{'active'},{'passive'},{'active','control'}};

sessionsList       = {sessionName};
orthoState         = {'none','aggro'}; % other ortho conditions ain't so important.

%% init
outputsize = [ numel(sessionsList),numel(orthoState),numel(contextSets),numel(gripCounts),gripCountReps ];
outputs = struct('sessionName',cell(outputsize),...
    'contextSet',cell(outputsize),...
    'orthoState',cell(outputsize),...
    'subsampleFraction',cell(outputsize),...
    'classificationAccuracyCell',cell(outputsize),...
    'classificationOptions',cell(outputsize),...
    'gripCount',cell(outputsize));

%% export init
file2save = fullfile('..','Analysis-Outputs',sprintf('%s-grip-count-control-%s.mat',sessionName,date));

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
            
            ugrips = cellstr( unique( char( tempdatacell{1}{1}.Objects ),'rows' ) );
            ngrips = numel( ugrips );
            
            for subGripInd = 1:numel(gripCounts)
                
                if ngrips <= gripCounts(subGripInd)
                    break
                end
            
                for subGripIter = 1:gripCountReps
                    whichGrips = randperm(ngrips,gripCounts(subGripInd));
                    keepGrips  = ugrips(whichGrips);
                    
                    temptempdatacell = tempdatacell;
                    for ii = 1:numel(temptempdatacell)
                        for jj = 1:numel(temptempdatacell{ii})
                            keepTrials = ismember(temptempdatacell{ii}{jj}.Objects,...
                                keepGrips); % TODO: equalize the number of trials per grip type
                            temptempdatacell{ii}{jj}.Data = temptempdatacell{ii}{jj}.Data(:,:,keepTrials);
                            temptempdatacell{ii}{jj}.Objects = temptempdatacell{ii}{jj}.Objects(keepTrials);
                            temptempdatacell{ii}{jj}.TrialTypes = temptempdatacell{ii}{jj}.TrialTypes(keepTrials);
                            temptempdatacell{ii}{jj}.TurnTableIDs = temptempdatacell{ii}{jj}.TurnTableIDs(keepTrials);
                        end
                    end
                    
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).sessionName = thisSesh;
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).contextSet  = theseContexts;
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).orthoState  = orthoState{orthoind};
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).subsampleFraction = subsampleFraction;
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).gripCount         = gripCounts(subGripInd);

                    opts = makeclassifyopts('transform','none','alignment',alignments,...
                        'targetcontexts',contextSets{ctxind},'PCAdims',30,'transformdims',20,...
                        'nssreps',subsampleReps,'subsampsize',subsampleFraction);
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).classificationOptions = opts;

                    cout = crossclassify_refactor(temptempdatacell,sustainspace,opts);
                    outputs(seshind,orthoind,ctxind,subGripInd,subGripIter).classificationAccuracyCell = cout;
                    % AIP-F5-M1-pooled-chance
                end
                % export to file
                save(file2save,'outputs','-v7.3')
            end
            
        end
    end
end


        