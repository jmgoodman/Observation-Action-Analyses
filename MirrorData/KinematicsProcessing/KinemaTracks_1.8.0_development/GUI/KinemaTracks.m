function varargout = KinemaTracks(varargin)
%m-function for the GUI KinemaTracks
%Author: Stefan Schaffelhofer

%Do not use or share without authors permission

% SET GLOBALS
global SY;                                                                 
global LHO;                                                                
global GHO;                                                                
global STO;                                                                
global SO;
global CER;
global UDP1;
global FL;
global GST;
 
if nargin <= 2  % LAUNCH GUI
           
    
    %check if figure already exists
    h = findall(0,'tag','KinemaTracks');
    
    if (isempty(h))
        
        % DELETE OBJECTS:
        SY  =[];
        LHO =[];
        GHO =[];
        STO =[];
        SO  =[];
        CER =[];
        UDP1=[];
        FL  =[];
        GSTO = [];
     
        SY  = sysobj;
        SY  = set(SY,'ROMtype','virtual');
        SY  = set(SY,'transfermode','binary');
        SY  = set(SY,'volumeselected',1);
        STO = settingsobj;
        LHO = handobj; 
        GHO = handobj;
        UDP1 = udpobj('000.000.000.000', 'RemotePort',65535, 'LocalPort', 65535);
        set(UDP1,'UserData','All');
        CER  = serial('COM1', 'BaudRate', 115200,'DataBits', 8,'StopBits', 1); % some day, this may need to be changed to "serialport" rather than "serial", as newer versions of MATLAB recommend the former over the latter.
           
        % SET FLAGS
        FL.romset =0;
        FL.comfound=0;
        FL.sysinit=0;
        FL.toolsinit=0;
        FL.handloadedpart=0;
        FL.handloadedfull=0;
        FL.trackingon=0;
        FL.recordon=0;
        FL.udpok=0;
        FL.cerebusok=0;
        FL.wristinvert=0;
        
        % GUI settings
        GST.plot_enable=1;
        GST.udp_enable=0;
        GST.flatf1sens=0;
        GST.nopipinversion=0;
        
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'KinemaTracks');
        set(fig,'NumberTitle','off', 'Name','KinemaTracks');
        set(fig,'Visible','off');
        
        % Free all ports
        fclose(instrfindall());
        
        % Try to set serial port if project and COM port are given as
        % parameters
        if nargin == 2 && ischar(varargin{2})
            if ~strcmpi(varargin{2},'OFF')
                port_new_id = str2double(strtok(varargin{2}, 'COM'));
                InitComSettings('Init_Com_Settings', varargin{2}, port_new_id);
            end
        else
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            initcomhandle = InitComSettings(); % this brings up the first input you can give: whether to go offline or select a COM port for online recording & use
            % one can find the associated M-file in GUI/InitComSettings.m
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            waitfor(initcomhandle);
        end
        
        h1 = findall(0,'Tag','axes_hand');
        
        im = imread('KinemaTracks_LOGO.png');
        im=flipdim(im,1);
        axes(h1);
        imagesc(im);
        set(fig,'Visible','off');
        
        set(h1,'XLim',[0 size(im,2)],'YLim',[0 size(im,1)]);
        axis off;
        h2 = findall(0,'Tag','axes_global');
        axes(h2);
        imagesc(im);
        set(fig,'Visible','off');
        
        set(h2,'XLim',[0 size(im,2)],'YLim',[0 size(im,1)]);
        axis off;

        % Disable smoothing for faster graphics
        set(h,'GraphicsSmoothing','off');
        
        handles = guihandles(fig);
        updatehistory(handles.history_listbox,'Program started.');
        set(handles.decimation_edit,'String',5);
        if FL.comfound==0 
            updatehistory(handles.history_listbox,'Device not found on selected Port. Check if the device is connected or change the COM-Port.');
        end
        
        refreshselectivity(FL,handles);
        set(handles.record_button,'BackgroundColor','g');
        
        guidata(fig,handles)
        
        % Try to load project if project and COM port are given as
        % parameters
        if nargin >= 1 && ischar(varargin{1})
            Load_Project_Callback(h, 0, handles, varargin{1});
        end
         
    else
        figure(h);
        disp('Not allowed to start multiple KinemaTracks Windows. KinemaTracks already started.');        
        return
        
    end;
     
    set(fig,'Visible','on');
        
    
    h = findall(0,'Name','KinemaTracks');

