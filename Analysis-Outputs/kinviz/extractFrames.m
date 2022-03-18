%% description
% finds opensim movies after you record them & convert them to mp4
% then uses VideoReader to extract the constituent frames and save them
% using metadata recorded in frameObjects.txt

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

%% mp4 trawler

D = dir(mfd);
kinfolderid = arrayfun(@(x) ~isempty( regexpi(x.name,'_pooled$','once') ),D);
kinfolders = D(kinfolderid);
nfolders   = numel(kinfolders);

% don't need to implement a stack or queue or anything for a full tree traversal. We just have one level here
for folderind = 1:nfolders
    foldername  = kinfolders(folderind).name;
    file2search = fullfile(mfd,foldername,'*.mp4'); 
    mp4file     = dir(file2search); % should only be 1...
    file2read   = fullfile(mfd,foldername,mp4file.name);
    
    vobj = VideoReader(file2read); %#ok<TNMLP>
    
    % grab metadata from the text file
    metadata2read = fullfile(mfd,foldername,'frameObjects.txt');
    datastruct    = parsemetadata(metadata2read);
    
    timevals      = datastruct{1};
    onames        = datastruct{2};
    dtime         = median(diff(datastruct{1}));
    
    currentind    = 1;
    tv            = timevals(currentind) + dtime/2;
    
    tic
    while hasFrame(vobj)
        frame = vobj.readFrame();
        
        gotTime = vobj.currentTime;
        
        if gotTime > tv
            if currentind == 1
                postures = frame;
            else
                postures = cat(4,postures,frame);
            end
            
            currentind = currentind + 1;
            if currentind <= numel(timevals)
                tv = timevals(currentind) + dtime/2;
            else
                tv = inf;
            end
        else
            % pass
        end
    end
    
    % find pixels which ever change
    delstack       = diff( int16(postures),1,4 );
    delstack       = max(abs(delstack),[],4);
    delstack       = max(delstack,[],3);
    
    % set threshold (make it high enough to avoid capturing the pesky opensim logo through compression artefacts...)
    delmask        = delstack > 60;
    
    % find extents of change
    idx            = find(delmask(:));
    
    minx = inf;
    maxx = -inf;
    miny = inf;
    maxy = -inf;
    
    for ii = 1:numel(idx)
        [y,x] = ind2sub( size(delmask),idx(ii) );
        
        if y < miny
            miny = y;
        elseif y > maxy
            maxy = y;
        else
            % pass
        end
        
        if x < minx
            minx = x;
        elseif x > maxx
            maxx = x;
        else
            % pass
        end
    end
    
    % determine the background color
    postures_rs = permute(postures,[3,1,2,4]);
    postures_rs = postures_rs(:,:);
    bgcolor     = median(postures_rs(:,:),2);
    racolor     = range(postures_rs(:,:),2);
    
    % add a 1% buffer to the range
    buffersize  = racolor / 100;
    
    % add a 5% buffer to your window
    wid = size(postures,2);
    ht  = size(postures,1);
    
    minx = max( minx - floor(wid/20),1 );
    maxx = min( maxx + floor(wid/20),wid );
    miny = max( miny - floor(ht/20),1 );
    maxy = min( maxy + floor(ht/20),ht );
    
    % now apply the crop
    postures_cropped = postures(miny:maxy,minx:maxx,:,:);
    cropwid = size(postures_cropped,2);
    cropht  = size(postures_cropped,1);
    nimg = size(postures_cropped,4);
    
    % now set transparencies
    postures_cropped = double(postures_cropped) ./ 255;
    Amat = ones(cropht,cropwid,1,nimg);
    
    mintrans = max( (double(bgcolor) - double(buffersize))./255,0 );
    maxtrans = min( (double(bgcolor) + double(buffersize))./255,1 );
    
    minmat = repmat( permute(mintrans(:),[2,3,1]),cropht,cropwid,1,nimg );
    maxmat = repmat( permute(maxtrans(:),[2,3,1]),cropht,cropwid,1,nimg );
    
    transmask = all( postures_cropped >= minmat & postures_cropped <= maxmat,3 );
    Amat(transmask) = 0;
    
    % now display with imshow and SAVE EACH IMAGE
    for imind = 1:nimg
        oname = onames{imind};
        fname = fullfile(mfd,foldername,[oname,'_cropped.png']);
        frame = postures_cropped(:,:,:,imind);
        imwrite( frame,fname,'Alpha',Amat(:,:,1,imind) );
    end
    
    % TODO: re-take the vids with properly contrasting BG color...
        
end