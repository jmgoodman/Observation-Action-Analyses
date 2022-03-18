function datastruct = parsemetadata(filename)

% column 1 = time
% column 2 = object name

% open the file
fid = fopen(filename,'r');

try
    % now, skip the header
    fgetl(fid);
    
    % now parse
    format_    = '%f%s';
    datastruct = textscan(fid,format_,'delimiter','\t');
catch err
    fclose(fid);
    rethrow(err);
end

fclose(fid);

end
    

