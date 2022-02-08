%MOTREAD Read .mot files
%   MOTSTRUCT = MOTREAD(PATH) reads a single .mot file or a reads all .mot
%   files from a directory containing .mot files. PATH is either the
%   filename or the file directory. MOTSTRUCT is a struct variable
%   containing the information from the single .mot file or a cell array
%   containing the information from all of the .mot files in the directory.
%
%   Created by Gregg Tabot

function motStruct = motRead(path)
if isdir(path)
    directory = path;
    if ~isempty(findstr('/', directory)) && directory(end) ~= '/'
        directory(end + 1) = '/';
    elseif directory(end) ~= '\'
        directory(end + 1) = '\';
    end
    files = ls([directory '*.mot']);
    numFiles = length(files);
    motStruct = cell(1, numFiles);
    for i = 1:numFiles
        fid = fopen([directory files(i, :)]);
        motStruct{i} = parseFile(fid);
        fclose(fid);
    end
else
    [pathstr,name,ext] = fileparts(path);
    
    D = dir(pathstr);
    
    fexist = any( arrayfun(@(x) strcmpi([name,ext],x.name),D) );
    
    if fexist % replaces exist(path, 'file'), which DOES NOT WORK on MATLAB 2015a in Windows 10 (what a pain in the fucking ass)
        file = path;
        fid = fopen(file);
        motStruct = parseFile(fid);
        fclose(fid);
    else
        motStruct = struct;
    end
end
end

function motStruct = parseFile(fid)
    motStruct.fileName = fopen(fid);
    header = textscan(fid, '%s', 11, 'delimiter', '\n');
    header = header{1};
    motStruct.version = str2double(header{2}(9:end));
    motStruct.nRows = str2double(header{3}(7:end));
    motStruct.nColumns = str2double(header{4}(10:end));
    if strcmpi(header{5}, 'inDegrees=yes')
        motStruct.inDegrees = true;
    else
        motStruct.inDegrees = false;
    end
    columns = textscan(header{11}, '%s', motStruct.nColumns);
    motStruct.columnNames = columns{1};
    data = zeros(motStruct.nRows, motStruct.nColumns);
    for i = 1:motStruct.nRows
        try
            line = fgetl(fid);
            dataRow = textscan(line, '%.8f', motStruct.nColumns);
            data(i, :) = dataRow{1};
        catch err
            % if this fails, it means nRows is WRONG
            data = data(1:(i-1),:);
            motStruct.nRows = i-1;
            break
        end
    end
    motStruct.data = data;
end