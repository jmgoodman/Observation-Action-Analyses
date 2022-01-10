% cresults: analyzes the outputs of the analysis pipeline
% see also: analyze_outputs.m for a treatment of the FVE by the common component within the shared space
animalnames = {'Moe46','Moe50','Zara64','Zara68','Zara70'};

restoredefaultpath
addpath(genpath(fullfile( '..','Utils' )))

for ii = 1:numel(animalnames)
    dir2look = fullfile('.',animalnames{ii});
    clear results
    %     classifile = fullfile(dir2look,sprintf(...
    %         'classification_results_%s.mat',animalnames{ii}));
    commonfile = fullfile(dir2look,sprintf(...
        'commonspace_results_%s.mat',animalnames{ii}));
    sustainfile = fullfile(dir2look,sprintf(...
        'sustainspace_results_%s.mat',animalnames{ii})); % add _%s for the latest batch...
    %     results.classification = load(classifile);
    results.commonspace    = load(commonfile);
    results.sustainspace   = load(sustainfile);
    
    % commonspace analysis: loss plotting under the NEW, CORRECT version!
    ss = results.commonspace.commonspace_FXVE_mov.subsamples;
    
    lossvals = cellfun(@(x) x.lossfunction,ss,'uniformoutput',false);
    lossvals = cellfun(@(x) bsxfun(@times,x,1./max(x,[],2)),lossvals,'uniformoutput',false);
    lossvals = cat(3,lossvals{:});
    mu       = mean(lossvals,3);
    sd       = std(lossvals,0,3);
    
    dims        = bsxfun(@lt,mu,min(mu,[],2)+mean(sd,2));
    dims_max    = zeros(size(dims,1),1);
    dims_min    = zeros(size(dims,1),1);
    
    for rowind = 1:size(dims,1)
        maxdimality = find(dims(rowind,:),1,'last');
        dims_max(rowind) = maxdimality;
        
        mindimality = find(dims(rowind,:),1,'first');
        dims_min(rowind) = mindimality;
    end
    
    %     figure,plot(mu')
    
    %% FVE (within the 30-D PCA)
    eproj = ss{end}.exec;
    oproj = ss{end}.obs;
    
    eorig = ss{end}.exec_;
    oorig = ss{end}.obs_;
    
    lossvals = ss{end}.lossfunction; % i.e., residuals
    
    % eorig is the output of PCA and orthogonalization w.r.t. the mean-separating axis
    % ergo, it's already de-meaned
    totvar = cellfun(@(x,y) norm(x,'fro')^2 + ...
        norm(y,'fro')^2,eorig,oorig);
    
    FVE = 1 - bsxfun(@times,lossvals,1./totvar);
    
    
    % now do it on a subsampled basis
    eorig = cellfun(@(x) x.exec_,ss(1:(end-1)),'uniformoutput',false);
    oorig = cellfun(@(x) x.obs_,ss(1:(end-1)),'uniformoutput',false);
    
    lossvals = cellfun(@(x) x.lossfunction,ss(1:(end-1)),'uniformoutput',false); % sum of squared residuals when using a reduced-rank version of the OTHER context as your model (per se!) of THIS context
    
    totvar = cellfun(@(x,y) cellfun(@(x,y) norm(x,'fro')^2 + norm(y,'fro')^2,x,y),...
        eorig,oorig,'uniformoutput',false);
    
    FVE = cellfun(@(x,y) 1-bsxfun(@times,x,1./y),...
        lossvals,totvar,'uniformoutput',false);
    
    FVE_stack = cat(3,FVE{:});
    
    FVE_mu = mean(FVE_stack,3);
    FVE_sd = std(FVE_stack,0,3);
    
    %     figure,plot(FVE_mu')
    
    clors = lines(4); % AIP - F5 - M1 - pooled
    clors = clors([4,2,1],:);
    clors = [clors;0,0,0]; %#ok<AGROW>
    
    figure
    for jj = 1:size(FVE_mu,1)
        mu = FVE_mu(jj,:);
        sd = FVE_sd(jj,:);
        hold all
        ErrorRegion((1:numel(mu))',mu(:),sd(:),sd(:),'facecolor',clors(jj,:),...
            'edgecolor',clors(jj,:),'linecolor',clors(jj,:),'linestyle','-');
        hold all
        scatter(1:numel(mu),mu,64,clors(jj,:),'markeredgecolor',clors(jj,:),'markerfacecolor',clors(jj,:))
    end
    
    box off, axis tight
    xlabel('Number of dimensions in common subspace')
    ylabel('Fraction of total variance explained by common subspace')
    
    dims        = bsxfun(@gt,FVE_mu,max(FVE_mu,[],2)-mean(FVE_sd,2));
    dims_max    = zeros(size(dims,1),1);
    dims_min    = zeros(size(dims,1),1);
    
    [maxv,maxi] = max(FVE_mu,[],2);
    
    for rowind = 1:size(dims,1)
        maxdimality = find(dims(rowind,:),1,'last');
        dims_max(rowind) = maxdimality;
        
        mindimality = find(dims(rowind,:),1,'first');
        dims_min(rowind) = mindimality;
    end
    
    yl = get(gca,'ylim');
    for jj = 1:size(FVE_mu,1)
        dimbounds = [dims_min(jj),dims_max(jj)];
        
        ypos = max(yl) + range(yl)*(0.025*jj);
        
        hold all
        line(dimbounds,[ypos,ypos],'linewidth',1,'color',clors(jj,:))
    end
    axis tight
    
    hold all
    for jj = 1:size(FVE_mu,1)
        hold all
        scatter(maxi(jj),maxv(jj),196,'markeredgecolor',clors(jj,:),'markerfacecolor','none')
    end
    
    title( animalnames{ii} )
    customlegend({'AIP','F5','M1','Pooled'},'colors',clors,...
        'ystep',0.03)
    %% FVE by condition-independent component within the shared space
    
    eproj = ss{end}.exec;
    R2 = zeros( size(eproj,1),size(eproj,2),numel(ss)-1 );
    
    for jj = 1:(numel(ss)-1)
        eproj = ss{jj}.exec;
        oproj = ss{jj}.obs;
        
        % fold across objects
        eprojrs = cellfun(@(x) x',eproj,'uniformoutput',false);
        eprojrs = cellfun(@(x) reshape(x,size(x,1),100,[]),eprojrs,'uniformoutput',false);
        
        oprojrs = cellfun(@(x) x',oproj,'uniformoutput',false);
        oprojrs = cellfun(@(x) reshape(x,size(x,1),100,[]),oprojrs,'uniformoutput',false);
        
        % average across objects (& conditions)
        catprojrs = cellfun(@(x,y) cat(3,x,y),eprojrs,oprojrs,'uniformoutput',false);
        muprojrs  = cellfun(@(x) mean(x,3),catprojrs,'uniformoutput',false);
        residprojrs = cellfun(@(x,y) bsxfun(@minus,x,y),catprojrs,muprojrs,'uniformoutput',false);
        
        % everything is demeaned, so we can just do squared fronorm
        % plus, by design, it's supposed to have as little context-specific variance as possible
        % (I *could*, like, TEST that...)
        R2(:,:,jj) = cellfun(@(x,y) 1 - norm(x(:),'fro')^2 / norm(y(:),'fro')^2,...
            residprojrs,catprojrs );
        
        %         % the below code barely changes anything. indeed, these subspaces are designed to have as little context-dependent variance as possible...
        %         % okay what I just did was silly. what I REALLY need to do is admit a difference between conditions, too (i.e., that the common space may not actually be so common after all...)
        %         eprojresid = cellfun(@(x) bsxfun(@minus,x,mean(x,3)),eprojrs,'uniformoutput',false);
        %         oprojresid = cellfun(@(x) bsxfun(@minus,x,mean(x,3)),oprojrs,'uniformoutput',false);
        %
        %         % remember, you removed the subspace separating the means of the two tasks... so each one individually should also have 0 mean
        %         R2(:,:,jj) = cellfun(@(w,x,y,z) ( sum(w(:).^2) + sum(x(:).^2) )/( sum(y(:).^2) + sum(z(:).^2) ),...
        %             eprojresid,oprojresid,eproj,oproj);
    end
    
    % plot
    clors = lines(4); % AIP - F5 - M1 - pooled
    clors = clors([4,2,1],:);
    clors = [clors;0,0,0]; %#ok<AGROW>
    
    R2_mu = mean(R2,3);
    R2_sd = std(R2,0,3);
    
    figure
    for jj = 1:size(R2_mu,1)
        mu = R2_mu(jj,:);
        sd = R2_sd(jj,:);
        hold all
        ErrorRegion((1:numel(mu))',mu(:),sd(:),sd(:),'facecolor',clors(jj,:),...
            'edgecolor',clors(jj,:),'linecolor',clors(jj,:),'linestyle','-');
        hold all
        scatter(1:numel(mu),mu,64,clors(jj,:),'markeredgecolor',clors(jj,:),'markerfacecolor',clors(jj,:))
    end
    
    box off, axis tight
    xlabel('Number of dimensions in common subspace')
    ylabel('Fraction of common subspace variance captured by a condition-invariant component')
    
    %     dims        = bsxfun(@gt,FVE_mu,max(FVE_mu,[],2)-mean(FVE_sd,2));
    %     dims_max    = zeros(size(dims,1),1);
    %     dims_min    = zeros(size(dims,1),1);
    %
    %     [maxv,maxi] = max(FVE_mu,[],2);
    %
    %     for rowind = 1:size(dims,1)
    %         maxdimality = find(dims(rowind,:),1,'last');
    %         dims_max(rowind) = maxdimality;
    %
    %         mindimality = find(dims(rowind,:),1,'first');
    %         dims_min(rowind) = mindimality;
    %     end
    
    yl = get(gca,'ylim');
    for jj = 1:size(FVE_mu,1)
        dimbounds = [dims_min(jj),dims_max(jj)];
        
        ypos = max(yl) + range(yl)*(0.025*jj);
        
        hold all
        line(dimbounds,[ypos,ypos],'linewidth',1,'color',clors(jj,:))
    end
    axis tight
    
    %     hold all
    %     for jj = 1:size(FVE_mu,1)
    %         hold all
    %         scatter(maxi(jj),maxv(jj),196,'markeredgecolor',clors(jj,:),'markerfacecolor','none')
    %     end
    
    title( animalnames{ii} )
    customlegend({'AIP','F5','M1','Pooled'},'colors',clors,...
        'ystep',0.03)
    
    %% quantify, within the common space, how much variance is context specific
    eproj = ss{end}.exec;
    R2 = zeros( size(eproj,1),size(eproj,2),numel(ss)-1 );
    
    for jj = 1:(numel(ss)-1)
        eproj = ss{jj}.exec;
        oproj = ss{jj}.obs;
        
        % fold across objects
        eprojrs = cellfun(@(x) x',eproj,'uniformoutput',false);
        eprojrs = cellfun(@(x) reshape(x,size(x,1),100,[]),eprojrs,'uniformoutput',false);
        
        oprojrs = cellfun(@(x) x',oproj,'uniformoutput',false);
        oprojrs = cellfun(@(x) reshape(x,size(x,1),100,[]),oprojrs,'uniformoutput',false);
        
        % average across contexts
        catprojrs = cellfun(@(x,y) cat(4,x,y),eprojrs,oprojrs,'uniformoutput',false);
        muprojrs  = cellfun(@(x) mean(x,4),catprojrs,'uniformoutput',false);
        residprojrs = cellfun(@(x,y) bsxfun(@minus,x,y),catprojrs,muprojrs,'uniformoutput',false);
        
        R2(:,:,jj) = cellfun(@(x,y) 1 - norm(x(:),'fro')^2 / norm(y(:),'fro')^2,...
            residprojrs,catprojrs );
    end
    
    % plot
    clors = lines(4); % AIP - F5 - M1 - pooled
    clors = clors([4,2,1],:);
    clors = [clors;0,0,0]; %#ok<AGROW>
    
    R2_mu = mean(R2,3);
    R2_sd = std(R2,0,3);
    
    figure
    for jj = 1:size(R2_mu,1)
        mu = R2_mu(jj,:);
        sd = R2_sd(jj,:);
        hold all
        ErrorRegion((1:numel(mu))',mu(:),sd(:),sd(:),'facecolor',clors(jj,:),...
            'edgecolor',clors(jj,:),'linecolor',clors(jj,:),'linestyle','-');
        hold all
        scatter(1:numel(mu),mu,64,clors(jj,:),'markeredgecolor',clors(jj,:),'markerfacecolor',clors(jj,:))
    end
    
    box off, axis tight
    xlabel('Number of dimensions in common subspace')
    ylabel('Fraction of common subspace variance that is shared across contexts')
    
    %     dims        = bsxfun(@gt,FVE_mu,max(FVE_mu,[],2)-mean(FVE_sd,2));
    %     dims_max    = zeros(size(dims,1),1);
    %     dims_min    = zeros(size(dims,1),1);
    %
    %     [maxv,maxi] = max(FVE_mu,[],2);
    %
    %     for rowind = 1:size(dims,1)
    %         maxdimality = find(dims(rowind,:),1,'last');
    %         dims_max(rowind) = maxdimality;
    %
    %         mindimality = find(dims(rowind,:),1,'first');
    %         dims_min(rowind) = mindimality;
    %     end
    
    yl = get(gca,'ylim');
    for jj = 1:size(FVE_mu,1)
        dimbounds = [dims_min(jj),dims_max(jj)];
        
        ypos = max(yl) + range(yl)*(0.025*jj);
        
        hold all
        line(dimbounds,[ypos,ypos],'linewidth',1,'color',clors(jj,:))
    end
    axis tight
    
    %     hold all
    %     for jj = 1:size(FVE_mu,1)
    %         hold all
    %         scatter(maxi(jj),maxv(jj),196,'markeredgecolor',clors(jj,:),'markerfacecolor','none')
    %     end
    
    title( animalnames{ii} )
    customlegend({'AIP','F5','M1','Pooled'},'colors',clors,...
        'ystep',0.03)
end

for ii = 1:15
    figure(ii)
    savefigs(sprintf('commonspace_quant_%0.2i',ii))
end
    