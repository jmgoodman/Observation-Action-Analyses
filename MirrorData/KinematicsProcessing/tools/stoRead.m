%STOREAD Read .sto files
%   STOSTRUCT = STOREAD(PATH) reads a single .sto file or a reads all .mot
%   files from a directory containing .sto files. PATH is either the
%   filename or the file directory. STOSTRUCT is a struct variable
%   containing the information from the single .sto file or a cell array
%   containing the information from all of the .sto files in the directory.
%
%   Original MOTREAD Created by Gregg Tabot, modified for STO files by James Goodman

function stoStruct = stoRead(path)
if isdir(path)
    directory = path;
    if ~isempty(findstr('/', directory)) && directory(end) ~= '/'
        directory(end + 1) = '/';
    elseif directory(end) ~= '\'
        directory(end + 1) = '\';
    end
    files = ls([directory '*.sto']);
    numFiles = length(files);
    stoStruct = cell(1, numFiles);
    for i = 1:numFiles
        fid = fopen([directory files(i, :)]);
        stoStruct{i} = parseFile(fid);
        fclose(fid);
    end
elseif exist(path, 'file')
    file = path;
    fid = fopen(file);
    stoStruct = parseFile(fid);
    fclose(fid);
else
    stoStruct = struct;
end
end

function motStruct = parseFile(fid)
    motStruct.fileName = fopen(fid);
    header = textscan(fid, '%s', 12, 'delimiter', '\n');
    header = header{1};
    motStruct.version = str2double(header{2}(9:end));
    motStruct.nRows = str2double(header{3}(7:end));
    motStruct.nColumns = str2double(header{4}(10:end));
    if strcmpi(header{5}, 'inDegrees=yes')
        motStruct.inDegrees = true;
    else
        motStruct.inDegrees = false;
    end
    columns = textscan(header{12}, '%s', motStruct.nColumns);
    motStruct.columnNames = columns{1};
    data = zeros(motStruct.nRows, motStruct.nColumns);
    for i = 1:motStruct.nRows
        line = fgetl(fid);
        dataRow = textscan(line, '%.8f', motStruct.nColumns);
        data(i, :) = dataRow{1};
    end
    motStruct.data = data;
end