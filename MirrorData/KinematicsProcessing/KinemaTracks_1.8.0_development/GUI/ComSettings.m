function varargout = ComSettings(varargin)
%m-function for the GUI KinemaTracks

%set globals
global SY;
global SO;
global FL;

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','COM Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'COM Settings');
        set(fig,'NumberTitle','off', 'Name','COM Settings');
        set(fig,'Visible','off');
     
        % Generate a structure of handles to pass to callbacks, and store it.
        handles = guihandles(fig);

         % binary or text mode is saved in UserData (BX, TX)
        device=get(SY,'device');

        % COM PORT
        set(handles.com_port_popup,'String',{'COM1','COM2','COM3','COM4','COM5',...
                                             'COM6','COM7','COM8','COM9','COM10'});
        comport=get(SO,'Port'); % get com-port (if already selected);
        if FL.comfound
            value=getvalue(handles.com_port_popup,comport);
            set(handles.com_port_popup,'Value',value); % use com port 1
            set(handles.com_port_popup,'BackgroundColor',[0 1 0]);

        else
            value=getvalue(handles.com_port_popup,comport);
            set(handles.com_port_popup,'Value',value); % use com port 1
            set(handles.com_port_popup,'BackgroundColor',[1 0 0]);
        end

        % BAUD RATE
        switch device
            case 'Wave'
            set(handles.baude_rate_popup,'String',{'9600','14400','19200',...
            '38400','57600','115200','921600','1228739'});
            case 'Aurora'
            set(handles.baude_rate_popup,'String',{'9600','14400','19200',...
            '38400','57600','115200'}); 
            otherwise 
            set(handles.baude_rate_popup,'String',{'9600','14400','19200',...
            '38400','57600','115200','921600','1228739'}); 
        end
        baudrate=num2str(get(SO,'BaudRate'));
        if isempty(baudrate)   
            set(handles.baude_rate_popup,'Value',1); % use com port 1
        else
            value=getvalue(handles.baude_rate_popup,baudrate);
            set(handles.baude_rate_popup,'Value',value); % use com port 1
        end


        % TRANSMISSION TYPE
        transmission=get(SY,'transfermode');
        set(SO,'UserData',transmission);

        switch device
            case 'Wave' 
                set(handles.transmission_popup,'String',{'binary'}); %Wave only supports BX
                set(handles.transmission_popup,'Value',1);
            case 'Aurora'
                if isempty(transmission)
                    set(handles.transmission_popup,'String',{'binary','text'}); %Aurora supports binary as well as text transmission
                    set(handles.transmission_popup,'Value',1);  
                else
                    set(handles.transmission_popup,'String',{'binary','text'}); %Aurora supports binary as well as text transmission
                    value=getvalue(handles.transmission_popup,transmission);
                    set(handles.transmission_popup,'Value',value); % use com port 1 
                end
            otherwise 
                set(handles.transmission_popup,'String',{'binary'}); %Wave only supports BX
                set(handles.transmission_popup,'Value',1);
        end

        % PARITY BITS
        set(handles.parity_bit_popup,'String',{'none','odd','even'});
        paritybit=get(SO,'Parity'); 

        if strcmp(paritybit,'mark') || strcmp(paritybit,'space') || isempty(paritybit) %check for not supported parity modes
            SY=set(SY,Parity,'none'); %set to none if a not-supported mode is enabled
            set(handles.parity_bit_popup,'Value',1);
        end

        value=getvalue(handles.parity_bit_popup,paritybit);
        set(handles.parity_bit_popup,'Value',value); % use com port 1

        % DATA BITS

        databits=num2str(get(SO,'DataBits'));

        string=get(handles.transmission_popup,'String');
        string=string{get(handles.transmission_popup,'Value')};

        switch string
            case 'binary'
            set(handles.data_bits_popup,'String',{'8'}); %only binary available for Wave
            set(handles.data_bits_popup,'Value',1); 
            case 'text'
            set(handles.data_bits_popup,'String',{'8','7'});
            value=getvalue(handles.data_bits_popup,databits);
            set(handles.data_bits_popup,'Value',value); % use com port 1 
            otherwise
            set(handles.data_bits_popup,'Value',1);
        end

        % STOP BITS    
        stopbits=num2str(get(SO,'StopBits'));
        set(handles.stop_bits_popup,'String',{'1','2'});
        if ~(strcmp(stopbits,'1')  ||  strcmp(stopbits,'2') ) % check if stop bit is neither 1 or 2
            set(handles.data_bits_popup,'Value',1); % if so, set default value 
        else
            value=getvalue(handles.stop_bits_popup,stopbits);
            set(handles.stop_bits_popup,'Value',value); % use com port 1 
        end

        % HANDSHAKE
        handshake=get(SO,'FlowControl');
        set(handles.handshake_popup,'String',{'none','hardware'});
        if ~(strcmp(handshake,'none')  ||  strcmp(stopbits,'hardware') ) % check if stop bit is neither 1 or 2
            set(handles.handshake_popup,'Value',1); % if so, set default value 
        else
            value=getvalue(handles.handshake_popup,handshake);
            set(handles.stop_bits_popup,'Value',value); % use com port 1 
        end

        set(fig,'Visible','on');
        
        
    else % when the figure has already been opend, bring it to front.
        
        %Figure exists ==> error
        disp('Not allowed to start multiple Windows. Window is already open.');
        %bring figure to front
        figure(h);
        return
        
    end;

    

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch exception
        rethrow(exception);
    end

