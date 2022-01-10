% newheatmap.m
% uses the new low-D orthogonalization
% maybe condense into bar plots instead of heatmaps
clear
clc
close all

seshnames = {'Moe46','Moe50','Zara64','Zara68','Zara70'};

restoredefaultpath
addpath(genpath(fullfile( '..','Utils' )))

for ii = [2,5] %1:numel(seshnames)
    clear copts cstruct
    tic
    seshdir = fullfile('.',seshnames{ii});
    cresultsfilename = sprintf('classification_results_%s.mat',seshnames{ii});
    fullfilename     = fullfile(seshdir,cresultsfilename);
    load(fullfilename);
    toc
    
    % use "normal" if you want to classify all objects and not just grip types (lol who wants to do that tho)
    %     hmapdata = cstruct.notransform.special.preortho; % maybe just use this. then you won't have to explain in your talk!
    %     hmapdata = cstruct.notransform.kinclust.postortho; % ummmm or maybe use this to avoid being too conservative about your cutoff for "no better than pure vision vs. movement period alignment"
    %     hmapdata = cstruct.notransform.kinclust.vizortho; % this might be more targeted
    
    % for comparing "pre" vs "post" alignment
    % note that "notransform" is a bit of an oversimplification - there's still 30D PCA followed by subselection of the top 20 PCs. With PCA being fit to the target context's data.
    %     hmapdata = cstruct.align.normal; % there are way fewer sublevels & stuff when considering the alignment analyses. Also, there's no kinematic clustering here - only raw.
    %     hmapdata = cstruct.notransform.normal.postortho; % "align" doesn't help...
    %     hmapdata = cstruct.uniform.normal; % alignment with (uniform) rescaling also doesn't help (note: didn't do nonuniform rescaling because that means applying a shear map - a transform family that's even more powerful than a mere rotation, one whose geometric properties follow naturally from the state space framework but for which a clear neural interpretation is lacking...)
    %     hmapdata = cstruct.procrustes.normal;
    
    % subsampling x context1 x context2 x alignment1 x alignment2 x subalign1 x subalign2
    % within each:
    % a kfold-cell
    % within those:
    % a vector of doubles: AIP / F5 / M1 / Pooled / Chance
    
    % iterate over all context, alignment, and subalignment pairs
    % average over folds, do NOT include in SEM calcs
    % average over subsamples, DO include in SEM calcs
    sz = size(hmapdata);
    heatmapmeans = zeros([5,sz(2:end)]);
    heatmapsds   = zeros([5,sz(2:end)]);
    
    hmapdata = permute( hmapdata,[2,3,4,5,6,7,1] );
    hmapdata = reshape( hmapdata,[],size(hmapdata,7) );
    
    for jj = 1:size(hmapdata,1)
        hmd = hmapdata(jj,:);
        hmd = horzcat(hmd{:});
        
        hmd_ = zeros(5,5,20); % area x fold x subsamp
        
        for foldind = 1:5
            for subsampind = 1:20
                temp = hmd{foldind,subsampind};
                hmd_(:,foldind,subsampind) = temp;
                %%%
                % PROCRUSTES NOTES
                %     AIP and pooled worked here with procrustes... but not F5 and M1 :(
                %     In the output of F5 & M1 (for procrustes) lies this error:
                %     Matrix dimensions must agree
                %     file: '/scratch2/jgoodma/Mirror-Analysis/Analysis-Scripts/datatransform.m'
                %     name: '@(X)transform.b*(X*meannull*coeff)*transform.T+transform.c'
                %     line: 68
                %     Also, the outputs that DID work (for procrustes) seem weird, with absurdly low classification accuracy.
                %     I suspect there's an error in the transformation matrix - probably a transpose somewhere that shouldn't be there, or a lack of transpose that should be there
                %     and maybe a bsxfun that is sorely needed to map transform.c to transform.T
                %%%
                clear temp
            end
        end
        
        hmd = hmd_;
        clear hmd_        
        
        foldavg = squeeze( mean(hmd,2) ); % area x subsamp
        
        ssavg = mean(foldavg,2);
        sssd  = std(foldavg,0,2);
        
        [i1,i2,i3,i4,i5,i6] = ind2sub( sz(2:end),jj );
        
        heatmapmeans(:,i1,i2,i3,i4,i5,i6) = ssavg;
        heatmapsds(:,i1,i2,i3,i4,i5,i6)   = sssd;
    end
                            
    % okay, now make master heatmaps
    heatmapdimsize = 2*3*3;
    masterheatmap  = zeros(5,heatmapdimsize,heatmapdimsize);
    masterheatsd   = zeros(size(masterheatmap));
    
    for jj1 = 1:2 % context
        for jj2 = 1:2
            for kk1 = 1:3 % align
                for kk2 = 1:3
                    for ll1 = 1:3 % subalign
                        for ll2 = 1:3
                            lind1 = sub2ind( [3,3,2],ll1,kk1,jj1 ); % reverse order to reflect proper hierarchical relationship
                            lind2 = sub2ind( [3,3,2],ll2,kk2,jj2 );
                            
                            masterheatmap(:,lind1,lind2) = ...
                                heatmapmeans(:,jj1,jj2,kk1,kk2,ll1,ll2);
                            masterheatsd(:,lind1,lind2) = ...
                                heatmapsds(:,jj1,jj2,kk1,kk2,ll1,ll2); % fifth level (chance) is always 0 s.d.
                        end
                    end
                end
            end
        end
    end
    
    % don't worry about rigorous stats. blank out all entries that are within 2 sds of chance
    blankus = bsxfun(@lt,masterheatmap(1:4,:,:)-masterheatsd(1:4,:,:),masterheatmap(5,:,:));
    masterheat   = masterheatmap(1:4,:,:);
    masterheatsd = masterheatsd(1:4,:,:);
    
    masterheat_ = masterheat;
    masterheat(blankus) = nan;
        
    % now show all the plots
    anames = {'AIP','F5','M1','Pooled'};
    clors = lines(4);
    clors = clors([4,2,1],:);
    clors = [clors;[0 0 0]];
    for jj = 1:4
        cmap = interp1([0;1],[1,1,1;clors(jj,:)],linspace(0,1,128)');
        figure,imagesc( squeeze( masterheat(jj,:,:) ),[masterheatmap(5,1,1) 1] ),colormap(cmap),colorbar
        title(sprintf('%s | %s | 3 epochs',seshnames{ii},anames{jj}))
        box off
        ylabel('Train')
        xlabel('Test')
        set(gca,'xtick',[0.5,9.5],'xticklabel',{'Execution','Observation'},'xticklabelrotation',-45)
        set(gca,'ytick',[0.5,9.5],'yticklabel',{'Execution','Observation'},'yticklabelrotation',45)
    end
    
    % next, omit the PRE-visual period and all classification accuracies dwarfed by IT
    masterheat   = masterheat_;
    visualinds   = [1:3,10:12];
    nonvisualinds = setdiff(1:18,visualinds);
    visualheat   = masterheat(:,visualinds,visualinds);
    movementheat = masterheat; movementheat(:,visualinds,:) = []; movementheat(:,:,visualinds) = [];
    movementsd   = masterheatsd; movementsd(:,visualinds,:) = []; movementsd(:,:,visualinds) = [];
    
    % across visual and movement periods AND across tasks. keep the threshold as low as possible! make it as easy to cross as possible!
    crossheat1 = masterheat(:,visualinds(1:3),nonvisualinds(7:12));
    crossheat2 = masterheat(:,visualinds(4:6),nonvisualinds(1:6));
    crossheat3 = masterheat(:,nonvisualinds(1:6),visualinds(4:6));
    crossheat4 = masterheat(:,nonvisualinds(7:12),visualinds(1:3));
    
    maxes      = [nanmax(crossheat1(:,:),[],2),nanmax(crossheat2(:,:),[],2),...
        nanmax(crossheat3(:,:),[],2),nanmax(crossheat4(:,:),[],2)];
    
    %     maxviz = max(visualheat(:,:),[],2);
    
    % actually, only focus on CROSS-decoding of visual information
    maxcross  = max( maxes,[],2 );
    
    blankmove = bsxfun(@lt,movementheat-movementsd,maxcross);
    
    movementheat(blankmove) = nan;
    
    for jj = 1:4
        cmap = interp1([0;1],[1,1,1;clors(jj,:)],linspace(0,1,128)');
        figure,imagesc( squeeze( movementheat(jj,:,:) ),[maxcross(jj) 1] ),colormap(cmap),colorbar
        title(sprintf('%s | %s | 2 epochs',seshnames{ii},anames{jj}))
        box off
        ylabel('Train')
        xlabel('Test')
        set(gca,'xtick',[0.5,6.5],'xticklabel',{'Execution','Observation'},'xticklabelrotation',-45)
        set(gca,'ytick',[0.5,6.5],'yticklabel',{'Execution','Observation'},'yticklabelrotation',45)
    end
    
    % don't get sucked down the post-hold rabbit hole
    % the reality is that there are too many fucking confounds (there's a NOISE that happens) to make too much of the classification result
    % at least, not without first removing the condition-independent component
end

%%
mkdir('NewHeatMaps')
for ii = 1:16
    figure(ii)
    savefigs(fullfile('.','NewHeatMaps',sprintf('newheatmaps%0.2i',ii)))
end