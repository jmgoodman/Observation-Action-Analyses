function s = readtrc(filename,flipZ,onlyheader)

if nargin == 1
    flipZ = false;
end

if nargin <= 2
    onlyheader = false;
end

if ~onlyheader
    s = readtrc_schneller(filename,flipZ,onlyheader); % just run the faster version of this script then, eh?
    return
else
    % pass
end

fid = fopen(filename,'r');

try
    Rows = textscan(fid,'%s','delimiter','\n');
catch err
    fclose(fid);
    rethrow(err)
end

fclose(fid);

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

% updated this (20.02.2020) to reflect reality. I don't know why I thought 
% trc files ALWAYS had a "gap" row...
% also edited to handle cases where rows aren't terminated with the tab
% delimiter

if ~onlyheader
    
    % 6th and beyond contain data
    d_char = Rows{1}(6:end);
    dlim = find(d_char{1} == sprintf('\t'));
    dlim = [0,dlim,numel(d_char{1})];
    dlim = unique(dlim);
    d = zeros(numel(d_char),numel(dlim)-1); % subtract 1 as dlim indicates cell bounds, of which there are 1 more than there are cells.
    
    
    % there's a faster way to do this but I'm not proficient enough with
    % cellfun & other data structure futzing-abouts to be able to write it
    for i = 1:size(d,1)
        % updated here as well to handle the case where the row is not
        % terminated by the tab delimiter
        dlim = [0,find(d_char{i} == sprintf('\t')),numel(d_char{i})];
        dlim = unique(dlim);
        dlim = dlim(:)';
        for j = 1:size(d,2)
            d(i,j) = str2double(d_char{i}((dlim(j)+1):(dlim(j+1))));
        end
        fprintf('Row %i of %i finished\n',i,size(d,1))
    end
    
    % flip z coordinates if R hand:
    if flipZ
        d(:,5:3:end) = -d(:,5:3:end);
    else
    end
    
else % only extract times & frames
    % 6th and beyond contain data
    d_char = Rows{1}(6:end);
    dlim = find(d_char{1} == sprintf('\t'));
    dlim = [0,dlim,numel(d_char{1})];
    dlim = unique(dlim);
    d = zeros(numel(d_char),2);
    
    
    % there's a faster way to do this but I'm not proficient enough with
    % cellfun & other data structure futzing-abouts to be able to write it
    for i = 1:size(d,1)
        % updated here as well to handle the case where the row is not
        % terminated by the tab delimiter
        dlim = [0,find(d_char{i} == sprintf('\t')),numel(d_char{i})];
        dlim = unique(dlim);
        dlim = dlim(:)';
        for j = 1:2 %size(d,2)
            d(i,j) = str2double(d_char{i}((dlim(j)+1):(dlim(j+1))));
        end
        fprintf('Row %i of %i finished\n',i,size(d,1))
    end
end


s.header = h;
s.data   = d;

return