elseif ischar(varargin{1}) 

    try
        [varargout{1:nargout}] = feval(varargin{:});
    catch exception
        rethrow(exception)
    end

end



end 


function varargout = Init_System_Callback(h, eventdata, handles, varargin)
global SY;
global SO;
global FL;

FL.sysinit=0;
FL.toolsinit=0;

status=get(SO,'Status');
if strcmp(status,'closed');
 fopen(SO);
end

SY=initsystem(SY,SO);  
updatehistory(handles.history_listbox,'Tracking-system initialized');
updatehistory(handles.history_listbox,['API: revision number: ' get(SY,'APIrevision')]);
status=get(SO,'Status');   
if strcmp(status,'open');
 fclose(SO);
end

FL.sysinit=1;
refreshselectivity(FL,handles);

guidata(h,handles);


end

function varargout = Init_Tools_Callback(h, eventdata, handles, varargin)
global FL;
global SY;
global SO;

if FL.sysinit 
    Init_System_Callback(h,eventdata,handles,varargin);
end

if FL.sysinit && FL.romset
    ROMtype=get(SY,'ROMtype');
    if ischar(ROMtype)
        switch ROMtype
            case 'virtual' 
                fopen(SO);
                SY=selectvolume(SY,SO);
                SY=inittools(SY,SO);
                fclose(SO);
                FL.toolsinit=1;
                updatehistory(handles.history_listbox,'Tools initialized.');
                refreshselectivity(FL,handles);
                
            case 'srom'
                fopen(SO);
                SY=inittools(SY,SO);
                SY=selectvolume(SY,SO);
                fclose(SO);
                FL.toolsinit=1;
                updatehistory(handles.history_listbox,'Tools initialized.');
                refreshselectivity(FL,handles);
            otherwise
                FL.toolsinit=0;
                refreshselectivity(FL,handles);
                updatehistory(handles.history_listbox,'ROM-type not known or empty.');
                error('ROM-type not known or empty.');
        end
    else
        updatehistory(handles.history_listbox,'ROM-type not known or empty.');
        error('ROM-type not known.');
    end              
else
    updatehistory(handles.history_listbox,'Initialization failed.');
    error('Initialization failed.');
end
end

function varargout = Calibrate_Callback(h, eventdata, handles, varargin)
global SY;
global SO;
global LHO;
global GHO;
global FL;
global STO;
global calibdata;
numsamples=50;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% this is where "calibdata" gets created. where it gets USED, however, is
% another story...
[LHO,GHO,SO,SY,sd,calibdata] = calibratehand2(LHO,GHO,SO,SY,numsamples);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
FL=checkforflag(LHO,FL);
handles=refreshselectivity(FL,handles);
guidata(h,handles);
plotHand(LHO,GHO,handles);
end


function varargout = Autoscale_Callback(h, eventdata, handles, varargin)
global LHO;
global GHO;
global STO;
h = findall(0,'tag','KinemaTracks');
handlesMain = guihandles(h); 

LHO2=struct(LHO);
GHO2=struct(GHO);
plotHand(LHO2,GHO2,handlesMain)


ScaleWrite(STO,LHO,GHO);
ScaleUpdate_Callback();

end

function varargout = ScaleWrite(STO,LHO,GHO)

h = findall(0,'tag','KinemaTracks');
handlesMain = guihandles(h); 

if isempty(STO.localhandaxes) || sum(isnan(STO.localhandaxes))>0
    STO=automaticscale(handlesMain,LHO,GHO,STO);
end
    
set(handlesMain.xmin_loc_edit,'String',num2str(round(STO.localhandaxes(1))));
set(handlesMain.xmax_loc_edit,'String',num2str(round(STO.localhandaxes(2))));
set(handlesMain.ymin_loc_edit,'String',num2str(round(STO.localhandaxes(3))));
set(handlesMain.ymax_loc_edit,'String',num2str(round(STO.localhandaxes(4))));
set(handlesMain.zmin_loc_edit,'String',num2str(round(STO.localhandaxes(5))));
set(handlesMain.zmax_loc_edit,'String',num2str(round(STO.localhandaxes(6))));    
    

