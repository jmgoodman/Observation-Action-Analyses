function [] = dataSaver(hObject, eventdata, handles, targetObj)

% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% targetObj  name of the handle to the figure or table bound to the pushbutton

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this is the callback for all the pushbuttons to save figures & data

%% step -1: get directory
mfd = mfilename('fullpath');
[cd_,~,~] = fileparts(mfd);
[cd_,~,~] = fileparts(cd_); % get to ResultsExplorer directory

%% step 0: if a table, save to a csv file
% can then use a csv viewer to peruse the data with human eyes
% OR can automate data retrieval using standard csv parsers
% Mac's Preview displays .csv files VERY nicely
thisObj = handles.(targetObj);
if ~isempty( regexpi( class( thisObj ),'table','once' ) )
    thisData = thisObj.Data;
    colNames = thisObj.ColumnName;
    rowNames = thisObj.RowName;
    
    if iscell(thisData)
        T = cell2table( thisData,'RowNames',rowNames,'VariableNames',colNames);
    else
        T = array2table( thisData,'RowNames',rowNames,'VariableNames',colNames);
    end
    
    
    defaultFile   = fullfile(cd_,'Outputs',sprintf('%s.csv',targetObj));
    [fname,fpath] = uiputfile(defaultFile);
    
    if fname
        fullfname = fullfile(fpath,fname);
        writetable(T,fullfname,'FileType','text','WriteRowNames',true);
    else
        warning('no file chosen, saving aborted')
    end
    
    return % end evaluation here if just a table
else
    % pass
end

%% step 1: if a figure, bring up a new figure window which slaps the figure onto a US letter-size sheet

% call the other gui
h = plotPreview;

