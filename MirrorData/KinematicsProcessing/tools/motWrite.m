function motWrite(filename, columnNames, data)
fileID = fopen([filename '.mot'], 'w');
try
    fprintf(fileID, 'Coordinates\n');
    fprintf(fileID, 'version=1\n');
    fprintf(fileID, 'nRows=%d\n', size(data, 1));
    fprintf(fileID, 'nColumns=%d\n', size(data, 2));
    fprintf(fileID, 'inDegrees=yes\n');
    fprintf(fileID, '\n');
    fprintf(fileID, 'Units are S.I. units (second, meters, Newtons, ...)\n');
    fprintf(fileID, 'Angles are in degrees.\n');
    fprintf(fileID, '\n');
    fprintf(fileID, 'endheader\n');
    fprintf(fileID, '%s', columnNames{1}); fprintf(fileID, '\t%s', columnNames{2:end}); fprintf(fileID, '\n');
    for row = 1:size(data, 1)
        fprintf(fileID, '%f', data(row, 1)); fprintf(fileID, '\t%f', data(row, 2:end)); fprintf(fileID, '\n');
    end
    fclose(fileID);
catch me
    fclose(fileID);
    disp(me);
end
end