%% calls methods (only the ones that require parallel processing, and their prerequisites)

%% cleanup
clear,clc,close all

%% setup
restoredefaultpath
analysis_setup

%% clustering

fullpath = fullfile('..','Analysis-Outputs','clustfiles');
fname    = 'clustout_stats.mat';

D = dir(fullpath);
Dnames = arrayfun(@(x) x.name,D,'uniformoutput',false);

if ismember(fname,Dnames) % exist(fname,'file') == 2
    cstruct = load(fullfile(fullpath,fname));
else
    cstruct = Clustering_ExternalCall;
end

%% run kinematic clustering
kcstruct_moe   = moe_kinclust;
kcstruct_zara  = zara_kinclust;
kcstruct_human = human_kinclust;

%% load data
sesh_strs = {'Moe32','Moe34','Moe46','Moe50','Zara64','Zara68','Zara70'};

warning('off','manopt:getHessian:approx')
for sesh_ind = 1:numel(sesh_strs)
    seshstr    = sesh_strs{sesh_ind};

    % set a flag to ignore neural data stuff for sessions 32 and 34, which are just for kinematics
    if strcmpi(seshstr,'moe32') || strcmpi(seshstr,'moe34')
        neuralflag = false;
    else
        neuralflag = true;
    end
    
    ismoe = ~isempty(regexpi(seshstr,'Moe','once'));
    
    load(sprintf('%s_datastruct.mat',seshstr));
    
    olddir = cd( fullfile('..','Analysis-Outputs') );
    mkdir(seshstr);
    cd(olddir);
    
    if neuralflag
        this_cs_ind = find( ismember(cstruct.seshnames,seshstr) );
        this_cs     = cstruct.contraststruct(this_cs_ind);
    else
        % pass
    end

    %% find sustained space
    if neuralflag
        fname = sprintf('sustainspace_results_%s.mat',seshstr);
        olddir = cd( fullfile('..','Analysis-Outputs') );
        D = dir(seshstr);
        Dnames = arrayfun(@(x) x.name,D,'uniformoutput',false);
        if ismember(fname,Dnames) % exist(fname,'file') == 2
            load(fullfile(seshstr,fname))
            cd(olddir);
        else
            cd(olddir);
            sustainspace = findsustainspace(datastruct.cellform,'both','ZhuGhodsi');
            sustainspace_aggressive = findsustainspace(datastruct.cellform,'both','95percent');
            
            olddir = cd( fullfile('..','Analysis-Outputs') );
            cd(seshstr);
            save(fname,'sustainspace','sustainspace_aggressive','-v7.3')
            cd(olddir);
        end
    else
        % pass
    end
    
    %% find common space (outside of sustained space)
    if neuralflag
        fname = sprintf('commonspace_results_%s.mat',seshstr);
        olddir = cd( fullfile('..','Analysis-Outputs') );
        D = dir(seshstr);
        Dnames = arrayfun(@(x) x.name,D,'uniformoutput',false);
        if ismember(fname,Dnames) % exist(fname,'file') == 2
            load(fullfile(seshstr,fname))
            cd(olddir);
        else
            cd(olddir);
            commonspace_FXVE_mov    = findcommonspace(datastruct.cellform,sustainspace,'FXVE','both');
            
            olddir = cd( fullfile('..','Analysis-Outputs') );
            cd(seshstr);
            save(fname,'commonspace_FXVE_mov','-v7.3')
            cd(olddir);
        end
    else
        % pass
    end
    
    %% set up classification opts
    copts.normal.active  = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'active'},'PCAdims',30,'transformdims',20); % "PCAdims" doesn't really matter - in the end we just take the first transformdims PCs
    copts.normal.passive = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'passive'},'PCAdims',30,'transformdims',20);
    copts.withMGG.active = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'active','control'},'PCAdims',30,'transformdims',20); 
    % no passive for now... maybe you want that though? to verify that cross-classification is built on visual representations??? NO. write first, THEN decide if you need it. You've been stuck in the analysis tweaking step of this loop for far too long as it stands...
    % the above advice also applies to rerunning everything with aggressive orthogonalization as the default! no no no! just fuckin' write and work with what you got!!!!!
    
    % "special"-only classification will use the "normal" and "withMGG" settings

    if neuralflag
        % these two settings are meant to demonstrate the lack of overfitting. i.e., if we just focused on the putative mirror neurons or common space, we might have performed better
        copts.mediansplit.active  = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'active'},'PCAdims',30,'transformdims',20,'mediansplit',this_cs);
        copts.mediansplit.passive = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'passive'},'PCAdims',30,'transformdims',20,'mediansplit',this_cs);
        copts.commonspace.active  = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'active'},'PCAdims',30,'transformdims',20,'commonspace',commonspace_FXVE_mov);
        copts.commonspace.passive = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'passive'},'PCAdims',30,'transformdims',20,'commonspace',commonspace_FXVE_mov);
    else
        % pass
    end
    
    %% now, we run the analyses
    if neuralflag
        cstruct.normal.preortho.active = crossclassify_refactor(datastruct.cellform,[],copts.normal.active);
    	cstruct.normal.postortho.active = crossclassify_refactor(datastruct.cellform,sustainspace,copts.normal.active);
    	cstruct.normal.postortho_aggro.active = crossclassify_refactor(datastruct.cellform,sustainspace_aggressive,copts.normal.active);

    	cstruct.normal.preortho.passive = crossclassify_refactor(datastruct.cellform,[],copts.normal.passive);
    	cstruct.normal.postortho.passive = crossclassify_refactor(datastruct.cellform,sustainspace,copts.normal.passive);
    	cstruct.normal.postortho_aggro.passive = crossclassify_refactor(datastruct.cellform,sustainspace_aggressive,copts.normal.passive);

    	cstruct.withMGG.preortho.active = crossclassify_refactor(datastruct.cellform,[],copts.withMGG.active);
    	cstruct.withMGG.postortho.active = crossclassify_refactor(datastruct.cellform,sustainspace,copts.withMGG.active);
    	cstruct.withMGG.postortho_aggro.active = crossclassify_refactor(datastruct.cellform,sustainspace_aggressive,copts.withMGG.active);

    	cstruct.mediansplit.preortho.active = crossclassify_refactor(datastruct.cellform,[],copts.mediansplit.active);
    	cstruct.mediansplit.postortho.active = crossclassify_refactor(datastruct.cellform,sustainspace,copts.mediansplit.active);
    	cstruct.mediansplit.postortho_aggro.active = crossclassify_refactor(datastruct.cellform,sustainspace_aggressive,copts.mediansplit.active);

    	cstruct.mediansplit.preortho.passive = crossclassify_refactor(datastruct.cellform,[],copts.mediansplit.passive);
    	cstruct.mediansplit.postortho.passive = crossclassify_refactor(datastruct.cellform,sustainspace,copts.mediansplit.passive);
    	cstruct.mediansplit.postortho_aggro.passive = crossclassify_refactor(datastruct.cellform,sustainspace_aggressive,copts.mediansplit.passive);

    	% "postortho" the only option here because commonspace inference is dependent on ZhuGhodsi sustainspace
    	cstruct.commonspace.postortho.active  = crossclassify_refactor(datastruct.cellform,sustainspace,copts.commonspace.active);
    	cstruct.commonspace.postortho.passive = crossclassify_refactor(datastruct.cellform,sustainspace,copts.commonspace.passive);
    else
        % pass
    end
    
    %% special-restricted classification (if the special turntable even exists for this session)
    if neuralflag
        tempdscf = datastruct.cellform;
        TTtoKeep = tempdscf{1}{1}.TurnTableIDs > 90 & tempdscf{1}{1}.TurnTableIDs < 100;
        if any(TTtoKeep)
            for ii = 1:numel(tempdscf)
                for jj = 1:numel(tempdscf)
                    tempdscf{ii}{jj}.Data = ...
                        tempdscf{ii}{jj}.Data(:,:,TTtoKeep);
                    tempdscf{ii}{jj}.Objects = ...
                        tempdscf{ii}{jj}.Objects(TTtoKeep);
                    tempdscf{ii}{jj}.TrialTypes = ...
                        tempdscf{ii}{jj}.TrialTypes(TTtoKeep);
                    tempdscf{ii}{jj}.TurnTableIDs = ...
                        tempdscf{ii}{jj}.TurnTableIDs(TTtoKeep);
                    
                    if ~isempty(tempdscf{ii}{jj}.KinematicData) && isnumeric(tempdscf{ii}{jj}.KinematicData)
                        tempdscf{ii}{jj}.KinematicData = ...
                            tempdscf{ii}{jj}.KinematicData(:,:,TTtoKeep);
                    else
                        % pass
                    end
                end % for jj
            end % for ii

            cstruct.special.preortho.active = crossclassify_refactor(tempdscf,[],copts.normal.active);
    		cstruct.special.postortho.active = crossclassify_refactor(tempdscf,sustainspace,copts.normal.active);
    		cstruct.special.postortho_aggro.active = crossclassify_refactor(tempdscf,sustainspace_aggressive,copts.normal.active);

    		cstruct.special.preortho.passive = crossclassify_refactor(tempdscf,[],copts.normal.passive);
    		cstruct.special.postortho.passive = crossclassify_refactor(tempdscf,sustainspace,copts.normal.passive);
    		cstruct.special.postortho_aggro.passive = crossclassify_refactor(tempdscf,sustainspace_aggressive,copts.normal.passive);
            
        else
            % pass
        end
    else
        % pass
    end
    
    %% kinematic classification per se (see if this might track as your limiting factor, would help to motivate the decoding half)
    % instead of saving confusion matrices and trying to compare them for similarities (which is NOT a trivial operation, and involves decisions about the diagonal that aren't super straightforward, and most importantly, has a HUGE memory overhead), let's track performance per se as a function of transform.
    if ~isempty(datastruct.cellform{1}{1}.KinematicData)
        copts.kinematics.active  = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'active'},'PCAdims',20,'transformdims',12,'datamode','kinematic'); % 'lighton' included for consistency
        copts.kinematics.passive = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'passive'},'PCAdims',20,'transformdims',12,'datamode','kinematic');
        copts.kinematics.control = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'control'},'PCAdims',20,'transformdims',12,'datamode','kinematic');

        % neuralflag also has info about whether to run passive-active or just control classification 
        if neuralflag
            cstruct.kinematics.active = crossclassify_refactor(datastruct.cellform,[],copts.kinematics.active);
            cstruct.kinematics.passive = crossclassify_refactor(datastruct.cellform,[],copts.kinematics.passive);
        else
            cstruct.kinematics.control = crossclassify_refactor(datastruct.cellform,[],copts.kinematics.control);
        end
    else
        % just don't add kinematics fields if they ain't available
    end
    
    %%%%%%
    %% Implementing kinematic clustering
    if ismoe
        kca = kcstruct_moe;
        kcp = kcstruct_human; % yes, use the human kinematics from Zara's data as your point of reference...
    else
        kca = kcstruct_zara;
        kcp = kcstruct_human;
    end
    
    % ACTIVE clustering
    tempdscf = datastruct.cellform;
    for ii = 1:numel(tempdscf)
        for jj = 1:numel(tempdscf{ii})
            for kk = 1:numel(kca.objnames)
                theseinds = ismember( ...
                    tempdscf{ii}{jj}.Objects,...
                    kca.objnames{kk} );
                tempdscf{ii}{jj}.Objects(theseinds) = {num2str(kca.clusterinds(kk))};
            end
        end
    end
        
    copts.kinclust.active  = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'active'},'PCAdims',30,'transformdims',20); % cannot simply include "control" since that only has 6 objects!!! and in that context, pre- and post-grip clustering will be EQUIVALENT!!!
    copts.kinclust.passive = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'passive'},'PCAdims',30,'transformdims',20);
    copts.kinclust.control = makeclassifyopts('transform','none','alignment',{'lighton','move','hold'},'targetcontexts',{'control'},'PCAdims',30,'transformdims',20);

    % neuralflag also has info about whether to run passive-active or just control classification
    % (in addition to whether to do neural or just kinematic classification, of course!)
    if neuralflag
        cstruct.kinclust.preortho.active = ...
            crossclassify_refactor(tempdscf,[],copts.kinclust.active);
        cstruct.kinclust.postortho.active = ...
            crossclassify_refactor(tempdscf,sustainspace,copts.kinclust.active);
        cstruct.kinclust.postortho_aggro.active = ...
            crossclassify_refactor(tempdscf,sustainspace_aggressive,copts.kinclust.active);
        if ~isempty(datastruct.cellform{1}{1}.KinematicData)
            cstruct.kinclust.kinematics.active = ...
                crossclassify_refactor(tempdscf,[],copts.kinematics.active);
        else
            % pass
        end
        
        % PASSIVE clustering
        clear tempdscf
        tempdscf = datastruct.cellform;
        for ii = 1:numel(tempdscf)
            for jj = 1:numel(tempdscf{ii})
                for kk = 1:numel(kcp.objnames)
                    theseinds = ismember( ...
                        tempdscf{ii}{jj}.Objects,...
                        kcp.objnames{kk} );
                    tempdscf{ii}{jj}.Objects(theseinds) = {num2str(kcp.clusterinds(kk))};
                end
            end
        end
        
        cstruct.kinclust.preortho.passive = ...
            crossclassify_refactor(tempdscf,[],copts.kinclust.passive);
        cstruct.kinclust.postortho.passive = ...
            crossclassify_refactor(tempdscf,sustainspace,copts.kinclust.passive);
        cstruct.kinclust.postortho_aggro.passive = ...
            crossclassify_refactor(tempdscf,sustainspace_aggressive,copts.kinclust.passive);
        if ~isempty(datastruct.cellform{1}{1}.KinematicData)
            cstruct.kinclust.kinematics.passive = ...
                crossclassify_refactor(tempdscf,[],copts.kinematics.passive);
        else
            % pass
        end
    else
        % if you're already lacking neural data, you better not be lacking kinematic data!
        cstruct.kinclust.kinematics.control = ...
            crossclassify_refactor(tempdscf,[],copts.kinematics.control);
    end
    
    %%%%%%
    
    % cross-clustering proved a waste of time. axe it.
    
    %% decoding! SIKE
    % that's a future project's problem
    % you CAN'T be adding this to your pipeline if you wanna publish this decade, man
    
    %% abandoning regular snapshots, writing to disk ends up being the most time-consuming thing!!!
    % save after completion of each loop instead
    saveclassifyoutput(seshstr,cstruct,copts);
end