function varargout = Player(varargin)
%m-function for the GUI KinemaTracks

%set globals
global REC;
global ST;
global TO;
global GHO;
global LHO;
global FL;
global lastfile;
% conspicuously absent: calibdata

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Player');
    

    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'Player');
        set(fig,'NumberTitle','off', 'Name','Player');
        
        h1 = findall(0,'Tag','axes_object');
        axes(h1);
        axis off;
        
        
%         h = findall(0,'tag','KinemaTracks');
%         handlesMain = guihandles(h); 
%         plotHand(LHO,GHO,handlesMain); 
%         automaticscale(handlesMain,LHO,GHO);
%         h1 = findall(0,'Tag','axes_hand');
%         axes(h1);
%         axis on;
%         h2 = findall(0,'Tag','axes_global');
%         axes(h2);
%         axis on;
        
        
%         set(fig,'Visible','off');
        
% Generate a structure of handles to pass to callbacks, and store it.
        handles = guihandles(fig);
        
        refreshPlayerPlot(handles);
        
        % Generate a structure of handles to pass to callbacks, and store it.
        
        
        handles = guihandles(fig);

        set(fig,'Visible','on');
        
        
    else 
        
   
        disp('Not allowed to start multiple Windows. Window is already open.');
        %bring figure to front
        figure(h);
        return
        
    end;
    

    


    

elseif ischar(varargin{1}) 
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch exception
        rethrow(exception);
    end

end
end 


function [] = refreshPlayerPlot(handles)
global REC;
global ST;
global TO;
global DI;
global GHO;
global LHO;
global FL;

% Visualize Button Colors
        if isempty(REC) || isempty(GHO) || isempty(LHO) % check if recording file is loaded
            FL.recloaded=0;
            set(handles.load_kinematic_button,'BackgroundColor','r');
            set(handles.play_button,'Enable','off');
            set(handles.stop_button,'Enable','off');
            set(handles.pause_button,'Enable','off');
        else 
            FL.recloaded=1;
            set(handles.load_kinematic_button,'BackgroundColor','g');
            set(handles.play_button,'Enable','on');
            set(handles.stop_button,'Enable','on');
            set(handles.pause_button,'Enable','on');
            set(handles.start_time_edit,'String',num2str(min(REC(:,1,2))));
            set(handles.stop_time_edit,'String',num2str(max(REC(:,1,2))));
            set(handles.speed_edit,'String','1');
        end
        
        if isempty(ST) 
            FL.stateloaded=0;
            set(handles.load_state_button,'BackgroundColor','r');
        else
            FL.stateloaded=1;
            set(handles.load_state_button,'BackgroundColor','g');
        end
        
        if isempty(DI)
            FL.diloaded=0;
            set(handles.load_di_button,'BackgroundColor','r');
        else
            FL.diloaded=1;
            set(handles.load_di_button,'BackgroundColor','g');
        end
        
        if isempty(TO)
            FL.trialloaded=0;
            set(handles.load_trial_button,'BackgroundColor','r');
        else
            FL.trialloaded=1;
            set(handles.load_trial_button,'BackgroundColor','g');
        end
        

        if FL.trialloaded==1
            set(handles.set_time_button,'Enable','on');
            set(handles.condition_edit,'Enable','on');

        else
            set(handles.set_time_button,'Enable','off');
            set(handles.condition_edit,'Enable','off');
        end
        
        if FL.trialloaded==1 && FL.stateloaded==1 

            set(handles.fixation_text,'Visible','off')
            set(handles.cue_text,'Visible','off')
            set(handles.fixation_button,'Visible','off')
            set(handles.cue_button,'Visible','off')
        else
            set(handles.axes_object,'Visible','off')
            set(handles.object_text,'Visible','off')
            set(handles.fixation_text,'Visible','off')
            set(handles.cue_text,'Visible','off')
            set(handles.fixation_button,'Visible','off')
            set(handles.cue_button,'Visible','off')
        end
end

