function outstruct = Clustering_ExternalCall
h       =  findobj('type','figure');
noldfig = length(h);

% TODO: add spectral clustering to this, to visualize what the best clustering would be if you COULD do it...
% (gotta make sure your stats don't violently disagree with your gut checks, you know?)

%% for each session
seshnames = {'Moe46','Moe50','Zara64','Zara68','Zara70'};
dipteststruct      = struct('pooled',cell(size(seshnames)),'AIP',cell(size(seshnames)),'F5',cell(size(seshnames)),'M1',cell(size(seshnames)));
dipteststructcorrs = struct('pooled',cell(size(seshnames)),'AIP',cell(size(seshnames)),'F5',cell(size(seshnames)),'M1',cell(size(seshnames)));
PAIRSstruct        = struct('pooled',cell(size(seshnames)),'AIP',cell(size(seshnames)),'F5',cell(size(seshnames)),'M1',cell(size(seshnames)));
Nstruct            = struct('pooled',cell(size(seshnames)),'AIP',cell(size(seshnames)),'F5',cell(size(seshnames)),'M1',cell(size(seshnames)));
contraststruct     = struct('pooled',cell(size(seshnames)),'AIP',cell(size(seshnames)),'F5',cell(size(seshnames)),'M1',cell(size(seshnames)),'pooledareanames',cell(size(seshnames)),...
    'pooledneuronIDs',cell(size(seshnames)),'AIPneuronIDs',cell(size(seshnames)),'F5neuronIDs',cell(size(seshnames)),'M1neuronIDs',cell(size(seshnames)));
congruencestruct   = struct('pooled',cell(size(seshnames)),'AIP',cell(size(seshnames)),'F5',cell(size(seshnames)),'M1',cell(size(seshnames)),'pooledareanames',cell(size(seshnames)),...
    'pooledneuronIDs',cell(size(seshnames)),'AIPneuronIDs',cell(size(seshnames)),'F5neuronIDs',cell(size(seshnames)),'M1neuronIDs',cell(size(seshnames)));

for seshind = 1:numel(seshnames)
    %% load in the data
    seshname         = seshnames{seshind};
    %     MirrorDataObject = load([seshname,'.mat']);
    %     fn = fieldnames(MirrorDataObject);
    %     MirrorDataObject = MirrorDataObject.(fn{1});
    load( [seshname,'_datastruct.mat'] ); % "datastruct" is the output
    
    % use the biggest wings you can muster
    wingwidth      = 500;
    Wins           = {    [-1,1]*wingwidth,          [-1,1]*wingwidth,   [-1,1]*wingwidth+700,        [-1,1]*wingwidth,      [-1,1]*wingwidth,          [-1,1]*wingwidth,      [-1,1]*wingwidth   };
    % now these should ACCURATELY reflect memory overhead. Until recently, tensorize was taking up over 150% of the capacity of the arrays I actually needed to be holding in memory, which in turn was almost certainly literally using up ALL of my RAM!
    % wingwidth = 100 % memory -> 1958 MB
    % wingwidth = 300 % memory -> 3612 MB
    % wingwidth = 500 % memory -> 5297 MB (reaches 8412 within tensorize)
    % wingwidth = 1000 % memory EXPECTATION: 9466 MB
    
    
    %     ppd           = preprocess(MirrorDataObject,'removebaseline',false,'normalize',false,'windows',Wins,'dokinematics',false); % uhhh actually do NOT remove the baseline... this could be VERY IMPORTANT per the Shenoy lab's paper on motor learning!!! try to design metrics that factor it out if you care about transient modulation... otherwise, LEAVE IT IN so you can analyze it when you want/need to! Plus, in general, it's SUPER fucked up to just apply a linear model to "cancel out" a portion of the population activity when analyzing... population dynamics which might DEPEND on that shift! Which in turn would SERIOUSLY hurt your LDS models when you run them! Uh oh! All the more important to NOT BASELINE SUBTRACT!!!
    ppd = datastruct.cellform;
    % don't bother renaming this to dt or something. the memory overhead is still going to be there when you run tensorize; the overwrite doesn't happen until AFTER all that happens, after all...
    % hmmmmmmm should I ACTUALLY be preserving TT information in addition to object per se? so that I don't end up "mixing" turntable effects?
    
    areaorder     = cellfun(@(x) x{1}.ArrayIDs{1},ppd,'uniformoutput',false);
    nneur_by_area = cellfun(@(x) size(x{1}.Data,2),ppd);
    repareanames  = cellfun(@(x,y) repmat({x},y,1),areaorder,num2cell(nneur_by_area),'uniformoutput',false);
    areanames     = vertcat(repareanames{:});
    %     objectnames   = unique(char(ppd{1}{1}.Objects),'rows');
    %     objectnames   = cellstr(objectnames);
    TTinds   = ppd{1}{1}.TurnTableIDs;
    ObjNames = ppd{1}{1}.Objects;
    
    TT_and_obj_cells = cellfun(@(x,y) [num2str(x),' ',y],num2cell(TTinds),ObjNames,'uniformoutput',false);
    [ucells,~,uinds] = unique(TT_and_obj_cells);
    
    %     dt            = tensorize_keepTTinfo(ppd); % if each object is counted as different if it comes from a different turntable
    %     dt            = tensorize(ppd); % if you want to combine turntables if they had the same object
    [dt,~,~,neuronIDs]  = tensorizeTT1(ppd); % if you wanna forget about those silly "same-object-class" turntables and just focus on TT1 which had a nice variety (may distort active-passive index a tad, but makes the correlation index a lot more likely to be meaningful)
    
    % save neuron IDs
    contraststruct(seshind).pooledneuronIDs = neuronIDs;
    congruencestruct(seshind).pooledneuronIDs = neuronIDs;
    
    fullareas = {'M1','F5','AIP'};
    
    for areaind = 1:numel(fullareas)
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areanames );
        fieldname = [fullareas{areaind},'neuronIDs'];
        contraststruct(seshind).(fieldname) = neuronIDs(areainds,:);
        congruencestruct(seshind).(fieldname) = neuronIDs(areainds,:);
    end
    
    clearvars -except noldfig ucells uinds seshnames seshname seshind dt dtt1 areanames areaorder wingwidth dipteststruct dipteststructcorrs PAIRSstruct Nstruct contraststruct
    
    %% clustering strategy 1: use modulation aligned to movement, active vs. passive
    % (consider also running this when aligning to "hold", as there's reason to suspect that "hold", NOT "movement onset", is the alignment point that matters for observation responses...
    % some metadata to help you follow along:
    %     alignments = {'fixation_achieve_time','cue_onset_time','cue_onset_time','go_phase_start_time','movement_onset_time','hold_onset_time','reward_onset_time'};
    %     tasks      = {'active','control','passive'};
    
    %     dt_movalign = dt(:,:,:,(4*epochwid+1):(5*epochwid),:); % move alignment
    %     dt_movalign = dt(:,:,:,(5*epochwid+1):(6*epochwid),:); % hold alignment
    epochwid    = wingwidth*2/10;
    dt_movalign = dt(:,:,[1,3],(4*epochwid+1):(6*epochwid),:); % neurons x objects x contexts x time x trials
    dtmu        = nanmean(dt_movalign,5);
    dtse        = nanstd(dt_movalign,1,5) ./ sqrt( sum( ~isnan(dt_movalign),5 ) );
    
    % you COULD use the range...
    % ...or you COULD use a robust statistic like variance (or at least the iqr!)
    dtperm      = permute(dtmu,[1,3,2,4]); % get condition to the second index. should now be neur x condition x object x time
    dtseperm    = permute(dtse,[1,3,2,4]);
    clear dtmu
    
    dtflat      = dtperm(:,:,:);
    dtiqr       = range(dtflat,3);%iqr(dtflat,3);
    dtflatter   = dtflat(:,:);
    dtiqrtotal  = range(dtflatter,2);%iqr(dtflatter,2);
    clear dtflat dtflatter
    
    % ignore neurons that don't have an IQR (range) of at least X Hz
    keepinds = dtiqrtotal > 0.2; %10; % when I switched to using pre-computed datastructs, this meant using normalized instead of absolute firing rates. ergo, this threshold needed to change. So, change it did; now, firing rate modulation needs to be at least 20% of the base firing rate OR 5Hz (given the "soft" part of soft-normalization), whichever is higher. In other words, don't give me neurons whose overall modulation is less than 1 Hz. This is a "looser" restriction than the one I was using before, but hey, the results should *still* hold (in fact, firing rate as a threshold is kinda suspect, since multi units tend to have the highest rates!)
    szvals   = dtiqrtotal(keepinds)./max(dtiqrtotal(keepinds));
    szvals   = 625 * szvals;
    szvals   = 100 * ones(size(szvals)); % all the same size, no information overload please!

    
    dtiqrkept = dtiqr(keepinds,:);
    areaskept = areanames(keepinds);
    
    % and compute contrast indices (where +ve means MIRROR-LIKE, or rather, OBSERVATION-PREFERRING)
    contrastinds = diff(dtiqrkept,1,2) ./ sum(dtiqrkept,2);
    
    % populate contrast struct
    cifull = diff(dtiqr,1,2) ./ sum(dtiqr,2);
    cifull(~keepinds) = nan;
    
    contraststruct(seshind).pooled = cifull;
    contraststruct(seshind).pooledareanames = areanames;
    
    fullareas = {'M1','F5','AIP'};
    
    for areaind = 1:numel(fullareas)
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areanames );
        contraststruct(seshind).(fullareas{areaind}) = cifull(areainds);
    end
    
    % and run stats
    clear tempstruct
    [tempstruct.dipstat,tempstruct.pval] = HartigansDipSignifTest(contrastinds,1e4,'uniform');
    figure,pause(0.5)
    q=cdfplot(contrastinds);
    set(q,'color',[0 0 0]);
    
    dipteststruct(seshind).pooled = tempstruct;
    Nstruct(seshind).pooled       = numel(contrastinds);
    
    clors = lines(4);
    clors = [clors(1,:);mean(clors(2:3,:));clors(4,:)];

    % split by area
    fullareas = {'M1','F5','AIP'};
    
    % run stats on each area/array separately
    %     ci = zeros(size(contrastinds));
    hold all
    for areaind = 1:numel(fullareas)
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areaskept );
        %         areainds = ismember( areaskept,areaorder{areaind} );
        clear tempstruct
        [tempstruct.dipstat,tempstruct.pval] = HartigansDipSignifTest(contrastinds(areainds),1e4,'uniform');
        dipteststruct(seshind).(fullareas{areaind}) = tempstruct;
        Nstruct(seshind).(fullareas{areaind})       = sum(areainds);
        hold all,q=cdfplot(contrastinds(areainds));
        set(q,'color',clors(areaind,:))
        %         ci(areainds) = bsxfun(@minus, contrastinds(areainds),median(contrastinds(areainds)) ); % remove area medians in case there is an area effect on top of the "mirror neuron" effect
    end
    
    %     hold all
    %     q = cdfplot(ci); set(q,'color',[0.3 0.3 0.3])
    %     [ds,pv] = HartigansDipSignifTest(ci,1e4,'uniform');
    
    legend(horzcat('Pooled',fullareas),'location','bestoutside')
    title(seshname)
    xlabel('Passive-Active Index')
    ylabel('Cumulative fraction of neurons')
    box off, axis square
    xlim([-1 1])
    ylim([0 1])

    %%
    % use these indices to plot a few PETHs, too
    
    %     dtpermtemp    = permute(dt_movalign,[1,4,3,2,5]); % should now be neur x time x condition x object x trial
    %
    %     dtp    = nanmean(dtpermtemp(:,:,:,:),4);
    %     dtsep  = nanstd(dtpermtemp(:,:,:,:),1,4) ./ sqrt( sum( ~isnan(dtpermtemp(:,:,:,:)),4 ) ); % flattened, should now be neur x time x condition
    
    dtp    = permute(dtperm,[1,4,2,3]); % should now be neur x time x condition x object
    
    %     dtpmed = median(dtp,4);
    %     dtup   = prctile(dtp,75,4) - dtpmed;
    %     dtdown = dtpmed - prctile(dtp,25,4);
    %     dtp    = dtpmed;
    dtup   = std(dtp,1,4) ./ sqrt( sum( ~isnan(dtp),4 ) );
    dtdown = std(dtp,1,4) ./ sqrt( sum( ~isnan(dtp),4 ) );
    dtp    = mean(dtp,4);
    
    dtp    = dtp(keepinds,:,:);
    dtup   = dtup(keepinds,:,:);
    dtdown = dtdown(keepinds,:,:);
    
    for areaind = 1:numel(fullareas)
        figure
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areaskept );
        ci       = contrastinds(areainds);
        dta      = dtp(areainds,:,:);
        dtupa    = dtup(areainds,:,:);
        dtdowna  = dtdown(areainds,:,:);
        
        %         targetp  = [25,50,75];
        targetp  = [25 85 99];
        prctiles = prctile(ci,targetp); % ah ok. so the clustering PETHs use medians and IQRs...
        %         prctiles(2) = 0; % find a "mirror" neuron
        
        exampleinds = zeros(size(prctiles));
        for pind = 1:numel(prctiles)
            exampleinds(pind) = find( abs( ci - prctiles(pind) ) == ...
                min( abs( ci - prctiles(pind) ) ),1,'first');
        end
        
        clors = lines(2);
        for eind = 1:numel(exampleinds)
            %             subpind = (areaind-1)*numel(fullareas) + eind;
            %             subplot(3,3,subpind)
            subplot(1,3,eind)
            mee     = squeeze( dta( exampleinds(eind),:,: ) );
            upe     = squeeze( dtupa( exampleinds(eind),:,: ) );
            doe     = squeeze( dtdowna( exampleinds(eind),:,: ) );
            for condind = 1:2
                hold all
                ErrorRegion((1:100)',mee(1:100,condind),upe(1:100,condind),doe(1:100,condind),...
                    'facecolor',clors(condind,:),'edgecolor',clors(condind,:),...
                    'facealpha',0.2,'edgealpha',0,'linecolor',clors(condind,:));
                %                 hold all
                %                 ErrorRegion((101:200)',mee(101:200,condind),upe(101:200,condind),doe(101:200,condind),...
                %                     'facecolor',clors(condind,:),'edgecolor',clors(condind,:),...
                %                     'facealpha',0.2,'edgealpha',0,'linecolor',clors(condind,:));
            end
            
            box off, axis tight
            xlim([0.5 100.5])
            %             ylim([0 30]) % optional
            ylim([0 1]) % for dealing with normalization
            set(gca,'xtick',[0.5,50.5,100.5],...
                'xticklabel',{'-500','Move Onset','+500'})
            
            if eind == 2
                xlabel('Time (ms)')
            else
                set(gca,'xticklabel',[])
            end
            
            if eind == 1
                ylabel('Normalized Firing Rate (Hz)') % added "normalized" when I started working with pre-compiled (normalized) datastructs
            else
                set(gca,'yticklabel',[])
            end
            
            %             hold all
            %             line(100.5*[1 1],get(gca,'ylim'),'linewidth',2,'color',[0 0 0])
            
            %             customlegend({'VGG','Obs'},'colors',clors);
            %             title([fullareas{areaind},': ',sprintf('%ith percentile Passive-Active Index = %0.4f',targetp(eind),ci(exampleinds(eind)))])
        end
    end
    
    %% strategy 2: correlation
    % instead of taking the overall range
    % let's compute the temporal variation on an object-by-object basis
    % and correlate it between active & passive
    % this lets us correlate modulations
    % without having to fit a big fat idiot model to align the latencies / time scale
    % (note: doesn't make sense to plot PETHs based on this. It'd be way too noisy. TODO: We COULD plot rate scatterplots, though)
    dtpermiqr     = range(dtperm,4); %iqr(dtperm,4); % neuron x condition x object
    dtpermiqrkept = dtpermiqr(keepinds,:,:);
    
    corrvals = zeros(size(dtpermiqrkept,1),1);
    for neurind = 1:size(dtpermiqrkept)
        thisiqr = squeeze(dtpermiqrkept(neurind,:,:)); % condition x object
        corrvals(neurind) = corr(thisiqr(1,:)',thisiqr(2,:)'); % we're just working with dt, not dtt1, so we only have to worry about two tasks: vgg and obs
    end
    
    % populate congruence struct
    congruencestruct(seshind).pooled = corrvals;
    congruencestruct(seshind).pooledareanames = areanames;
    
    fullareas = {'M1','F5','AIP'};
    
    for areaind = 1:numel(fullareas)
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areanames );
        congruencestruct(seshind).(fullareas{areaind}) = corrvals(areainds);
    end
    
    % and run stats
    clear tempstruct
    [tempstruct.dipstat,tempstruct.pval] = HartigansDipSignifTest(corrvals,1e4,'uniform');
    figure,pause(0.5)
    q=cdfplot(corrvals);
    set(q,'color',[0 0 0]);
    
    dipteststructcorrs(seshind).pooled = tempstruct;
    pause(0.5)
    
    clors = lines(4);
    clors = [clors(1,:);mean(clors(2:3,:));clors(4,:)];
    
    % split by area
    fullareas = {'M1','F5','AIP'};
    
    % run stats on each area/array separately
    %     ci = zeros(size(contrastinds));
    hold all
    for areaind = 1:numel(fullareas)
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areaskept );
        %         areainds = ismember( areaskept,areaorder{areaind} );
        clear tempstruct
        [tempstruct.dipstat,tempstruct.pval] = HartigansDipSignifTest(corrvals(areainds & ~isnan(corrvals)),1e4,'uniform');
        dipteststructcorrs(seshind).(fullareas{areaind}) = tempstruct;
        hold all,q=cdfplot(corrvals(areainds & ~isnan(corrvals)));
        set(q,'color',clors(areaind,:))
        %         ci(areainds) = bsxfun(@minus, contrastinds(areainds),median(contrastinds(areainds)) ); % remove area medians in case there is an area effect on top of the "mirror neuron" effect
    end
    
    %     hold all
    %     q = cdfplot(ci); set(q,'color',[0.3 0.3 0.3])
    %     [ds,pv] = HartigansDipSignifTest(ci,1e4,'uniform');
    
    legend(horzcat('Pooled',fullareas),'location','bestoutside')
    title(seshname)
    xlabel('Modulation Correlation') % doing it this way will also give us a way to segue into the dynamical portion: basically, we can start talking about initial conditions arising from shifting baselines, and even if the dynamical systems fits don't work ACROSS tasks, they might still offer very good predictions when we pool ACROSS tasks but leave out an object
    ylabel('Cumulative fraction of neurons')
    box off, axis square
    xlim([-1 1])
    ylim([0 1])

    %% use PAIRS test to seek multivariate clusters (TODO: test unsupervised clustering algorithms to see if PAIRS is being unfair... it SHOULD be an awfully false-positive-happy method if anything, but it's quirky and nonstandard and therefore it's possible that it's actually super conservative in this case)
    pairsdata = [contrastinds(:),corrvals(:)];
    
    clear ps
    ps = PAIRStest(pairsdata(all(~isnan(pairsdata),2),:),3,2,1000); % NOTE: I ran this for 1000 iterations, not the full 1e4! ...but, if it takes that many iterations of my null sample to get a significant result with a test this sensitive, it's safe to at least say that mirror neurons are a somewhat dubious neuron class...
    figure,pause(0.5)
    %     scatter(pairsdata(:,1),pairsdata(:,2),szvals,[0 0 0],'filled','markerfacealpha',0.5,'markeredgecolor',[0 0 0],'markeredgealpha',1)
    scatter(pairsdata(:,1),pairsdata(:,2),szvals,[0 0 0],'linewidth',1.5,'markeredgecolor',[0 0 0])
    xlim([-1 1])
    ylim([-1 1])
    box off, grid on
    axis square
    xlabel('Passive-Active Index')
    ylabel('Passive-Active Correlation')
    title(seshname)
    
    PAIRSstruct(seshind).pooled = ps;
    
    clors = lines(4);
    clors = [clors(1,:);mean(clors(2:3,:));clors(4,:)];
    
    % split by area
    fullareas = {'M1','F5','AIP'};
    
    % run stats on each area/array separately
    %     ci = zeros(size(contrastinds));
    figure,pause(0.5)
    for areaind = 1:numel(fullareas)
        areainds = cellfun( @(x) ~isempty( regexpi(x,fullareas{areaind},'once') ),areaskept );
        clear ps
        ps = PAIRStest(pairsdata(areainds&all(~isnan(pairsdata),2),:),3,2,1000);
        PAIRSstruct(seshind).(fullareas{areaind}) = ps;
        %         hold all,scatter(pairsdata(areainds,1),pairsdata(areainds,2),szvals(areainds),clors(areaind,:),'filled','markerfacealpha',0.5,'markeredgecolor',clors(areaind,:),'markeredgealpha',1)
        hold all,scatter(pairsdata(areainds&all(~isnan(pairsdata),2),1),pairsdata(areainds&all(~isnan(pairsdata),2),2),szvals(areainds&all(~isnan(pairsdata),2)),clors(areaind,:),'linewidth',1.5,'markeredgecolor',clors(areaind,:))
    end
    xlim([-1 1])
    ylim([-1 1])
    box off, grid on
    axis square
    xlabel('Passive-Active Index')
    ylabel('Passive-Active Correlation')
    title(seshname)
        
    %% cleanup
    clearvars -except noldfig seshnames seshind dipteststruct dipteststructcorrs PAIRSstruct Nstruct contraststruct
    
    
end

%% saving plots
olddir = cd('..');
mkdir(fullfile('.','Analysis-Outputs','clustfiles'))

h       =  findobj('type','figure');
nfigtot = length(h);
nfig    = nfigtot - noldfig;

for ii = 1:nfig
    figure(ii+noldfig)
    print(fullfile('Analysis-Outputs','clustfiles',sprintf('clustfigure%0.2i.tif',ii)),'-dtiff','-r300')
    print(fullfile('Analysis-Outputs','clustfiles',sprintf('clustfigure%0.2i.svg',ii)),'-dsvg')
    savefig(fullfile('Analysis-Outputs','clustfiles',sprintf('clustfigure%0.2i.fig',ii)))
end

save(fullfile('.','Analysis-Outputs','clustfiles','clustout_stats.mat'),'contraststruct','dipteststruct','dipteststructcorrs','PAIRSstruct','seshnames','Nstruct','-v7.3')
    
cd(olddir);
%% sending outputs
outstruct.dipteststruct = dipteststruct;
outstruct.dipteststructcorrs = dipteststructcorrs;
outstruct.PAIRSstruct = PAIRSstruct;
outstruct.seshnames = seshnames;
outstruct.Nstruct = Nstruct;
outstruct.contraststruct = contraststruct;
