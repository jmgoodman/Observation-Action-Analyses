function dtensor = tensorize_keepTTinfo(ppd)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% add inputs to allow one to include the control task, focus on just one particular turntable, etc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% [uon,~,uoi]  = unique(char(ppd{1}{1}.Objects),'rows');
% uon          = cellstr(uon);

[uon,~,uoi] = unique(ppd{1}{1}.TurnTableIDs);

[ucn,~,uci]  = unique(char(ppd{1}{1}.TrialTypes),'rows');
ucn          = cellstr(ucn);

keepcontinds = find( cellfun(@(x) ismember(x,{'active','passive','control'}),ucn) );
keepconts    = ucn(keepcontinds);

nconts  = numel(keepconts);
nobjs   = numel(uon);
ntrials = 0;

% find the object x context combination with the most trials
for cind = 1:nconts
    for oind = 1:nobjs
        thiscontind = keepcontinds(cind);
        thisobjind  = oind;
        
        these_trials = uci == thiscontind & uoi == thisobjind;
        
        ntrialstemp = sum(these_trials);
        
        if ntrialstemp > ntrials
            ntrials = ntrialstemp;
        else
            % pass
        end
    end
end

% combine all areas, see if you can discern areas in an unsupervised manner
thisdata   = cellfun(@(x) cellfun(@(y) y.Data,x,'uniformoutput',false),ppd,'uniformoutput',false);
clear ppd % lines like this do the necessary work of reducing memory overhead. This is a LOT of data, after all!

tempdata   = cell(size(thisdata{1}));

for epochind = 1:numel(tempdata)
    td    = cellfun(@(x) x{epochind},thisdata,'uniformoutput',false);
    tdcat = horzcat(td{:}); % neurons are columns
    clear td
    tempdata{epochind} = tdcat;
    clear tdcat
end

thisdata = tempdata;
clear tempdata

thisdata   = vertcat(thisdata{:});

nneur     = size(thisdata,2);
nsamps    = size(thisdata,1);

% organize into a tensor
% neurons x objects x contexts x time x trials
dtensor   = nan(nneur,nobjs,nconts,nsamps,ntrials);

% now run through each obj x context combo
for cind = 1:nconts
    for oind = 1:nobjs
        thiscontind = keepcontinds(cind);
        thisobjind  = oind;
        
        these_trials = uci == thiscontind & uoi == thisobjind;
        
        if sum(these_trials) == 0
            continue
        else
            % pass
        end
        
        thisdataslice = thisdata(:,:,these_trials);
        % time x neurons x trials
        
        thisdataslice = permute(thisdataslice,[2,4,5,1,3]);
        % neurons x 0 x 0 x time x trials
        
        dtensor(:,oind,cind,:,1:size(thisdataslice,5)) = thisdataslice;
        clear thisdataslice
    end
end
clear thisdata

return