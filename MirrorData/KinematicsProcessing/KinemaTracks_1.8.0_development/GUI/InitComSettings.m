function h = InitComSettings(varargin)
%m-function for the GUI KinemaTracks

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Init COM Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'Init COM Settings');
        set(fig,'NumberTitle','off', 'Name','Init COM Settings');
        set(fig,'Visible','off');
        
        % Generate a structure of handles to pass to callbacks, and store it.
        handles = guihandles(fig);

        % COM PORT
        set(handles.com_port_popup,'String',{'COM1','COM2','COM3','COM4','COM5',...
                                             'COM6','COM7','COM8','COM9','COM10'});

        set(fig,'Visible','on');
        h=fig;
        
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

option=get(handles.com_port_popup,'String'); % new port from GUI editor
port_new_id=get(handles.com_port_popup,'Value');
port_new=option{port_new_id};
Init_Com_Settings(port_new, port_new_id)

end

function [] = Init_Com_Settings(port_new, port_new_id)

global SO;
global FL;
global SY;

try
set(SO,'Port',port_new); % set serial object to new port
SO  = serial(port_new, 'BaudRate', 9600,'InputBufferSize', 1024,'OutputBufferSize', 1024, 'Terminator',13);  %serial object
% check if tracking system is connected
port=findTrackingPort(port_new_id); 

if ~isempty(port)  % A device was found on selected port:
    
    status=get(SO,'Status');
    
    if strcmp(status,'closed'); % open port
        fopen(SO);
    end   
    
    fprintf(SO,'VER 4'); % get information about device
    systemreturn = fscanf(SO);
    
    status=get(SO,'Status'); % close port
    if strcmp(status,'open');
        fclose(SO);
    end 
    
    errorcheck(systemreturn);
    split = textscan(systemreturn(2:end-5), '%s', 'EndOfLine', sprintf('\n'));
    split = split{1};
    if strcmp(split{14}(1:7),'007.014')
        SY=set(SY,'device','Wave');
        set(SO,'BaudRate',921600);
        FL.comfound=1;
    else
        SY=set(SY,'device','Aurora');
        set(SO,'BaudRate',115200);
        FL.comfound=1;
    end
else  % no device was found on selected board
    FL.comfound=0;
end

h = findall(0,'Tag','Init COM Settings');
delete(h);

catch exception
    status=get(SO,'Status');
    if strcmp(status,'open');
        fclose(SO);
    end 
    h = findall(0,'Tag','Init COM Settings');
    delete(h);
    rethrow(exception); 
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Cancel_Button_Callback(h,~,handles,varargin) % this is where the script goes when you press "offline". I know, it's weird that it's called "cancel", but it's where the "offline" button takes you, promise.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% delete the GUI and do not take over any settings
h = findall(0,'Name','Init COM Settings');
FL.comfound=0;
SO  = serial('COM1', 'BaudRate', 115200,'InputBufferSize', 1024,'OutputBufferSize', 1024, 'Terminator',13);  %serial object
delete(h);

end

function [] = Com_Port_Callback(~,~,handles,varargin)
global SO;
global FL;
value=get(SO,'Port'); 
option=get(handles.com_port_popup,'String');
option=option{get(handles.com_port_popup,'Value')};
end