if ~isempty(STO.globalhandaxes) && sum(isnan(STO.globalhandaxes))>0
    STO=automaticscale(handlesMain,LHO,GHO,STO);
end

set(handlesMain.xmin_glo_edit,'String',num2str(round(STO.globalhandaxes(1))));
set(handlesMain.xmax_glo_edit,'String',num2str(round(STO.globalhandaxes(2))));
set(handlesMain.ymin_glo_edit,'String',num2str(round(STO.globalhandaxes(3))));
set(handlesMain.ymax_glo_edit,'String',num2str(round(STO.globalhandaxes(4))));
set(handlesMain.zmin_glo_edit,'String',num2str(round(STO.globalhandaxes(5))));
set(handlesMain.zmax_glo_edit,'String',num2str(round(STO.globalhandaxes(6))));

end

function varargout = ScaleUpdate_Callback(varargin)

global STO;

h1 = findall(0,'Tag','axes_hand');
axes(h1);
axis on;
h2 = findall(0,'Tag','axes_global');
axes(h2);
axis on;


h = findall(0,'tag','KinemaTracks');
handlesMain = guihandles(h); 

STO.localhandaxes(1)=str2double(get(handlesMain.xmin_loc_edit,'String'));
STO.localhandaxes(2)=str2double(get(handlesMain.xmax_loc_edit,'String'));
STO.localhandaxes(3)=str2double(get(handlesMain.ymin_loc_edit,'String'));
STO.localhandaxes(4)=str2double(get(handlesMain.ymax_loc_edit,'String'));
STO.localhandaxes(5)=str2double(get(handlesMain.zmin_loc_edit,'String'));
STO.localhandaxes(6)=str2double(get(handlesMain.zmax_loc_edit,'String'));

STO.globalhandaxes(1)=str2double(get(handlesMain.xmin_glo_edit,'String'));
STO.globalhandaxes(2)=str2double(get(handlesMain.xmax_glo_edit,'String'));
STO.globalhandaxes(3)=str2double(get(handlesMain.ymin_glo_edit,'String'));
STO.globalhandaxes(4)=str2double(get(handlesMain.ymax_glo_edit,'String'));
STO.globalhandaxes(5)=str2double(get(handlesMain.zmin_glo_edit,'String'));
STO.globalhandaxes(6)=str2double(get(handlesMain.zmax_glo_edit,'String'));

h1 = findall(0,'Tag','axes_hand');
set(h1,'XLim',[STO.localhandaxes(1) STO.localhandaxes(2)]);
set(h1,'YLim',[STO.localhandaxes(3) STO.localhandaxes(4)]);
set(h1,'ZLim',[STO.localhandaxes(5) STO.localhandaxes(6)]);

h2 = findall(0,'Tag','axes_global');
set(h2,'XLim',[STO.globalhandaxes(1) STO.globalhandaxes(2)]);
set(h2,'YLim',[STO.globalhandaxes(3) STO.globalhandaxes(4)]);
set(h2,'ZLim',[STO.globalhandaxes(5) STO.globalhandaxes(6)]);

end




function varargout = Start_Callback(h, eventdata, handles, varargin)
global FL;
global GST;
global SY;
global SO;
global LHO;
global GHO;
global UDP1;
global CER;
global STO;
global calibdata;
global recording;
global udpSendCount;

h1 = findall(0,'Tag','axes_hand');
axes(h1);
axis on;
h2 = findall(0,'Tag','axes_global');
axes(h2);
axis on;

ScaleWrite(STO,LHO,GHO);
ScaleUpdate_Callback();

ti=clock;

