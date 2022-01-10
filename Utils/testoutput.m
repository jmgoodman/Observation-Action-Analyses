% testoutput

restoredefaultpath
addpath(genpath(fullfile('..','Analysis-Outputs')))

seshnames = {'Zara64','Zara68','Zara70','Moe46','Moe50'};

fn = {'normal','withMGG','mediansplit','commonspace','special','kinematics','kinclust'}; % vertex ids

for seshind = 1:numel(seshnames)
	fname = strcat('classification_results_',seshnames{seshind},'.mat');
	load(fname)

	disp(seshnames{seshind})

	fn_cstruct = fieldnames(cstruct);

	keepfn = ismember(fn,fn_cstruct);

	fnkept = fn(keepfn);

	disp(fnkept)

	anybad = false(size(fnkept));

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
	            traversal_stack(end)=[];
	            testcell = any( reshape( cellfun(@(x) any( cellfun(@(y) ...
	                strcmpi(class(y),'MException'),x) ),...
	                cs ),[],1) );
	            if testcell
	                anybad(fi) = true;
	                break
	            else
	                % pass
	            end
	        end
	        
	    end
	end

	disp(anybad)
        
end
