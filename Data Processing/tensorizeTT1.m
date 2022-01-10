function [dtensor,arealabels,labstruct,neuronIDs] = tensorizeTT1(ppd)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this version of the script only looks at the mixed turntable (TT1) in order to keep all 3 tasks in its tensor.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

keepTTinds   = floor(ppd{1}{1}.TurnTableIDs/10) == 1;

[uon,~,uoi]  = unique(char(ppd{1}{1}.Objects(keepTTinds)),'rows');
uon          = cellstr(uon);
labstruct.objects = uon; % we already filter by keepTTinds here...

[ucn,~,uci]  = unique(char(ppd{1}{1}.TrialTypes(keepTTinds)),'rows');
ucn          = cellstr(ucn);
labstruct.contexts = ucn;

keepcontinds = find( cellfun(@(x) ismember(x,{'active','passive','control'}),ucn) );
keepconts    = ucn(keepcontinds); % alphabetic order, so {'active','control','passive'}. Don't forget it!


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
thisdata   = cellfun(@(x) cellfun(@(y) y.Data(:,:,keepTTinds),x,'uniformoutput',false),ppd,'uniformoutput',false);
arealabels = cellfun(@(x) x{1}.ArrayIDs,ppd,'uniformoutput',false);
arealabels = vertcat(arealabels{:});

neuronIDs  = cellfun(@(x) x{1}.NeuronIDs,ppd,'uniformoutput',false);
neuronIDs  = vertcat(neuronIDs{:});

tempdata   = cell(size(thisdata{1}));

for epochind = 1:numel(tempdata)
    td    = cellfun(@(x) x{epochind},thisdata,'uniformoutput',false);
    tdcat = horzcat(td{:}); % neurons are columns
    tempdata{epochind} = tdcat;
end

thisdata = tempdata;

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
        
        thisdataslice = thisdata(:,:,these_trials);
        % time x neurons x trials
        
        thisdataslice = permute(thisdataslice,[2,4,5,1,3]);
        % neurons x 0 x 0 x time x trials
        
        dtensor(:,oind,cind,:,1:size(thisdataslice,5)) = thisdataslice;
    end
end