if get(handles.start_toggle,'Value') % else ignore the callback
    try
        
    udptype=get(UDP1,'UserData'); % get udp type
    decimation=str2double(get(handles.decimation_edit,'String'));
    set(handles.start_toggle,'String','STOP TRACKING');
    
    status=get(SO,'Status');   
    if strcmp(status,'closed');
         fopen(SO);
    end
    
    
    cer_found=0;
    try
    status=get(CER,'Status');   
    if strcmp(status,'closed');
         fopen(CER);
         cer_found=1;
    end
    catch 
    end
    
    % OPEN UDP PORT
    status=get(UDP1,'Status'); 
    if strcmp(status,'closed');
        fopen(UDP1);
    end
    % Reset send count
    udpSendCount = 0;

    SY=tracking(SY,SO,'start');
    FL.trackingon=1;
    refreshselectivity(FL,handles);
    
    numTools=get(SY,'numtools');

    data=zeros(numTools+1,7); 
    
    % Prevents chrashing when a tool is not available
    %data=zeros(8,7);
    
    % GUI settings
    GST.plot_enable=get(handles.plot_enable_checkbox,'value');
    GST.udp_enable=get(handles.udp_enable_checkbox,'value');
    GST.flatf1sens=get(handles.flatf1sens_checkbox,'value');
    GST.nopipinversion=get(handles.nopipinversion_checkbox,'value');

    rec_path_temp=get(STO,'filenamerecording');
    if exist(rec_path_temp)==7
        rec_path=rec_path_temp;
    else
        no_path_selected=1;
        while no_path_selected 
            [rec_path] = uigetdir(cd,'Select recording folder...');
            if exist(rec_path)==7
                no_path_selected=0;
                STO=set(STO,'filenamerecording',rec_path);
            end
        end
    end
    recording=NaN(1000000,size(data,1),size(data,2)); 

    sendRequest(SY,SO); 
    package=receiveRequest(SY,SO);


    loopfinished=1;
    kk=1;clc
    rr=1;
    tic;
    t2=0;
    
    warning off;
    % Old style copy objects, don't allow online updates
    %LHO2=struct(LHO);
    %GHO2=struct(GHO);
    
    % Start the timer, toc is used to get the time of a data sample
    tic;
    
    % Old style copy objects
    %LHO2=determinewrist(LHO2);
    LHO=determinewrist(LHO);
    set(handles.axes_hand,'UserData',0);
    while 1 

        if get(handles.start_toggle,'value') && loopfinished
            kk=kk+1;
            loopfinished=0;
            sendRequest(SY,SO); 
            if numel(package)~=0 
                data=translate(data,SY,package); 
            else
                warning('Empty packeage');
            end
            data(1,:)=toc; 
            
            if get(handles.record_button,'Value')
                recording(rr,:,:)=data(:,:);
                if cer_found
                        fprintf(CER,'%s','!!!!');
                        fwrite(CER,rr,'uint32');
                end
                rr=rr+1;
            end
            
            % Old style copy objects, don't allow online updates
            %GHO2 = refreshGlobalHand(GHO2,data);
            %LHO2 = updateLocalHand(LHO2,GHO2);
            %GHO2 = updateGlobalHand(GHO2,LHO2);
            %GHO2 = updateGlobalArm(GHO2,LHO2); 
            %LHO2 = updateLocalArm(LHO2,GHO2);
            
            GHO = refreshGlobalHand(GHO,data);
            LHO = updateLocalHand(LHO,GHO);
            GHO = updateGlobalHand(GHO,LHO);
            GHO = updateGlobalArm(GHO,LHO); 
            LHO = updateLocalArm(LHO,GHO);
            
            if get(handles.plot_enable_checkbox,'Value')
                  if ~mod(kk,decimation)
                       % Old style copy objects, don't allow online updates
                       %plotHand(LHO2,GHO2,handles);  
                       plotHand(LHO,GHO,handles);
                  end
            end
            
            drawnow;
            
            if get(handles.udp_enable_checkbox,'Value')
                % Old style copy objects, don't allow online updates
                %sendHandUDP(UDP1,LHO2,GHO2,udptype);
                sendHandUDP(UDP1,LHO,GHO,udptype,data(1,1));
            end

            package=receiveRequest(SY,SO);
            loopfinished=1;
            guidata(h,handles);

            if ~mod(kk,100)
                t1=t2;
                t2=toc;
                set(handles.sample_rate_edit,'String',num2str((100)/(t2-t1)));
            end

        else
            set(handles.start_toggle,'String','START TRACKING');
            set(handles.record_button,'Value',0);
            recording(isnan(recording(:,1,1)),:,:)=[]; 
            
            if ~isempty(recording)
            save([rec_path '/' num2str(ti(1)) '_' num2str(ti(2)) '_' num2str(ti(3)) '_' ...
                  num2str(ti(4)) '_' num2str(ti(5)) '_' ],'LHO','GHO','SY','recording','calibdata');
            end
            
            set(handles.start_toggle,'String','START TRACKING');
            set(handles.record_button,'Value',0);
            set(handles.record_button,'BackgroundColor','g');
            disp(['Samples recorded: ' num2str(length(recording))]);
            clear recording;
            
            status=get(SO,'Status');
            SY=tracking(SY,SO,'stop');
            if strcmp(status,'open');
             fclose(SO);
            end
            
            FL.trackingon=0;
            
            status=get(CER,'Status');
            if strcmp(status,'open');
             fclose(CER);
            end 
            
            status=get(UDP1,'Status');  
            if strcmp(status,'open');
                fclose(UDP1);
            end
            
            refreshselectivity(FL,handles);
            break;
        end
    end
    warning on;



    catch exception 
       disp(exception);
       disp(exception.stack);
       set(handles.start_toggle,'String','START TRACKING');
       set(handles.record_button,'Value',0);
       set(handles.record_button,'BackgroundColor','g');
       set(handles.decimation_edit,'Enable','on');
       
       recording(isnan(recording(:,1,1)),:,:)=[];
       if ~isempty(recording)
       
       save([rec_path '/' num2str(ti(1)) '_' num2str(ti(2)) '_' num2str(ti(3)) '_' ...
              num2str(ti(4)) '_' num2str(ti(5)) '_' ],'LHO','GHO','SY','recording','calibdata');
       end

        
        SY=tracking(SY,SO,'stop');
        status=get(SO,'Status');
        if strcmp(status,'open');
         fclose(SO);
        end   
        status=get(CER,'Status');
        if strcmp(status,'open');
         fclose(CER);
        end  
        FL.trackingon=0;
        status=get(UDP1,'Status');   
        if strcmp(status,'open');
            fclose(UDP1);
        end
        refreshselectivity(FL,handles);
        rethrow(exception);
    end
