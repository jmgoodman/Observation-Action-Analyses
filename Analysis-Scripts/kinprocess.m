function kinout = kinprocess(seshstr) % note: this is a debug/rough data exploration script, not a proper analysis script!!!

if isempty(regexpi(seshstr,'\.mat$','once'))
    seshfile = strcat(seshstr,'.mat');
else
    seshfile = seshstr;
    seshstr  = seshstr(1:(end-4));
end

% process the kinematics of the given session
M = load(seshfile);

fn = fieldnames(M);
M = M.(fn{1});

% check to make sure kinematic field isn't empty
if ~isempty(M.Kinematic)
    % extract both joints & marker positions
    % devise clusterings & classifications based on both
    
    % eliminate blocking, we have already registered the sample times to event times (albeit in a kind of hacky way particular to Zara), which maintain blocking
    JDcat = arrayfun(@(x) x.JointStruct.data,M.Kinematic,'uniformoutput',false);
    JDcat = vertcat(JDcat{:});
    
    MDcat = arrayfun(@(x) x.MarkerStruct.data,M.Kinematic,'uniformoutput',false);
    MDcat = vertcat(MDcat{:});
    
    % extract only the joints that are... joints (rather than phantom joints or muscle attachments)
    JDgoodcols = 1:28;
    JDcolnames = M.Kinematic(1).JointStruct.columnNames(JDgoodcols);
    JD         = JDcat(:,JDgoodcols);
    
    % include all marker positions. 
    % (they're all relative to shoulder, which means they all have a consistent reference frame! which means these raw numbers are, indeed, meaningful!) 
    % (that said, monkeys are smaller than humans, so raw marker positions are gonna really skew toward finding differences in grips between active & passive, so maybe it's unwise to use them after all...)
    % (welp nope, joint angles are also susceptible to this...)
    % (the idea is that even the inferred ones are important, as they allow for reconstruction of the orientation vectors. but don't keep the "helper" vectors that ultimately didn't help fit the Opensim model
    MDgoodcols = 2:77;
    MDcolnames = cellfun(@(x,y) [x,'_',y],...
        repmat( M.Kinematic(1).MarkerStruct.header(4,3:3:75),3,1 ),...
        repmat({'X';'Y';'Z'},1,25),'uniformoutput',false);
    MDcolnames = MDcolnames(:);
    MDcolnames = vertcat( M.Kinematic(1).MarkerStruct.header(4,2), ...
        MDcolnames );
    MD         = MDcat(:,MDgoodcols); % first column is equal to that of JD
    
        
    % nan interpolation function
    interpnan = @(x) interp1( find(~any(isnan(x),2)),...
        x(~any(isnan(x),2),:),...
        (1:size(x,1))' );
    
    JD = interpnan(JD); MD = interpnan(MD);
    
    % extract hand postures at hold onsets
    % until 500ms after hold onset, the moment where the animal should receive reward (and during which the hand should be quiescent, at least until the very moment reward is delivered)
    holdonsets = vertcat(M.Event.hold_onset_time) + 500; % also try 100 ms prior to when contact is established, to ensure we're looking at volitional grasp repertoires and not object-imposed ones
    
    onsetinds  = nan(size(holdonsets));
    
    for trialind = 1:numel(holdonsets)
        thisonset    = holdonsets(trialind);
        besttimeind  = find( abs( JD(:,1) - thisonset ) == min( abs( JD(:,1) - thisonset ) ),...
            1,'first' );
        onsetinds(trialind) = besttimeind;
    end
    
    JDhold = JD(onsetinds,:);
    MDhold = MD(onsetinds,:);
    honset = onsetinds;
    
    
    % extract hand postures at go cue onset
    % goonsets = vertcat(M.Event.go_phase_start_time);
    goonsets = vertcat(M.Event.movement_onset_time) - 500; % from 500ms prior to movement onset. Hand should be quiescent.
    
    onsetinds  = nan(size(goonsets));
    
    for trialind = 1:numel(goonsets)
        thisonset    = goonsets(trialind);
        besttimeind  = find( abs( JD(:,1) - thisonset ) == min( abs( JD(:,1) - thisonset ) ),...
            1,'first' );
        onsetinds(trialind) = besttimeind;
    end
    
    JDgo   = JD(onsetinds,:);
    MDgo   = MD(onsetinds,:);
    gonset = onsetinds;
    
    %%
    % entire trajectories
    % (focus only on joint angles)
    JDtraj = cell(numel(honset),1);
    
    for oind = 1:numel(honset)
        JDtemp = JD(gonset(oind):honset(oind),:);
        JDtraj{oind} = JDtemp;
    end
    
    % concatenate trials aligned to hold onset (well, 500 ms thereafter)
    minlen = min(cellfun(@(x) size(x,1),JDtraj));
    JDtraj = cellfun(@(x) x( (end-minlen+1):end,: ),JDtraj,'uniformoutput',false);
    
    % subtract time #1 from each (and convert from ms to s)
    JDtraj = cellfun(@(x) [ (x(:,1)-min(x(:,1)))./1000,x(:,2:end) ],JDtraj,'uniformoutput',false);
    
    % and concatenate
    JDtraj = cat(3,JDtraj{:});
    
    %%
    % see if these data cluster as nicely as you'd hope
    % do it by object x condition
    catcond        = horzcat(M.Object.indices,M.TrialType.indices);
    [urows,~,uind] = unique(catcond,'rows');
    
    % specific to Zara70 (ah! that's why we have a problem!)
    %     mrkr = {'*','*','*','*','*','*',...
    %         '+',...
    %         's','s','s','s','s','s',...
    %         'x',...
    %         'o','o','o','o','o','o'};
    %
    %     sz   = [15,20,25,30,35,40,...
    %         10,...
    %         15,20,25,30,35,40,...
    %         30,...
    %         10,20,30,40,50,60];
    %
    %     clors = [1 0.69 0.39;... % active
    %         0,0,0;... % control
    %         0.39 0.69 1]; % passive
    %
    %     [coef,GripPCs] = pca([MDhold(:,2:end);MDgo(:,2:end)],...
    %         'numcomponents',3); % make this markers, because I suspect a problem with the passive kinematic joint angle reconstructions... active ones look perfectly fine, however.
    %     % indeed, marker position variances and PC scatters make way more sense in Marker than Joint space.
    %
    %     figure
    %     for objind = 1:max(urows(:,1))
    %         for condind = [1,3]
    %             thisrow = find(urows(:,1)==objind & urows(:,2)==condind);
    %             plotthese = find(uind==thisrow);
    %
    %             holdinds = plotthese;
    %             goinds   = plotthese + size(JDhold,1);
    %
    %             hold all
    %             scatter3(GripPCs(holdinds,1),GripPCs(holdinds,2),...
    %                 GripPCs(holdinds,3),sz(objind),clors(condind,:),...
    %                 mrkr{objind})
    %             hold all
    %             scatter3(GripPCs(goinds,1),GripPCs(goinds,2),...
    %                 GripPCs(goinds,3),sz(objind),0.33*clors(condind,:),...
    %                 mrkr{objind})
    %         end
    %     end
    %     xlabel('PC1')
    %     ylabel('PC2')
    %     zlabel('PC3')
    %     box off, grid on
    
    % kinematic variance
    indA   = find( ismember(M.TrialType.unique_names,{'active','VGG','2','4','6','8'}) ) ; % include numbers to account for the typical block organization when "trialtypes" was accidentally left undefined
    indP   = find( ismember(M.TrialType.unique_names,{'passive','Obs','3','5','7','9'}) );
    
    %%
    JDtrajA = JDtraj(:,:,ismember(uind,find(ismember(urows(:,2),indA))));
    JDtrajP = JDtraj(:,:,ismember(uind,find(ismember(urows(:,2),indP))));
      
    %%
    MDHA   = (MDhold(ismember(uind,find(ismember(urows(:,2),indA))),2:end));
    MDHP   = (MDhold(ismember(uind,find(ismember(urows(:,2),indP))),2:end));
    JDHA   = (JDhold(ismember(uind,find(ismember(urows(:,2),indA))),2:end));
    JDHP   = (JDhold(ismember(uind,find(ismember(urows(:,2),indP))),2:end));
    
    varHA = var(JDHA);
    varHP = var(JDHP);
    
    MDGA  = (MDgo(ismember(uind,find(ismember(urows(:,2),indA))),2:end));
    MDGP  = (MDgo(ismember(uind,find(ismember(urows(:,2),indP))),2:end));
    JDGA  = (JDgo(ismember(uind,find(ismember(urows(:,2),indA))),2:end));
    JDGP  = (JDgo(ismember(uind,find(ismember(urows(:,2),indP))),2:end));
        
    varGA = var(JDGA);
    varGP = var(JDGP);
    
    figure,scatter(varHA,varHP),axis equal,xlabel('holdvar active'),ylabel('holdvar passive'),axis equal,axis tight
    savefigs('grip joint angle variance between active and passive comparison')
    figure,scatter(varGA,varGP),axis equal,xlabel('govar active'),ylabel('govar passive'),axis equal,axis tight
    savefigs('quiescent joint angle variance between active and passive comparison')
    figure,scatter(varHP,varGP),axis equal,xlabel('holdvar passive'),ylabel('govar passive'),axis equal,axis tight
    savefigs('passive grip vs quiescence joint angle variance comparison')
    figure,scatter(varHA,varGA),axis equal,xlabel('holdvar active'),ylabel('govar active'),axis equal,axis tight
    savefigs('active grip vs quiescence joint angle variance comparison')
    
    figure,ba = bar([varHA;varHP]',1);
    set(gca,'xtick',1:numel(varHP),'xticklabel',JDcolnames(2:end),'xticklabelrotation',45,'ticklabelinterpreter','none')
    box off, axis tight
    legend('active','passive','location','northeastoutside'),legend boxoff
    ylabel('joint angle variance during hold')
    savefigs('active vs passive joint angle variance split by joint')
    
    varHA = var(MDHA); varHA = reshape(varHA(:),3,[]); varHA = sum(varHA);
    varHP = var(MDHP); varHP = reshape(varHP(:),3,[]); varHP = sum(varHP);
    varGA = var(MDGA); varGA = reshape(varGA(:),3,[]); varGA = sum(varGA);
    varGP = var(MDGP); varGP = reshape(varGP(:),3,[]); varGP = sum(varHA);
    
    MarkerNames = cellfun(@(x) x(1:(end-4)),MDcolnames(2:3:end),'uniformoutput',false);
    
    figure,ba = bar([varHA;varHP]',1);
    set(gca,'xtick',1:numel(varHP),'xticklabel',MarkerNames,'xticklabelrotation',45,'ticklabelinterpreter','none')
    box off, axis tight
    legend('active','passive','location','northeastoutside'),legend boxoff
    ylabel('marker position variance during hold')
    savefigs('active vs passive marker position variance split by joint')
    
    %     % plot time courses
    %     % (or not, they're awfully redundant)
    %     % (they all look pretty normal, let's leave it at that)
    %     for ii = 1:20:numel(holdonsets)
    %         inds = gonset(ii):honset(ii);
    %         figure
    %         spi = 1;
    %         for jj = 2:10:numel(MDcolnames)
    %             subplot(3,3,spi)
    %             plot(MD(inds,1)-MD(inds(1),1),MD(inds,jj))
    %             box off, axis tight
    %             xlabel('time from go cue (ms) [end = hold onset + 200ms]')
    %             ylabel(MDcolnames{jj},'interpreter','none')
    %             spi = spi+1;
    %         end
    %     end
    
    % so it looks like joint angles tell the story of the same grasp over and over by the humans (opensim model doesn't even seem to grasp objects, just move the hand forward & back over & over), and a beautiful variety by the monkeys
    % HOWEVER
    % I imagine the real culprit is a poor model *per se*, perhaps bad scaling, or possibly improper mirroring of right-handed data for a left-handed model
    % Indeed, the marker positions tell a decidedly different story, one where both human AND monkey are grasping with a wide variety of different grips
    % I suspect the marker position story is the one that's true, especially since it didn't have to pass through a goofy inverse kinematics model
    % JUST TO MAKE SURE
    % I will:
    %   run classification analyses, contrast marker position vs. joint angle performance
    %   create & play videos of their movements as an eyeball-based sanity check
    
    % classification sanity check:
    %     TTA = M.Object.TurntableIndex(ismember(M.TrialType.names,'active'));
    %     TTP = M.Object.TurntableIndex(ismember(M.TrialType.names,'passive'));
    
    % object sanity check
    TTA = M.Object.indices( ismember(M.TrialType.names,{'active','VGG','2','4','6','8',}) );
    TTP = M.Object.indices( ismember(M.TrialType.names,{'passive','Obs','3','5','7','9'}) );
    
    [~,v] = version;
    if datenum(v) <= 736007
        cvpA = cvpartition(TTA,'KFold',5);%,'Stratify',true); % "stratify" is actually the default option for older matlabs
        cvpP = cvpartition(TTP,'KFold',5);%,'Stratify',true);
    else
        cvpA = cvpartition(TTA,'KFold',5,'Stratify',true);
        cvpP = cvpartition(TTP,'KFold',5,'Stratify',true);
    end
        
    
    % select only the finger-related joint angles; no elbow, shoulder, or even wrist! (*sad Schieber noises*)
    Jinds2keep = 1:27;%8:27;
    
    % it's trickier in marker space, because we need to re-center w.r.t. the wrist
    MDHA = bsxfun(@minus,MDHA,repmat(MDHA(:,61:63),1,25)); MDHA_ = MDHA; 
    MDHP = bsxfun(@minus,MDHP,repmat(MDHP(:,61:63),1,25)); MDHP_ = MDHP; 
    MDGA = bsxfun(@minus,MDGA,repmat(MDGA(:,61:63),1,25)); MDGA_ = MDGA; 
    MDGP = bsxfun(@minus,MDGP,repmat(MDGP(:,61:63),1,25)); MDGP_ = MDGP; 
        
    Minds2keep = 1:75;%1:60; % then discount the wrist (because it's redefined to just be zero anyway)
    
    JDHA_ = JDHA; JDHP_ = JDHP; JDGA_ = JDGA; JDGP_ = JDGP;
    
    % pca
    [~,MDHA,lat] = pca((MDHA(:,Minds2keep))); %MDHA = MDHA(:,1:30);%cumsum(lat) <= 0.95*sum(lat)); % COULD try z-scoring, but the relative values are quite meaningful, so I'll leave the raw magnitudes in...
    [~,MDHP,lat] = pca((MDHP(:,Minds2keep))); %MDHP = MDHP(:,1:30);%cumsum(lat) <= 0.95*sum(lat)); % we also PCA preprocess to try and mitigate overfitting
    [~,JDHA,lat] = pca((JDHA(:,Jinds2keep))); %JDHA = JDHA(:,1:12);%cumsum(lat) <= 0.95*sum(lat));
    [~,JDHP,lat] = pca((JDHP(:,Jinds2keep))); %JDHP = JDHP(:,1:12);%cumsum(lat) <= 0.95*sum(lat));
    [~,MDGA,lat] = pca((MDGA(:,Minds2keep))); %MDGA = MDGA(:,1:30);%cumsum(lat) <= 0.95*sum(lat));
    [~,MDGP,lat] = pca((MDGP(:,Minds2keep))); %MDGP = MDGP(:,1:30);%cumsum(lat) <= 0.95*sum(lat));
    [~,JDGA,lat] = pca((JDGA(:,Jinds2keep))); %JDGA = JDGA(:,1:12);%cumsum(lat) <= 0.95*sum(lat));
    [~,JDGP,lat] = pca((JDGP(:,Jinds2keep))); %JDGP = JDGP(:,1:12);%cumsum(lat) <= 0.95*sum(lat));
    
    % general plotting
    figure
    scatter3(MDHA(:,1),MDHA(:,2),MDHA(:,3),25,[1 0.69 0.39]), grid on, axis equal
    figure
    scatter3(MDHP(:,1),MDHP(:,2),MDHP(:,3),25,[0.39 0.69 1]), grid on, axis equal
    
    % de-mean each separately, so that the main source of PCA variance isn't just the fact that the two hands occupied different parts of the WAVE generator field
    % actually, de-MEDIAN them, in case the two extend outliery tendrils into their own unique parts of their grasping repertoires
    MHDA__ = bsxfun( @minus,MDHA_(:,Minds2keep),median(MDHA_(:,Minds2keep)) );
    MHDP__ = bsxfun( @minus,MDHP_(:,Minds2keep),median(MDHP_(:,Minds2keep)) );
    [qq,~,~,~,~,mu] = pca( vertcat( MHDA__,MHDP__) );
    qqA = bsxfun(@minus,MHDA__,mu)*qq;
    qqP = bsxfun(@minus,MHDP__,mu)*qq;
    
    % ignore the first few PCs, this is where monkey and human diverge most starkly
    figure
    scatter3(qqA(:,1),qqA(:,2),qqA(:,3),25,[1 0.69 0.39]), grid on, axis equal
    hold all
    scatter3(qqP(:,1),qqP(:,2),qqP(:,3),25,[0.39 0.69 1]), grid on, axis equal
    
    %%%
    % alternatively, just do the same thing with joints, since scaling issues between man and monkey are present
    figure
    scatter3(JDHA(:,1),JDHA(:,2),JDHA(:,3),25,[1 0.69 0.39]), grid on, axis equal
    figure
    scatter3(JDHP(:,1),JDHP(:,2),JDHP(:,3),25,[0.39 0.69 1]), grid on, axis equal
    
    JHDA__ = bsxfun( @minus,JDHA_(:,Jinds2keep),median(JDHA_(:,Jinds2keep)) );
    JHDP__ = bsxfun( @minus,JDHP_(:,Jinds2keep),median(JDHP_(:,Jinds2keep)) );
    [qq,~,~,~,~,mu] = pca( vertcat( JHDA__,JHDP__) );
    qqA = bsxfun(@minus,JHDA__,mu)*qq;
    qqP = bsxfun(@minus,JHDP__,mu)*qq;
    
    % ignore the first few PCs, this is where monkey and human diverge most starkly
    figure
    scatter3(qqA(:,1),qqA(:,2),qqA(:,3),25,[1 0.69 0.39]), grid on, axis equal
    hold all
    scatter3(qqP(:,1),qqP(:,2),qqP(:,3),25,[0.39 0.69 1]), grid on, axis equal
    %%%
    
    % delete rows
    mdlMHA = fitcdiscr(MDHA,TTA,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpA);
    mdlMHP = fitcdiscr(MDHP,TTP,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpP);
    mdlJHA = fitcdiscr(JDHA,TTA,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpA);
    mdlJHP = fitcdiscr(JDHP,TTP,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpP);
    
    mdlMGA = fitcdiscr(MDGA,TTA,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpA);
    mdlMGP = fitcdiscr(MDGP,TTP,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpP);
    mdlJGA = fitcdiscr(JDGA,TTA,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpA);
    mdlJGP = fitcdiscr(JDGP,TTP,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpP);    
    
    % populate table
    accs.hold.marker.active  = mean(kfoldPredict(mdlMHA)==TTA);%1-kfoldLoss(mdlMHA);
    accs.hold.marker.passive = mean(kfoldPredict(mdlMHP)==TTP);%1-kfoldLoss(mdlMHP);
    accs.hold.joint.active   = mean(kfoldPredict(mdlJHA)==TTA);%1-kfoldLoss(mdlJHA);
    accs.hold.joint.passive  = mean(kfoldPredict(mdlJHP)==TTP);%1-kfoldLoss(mdlJHP);
    
    accs.go.marker.active  = mean(kfoldPredict(mdlMGA)==TTA);%1-kfoldLoss(mdlMGA); % kinematics, not cortical activity!
    accs.go.marker.passive = mean(kfoldPredict(mdlMGP)==TTP);%1-kfoldLoss(mdlMGP);
    accs.go.joint.active   = mean(kfoldPredict(mdlJGA)==TTA);%1-kfoldLoss(mdlJGA);
    accs.go.joint.passive  = mean(kfoldPredict(mdlJGP)==TTP);%1-kfoldLoss(mdlJGP);
        
    % now do cross-classification
    xmdlJHA = fitcdiscr(JDHA,TTA,'discrimtype','pseudolinear');
    xmdlJHP = fitcdiscr(JDHP,TTP,'discrimtype','pseudolinear');
    xmdlJGA = fitcdiscr(JDGA,TTA,'discrimtype','pseudolinear');
    xmdlJGP = fitcdiscr(JDGP,TTP,'discrimtype','pseudolinear');
    
    indvals = {'go active','hold active','go passive','hold passive'};
    crossmat = zeros(4);
    dimvals  = {'train','test'};
    
    for basemdl = 1:4
        switch basemdl
            case 1
                mdl = xmdlJGA;
            case 2
                mdl = xmdlJHA;
            case 3
                mdl = xmdlJGP;
            case 4
                mdl = xmdlJHP;
        end
        
        for testdata = 1:4
            switch testdata
                case 1
                    x = JDGA;
                    y = TTA;
                case 2
                    x = JDHA;
                    y = TTA; 
                case 3
                    x = JDGP;
                    y  = TTP;
                case 4
                    x = JDHP;
                    y  = TTP;
            end
            
            thisloss = mean( predict(mdl,x) == y );
            crossmat(basemdl,testdata) = thisloss;
        end
    end
    
    crossaccs.mat = crossmat;
    crossaccs.indvals = indvals;
    crossaccs.dimvals = dimvals;
    
    %% takes a while to run, better to just skip...
    % okay, so there IS variety according to the classifiers
    % but the "eyeball test" struggles to find it
    % and an inspection of overall kinematic variance & PCA projections match the intuitions that arise from the "eyeball test"
    % (the monkey kinematics, comparatively, look fucking beautiful)
    % (I am HOPING that the issue is just poorly executed IK... bad scaling, less-than-ideal reflection axis, that sort of thing.)
    % (except even if I look at variance in the raw marker positions, I see the same general trends...)
    %
    % ---> (...BUT I should implement the "eyeball test" for raw marker positions. Just to be sure.) < ---
    
    % ... that sanity check is HERE!!!
    % for each trial
    % actually, we should trial-average these
    % and just look at the average grips
    nobj = numel(M.Object.unique_names);
    
    onames = M.Object.names(ismember(M.TrialType.names,{'Obs','passive','3','5','7','9'}));
    % clors = hsv(26); clors(:,2) = 0.85*clors(:,2);
    clorbase = hsv(7); clorbase(:,2) = 0.85*clorbase(:,2);
    fingerclors = repmat(clorbase(1:5,:),1,1,4);
    fingerperm  = permute(fingerclors,[2,3,1]);
    fingerflat  = fingerperm(:,:)';
    clors       = vertcat(fingerflat,clorbase(6,:));
    
    uonames = unique(onames);
    
    uomrkr = zeros(numel(uonames),size(MDHP_,2));
    uojt   = zeros(numel(uonames),size(JDHP_,2));
    
    JDtrajmuP = zeros(size(JDtrajP,1),size(JDtrajP,2),numel(uonames));
    
    for oind = 1:numel(uonames)
        thesetrials = ismember(onames,uonames{oind});
        uomrkr(oind,:) = mean( MDHP_(thesetrials,:),1 );
        uojt(oind,:)   = mean( JDHP_(thesetrials,:),1 );
        JDtrajmuP(:,:,oind) = nanmean(JDtrajP(:,:,thesetrials),3);
    end
    uomrkrP = uomrkr;
    uojtP   = uojt;
    
    % script for plotting hand based on marker positions. EXTRACT THIS INTO ITS OWN HELPER METHOD! really nice for visualizing kinematics...
    xmin = min(min(uomrkr(:,1:3:63))); xmax = max(max(uomrkr(:,1:3:63)));
    ymin = min(min(uomrkr(:,2:3:63))); ymax = max(max(uomrkr(:,2:3:63)));
    zmin = min(min(uomrkr(:,3:3:63))); zmax = max(max(uomrkr(:,3:3:63)));
    for trialind = 1%:(size(uomrkr,1)-nobj+1) % misnomer: object ind
        for markerind = 1:25
            if ismember(markerind,[22,23,24,25])
                continue
            else
                % pass
            end
            for tind = 1:nobj
                figure(tind+100)
                hold all
                scatter3(uomrkr(trialind+tind-1,1+3*(markerind-1)),...
                    uomrkr(trialind+tind-1,2+3*(markerind-1)),...
                    uomrkr(trialind+tind-1,3+3*(markerind-1)),...
                    64,clors(markerind,:))
                
                xlabel('x')
                ylabel('y')
                zlabel('z')
                box off, axis equal, grid on
                xlim([xmin,xmax])
                ylim([ymin,ymax])
                zlim([zmin,zmax])
                view([60 30])
                title(uonames{tind})
            end
        end
    end
    
    % now draw lines
    for tind = 1:nobj
        figure(tind+100)
        
        % plot the thumb
        hold all
        plot3( uomrkr(trialind+tind-1,1:3:10),...
            uomrkr(trialind+tind-1,2:3:11),...
            uomrkr(trialind+tind-1,3:3:12),...
            'linewidth',1,'color',clors(1,:) )
        
        % plot the index
        hold all
        plot3( uomrkr(trialind+tind-1,13:3:22),...
            uomrkr(trialind+tind-1,14:3:23),...
            uomrkr(trialind+tind-1,15:3:24),...
            'linewidth',1,'color',clors(5,:) )
        
        % plot the middle
        hold all
        plot3( uomrkr(trialind+tind-1,25:3:34),...
            uomrkr(trialind+tind-1,26:3:35),...
            uomrkr(trialind+tind-1,27:3:36),...
            'linewidth',1,'color',clors(9,:) )
        
        % plot the ring
        hold all
        plot3( uomrkr(trialind+tind-1,37:3:46),...
            uomrkr(trialind+tind-1,38:3:47),...
            uomrkr(trialind+tind-1,39:3:48),...
            'linewidth',1,'color',clors(13,:) )
        
        % plot the pinky
        hold all
        plot3( uomrkr(trialind+tind-1,49:3:58),...
            uomrkr(trialind+tind-1,50:3:59),...
            uomrkr(trialind+tind-1,51:3:60),...
            'linewidth',1,'color',clors(17,:) )
        
        % plot the wrist & connections among all the MCPs
        hold all
        plot3( uomrkr(trialind+tind-1,[61,1,13,25,37,49,61,13,61,25,61,37,61,49]),...
            uomrkr(trialind+tind-1,[61,1,13,25,37,49,61,13,61,25,61,37,61,49]+1),...
            uomrkr(trialind+tind-1,[61,1,13,25,37,49,61,13,61,25,61,37,61,49]+2),...
            'linewidth',1,'color',clors(21,:) )
    end
        
    
    % do it for active now, too
    onames = M.Object.names(ismember(M.TrialType.names,{'VGG','active','2','4','6','8'}));
    % clors = hsv(26); clors(:,2) = 0.85*clors(:,2);
    clorbase = hsv(7); clorbase(:,2) = 0.85*clorbase(:,2);
    fingerclors = repmat(clorbase(1:5,:),1,1,4);
    fingerperm  = permute(fingerclors,[2,3,1]);
    fingerflat  = fingerperm(:,:)';
    clors       = vertcat(fingerflat,clorbase(6,:));
    
    uonames = unique(onames);
    
    uomrkr = zeros(numel(uonames),size(MDHP_,2));
    uojt   = zeros(numel(uonames),size(JDHP_,2));
    JDtrajmuA = zeros(size(JDtrajA,1),size(JDtrajA,2),numel(uonames));
    
    for oind = 1:numel(uonames)
        thesetrials = ismember(onames,uonames{oind});
        uomrkr(oind,:) = mean( MDHA_(thesetrials,:),1 );
        uojt(oind,:)   = mean( JDHA_(thesetrials,:),1 );
        JDtrajmuA(:,:,oind) = nanmean(JDtrajA(:,:,thesetrials),3);
    end
    uomrkrA = uomrkr;
    uojtA   = uojt;
    
    xmin = min(min(uomrkr(:,1:3:63))); xmax = max(max(uomrkr(:,1:3:63)));
    ymin = min(min(uomrkr(:,2:3:63))); ymax = max(max(uomrkr(:,2:3:63)));
    zmin = min(min(uomrkr(:,3:3:63))); zmax = max(max(uomrkr(:,3:3:63)));
    for trialind = 1%:((size(uomrkr,1))-nobj+1)
        for markerind = 1:25
            if ismember(markerind,[22,23,24,25])
                continue
            else
                % pass
            end
            for tind = 1:nobj
                figure(tind+200)
                hold all
                scatter3(uomrkr(trialind+tind-1,1+3*(markerind-1)),...
                    uomrkr(trialind+tind-1,2+3*(markerind-1)),...
                    uomrkr(trialind+tind-1,3+3*(markerind-1)),...
                    64,clors(markerind,:))
                
                xlabel('x')
                ylabel('y')
                zlabel('z')
                box off, axis equal, grid on
                xlim([xmin,xmax])
                ylim([ymin,ymax])
                zlim([zmin,zmax])
                view([60 30])
                title(uonames{tind})
            end
        end
    end
    
    % now draw lines
    for tind = 1:nobj
        figure(tind+200)
        
        % plot the thumb
        hold all
        plot3( uomrkr(trialind+tind-1,1:3:10),...
            uomrkr(trialind+tind-1,2:3:11),...
            uomrkr(trialind+tind-1,3:3:12),...
            'linewidth',1,'color',clors(1,:) )
        
        % plot the index
        hold all
        plot3( uomrkr(trialind+tind-1,13:3:22),...
            uomrkr(trialind+tind-1,14:3:23),...
            uomrkr(trialind+tind-1,15:3:24),...
            'linewidth',1,'color',clors(5,:) )
        
        % plot the middle
        hold all
        plot3( uomrkr(trialind+tind-1,25:3:34),...
            uomrkr(trialind+tind-1,26:3:35),...
            uomrkr(trialind+tind-1,27:3:36),...
            'linewidth',1,'color',clors(9,:) )
        
        % plot the ring
        hold all
        plot3( uomrkr(trialind+tind-1,37:3:46),...
            uomrkr(trialind+tind-1,38:3:47),...
            uomrkr(trialind+tind-1,39:3:48),...
            'linewidth',1,'color',clors(13,:) )
        
        % plot the pinky
        hold all
        plot3( uomrkr(trialind+tind-1,49:3:58),...
            uomrkr(trialind+tind-1,50:3:59),...
            uomrkr(trialind+tind-1,51:3:60),...
            'linewidth',1,'color',clors(17,:) )
        
        % plot the wrist & connections among all the MCPs
        hold all
        plot3( uomrkr(trialind+tind-1,[61,1,13,25,37,49,61,13,61,25,61,37,61,49]),...
            uomrkr(trialind+tind-1,[61,1,13,25,37,49,61,13,61,25,61,37,61,49]+1),...
            uomrkr(trialind+tind-1,[61,1,13,25,37,49,61,13,61,25,61,37,61,49]+2),...
            'linewidth',1,'color',clors(21,:) )
    end
    
    %% output mot files
    for objind = 1:numel(uonames)
        thisgraspA = JDtrajmuA(:,:,objind);
        thisgraspP = JDtrajmuP(:,:,objind);
        
        fnameA = strcat(uonames{objind},' Active');
        fnameP = strcat(uonames{objind},' Passive');
        motWrite(fnameA,JDcolnames,thisgraspA);
        motWrite(fnameP,JDcolnames,thisgraspP);
    end
    
    %% spit out figures too
    for tind = 1:nobj
        fname = uonames{tind};
        figure(100+tind)
        savefigs( strcat(fname,' Passive'));
        figure(200+tind)
        savefigs( strcat(fname,' Active'));
    end
    
    %%
    % clustering analysis (on the joints)
    % try de-meaning them so a mere repertoire or "base" posture difference doesn't drive all differences across contexts
    jA = bsxfun(@minus,uojtA,mean(uojtA)); jP = bsxfun(@minus,uojtP,mean(uojtP));
    mA = bsxfun(@minus,uomrkrA,mean(uomrkrA)); mP = bsxfun(@minus,uomrkrP,mean(uomrkrP));
    
    % cut out arm stuff, only hands please! (exclude the wrist too)
    jA = jA(:,8:end); jP = jP(:,8:end); % 5-7 = wrist, 1-4 = shoulder/elbow (time has already been removed)
    mA = mA(:,1:60) - repmat(mA(:,61:63),1,20);  mP = mP(:,1:60) - repmat(mP(:,61:63),1,20); % everything beyond 60 is a wrist marker (which is set to be zero and the rotational pivot)
    
    % TODO: rotate the hand s.t. the 1CMC marker defines the X axis, and the 3MCP marker defines the Y, and the Z axis follows from the left-hand rule.
    for objind = 1:size(mA,1)
        problem.M = rotationsfactory(3);
        problem.cost = @(R) -dot( R(:,1),mA(objind,1:3) ) - dot( R(:,2),mA(objind,25:27) );
        Rfit = trustregions(problem);
        
        for jointind = 1:20
            mA(objind,((jointind-1)*3)+(1:3)) = mA(objind,((jointind-1)*3)+(1:3))*Rfit;
            
            problem.M = rotationsfactory(3);
            problem.cost = @(R) -dot( R(:,1),mP(objind,1:3) ) - dot( R(:,2),mP(objind,25:27) );
            Rfit = trustregions(problem);
            mP(objind,((jointind-1)*3)+(1:3)) = mP(objind,((jointind-1)*3)+(1:3))*Rfit;
        end
    end
    
    clabs = vertcat( strcat(uonames,' active'),strcat(uonames,' passive') );
    Zj = linkage([jA;jP],'ward'); figure, [Dj,~,Oj] = dendrogram(Zj,0,'Labels',clabs,'Orientation','left','colorthreshold',0.5*max(Zj(:,3))); box off
    savefigs('object clustering by grip joint angles excluding elbow and wrist')
    
    Zm = linkage([mA;mP],'ward'); figure, [Dm,~,Om] = dendrogram(Zm,0,'Labels',clabs,'Orientation','left','colorthreshold',0.5*max(Zm(:,3))); box off
    savefigs('object clustering by grip marker positions excluding elbow and wrist')
    
    JJ = vertcat(jA,jP);
    MM = vertcat(mA,mP);
    figure,imagesc(squareform(pdist(JJ(Oj,:)))),set(gca,'ytick',1:numel(clabs),'yticklabel',clabs(Oj),'xtick',1:numel(clabs),'xticklabel',clabs(Oj),'xticklabelrotation',45),axis square,box off,colorbar
    savefigs('dissimilarity matrix for grip joint angle clustering')
    figure,imagesc(squareform(pdist(MM(Om,:)))),set(gca,'ytick',1:numel(clabs),'yticklabel',clabs(Om),'xtick',1:numel(clabs),'xticklabel',clabs(Om),'xticklabelrotation',45),axis square,box off,colorbar
    savefigs('dissimilarity matrix for grip marker position clustering')
    
    %% final push: do everything above (variance, classification, clustering), but only using the grip aperture
    
    % active thumb-to-index tip distance (i.e., the aperture)
    apertureA = sqrt( sum( (MDHA_(:,10:12) - MDHA_(:,22:24)).^2,2 ) );
    
    % passive, too
    apertureP = sqrt( sum( (MDHP_(:,10:12) - MDHP_(:,22:24)).^2,2 ) );
    
    %     % variance
    %     figure
    %     clors = lines(2);
    %     b1 = bar( 1,var(apertureA) ); set(b1,'facecolor',clors(1,:));
    %     hold all
    %     b2 = bar( 2,var(apertureP) ); set(b2,'facecolor',clors(2,:));
    %     set(gca,'xtick',1:2,'xticklabel',{'Monkey','Human'})
    %     box off, axis tight
    %     ylabel('Grip aperture variance')
    
    % group by object
    onamesA = M.Object.names(ismember(M.TrialType.names,{'VGG','active','2','4','6','8'}));
    onamesP = M.Object.names(ismember(M.TrialType.names,{'Obs','passive','3','5','7','9'}));
    
    uonames = unique(vertcat(onamesA,onamesP));
    
    uoapA = zeros(numel(uonames),1);
    uoapP = zeros(numel(uonames),1);
    
    for oind = 1:numel(uonames)
        thesetrialsA  = ismember(onamesA,uonames{oind});
        uoapA(oind) = mean( apertureA(thesetrialsA),1 );
        thesetrialsP  = ismember(onamesP,uonames{oind});
        uoapP(oind) = mean( apertureP(thesetrialsP),1 );
    end
    
    % add error bars
    sdA = zeros(size(uonames));
    sdP = zeros(size(uonames));
    for oind = 1:numel(uonames)
        thesetrialsA = ismember(onamesA,uonames{oind});
        sdA(oind) = std(apertureA(thesetrialsA));
        thesetrialsP = ismember(onamesP,uonames{oind});
        sdP(oind) = std(apertureP(thesetrialsP));
    end
    
    % correlate aperture now that you've aligned to object
    figure,%scatter(uoapA,uoapP)
    errorbar(uoapA,uoapP,sdP,sdP,sdA,sdA,'ko','linewidth',1)
    box off, axis equal
    xlabel('Monkey mean aperture sizes by object')
    ylabel('Human mean aperture sizes by object')
    
    savefigs('aperture scatterplot correlation')
    
    % signal variance
    signalA = zeros(size(apertureA));
    signalP = zeros(size(apertureP));
    for oind = 1:numel(uonames)
        thesetrialsA  = ismember(onamesA,uonames{oind});
        signalA(thesetrialsA) = uoapA(oind);
        thesetrialsP  = ismember(onamesP,uonames{oind});
        signalP(thesetrialsP) = uoapP(oind);
    end
    
    %     figure
    %     clors = lines(2);
    %     b1 = bar( 1,var(signalA) ); set(b1,'facecolor',clors(1,:));
    %     hold all
    %     b2 = bar( 2,var(signalP) ); set(b2,'facecolor',clors(2,:));
    %     set(gca,'xtick',1:2,'xticklabel',{'Monkey','Human'})
    %     box off, axis tight
    %     ylabel('Grip aperture signal variance')
    
    % now find within-class variance
    aperturenoiseA = apertureA;
    aperturenoiseP = apertureP;
    
    for oind = 1:numel(uonames)
        thesetrialsA = ismember(onamesA,uonames{oind});
        aperturenoiseA(thesetrialsA) = aperturenoiseA(thesetrialsA) - uoapA(oind);
        thesetrialsP = ismember(onamesP,uonames{oind});
        aperturenoiseP(thesetrialsP) = aperturenoiseP(thesetrialsP) - uoapP(oind);
    end
    
    %     % noise variance
    %     figure
    %     clors = lines(2);
    %     b1 = bar( 1,var(aperturenoiseA) ); set(b1,'facecolor',clors(1,:));
    %     hold all
    %     b2 = bar( 2,var(aperturenoiseP) ); set(b2,'facecolor',clors(2,:));
    %     set(gca,'xtick',1:2,'xticklabel',{'Monkey','Human'})
    %     box off, axis tight
    %     ylabel('Grip aperture noise variance')
    
    % combine them all
    figure
    bar( [var(apertureA),var(signalA),var(aperturenoiseA);...
        var(apertureP),var(signalP),var(aperturenoiseP)] )
    set(gca,'xtick',1:2,'xticklabel',{'Monkey','Human'})
    box off, axis tight
    ylabel('Aperture variance')
    legend({'total','signal','noise'},'location','northeastoutside')
    legend boxoff
    
    savefigs('aperture variance breakdown')
    
    % you don't need to do all this. it's 1-D my dude.
    %     % classify
    %     apmdlA = fitcdiscr(apertureA,onamesA,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpA);
    %     apmdlP = fitcdiscr(apertureP,onamesP,'discrimtype','pseudolinear','crossval','on','CVPartition',cvpP);
    %
    %     apaccA = 1-kfoldLoss(apmdlA);
    %     apaccP = 1-kfoldLoss(apmdlP);
    %
    %     % cross-classification
    %     xmdlA = fitcdiscr(apertureA,onamesA,'discrimtype','pseudolinear');
    %     xmdlP = fitcdiscr(apertureP,onamesP,'discrimtype','pseudolinear');
    %
    %     xacc_P_mdlA = 1 - loss(xmdlA,apertureP,onamesP);
    %     xacc_A_mdlP = 1 - loss(xmdlP,apertureA,onamesA);
    %
    %     % now clustering
    %     clabs = vertcat( strcat(uonames,' active'),strcat(uonames,' passive') );
    %     Zap = linkage([uoapA;uoapP],'ward'); figure, [Dap,~,Oap] = dendrogram(Zap,0,'Labels',clabs,'Orientation','left','colorthreshold',0.5*max(Zap(:,3))); box off
    %     % savefigs('object clustering by grip joint angles excluding elbow and wrist')
    
    AP  = vertcat(uoapA,uoapP);
    APS = vertcat(sdA,sdP);
    %     figure,imagesc(squareform(pdist(AP(Oap,:)))),set(gca,'ytick',1:numel(clabs),'yticklabel',clabs(Oap),'xtick',1:numel(clabs),'xticklabel',clabs(Oap),'xticklabelrotation',45),axis square,box off,colorbar
    %     % savefigs('dissimilarity matrix for grip joint angle clustering')
    
    % plot cumulative distro
    [cdistro,cind] = sort(AP,'ascend');
    
    figure,b=bar(cdistro);
    set(b,'facecolor','none')
    hold all
    errorbar((1:numel(cdistro))',cdistro,APS(cind),'k.','markersize',0.01,'linewidth',1)
    set(gca,'xtick',1:numel(AP),'xticklabel',clabs(cind),'xticklabelrotation',45)
    ylabel('Aperture (mm)')
    box off, axis tight
    savefigs('aperture objectsort pooled')
    
    % do each separately
    [adistro,aind] = sort(uoapA,'ascend');
    [pdistro,pind] = sort(uoapP,'ascend');
    clA            = strcat(uonames,' active');
    clP            = strcat(uonames,' passive');
    
    figure,b=bar(adistro);
    set(b,'facecolor','none')
    hold all
    errorbar((1:numel(adistro))',adistro,sdA(aind),'k.','markersize',0.01,'linewidth',1)
    set(gca,'xtick',1:numel(adistro),'xticklabel',clA(aind),'xticklabelrotation',45)
    ylabel('Aperture (mm)')
    box off, axis tight
    savefigs('aperture objectsort active')
    
    figure,b=bar(pdistro);
    set(b,'facecolor','none')
    hold all
    errorbar((1:numel(pdistro))',pdistro,sdP(pind),'k.','markersize',0.01,'linewidth',1)
    set(gca,'xtick',1:numel(pdistro),'xticklabel',clP(pind),'xticklabelrotation',45)
    ylabel('Aperture (mm)')
    box off, axis tight
    savefigs('aperture objectsort passive')

        
    
    %%
    % hmmm 
    kinout = accs;
    
    %%
    % the story:
    % kinematic classification is good no matter what
    % but overall variance is abysmal
    %   variance charts
    %   final postures
    %   videos of the grasps
    %   clustering charts
    % 
    % HOWEVER, in marker-coordinate space, the variances are actually comparable
    %   variance charts
    %   clustering charts
    %
    % CROSS-CLASSIFICATION: in any case, cross-classification is abysmal
    % (so neural cross-classification being poor really shouldn't be that surprising...)
    % (although maybe if we apply PLS or something, we end up with really shockingly GOOD cross-classification, with a stable transformation to boot, which we definitely do not see in the neuronal data)
    
else
    % pass
end

return