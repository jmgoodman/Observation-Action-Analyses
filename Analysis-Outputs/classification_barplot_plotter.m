% cleanup
clear,clc,close all

% plotting color convention
addpath(fullfile('..','Utils'));
colorStruct = defColorConvention();

% use the window centered 250ms after movement onset
D = dir('*-subsample-size-control-*.mat');

% animal names
animal_names = arrayfun(@(x) regexpi(x.name,'\d','split'),...
    D,'uniformoutput',false);
animal_names = cellfun(@(x) x{1},animal_names,...
    'uniformoutput',false);

unique_animal_names = cellstr( unique( char(animal_names),'rows' ) );

stats_10vs90      = [];
stats_ovschance   = [];
stats_a10vschance = [];

for uind = 1:numel(unique_animal_names)
    these_sessions = cellfun(@(x) strcmpi(x,unique_animal_names{uind}),...
        animal_names);
    
    Dtemp = D(these_sessions);
    
    % pooled across sessions
    a90 = [];
    a10 = [];
    o90 = [];
    
    for seshind = 1:numel(Dtemp)
        seshfile = Dtemp(seshind).name;
        subsampdata = load(seshfile);
        
        % index order:
        % 1 = default (I forget what this originally was, but its size is 1
        % in any case)
        % 2: 2 = orthogonalized
        % 3: 1 = active, 2 = passive
        % 4: 1 = 10% subsample, 10 = 90% subsample
        
        % within .classificationAccuracyCell:
        % dim 1: # of subsamples
        % dim 2&3: context
        % dim 4&5: alignment (viz - mov - hold)
        % dim 6&7: subalignment (-250, 0, +250)
        
        % within that:
        % cell dim 1: cross-validation fold
        
        % within that:
        % vector dim 1: area (pooled-aip-f5-m1-chance)
        
        % we want to compare action vs observation during the late subalign
        % of the movement period
        
        % iterate over 100 subsamples
        act90 = zeros(100,5);
        act10 = zeros(100,5);
        obs90 = zeros(100,5);
        for subsampind = 1:100
            act90(subsampind,:) = ...
                mean(horzcat(subsampdata.outputs(1,2,1,10).classificationAccuracyCell{subsampind,1,1,2,2,3,3}{:}),2)';
            act10(subsampind,:) = ...
                mean(horzcat(subsampdata.outputs(1,2,1,1).classificationAccuracyCell{subsampind,1,1,2,2,3,3}{:}),2)';
            obs90(subsampind,:) = ...
                mean(horzcat(subsampdata.outputs(1,2,2,10).classificationAccuracyCell{subsampind,1,1,2,2,3,3}{:}),2)';
        end
        a90 = vertcat(a90,act90); %#ok<*AGROW>
        a10 = vertcat(a10,act10);
        o90 = vertcat(o90,obs90);
    end
    
    % go forth and make a barplot
    a90mu = mean(a90); a90sd = std(a90);
    a10mu = mean(a10); a10sd = std(a10);
    o90mu = mean(o90); o90sd = std(o90);
    
    % barplots, a90 / a10 vs o90
    % a90
    % chance
    figure
    clors = lines(2);
    clevel = a90mu(end);
    hold all
    line([0.5 4.5],[clevel,clevel],'linewidth',2,'linestyle','--','color',clors(1,:))
    clevel = o90mu(end);
    hold all
    line([0.5 4.5],[clevel,clevel],'linewidth',2,'linestyle','--','color',clors(2,:))
    
    % data
    b=bar(vertcat(a90mu(1:4),o90mu(1:4))','grouped');
    set(b,'linewidth',2)
    hold all,errorbar([1,2,3,4]-.1425,a90mu(1:4),a90sd(1:4),'k.','markersize',1,'linewidth',2)
    hold all,errorbar([1,2,3,4]+.1425,o90mu(1:4),o90sd(1:4),'k.','markersize',1,'linewidth',2)
    set(gca,'xtick',1:4,'xticklabel',colorStruct.labels([2:4,1]),'fontsize',16)
    box off, axis tight
    ylabel('Classification accuracy'), ylim([0 1])
    xlabel('Cortical area')
    title(['Monkey ',upper(unique_animal_names{uind}(1))]);

    
    % a10
    % chance
    figure
    clevel = a10mu(end);
    hold all
    line([0.5 4.5],[clevel,clevel],'linewidth',2,'linestyle','--','color',clors(1,:))
    clevel = o90mu(end);
    hold all
    line([0.5 4.5],[clevel,clevel],'linewidth',2,'linestyle','--','color',clors(2,:))
    
    % data
    b=bar(vertcat(a10mu(1:4),o90mu(1:4))','grouped');
    set(b,'linewidth',2)
    hold all,errorbar([1,2,3,4]-.1425,a10mu(1:4),a10sd(1:4),'k.','markersize',1,'linewidth',2)
    hold all,errorbar([1,2,3,4]+.1425,o90mu(1:4),o90sd(1:4),'k.','markersize',1,'linewidth',2)
    set(gca,'xtick',1:4,'xticklabel',colorStruct.labels([2:4,1]),'fontsize',16)
    box off, axis tight
    ylabel('Classification accuracy'), ylim([0 1])
    xlabel('Cortical area')
    title(['Monkey ',upper(unique_animal_names{uind}(1))]);
    
    % and here's the stats (bootstrapped)
    stats_10vs90 = vertcat( stats_10vs90,sum(o90(:,1:4) > a10(:,1:4))./size(o90,1) );
    stats_ovschance = vertcat( stats_ovschance,sum(o90(:,1:4) < o90(:,5))./size(o90,1) );
    stats_a10vschance = vertcat( stats_a10vschance,sum(a10(:,1:4) < a10(:,5))./size(a10,1) );
end

%% save
for i = 1:4
    figure(i)
    print(sprintf('classify-barplot-%i.svg',i),'-dsvg')
end

save('classify-barplot-stats.mat','stats_ovschance','stats_a10vschance','stats_10vs90');