end

guidata(h,handles);

end

function varargout = Stop_Callback(h, eventdata, handles, varargin)
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here is where we jump when we click to open the Player.
% note also the "Player" function, which is located in
% "supportingfunctions".
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = Player_Callback(h, eventdata, handles, varargin)
global STO;
global LHO;
global GHO;
ScaleWrite(STO,LHO,GHO);
ScaleUpdate_Callback(); % this function just seems to scale windows. It's purely graphical (as far as I can tell, anyway!)
Player();
end

function varargout = About_Callback(h, eventdata, handles, varargin)
About();
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% here is where selecting "extract features" takes you
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = Extract_Features_Callback(h, eventdata, handles, varargin)
ExtractFeatures(); % located in the GUI folder
end


function varargout = Plot_Enable_Callback(h, eventdata, handles, varargin)
global GST;
GST.plot_enable=get(handles.plot_enable_checkbox,'Value');
end

function varargout = UDP_Enable_Callback(h, eventdata, handles, varargin)
global GST;
GST.udp_enable = get(handles.udp_enable_checkbox,'value');
end

function varargout = Flat_F1_Sens_Callback(h, eventdata, handles, varargin)
global GST;
GST.flatf1sens = get(handles.flatf1sens_checkbox,'value');
end

function varargout = No_Pip_Inv_Callback(h, eventdata, handles, varargin)
global GST;
GST.nopipinversion = get(handles.nopipinversion_checkbox,'value');
end

function varargout = WristInvert_Enable_Callback(h, eventdata, handles, varargin)
global FL;
val = get(handles.wristinvert_checkbox,'value');
FL.wristinvert=val;

% reserved
end

function varargout = Cerebus_Enable_Callback(h, eventdata, handles, varargin)