%########################### EXIT MENUE ###################################

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Load_Kinematic_Callback(~,~,handles,varargin) % This is where the "load kinematic" button leads!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global lastdir;
global lastfile;
global REC;
global FL;
if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
[FileName,PathName,~] = uigetfile({'*.mat','*_HTS.mat File'},'Select Recording...', lastdir);
if PathName~=0
    lastdir=PathName; 
    lastfile=FileName;
end

S=load([PathName FileName],'recording');
if size(S.recording,2)==8 && size(S.recording,3)==7 && size(S.recording,1)>1
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    REC=S.recording; % NOTE: WHEREVER YOU SEE REC, THAT IS WHERE DATA LIVE!!!!!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    FL.recloaded=1;
else
    FL.recloaded=0;
end
    
refreshPlayerPlot(handles);


end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Play_Callback(~,~,handles,varargin) % This is where the "Play" button leads!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global REC;
global TO;
global ST;
global GHO;
global LHO;
global STO;
global UDP1;
global udpSendCount;

h = findall(0,'tag','KinemaTracks');
handlesMain = guihandles(h); 

data=zeros(size(REC,2),size(REC,3));

% Old style copy objects, don't allow online updates
%warning off;
%GHO2=struct(GHO);
%LHO2=struct(LHO);
%warning on;

speed=str2double(get(handles.speed_edit,'String'));
secfrom=str2double(get(handles.start_time_edit,'String'));
secto=str2double(get(handles.stop_time_edit,'String'));

if isnan(secto)
    secto = secfrom;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
