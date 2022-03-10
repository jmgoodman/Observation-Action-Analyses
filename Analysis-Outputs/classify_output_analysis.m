% testoutput
set(0,'defaultfigurewindowstyle','docked')

clear
clc
close all

restoredefaultpath
addpath(genpath(fullfile('..','Analysis-Scripts')))
analysis_setup
addpath(genpath(fullfile('..','Analysis-Outputs')))

seshnames = {'Moe32','Moe34','Moe46','Moe50','Zara64','Zara68','Zara70'}; % order that Call.m ran them in

fn = {'normal','withMGG','mediansplit','commonspace','special','kinematics','kinclust'}; % vertex ids
% note: kinematic classifier outputs have a different shape since they use
% bin edges and not counts within bin bounds

% create cell array to dump classification mats into
% original data:
% subsamples x context1 x context2 x align1 x align2 x subalign1 x subalign2
% array order: aip-f5-m1-pooled-chance
% align order: lighton - move - hold

% new array:
% level 1: session
% level 2: fieldnames
% level 3: array
% level 4: align x subalign

for seshind = 1:numel(seshnames)
    sname = seshnames{seshind};
    
    pco = 'processed-classification-outputs';
    mkdir(fullfile('..','Analysis-Outputs',sname,pco))
    
    fname = strcat('classification_results_',seshnames{seshind},'.mat');
    load(fname)
    
    disp(seshnames{seshind})
    
    fn_cstruct = fieldnames(cstruct);
    
    keepfn = ismember(fn,fn_cstruct);
    
    fnkept = fn(keepfn);
    
    % depthsearch
    for fi = 1:numel(fnkept)
        traversal_stack = {fnkept(fi)};
        visited_list    = {fnkept(fi)};
        
        while ~isempty(traversal_stack)
            tstack    = traversal_stack{end};
            
            cs = cstruct;
            
            for stackind = 1:numel(tstack)
                cs = cs.(tstack{stackind});
            end
            
            if isstruct(cs)
                adjnodes = fieldnames(cs);
                
                for nodeind = 1:numel(adjnodes)
                    nodename = horzcat(traversal_stack{end},adjnodes(nodeind));
                    
                    % search the visited_list
                    has_been_visited = false;
                    for visitind = 1:numel(visited_list)
                        if numel(visited_list{visitind}) == numel(nodename)
                            testval = all( cellfun(@(x,y) ...
                                strcmpi(x,y),nodename,visited_list{visitind}) );
                            if testval
                                has_been_visited = true;
                                continue
                            else
                                % pass
                            end
                            
                        else
                            % pass
                        end
                    end
                    
                    if ~has_been_visited
                        visited_list    = vertcat(visited_list,{nodename}); %#ok<*AGROW>
                        traversal_stack = vertcat(traversal_stack,{nodename});
                        break
                    else
                        % pass
                    end
                    
                    if has_been_visited && nodeind == numel(adjnodes) % if all have already been visited, pop the stack
                        traversal_stack(end) = [];
                    else
                        % pass (this shouldn't be reachable)
                    end
                    
                end
                
            else % if not isstruct, iscell!
                % pop
                thisnode = traversal_stack{end};
                traversal_stack(end)=[];
                
                % lh assignment
                appendlh = @(lh,fn2append) sprintf('%s.%s',lh,fn2append);
                lh = sprintf('classmats.%s',sname);
                
                for cellind = 1:numel(thisnode)
                    lh = appendlh(lh,thisnode{cellind});
                end
                
                % extract mu & sd across kfolds and subsamples
                narrays   = numel(cs{1}{1});
                ncontext  = size(cs,2);
                nalign    = size(cs,4);
                nsubalign = size(cs,6);
                mumat = zeros(nalign*nsubalign,nalign*nsubalign,narrays); % train x test x array
                sdmat = zeros(size(mumat));
                
                cstemp = cs(:,1,1,1,1,1,1);
                nsubsamp = numel(cstemp);
                nfold    = numel(cstemp{1});
                
                stackmat = zeros(nalign*nsubalign,nalign*nsubalign,narrays,nsubsamp,nfold);
                
                for context1 = 1:ncontext % train
                    for context2 = 1:ncontext % test
                        for align1 = 1:nalign % train
                            for align2 = 1:nalign % test
                                for subalign1 = 1:nsubalign % train
                                    for subalign2 = 1:nsubalign % test
                                        thisalignpair = squeeze( cs(:,context1,context2,align1,align2,subalign1,subalign2) );
                                        thisaligncat  = vertcat(thisalignpair{:}); % cat all subsamplings
                                        thisaligncat  = horzcat(thisaligncat{:}); % cat all kfold x subsamplings
                                        
                                        newcat        = horzcat(thisalignpair{:}); % cat folds along a different axis, gives folds x subsamplings
                                        newcat        = permute(newcat,[3,2,1]); % get to area x subsamplings x folds
                                        newcat        = cell2mat(newcat); % et voila
                                        
                                        mu_ = mean(thisaligncat,2);
                                        sd_ = std(thisaligncat,0,2);
                                        
                                        matind1 = sub2ind([nsubalign,nalign,ncontext],subalign1,align1,context1); % cycle thru subaligns first, THEN aligns, THEN contexts
                                        matind2 = sub2ind([nsubalign,nalign,ncontext],subalign2,align2,context2);
                                        
                                        mumat(matind1,matind2,:) = mu_;
                                        sdmat(matind1,matind2,:) = sd_;
                                        stackmat(matind1,matind2,:,:,:) = newcat;
                                    end
                                end
                            end
                        end
                    end
                end
                
                % compare output to previous structs, if exactly the same,
                % disregard (a way to salvage data where I ended up
                % duplicating fields that weren't overwritten between
                % sessions)
                doflag = true;
                for prevseshind = 1:(seshind-1)
                    oldseshname = seshnames{prevseshind};
                    [seshbeg,seshend] = regexpi(lh,sname,'start','end');
                    lhbeg = lh(1:(seshbeg-1));
                    lhend = lh((seshend+1):end);
                    oldlh = [lhbeg,oldseshname,lhend];
                    
                    try % skip fields that aren't present in the old array, for instance
                        oldmumat = eval( sprintf( '%s.mu;',oldlh ) );
                        oldsdmat = eval( sprintf( '%s.sd;',oldlh ) );
                        oldstackmat = eval( sprintf( '%s.stack;',oldlh ) );
                    
                        testval = all( abs( oldmumat(:) - mumat(:) ) < 1e-6 ) && ...
                            all( abs( oldsdmat(:) - sdmat(:) ) < 1e-6 ) && ...
                            all( abs( oldstackmat(:) - stackmat(:) )<1e-6 );
                        
                        if testval
                            doflag = false;
                            break
                        else
                            % pass
                        end
                    catch err
                        % pass
                    end
                end
                
                if doflag
                    eval( sprintf('%s.mu = mumat;',lh) );
                    eval( sprintf('%s.sd = sdmat;',lh) );
                    eval( sprintf('%s.stack = stackmat;',lh) );
                else
                    % pass
                end
                
                %                 % make a plot
                %                 cmap = flipud(bone);
                %
                %                 mumat_kept = mumat(:,:,1:(end-1));
                %                 sdmat_kept = sdmat(:,:,1:(end-1));
                %                 mumat_chance = mumat(:,:,end);
                %                 sdmat_chance = sdmat(:,:,end);
                %
                %                 % pooled variance
                %                 pooledsd = sqrt(bsxfun(@plus,sdmat_kept.^2,sdmat_chance.^2)/2);
                %
                %                 mumat_mask = bsxfun(@gt,mumat_kept-pooledsd,mumat_chance);
                %
                %                 mumat_plot = mumat_kept.*mumat_mask;news.ws
                %
                %                 for sliceind = 1:size(mumat_plot,3)
                %                     figure
                %                     imagesc(mumat_plot(:,:,sliceind),[0 1]),colormap(cmap)
                %                     box off, axis tight
                %                     xlabel('test')
                %                     ylabel('train')
                %                     set(gca,'xtick',[],'ytick',[])
                %                     title(sprintf('%s.%i',lh,sliceind),'interpreter','none')
                %                     colorbar
                %                     fname = fullfile('..','Analysis-Outputs',sname,pco,sprintf('%s.%i',lh,sliceind));
                %                     savefigs(fname)
                %                     close(gcf)
                %                 end
            end
            
        end
    end
    
end

fname = fullfile('..','Analysis-Outputs','all-sessions-classmats.mat');
save(fname,'classmats','-v7.3')

%%
% note: subsamples AND folds are normally paired samples when comparing
% across areas & with chance level
%
% subsamples, but NOT folds, are paired samples when comparing across
% contexts, alignments, and subalignments
%
% note: stack is now aligns x aligns x areas x subsamples x folds
