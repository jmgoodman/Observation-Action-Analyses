function plotProjections(hObject, eventdata, handles)
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
seshIdx          = get(handles.sessionSelector,'Value');
arrayIdx         = get(handles.sessionSelector,'Value');

trueArrayIdx     = mod(arrayIdx-2,4)+1; % AIP - F5 - M1 - pooled, but listed with pooled first in the GUI



% (time x context x TT x object) x neuron
% we're just gonna look at active vs. passive, screw control
% so we have 2 contexts
% n TT
% 6 objects per TT
% and 150 samples for perimovement and 100 for premovement

periAlign   = trialAverageCell{seshIdx}{1,2}.data{trueArrayIdx};
periAlignPC = trialAverageCell{seshIdx}{1,2}.nativeCoef{trueArrayIdx};

preAlign    = trialAverageCell{seshIdx}{1,1}.data{trueArrayIdx};
preAlignPC  = trialAverageCell{seshIdx}{1,1}.nativeCoef{trueArrayIdx};

n           = ncompsConservative(seshIdx,trueArrayIdx);

periAlign_full  = bsxfun(@minus,periAlign,mean(periAlign)) * periAlignPC;
periAlign_ortho = bsxfun(@minus,periAlign,mean(periAlign)) * ...
    ( preAlignPC(:,(n+1):end)*preAlignPC(:,(n+1):end)' ) * periAlignPC;

% preAlign activity will trivially be equal to 0 after orthogonalization
preAlign_full   = bsxfun(@minus,preAlign,mean(preAlign)) * preAlignPC;
preAlign_ortho  = preAlign_full; preAlign_ortho(:,1:n) = 0;

% unflatten
periDur = 150;
contextCount = 2;
objectCountPerTT = 6;

periAlign_full = reshape(periAlign_full,periDur,...
    objectCountPerTT,[],contextCount,size(periAlign_full,2));
periAlign_ortho = reshape(periAlign_ortho,periDur,...
    objectCountPerTT,[],contextCount,size(periAlign_ortho,2));

preDur = 100;
preAlign_full = reshape(preAlign_full,preDur,...
    objectCountPerTT,[],contextCount,size(preAlign_full,2));
preAlign_ortho = reshape(preAlign_ortho,preDur,...
    objectCountPerTT,[],contextCount,size(preAlign_ortho,2));

% next: find a pair of objects that maximize the dynamic movement-coupled
% variation between the two
%
% then plot 4 traces: 2 contexts x 2 objects
% with smaller breaks between subalignments and a bigger break between the two macroalignments
% for each plot, overlay the PC1 score prior to ortho with that post-ortho


%%

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
            'fontname','helvetica','fontsize',12,'color',colorStruct.colors(arrayInd,:))
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
