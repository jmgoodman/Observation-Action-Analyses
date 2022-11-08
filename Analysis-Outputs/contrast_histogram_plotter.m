% cleanup
close all, clc

% load data
if ~exist('contraststruct','var')
    load(fullfile('.','clustfiles','clustout_stats.mat'));
end

% plotting color convention
addpath(fullfile('..','Utils'));
colorStruct = defColorConvention();

% rearrange data to a friendly format
monkeyNames = {'moe','zara'};
monkeyInds  = {1:2,3:5};
areaNames   = {'M1','F5','AIP'};

data = struct;
for monkeyIdx = 1:numel(monkeyNames)
    monkeyName = monkeyNames{monkeyIdx};
    monkeyInd  = monkeyInds{monkeyIdx};
    for areaIdx = 1:numel(areaNames)
        areaName = areaNames{areaIdx};
        tempdata = arrayfun(@(x) x.(areaName),...
            contraststruct(monkeyInd),...
            'uniformoutput',false);
        tempdata = vertcat(tempdata{:});
        
        % remove NaN
        tempdata(isnan(tempdata)) = [];
        
        data.(monkeyName).(areaName) = tempdata;
    end
end

% now plot the histograms
for rotInd = 1:numel(areaNames)
    aNames = circshift(areaNames,-rotInd);
    for monkeyName = monkeyNames
        monkeyName_ = monkeyName{1};
        pooled = [];
        nneur  = [];
        figure
        for areaIdx = 1:numel(aNames)
            areaName_ = aNames{areaIdx};
            alph = 0.2;
            if areaIdx==numel(aNames)
                alph = 1;
            end
            whichColor = strcmpi(colorStruct.labels,areaName_);
            thisColor  = colorStruct.colors(whichColor,:);
            hold all
            h=histogram(data.(monkeyName_).(areaName_),-1:.1:1,'Normalization','probability',...
                'facecolor',thisColor,'facealpha',alph,'edgecolor',[0 0 0],'edgealpha',alph);
            pooled = vertcat(pooled,data.(monkeyName_).(areaName_)); %#ok<AGROW>
            nneur = vertcat(nneur,numel(data.(monkeyName_).(areaName_)));
        end
        
        nneur = circshift(nneur,rotInd); % de-rotate
        nneur = flipud(nneur);
        
        legendNames = {'AIP','F5','M1'};
        for legent = 1:numel(legendNames)
            legendNames{legent} = [legendNames{legent},': N=',num2str(nneur(legent))];
        end
        
        xlabel('Passive-Active Index')
        ylabel('Fraction of units')
        customlegend(legendNames,'colors',colorStruct.colors(2:end,:),...
            'fontsize',16,'xoffset',-0.15)
        
        set(gca,'fontsize',16)
        set(gcf,'paperposition',[0 0 6 6])
        title(['Monkey ',upper(monkeyName_(1))])
        box off, axis tight
        print([monkeyName_,'_',aNames{3},'.svg'],'-dsvg')
        
        % also pool
        if rotInd == 3
            figure
            whichColor = strcmpi(colorStruct.labels,'pooled');
            thisColor  = colorStruct.colors(whichColor,:);
            h=histogram(pooled,-1:.1:1,'Normalization','probability',...
                'facecolor',thisColor,'facealpha',0.2,'edgecolor',[0 0 0],'edgealpha',1);
            set(gca,'fontsize',16)
            set(gcf,'paperposition',[0 0 6 6])
            xlabel('Passive-Active Index')
            ylabel('Fraction of units')
            customlegend({['pooled: N=',num2str(sum(nneur))]},'colors',[0 0 0],...
                'fontsize',16,'xoffset',-0.2)
            title(['Monkey ',upper(monkeyName_(1))])
            box off, axis tight
            print([monkeyName_,'_','pooled','.svg'],'-dsvg')
        end
    end
end
        
        
        
        
        