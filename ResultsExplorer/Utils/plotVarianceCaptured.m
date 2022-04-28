function plotVarianceCaptured(hObject, eventdata, handles)
% hObject    handle to sessionSelector (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sessionSelector contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sessionSelector

% this makes the scatterplot for Figure 4C (variance captured in pre-
% versus peri-movement epochs)

seshCell         = getappdata(handles.output,'seshCell');
trialAverageCell = getappdata(handles.output,'trialAverageCell');
ncompsConservative = getappdata(handles.output,'ncompsConservative'); % cols = AIP - F5 - M1 - pooled, rows = sessions
ncompsAggressive   = getappdata(handles.output,'ncompsAggressive');
seshNames        = get(handles.sessionSelector,'String');
arrayNames       = get(handles.areaSelector,'String');


% first col, all objects
xcell = cellfun(@(x) x{1},seshCell(:,1),'uniformoutput',false);
ycell = cellfun(@(x) x{2},seshCell(:,1),'uniformoutput',false);

xcell = cellfun(@(x) x.data,xcell,'uniformoutput',false);
ycell = cellfun(@(x) x.data,ycell,'uniformoutput',false);

X = {};
Y = {};

for seshInd = 1:numel(xcell)
    arrayX = xcell{seshInd};
    arrayY = ycell{seshInd};
    X = vertcat(X,arrayX(:)'); %#ok<*AGROW>
    Y = vertcat(Y,arrayY(:)');
end

Xvals = cellfun(@(x,y) x(y),X,num2cell(ncompsConservative));
Yvals = cellfun(@(x,y) x(y),Y,num2cell(ncompsConservative));

% get colors and change order to match that of the cells above
colorStruct = defColorConvention();
colorStruct.colors = colorStruct.colors([2:4,1],:);
colorStruct.labels = colorStruct.labels([2:4,1]);

% for each session
axes(handles.variancePlot)
for seshInd = 1:size(Xvals,1)
    textLabel = seshNames{seshInd}(1);
    for arrayInd = 1:size(Xvals,2)
        x = Xvals(seshInd,arrayInd);
        y = Yvals(seshInd,arrayInd);
        
        hold all
        text(x,y,textLabel,'horizontalalign','center','verticalalign','middle',...
            'fontname','helvetica','fontsize',20,'color',colorStruct.colors(arrayInd,:))
    end
end

hold all
line([0 1],[0 1],'linewidth',1,'linestyle','--','color',[0 0 0])

xlim([0 1])
ylim([0 1])

xlabel('FVE pre-go')
ylabel('FVE peri-movement')
axis square

colorStruct = defColorConvention(); % get back to this order to maintain consistency with other plots
customlegend(colorStruct.labels,'colors',colorStruct.colors)
