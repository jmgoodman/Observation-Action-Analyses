function outstr = writetrc(filename,s)

% after you've done what you need to with the NaNs, write the updated
% struct into the file


% column and row delimiters
dc = sprintf('\t'); % tab delimiter
dr = sprintf('\n'); % newline

% shorthands
h = s.header;
d = s.data;


% start with the header
for i=1:5
    h_row = h(i,:);
    
    % edited to correct the formatting of the header, which turned out to
    % be a complete mess.
    %     useless_empty = cellfun(@isempty,h_row);
    %
    %     h_row = h_row(:,~useless_empty);
    
    % remove any trailing tab delimiters that you may have forgotten to
    % delete when reading these data in
    for jj = 1:numel(h_row)
        tabdelimlocs = (h_row{jj} == sprintf('\t'));
        h_row{jj}(tabdelimlocs) = [];
    end
    
    % re-insert those delimiters (except for the last row, where it isn't
    % needed)
    h_row(:,1:(end-1)) = cellfun(@horzcat,h_row(:,1:(end-1)),...
        repmat({dc},size(h_row(:,1:(end-1)))),'uniformoutput',false);

    if i==1
        h_new = horzcat(h_row{:},dr);
    else
        % given the new way of handling tab delimiters (namely, filling
        % everything out with them anyway), this additional line intended
        % to handle the case of row 5 of the header is no longer required.
        %         if i == 5
        %             h_new = horzcat(h_new,dc,dc);
        %         end
        
        h_new = horzcat(h_new,h_row{:},dr); %#ok<*AGROW>
    end
end

% the last dr is to account for the fact that there is an empty line
% between header and data
% edited on 20.02.2020 to stop doing this, because it is NOT actually
% necessary!
% outstr = horzcat(h_new,dr);
outstr = h_new; % note: this is just the header now.

% now open your file and write the header to it
fid = fopen(filename,'w');
fwrite(fid,outstr);
fclose(fid);

% now do the same with the data per se
F = ['%i\t',repmat('%0.5f\t',1,size(d,2)-1)]; % first column is frame # (ergo integer), other columns are floats
F = [F,'\n'];

fid = fopen(filename,'a');
fprintf(fid,F,d'); % transpose because fprintf reads the array as though it were a squeezed column vector
fclose(fid);
    
%% old, slow code (because it required writing everything to memory twice! super inefficient!)
% d1 = num2str(d(:,1),'%i\t');
% d1 = horzcat(d1,repmat(dc,size(d1,1),1));
% d2 = num2str(d(:,2:end),'%0.5f\t'); % hi. I'm the line that causes problems!
% d  = horzcat(d1,d2);
% d  = horzcat(d,repmat([dc,dr],size(d,1),1));
% d  = d'; % what the shit is all this about?
% d  = d(:);
% dtemp(dtemp == ' ') = []; % KILL the spaces
% outstr = horzcat(outstr,dtemp);
% now write it to file!
% fid = fopen(filename,'w');
% fwrite(fid,outstr);
% fclose(fid);