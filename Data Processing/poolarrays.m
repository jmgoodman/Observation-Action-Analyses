function [pooledarraydatacell,arraynames] = poolarrays(celldata)

% takes cell data and pools across arrays from the same area
% this doesn't return a copy of the whole cellform data passed as input, just the "data" field
oldarraynames = cellfun(@(x) x{1}.ArrayIDs{1}, celldata,'uniformoutput',false );

arraydivider  = cellfun(@(x) regexpi(x,'(-|_)'),oldarraynames);
newarraynames = cellfun(@(x,y) x(1:(y-1)),oldarraynames,num2cell(arraydivider),'uniformoutput',false);

[arraynames,~,uainds] = unique(char(newarraynames),'rows');
arraynames = cellstr(arraynames);

pooledarraydatacell = cell(max(uainds),1);

for aind = 1:max(uainds)
    thesearrays  = uainds == aind;
    keptarrays   = celldata(thesearrays);
    pooledarrays = cell(size(keptarrays{1}));
    %     fn           = fieldnames(keptarrays{1}{1});
    
    %     % field names to concatenate
    %     fn_to_cat = {'Data','NeuronIDs','ArrayIDs'};
    
    % for each alignment
    for alignind = 1:numel(keptarrays{1})
        pooledarrays{alignind} = keptarrays{1}{alignind}; % from here, you move on
        
        kd = cellfun(@(x) x{alignind}.Data,keptarrays,'uniformoutput',false);
        pooledarrays{alignind}.Data = cat(2,kd{:});
        
        nids = cellfun(@(x) x{alignind}.NeuronIDs,keptarrays,'uniformoutput',false);
        pooledarrays{alignind}.NeuronIDs = cat(1,nids{:});
        
        aids = cellfun(@(x) x{alignind}.ArrayIDs,keptarrays,'uniformoutput',false);
        pooledarrays{alignind}.ArrayIDs = repmat(arraynames(aind),numel(vertcat(aids{:})),1);
        
        pooledarrays{alignind}.OldArrayIDs = vertcat(aids{:});
    end
    
    pooledarraydatacell{aind} = pooledarrays;
end

return