end

function varargout = Record_Callback(h, eventdata, handles, varargin)
if get(handles.record_button,'Value')
    set(handles.record_button,'BackgroundColor','r');
else
    set(handles.record_button,'BackgroundColor','g');
end
end

function varargout = Save_Enable_Callback(h, eventdata, handles, varargin)

end

function varargout = Plot_Duration_Callback(h, eventdata, handles, varargin)

end

function varargout = Plot_Decimation_Callback(h, eventdata, handles, varargin)
newval=str2double(get(handles.decimation_edit,'String'));
if ~isnan(newval) && newval <=100 &&  newval>0
    set(handles.decimation_edit,'String',num2str(round(newval)));
else
    set(handles.decimation_edit,'String','');
end
end 

function varargout = Rotate_Local3D_Callback(h, eventdata, handles, varargin)
rotate3d(handles.axes_hand) ;
end % end of function

function varargout = Rotate_Global3D_Callback(h, eventdata, handles, varargin)
rotate3d(handles.axes_global) ;
end % end of function

%########################### FILE MENUE ###################################

function varargout = Save_Project_Callback(h, eventdata, handles, varargin)
global STO;
global SY;
global SO;
global LHO;
global GHO;
global UDP1;
global CER;
global GST;

%save the object
STO = saveProject(STO,SY,SO,LHO,GHO,UDP1,CER,GST,'SAVE');
guidata(h,handles);
end

function varargout = Save_Project_As_Callback(h, eventdata, handles, varargin)
global STO;
global SY;
global SO;
global LHO;
global GHO;
global UDP1;
global CER;
global GST;

%save the object
STO = saveProject(STO,SY,SO,LHO,GHO,UDP1,CER,GST,'SAVEAS');
guidata(h,handles);
end

function varargout = Save_Hand_Callback(h, eventdata, handles, varargin)
global LHO;
global GHO;
global STO;
saveHand(LHO,GHO,STO,'SAVE');
guidata(h,handles);
end

function varargout = Save_Hand_As_Callback(h, eventdata, handles, varargin)
global LHO;
global GHO;
global STO;
saveHand(LHO,GHO,STO,'SAVEAS');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function varargout = Load_Project_Callback(h, eventdata, handles, varargin) % Naturally enough, clicking "load project" brings us here.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global STO;
global SY;
global SO;
global LHO;
global GHO;
global UDP1;
global FL;
global CER;
global GST;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% lookie here the function "loadProject" is called. THIS one is in the
% "supportingfunctions" folder.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin == 4
    [status,STO_new,SY_new,SO_new,LHO_new,GHO_new,UDP1_new,CER_new,GST] = loadProject(varargin{1});
else
    [status,STO_new,SY_new,SO_new,LHO_new,GHO_new,UDP1_new,CER_new,GST] = loadProject();
end

if status==1 
    
    % if a new project is loaded, reset the GUI
    FL.romset=0;
    FL.comfound=0;
    FL.sysinit=0;
    FL.toolsinit=0;
    FL.handloadedpart=0;
    FL.handloadedfull=0;
    refreshselectivity(FL,handles); % refresh the GUI accordingly to the new loaded data
    
%     % COM PORT
%     port=get(SO_new,'Port'); % read out the com-port of the saved project
%     portnum=str2double(port(4:end));
% %     port=findTrackingPort(portnum); % check if this port is connected to the 
% %     if ~isempty(port) %initialize automatically on startup only if port was found
%         set(SO,'Port',get(SO_new,'Port'));
        FL.comfound=1;
% %     end
%     set(SO,'BaudRate',get(SO_new,'BaudRate'));
%     set(SO,'DataBits',get(SO_new,'DataBits'));
%     set(SO,'StopBits',get(SO_new,'StopBits'));
%     set(SO,'Parity',get(SO_new,'Parity'));
%     set(SO,'UserData',get(SO_new,'UserData'));
%     set(SO,'FlowControl',get(SO_new,'FlowControl'));

    % HAND
    FL=checkforflag(LHO_new,FL);  % check completeness of handobj "LHO" and set flags accordingly
    LHO=LHO_new;                  % overwrite old hand objects with the loaded data
    GHO=GHO_new;                     
    refreshselectivity(FL,handles); % refresh the GUI accordingly to the new loaded data
    
    % SYSTEM
    FL=checkforflag(SY_new,FL);
    SY=SY_new;
    
    
    % UDP
    UDP1=UDP1_new;
    
    % CEREBUS
    CER=CER_new;
    FL.cerebusok=1;
    % SETTINGS
    STO=STO_new;
    updatehistory(handles.history_listbox,'Project loaded.');
