%% Tables 3 and 4

sessions  ={'Zara64','Zara70','Moe46','Moe50'};
load('all-sessions-classmats.mat');

clc
for seshind = 1:numel(sessions)
    thissesh = sessions{seshind};
    
    cmat = classmats.(thissesh).kinclust.postortho_aggro.active.stack;
    
    % (align x subalign) x (align x subalign) x area x subsamplings x
    % kfolds
    % areas order: AIP / F5 / M1 / pooled / chance
    
    % take means across kfolds
    accs = mean(cmat,5);
    
    % single out the hold align, pre-subalign (so, index 7)
    accs = squeeze( accs(7,7,:,:) ); % areas x subsamplings
    
    areanames  = {'AIP','F5','M1'};
    
    % anova
    [p,tbl,stats] = anova1(accs(1:3,:)',areanames,'off');
    
    % marginal means
    mu  = mean(accs(1:3,:)'); %#ok<*UDIM>
    sdev = std(accs(1:3,:)');
    
    % multcompare
    [c,m,h,gnames] = multcompare(stats,'display','off');
    
    % t tests vs chance
    deltaperf = bsxfun(@minus,accs(1:4,:)',accs(5,:)');
    
    
    [~,p_ttest,~,stats_ttest] = ttest(deltaperf,0,'tail','right');
    
    % now display everything
    fprintf('================================\n')
    fprintf('%s\n',thissesh)
    fprintf('ANOVA VGG\n')
    fprintf('p = %0.4e\n',p)
    disp(tbl)
    disp(thissesh)
    fprintf('marginal means VGG\n')
    disp(areanames)
    fprintf('mu:\n')
    disp(mu)
    fprintf('sem:\n')
    disp(sdev)
    fprintf('t-tests VGG\n')
    fprintf('chance: %0.4f\n',accs(5,1))
    disp({'AIP','F5','M1','pooled'})
    fprintf('p:\n')
    fprintf('%0.4e | %0.4e | %0.4e | %0.4e\n',p_ttest(1),p_ttest(2),p_ttest(3),p_ttest(4))
    fprintf('t:\n')
    disp(stats_ttest.tstat)
    fprintf('df:\n')
    disp(stats_ttest.df)
    fprintf('================================\n\n')
    pause
end

%% Tables 5 and 6

for seshind = 1:numel(sessions)
    thissesh = sessions{seshind};
    
    cmat = classmats.(thissesh).kinclust.postortho_aggro.passive.stack;
    
    % (align x subalign) x (align x subalign) x area x subsamplings x
    % kfolds
    % areas order: AIP / F5 / M1 / pooled / chance
    
    % take means across kfolds
    accs = mean(cmat,5);
    
    % single out the hold align, pre-subalign (so, index 7)
    accs = squeeze( accs(7,7,:,:) ); % areas x subsamplings
    
    areanames  = {'AIP','F5','M1'};
    
    % anova
    [p,tbl,stats] = anova1(accs(1:3,:)',areanames,'off');
    
    % marginal means
    mu  = mean(accs(1:3,:)'); %#ok<*UDIM>
    sdev = std(accs(1:3,:)');
    
    % multcompare
    [c,m,h,gnames] = multcompare(stats,'display','off');
    
    % t tests vs chance
    deltaperf = bsxfun(@minus,accs(1:4,:)',accs(5,:)');
    [~,p_ttest,~,stats_ttest] = ttest(deltaperf,0,'tail','right');
    
    % now display everything
    fprintf('================================\n')
    fprintf('%s\n',thissesh)
    fprintf('ANOVA Obs\n')
    fprintf('p = %0.4e\n',p)
    disp(tbl)
    disp(thissesh)
    fprintf('marginal means Obs\n')
    disp(areanames)
    fprintf('mu:\n')
    disp(mu)
    fprintf('sem:\n')
    disp(sdev)
    fprintf('t-tests Obs\n')
    fprintf('chance: %0.4f\n',accs(5,1))
    disp({'AIP','F5','M1','pooled'})
    fprintf('p:\n')
    fprintf('%0.4e | %0.4e | %0.4e | %0.4e\n',p_ttest(1),p_ttest(2),p_ttest(3),p_ttest(4))
    fprintf('t:\n')
    disp(stats_ttest.tstat)
    fprintf('df:\n')
    disp(stats_ttest.df)
    fprintf('================================\n\n')
    pause
end

%% table 7 ALMOST THERE
D = dir('*subsample-size-control-*.mat');

for ii = 1:numel(D)
    fileName = D(ii).name;
    sessionName = regexpi(fileName,'-','split');
    sessionName = sessionName{1};
    
    clear outputs
    load(fileName,'outputs');
    
    % average across folds, nobody cares about folds
    % worry about the hold alignment (align 3), pre-hold (subalign 1)
    accActive90  = cellfun(@(x) mean(horzcat(x{:}),2),...
        outputs(1,2,1,10).classificationAccuracyCell(:,1,1,3,3,1,1),...
        'uniformoutput',false);
    accActive90 = horzcat(accActive90{:});
    
    accActive10  = cellfun(@(x) mean(horzcat(x{:}),2),...
        outputs(1,2,1,1).classificationAccuracyCell(:,1,1,3,3,1,1),...
        'uniformoutput',false);
    accActive10 = horzcat(accActive10{:});
    
    accPassive90 = cellfun(@(x) mean(horzcat(x{:}),2),...
        outputs(1,2,2,10).classificationAccuracyCell(:,1,1,3,3,1,1),...
        'uniformoutput',false);
    accPassive90 = horzcat(accPassive90{:});
    
    % now do your t-tests
    % AIP - F5 - M1 - pooled
    [~,p90,~,stats90] = ttest2( accActive90(1:4,:)',accPassive90(1:4,:)' );
    [~,p10,~,stats10] = ttest2( accActive10(1:4,:)',accPassive90(1:4,:)' );
    
    % now display everything
    fprintf('================================\n')
    fprintf('%s\n',sessionName)
    fprintf('t-tests 90-90 (active minus passive)\n')
    disp({'AIP','F5','M1','pooled'})
    fprintf('p:\n')
    fprintf('%0.4e | %0.4e | %0.4e | %0.4e\n',p90(1),p90(2),p90(3),p90(4))
    fprintf('t:\n')
    disp(stats90.tstat)
    fprintf('df:\n')
    disp(stats90.df)
    fprintf('t-tests 10-90 (active minus passive)\n')
    disp({'AIP','F5','M1','pooled'})
    fprintf('p:\n')
    fprintf('%0.4e | %0.4e | %0.4e | %0.4e\n',p10(1),p10(2),p10(3),p10(4))
    fprintf('t:\n')
    disp(stats10.tstat)
    fprintf('df:\n')
    disp(stats10.df)
    fprintf('================================\n\n')
    pause
end
    