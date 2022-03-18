%% description
% trawls directories
% takes the last frame of each .mot
% puts them all together into a single .mot
% now all you gotta do is make the movie in Opensim and extract the individual frames of that movie

%% setup
restoredefaultpath

mfp = mfilename('fullpath');
[mfd,~,~] = fileparts(mfp);
cd(mfd)

% path setup
old_dir = cd( fullfile('..','..') ); % only way I can figure to convert this to an absoulte path: run cd, then reference pwd

% now add other paths (this is basically analysis_setup absent the manopt stuff)
addpath( genpath( fullfile(pwd,'MirrorData') ) )
addpath( genpath( fullfile(pwd,'Utils') ) )
addpath( genpath( fullfile(pwd,'Data Processing') ) )
cd(old_dir)

%% mot trawler
D = dir(mfd);
kinfolderid = arrayfun(@(x) ~isempty( regexpi(x.name,'_pooled$','once') ),D);
kinfolders = D(kinfolderid);
nfolders   = numel(kinfolders);

% don't need to implement a stack or queue or anything for a full tree traversal. We just have one level here
for folderind = 1:nfolders
	% find all the .mot files
	% use motRead to read them
	% pull out the last frame (& the formatting / metadata / column names)
	% use motWrite to make the new video
    
    foldername = kinfolders(folderind).name;
    D_         = dir(fullfile(mfd,foldername));
    motfileid  = arrayfun(@(x) ~isempty( regexpi(x.name,'.mot$','once') ),D_);
    motfiles   = D_(motfileid);
    
    % make sure you're not doing any recursive nonsense
    previousresultid = arrayfun(@(x) ~isempty( regexpi( x.name,'allObjects','once' ) ),motfiles);
    motfiles         = motfiles(~previousresultid);
    nfiles           = numel(motfiles);
    
    clearvars colNames ncols catData dt inds
    nframespersnapshot = 30;
    framerate          = 30; % 1/30 second per frame (Opensim is pretty cagey about giving details about its video encoding... but I *think* it's actually 30 fps?
    for motfileind = 1:nfiles
        thismotfile   = motfiles(motfileind).name;
        fullfile2read = fullfile(mfd,foldername,thismotfile);
        datastruct    = motRead(fullfile2read);
        
        if motfileind == 1
            colNames = datastruct.columnNames;
            ncols    = numel(colNames);
            catData  = zeros( nfiles*nframespersnapshot,ncols );
            % dt       = median(diff(datastruct.data(:,1))); % not needed...
        else
            % pass
        end
        
        inds = (1:nframespersnapshot) + (motfileind-1)*nframespersnapshot;
        catData(inds,:) = repmat(datastruct.data(end,:),nframespersnapshot,1);
        
    end
    
    tvals = (-1+(1:size(catData,1)))./framerate;
    catData(:,1) = tvals(:);
    
    fileName2write = fullfile(mfd,foldername,'allObjects');
    motWrite(fileName2write,colNames,catData);
    
    % also write some metadata for the frames (using the order that dir
    % pulled them)
    objectNames = arrayfun(@(x) getPart(x.name,2),motfiles,'uniformoutput',false);
    
    metaDataFile = fullfile(mfd,foldername,'frameObjects.txt');
    fid = fopen(metaDataFile,'w');
    
    try
        fprintf(fid,'%8s\t%s\n','time (s)','object name');
        for objind = 1:nfiles
            tind_ = (objind-1)*nframespersnapshot+1;
            tval_ = tvals(tind_);
            fprintf(fid,'%0.6f\t%s\n',tval_,objectNames{objind});
        end
    catch err
        fclose(fid);
        rethrow(err)
    end
    fclose(fid);
end