%     automaticscale(handles,LHO,GHO);
    refreshselectivity(FL,handles); % refresh the GUI accordingly to the new loaded data
   
    % Saved GUI options
    set(handles.plot_enable_checkbox,'Value',GST.plot_enable);
    set(handles.udp_enable_checkbox,'Value',GST.udp_enable);
    set(handles.flatf1sens_checkbox,'Value',GST.flatf1sens);
    set(handles.nopipinversion_checkbox,'Value',GST.nopipinversion);
    
else
    updatehistory(handles.history_listbox,'Project loading failed.');
end

end

function varargout = Load_Hand_Callback(h, eventdata, handles, varargin)
global LHO;
global GHO;
global FL;
global REC;
[status, LHO_new, GHO_new, REC_new]=loadHand();
if status==1
    LHO=LHO_new;
    GHO=GHO_new;
%     automaticscale(handles,LHO,GHO);
    FL=checkforflag(LHO,FL); % check loaded data for completeness
    refreshselectivity(FL,handles); % refresh the GUI
elseif status == 2
    LHO = LHO_new;
    GHO = GHO_new;
    REC = REC_new;
    %     automaticscale(handles,LHO,GHO);
    FL=checkforflag(LHO,FL); % check loaded data for completeness
    refreshselectivity(FL,handles); % refresh the GUI
end
end

%######################### SETTINGS MENUE #################################
function varargout = Record_Settings_Callback(h, eventdata, handles, varargin)
RecordSettings();
end
function varargout = Hand_Settings_Callback(h, eventdata, handles, varargin)
HandSettings();
end

function varargout = Tool_Settings_Callback(h, eventdata, handles, varargin)
RomSelect(); % get user selection for ROM-type and ROM-file
end

function varargout = Volume_Select_Callback(h, eventdata, handles, varargin)
VolumeSelect();
end

function varargout = Com_Settings_Callback(h, eventdata, handles, varargin)
ComSettings();
end

function varargout = UDP_Settings_Callback(h, eventdata, handles, varargin)
UDPSettings();

end

function varargout = Cerebus_Settings_Callback(h, eventdata, handles, varargin)
CerebusSettings();
end

function varargout = Plot_Settings_Callback(h, eventdata, handles, varargin)
PlotSettings();
end

%########################### HELP MENUE ###################################

function varargout = NDI_Userguide_Wave_Callback(h, eventdata, handles, varargin)
%show user Manual
open('Wave_User_Guide Rev1.pdf');
guidata(h,handles);
end

function varargout = NDI_Userguide_Aurora_Callback(h, eventdata, handles, varargin)
%show user Manual
open('Aurora_User_Guide_Rev4.pdf');
guidata(h,handles);
end

function varargout = NDI_6DArchitect_UserGuide_Callback(h, eventdata, handles, varargin)
%show user Manual
open('6D_Architect_User_Guide_Rev_1.pdf');
guidata(h,handles);
end

function varargout = NDI_API_Guide_Callback(h, eventdata, handles, varargin)
%show user Manual
open('Aurora_API_Guide_Rev2.pdf');
guidata(h,handles);
end
function varargout = NDI_Tooldesign_Guide_Callback(h, eventdata, handles, varargin)
%show user Manual
open('Aurora_Tool_Design_Guide.pdf');
guidata(h,handles);
end

%########################### EXIT MENUE ###################################

function varargout = Exit_Menue_Callback(h, eventdata, handles, varargin)
%exit the program, user dialog if the the gcutsettingsobject should be
%saved for furture startup
h = findall(0,'Name','KinemaTracks');

% save settings ??
delete(h);

end


