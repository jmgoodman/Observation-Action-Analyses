function extractedstruct = extractlabels(celldata)

% extracts a bunch of labels associated with the cell-form data

objnames = celldata{1}{1}.Objects;
ttypes   = celldata{1}{1}.TrialTypes;
TTnames  = celldata{1}{1}.TurnTableIDs;
TTnames  = floor(TTnames/10); % first digit only

[uobjnames,~,objinds] = unique(char(objnames),'rows');
uobjnames = cellstr(uobjnames);

% shape names, for collecting similar objects of different sizes.
lastshapeind  = cellfun(@(x) regexpi(x,'(\s|\d)','once')-1,uobjnames,'uniformoutput',false);
lastshapeind  = cellfun(@(x,y) min( [x,length(y)] ),lastshapeind,uobjnames);
shapenames    = cellfun(@(x,y) x(1:y),uobjnames,num2cell(lastshapeind),'uniformoutput',false);

[ushapenames,~,shapeinds] = unique(char(shapenames),'rows');
ushapenames    = cellstr(ushapenames);
shapenames     = shapenames(objinds);
shapeinds      = shapeinds(objinds);

% turntable x object
[uTTnames,~,TTinds] = unique(TTnames);

% task types
[uttnames,~,ttinds] = unique(char(ttypes),'rows');
uttnames   = cellstr(uttnames);

nobjs         = max(objinds);
nconds        = numel(uttnames);
nTT           = numel(unique(TTnames));
nshapes       = max(shapeinds);

% extractedstruct
extractedstruct.objects.names       = objnames;
extractedstruct.objects.uniquenames = uobjnames;
extractedstruct.objects.uniqueinds  = objinds;
extractedstruct.objects.nunique     = nobjs;

extractedstruct.shapes.names        = shapenames;
extractedstruct.shapes.uniquenames  = ushapenames;
extractedstruct.shapes.uniqueinds   = shapeinds;
extractedstruct.shapes.nunique      = nshapes;

extractedstruct.turntablelabels.names       = TTnames;
extractedstruct.turntablelabels.uniquenames = uTTnames;
extractedstruct.turntablelabels.uniqueinds  = TTinds;
extractedstruct.turntablelabels.nunique     = nTT;

extractedstruct.trialcontexts.names       = ttypes;
extractedstruct.trialcontexts.uniquenames = uttnames;
extractedstruct.trialcontexts.uniqueinds  = ttinds;
extractedstruct.trialcontexts.nunique     = nconds;