end
end %end of KinemaTracks


%########################### EXIT MENUE ###################################

function [] = Accept_Button_Callback(~,~,handles,varargin)
global SO;
global FL;
global SY;

port_old=get(SO,'Port'); % old port from serial object
option=get(handles.com_port_popup,'String'); % new port from GUI editor
port_new_id=get(handles.com_port_popup,'Value');
port_new=option{port_new_id};
set(SO,'Port',port_new); % set serial object to new port

baudrate_old=get(SO,'BaudRate');
option=get(handles.baude_rate_popup,'String');
baudrate_new=str2double(option{get(handles.baude_rate_popup,'Value')});
set(SO,'BaudRate',baudrate_new);

parity_old=get(SO,'Parity');
option=get(handles.parity_bit_popup,'String');
parity_new=option{get(handles.parity_bit_popup,'Value')};
set(SO,'Parity',parity_new);

databits_old=get(SO,'DataBits');
option=get(handles.data_bits_popup,'String');
databits_new=str2double(option{get(handles.data_bits_popup,'Value')});
set(SO,'DataBits',databits_new);

stopbits_old=get(SO,'StopBits');
option=get(handles.stop_bits_popup,'String');
stopbits_new=str2double(option{get(handles.stop_bits_popup,'Value')});
set(SO,'StopBits',stopbits_new);

flowcontr_old=get(SO,'FlowControl');
option=get(handles.handshake_popup,'String');
flowcontr_new=option{get(handles.handshake_popup,'Value')};
set(SO,'FlowControl',flowcontr_new);

userdat_old=get(SO,'UserData');
option=get(handles.transmission_popup,'String');
userdat_new=option{get(handles.transmission_popup,'Value')};
set(SO,'UserData',userdat_new);
SY=set(SY,'transfermode',userdat_new);

% % check if tracking system is connected
% port=findTrackingPort(port_new_id); 
if ~isempty(port_new)                                                          % initialize automatically on startup only if port was found
    SO  = serial(port_new, 'BaudRate', baudrate_new,'InputBufferSize', 1024,'OutputBufferSize', 1024, 'Terminator',13);  %serial object    
    FL.comfound=1;
else
    FL.comfound=0;
end

% if serial parameter changed, the system has to be initialized again
if ~(strcmp(port_old,port_new) && baudrate_old==baudrate_new && ... % check if parameters have changed
     strcmp(parity_old,parity_new) && databits_old==databits_new &&...
     stopbits_old==stopbits_new && strcmp(flowcontr_old,flowcontr_new) && ...
     strcmp(userdat_old,userdat_new)) && FL.comfound

     FL.sysinit=0;
     FL.toosinit=0;

     status=get(SO,'Status');
     if strcmp(status,'closed');
       fopen(SO);
     end

     SY=initsystem(SY,SO);  

     status=get(SO,'Status');   
     if strcmp(status,'open');
       fclose(SO);
     end

     FL.sysinit=1;
     FL.toolsinit=0;

end

mainhandle=findall(0,'Name','KinemaTracks');
handles=guihandles(mainhandle);
refreshselectivity(FL,handles);

h = findall(0,'Tag','COM Settings');
delete(h);

end

function [] = Cancel_Button_Callback(h,~,handles,varargin) 
% delete the GUI and do not take over any settings
h = findall(0,'Name','COM Settings');
delete(h);
end

function [] = Com_Port_Callback(~,~,handles,varargin)
global SO;
global FL;
value=get(SO,'Port'); 
option=get(handles.com_port_popup,'String');
option=option{get(handles.com_port_popup,'Value')};
if strcmp(value,option) && FL.comfound % if the selected COM-port is the selected one, and if this selected port has been checked to be connect to the tracking system, dispaly green background.
    set(handles.com_port_popup,'BackgroundColor',[0 1 0]);
else
    set(handles.com_port_popup,'BackgroundColor',[1 1 1]);
    
end
end

function [] = Baude_Rate_Callback(~,~,handles,varargin)
%reserved
end

function [] = Parity_Bit_Callback(~,~,handles,varargin)
%reserved
end

function [] = Data_Bits_Callback(~,~,handles,varargin)
%reserved
end

function [] = Stop_Bits_Callback(~,~,handles,varargin)
%reserved
end

function [] = Handshake_Callback(~,~,handles,varargin)
%reserved
end

function [] = Transmission_Callback(~,~,handles,varargin)
end


