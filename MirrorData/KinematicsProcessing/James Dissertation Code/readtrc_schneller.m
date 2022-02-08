function s = readtrc_schneller(filename,flipZ,onlyheader)
% only "schneller" if onlyheader = false

if nargin == 1
    flipZ = false;
end

if nargin <= 2
    onlyheader = false; % merely preserved for compatability with legacy readtrc calls
end

try
    
    fid = fopen(filename,'r');
    Rows = textscan(fid,'%s',5,'delimiter','\n'); % this just gets the header
    % the header will be a poorly-formatted cell array. it has all the info, but it's formatted the way an alien (or a lazy human) would do it.
    
    % h and d give the header and data, respectively
    % first 5 rows give the header
    dlim = find(Rows{1}{end} == sprintf('\t'));
    h = cell(5,numel(dlim));
    for i = 1:size(h,1)
        % Modified on 20.02.2020: added the very last index to ensure we don't
        % truncate the last column IN THE EVENT that it isn't terminated with a
        % column delimiter (and only, say, with the new-line delimiter)
        dlim = [0,find(Rows{1}{i} == sprintf('\t')),numel(Rows{1}{i})];
        dlim = unique(dlim);
        dlim = dlim(:)';
        
        %     if i > 1
        %         dlim = [0,find(Rows{1}{i} == sprintf('\t')),numel(Rows{1}{i})];
        %     else
        %         dlim = [0,find(Rows{1}{i} == sprintf('\t'))];
        %     end
        
        if i < 5
            for j = 1:(numel(dlim)-1)
                h{i,j} = Rows{1}{i}((dlim(j)+1):(dlim(j+1)));
            end
        else
            for j = 1:(numel(dlim)-1) % fifth row is offset in these files
                h{i,j+2} = Rows{1}{i}((dlim(j)+1):(dlim(j+1)));
            end
        end
    end
    
    % remove any trailing tab delimiters from the header cell
    for i = 1:numel(h)
        h_current  = h{i};
        tabdellocs = h_current == sprintf('\t');
        h_current(tabdellocs) = [];
        h{i} = h_current;
    end
    
    
    %% new code from here
    ncols = size(h,2);
    nrows = str2double(h{3,3});
    d     = nan(nrows,ncols);
    thisind = 1;
    tic
    while ~feof(fid)
        dline = fgetl(fid);
        drow  = textscan(dline, '%.8f',ncols);        
        d(thisind,:) = drow{1}(:)';
        thisind = thisind+1;
        toc
    end
    
    % if flipZ, flip the Z coordinate of your data
    if flipZ
        d(:,5:3:end) = -d(:,5:3:end);
    else
        % pass
    end
    
    
    s.header = h;
    s.data   = d;
    
catch err
    fclose(fid);
    rethrow(err)
end

fclose(fid);