systemtimes=REC(:,1,2); % this column gives you the sample times (which may or may not be synchronized to the data -> check for more clues!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

from = find(systemtimes >= secfrom - 0.009, 1, 'first');
to = find(systemtimes <= secto + 0.009, 1, 'last');

set(handles.start_time_edit, 'String', num2str(systemtimes(from)));
set(handles.stop_time_edit, 'String', num2str(systemtimes(to)));

fprintf('From %f (%d) to %f (%d)\n', systemtimes(from), from, systemtimes(to), to);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
TDT_starttime(1,1)=REC(from,1,2); % get the first time sampled with TDT 
% well, there's your sign. It's synced, with no adjustments or extra data
% needed to accomplish said syncing.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

warning('off');
tic
set(handlesMain.axes_hand,'UserData',0); % set to first plot!


%-----
ca=gca;
automaticscale(handlesMain,LHO,GHO,STO); % based on data but ends up being a purely graphical method
h1 = findall(0,'Tag','axes_hand');
axes(h1);
axis on;
h2 = findall(0,'Tag','axes_global');
axes(h2);
axis on;
axes(gca);


decimation=str2double(get(handlesMain.decimation_edit,'String'));
udptype=get(UDP1,'UserData'); % get udp type
% OPEN UDP PORT
status=get(UDP1,'Status');
if strcmp(status,'closed');
     fopen(UDP1);
end
% Reset send count
udpSendCount = 0;
    
for ii=from:to % here's the epoch of interest
   data(:,:)=REC(ii,:,:); % here's where we take THIS sample in particular
   
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   TDTtime=data(1,2)-TDT_starttime; % here is where we see that first-row,second-column motif and the variable names featuring "TDT". More hints that these kinematic recordings come pre-synchronized with the TDT system. Probably just need to find the xWav samples in the TSQ file (as Andres mentioned) and align these sample times to those sample times.
   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   temp=toc;
   while temp<(TDTtime*(1/speed))
      temp=toc;
   end
   
   if (temp-TDTtime*(1/speed))<0.1
    
       % Old style copy objects, don't allow online updates
       %GHO2 = refreshGlobalHand(GHO2,data);
       %LHO2 = updateLocalHand(LHO2,GHO2);
       %GHO2 = updateGlobalHand(GHO2,LHO2);
       %GHO2 = updateGlobalArm(GHO2,LHO2); 
       %LHO2 = updateLocalArm(LHO2,GHO2);
       
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       % here we have those pesky global/local hand functions. all located
       % in the "supportingfunctions" folder.
       GHO = refreshGlobalHand(GHO,data);
       LHO = updateLocalHand(LHO,GHO);
       GHO = updateGlobalHand(GHO,LHO);
       GHO = updateGlobalArm(GHO,LHO); 
       LHO = updateLocalArm(LHO,GHO);
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

       if get(handlesMain.plot_enable_checkbox,'Value')
           if ~mod(ii,decimation)
               % Old style copy objects, don't allow online updates
               %plotHand(LHO2,GHO2,handlesMain);
               plotHand(LHO,GHO,handlesMain);
           end
       end

       drawnow;

       if get(handlesMain.udp_enable_checkbox,'Value')
           % Old style copy objects, don't allow online updates
           %sendHandUDP(UDP1,LHO2,GHO2,udptype);
           sendHandUDP(UDP1,LHO,GHO,udptype,data(1,1));
       end
   
   end
   
   if ~mod(ii,20)
       set(handles.time_edit,'String',num2str(data(1,2))); 
       if get(handles.stop_button,'Value')
           set(handles.stop_button,'Value',0);
           break;
       elseif get(handles.pause_button,'Value')
           waitfor(handles.pause_button,'Value',0)
           TDT_starttime=REC(ii,1,2);
           tic;
       end
   end
   
end
% toc;
% (secto-secfrom)*(1/speed)-toc
warning('on');

end

function [] = Load_Trial_Info_Callback(h,~,handles,varargin) 
global lastdir;
global TO;
global FL;
if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
[FileName,PathName,~] = uigetfile([lastdir '*_TO.mat'],'Select Recording...');
if PathName~=0; lastdir=PathName; end;

S=load([PathName FileName],'TO');

if isobject(S.TO) && strcmpi(class(S.TO),'trialobj')
    TO=S.TO;
    FL.trialloaded=1;
else
    FL.trialloaded=0;
end
    
refreshPlayerPlot(handles);
end

function [] = Load_State_Callback(~,~,handles,varargin)
global lastdir;
global ST;
global FL;
if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
[FileName,PathName,~] = uigetfile([lastdir '*_ST.mat'],'Select Recording...');
if PathName~=0; lastdir=PathName; end;

S=load([PathName FileName],'ST');
if isobject(S.ST) && strcmpi(class(S.ST),'epochobj')
    ST=S.ST;
    FL.stateloaded=1;
else
    FL.stateloaded=0;
end
    
refreshPlayerPlot(handles);
end

function [] = Load_dIO_Callback(~,~,handles,varargin)
global lastdir;
global DI;
global FL;

if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
[FileName,PathName,~] = uigetfile([lastdir '*_DI.mat'],'Select Recording...');
if PathName~=0; lastdir=PathName; end;

S=load([PathName FileName],'DI');
if isobject(S.DI) && strcmpi(class(S.DI),'epochobj')
    DI=S.DI;
    FL.diloaded=1;
else
    FL.diloaded=0;
end
    
refreshPlayerPlot(handles);
end

% Shortcut for single rame analysis
function [] = Start_Time_Callback(~,~,handles,varargin)

secfrom = get(handles.start_time_edit,'String');
set(handles.stop_time_edit, 'String', secfrom);
Play_Callback([],[],handles,varargin);

end


function [] = Set_Time_Callback(~,~,handles,varargin)
global TO;
griptype=TO.gripType;
condition=get(handles.condition_edit,'String');

if ~isempty(condition)
    
    hx = findall(0,'Tag','axes_object');
    axes(hx);
    if exist([condition '.bmp'])==2
        im = imread([condition '.bmp']);
        im2=im(297:854,375:1095,:);
    elseif exist([condition '.png'])==2
        im = imread([condition '.png']);
        im2=im(200:1000,1:900,:);
    end
       
    if ~isempty(im2)
        
        axis([0 500 0 400]);
        imagesc(im2);
        axis off;
        set(gca,'Tag','axes_object');
    end
end

condition=str2double(condition);

tc=TO.trialCorrect;
griptype(~(tc))=NaN;

id=find(griptype==condition,1,'first');
starttimes=TO.trialStart;
stoptimes =TO.trialStop;
tstart=starttimes(id);
tstop =stoptimes(id);

set(handles.start_time_edit,'String',num2str(tstart));
set(handles.stop_time_edit,'String',num2str(tstop));


end




