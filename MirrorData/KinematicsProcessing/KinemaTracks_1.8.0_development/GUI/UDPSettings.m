function varargout = UDPSettings(varargin)
%m-function for the GUI KinemaTracks

global UDP1;

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','UDP Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Name','UDP Settings');
        set(fig,'Visible','off');
        
    else
        
        %Figure exists ==> error
        troubles('Not allowed to start multiple Windows.',' Window is already open.');
        %bring figure to front
        figure(h);
        return
        
    end;
    
    % Generate a structure of handles to pass to callbacks, and store it.
    handles = guihandles(fig);
    
    
    % UPDATE GUI WITH UDP PARAMETERS
    mode=get(UDP1,'UserData');
    if isempty(mode)
        mode='';
    end
    % Transmission mode
    switch mode
        case 'Robot'
            value=getvalue(handles.transmission_mode_popup,'Robot');
            set(handles.transmission_mode_popup,'Value',value);
        case 'Local'
            value=getvalue(handles.transmission_mode_popup,'Local');
            set(handles.transmission_mode_popup,'Value',value);
        case 'Global'
            value=getvalue(handles.transmission_mode_popup,'Global');
            set(handles.transmission_mode_popup,'Value',value);
        otherwise % default value
            set(handles.transmission_mode_popup,'Value',1);
    end
    
    % get IP adress from UDP object
    ipadr=get(UDP1,'RemoteHost'); % IP address of receiver
    if strcmp(ipadr,'000.000.000.000'); % do not show the faked ip-adr that is necessary for UDP-object creation on startup
        ipadr='';
    end
    set(handles.ip_edit,'String',ipadr);
    
    % get remote-port from UDP object
    remoteport=get(UDP1,'RemotePort');
    if isnumeric(remoteport) % do not show the faked ip-adr that is necessary for UDP-object creation on startup
        if remoteport==65535 || isempty(remoteport)
            remoteport='';
        end
    end
    set(handles.remote_port_edit,'String',remoteport);
    
    
    % get local-pot from UDP object
    localport=get(UDP1,'LocalPort');
    if isnumeric(localport) % do not show the faked ip-adr that is necessary for UDP-object creation on startup
        if localport==65535 || isempty(localport)
            localport='';
        end
    end
    set(handles.local_port_edit,'String',localport);
    
    set(fig,'Visible','on');
    
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    %try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    %catch ex
    %    disp(['The action you are trying to perform causes an error! Fix the problem descibed below and try again.' ex]);
    %end

end
end %end of KinemaTracks


%########################### EXIT MENUE ###################################

function varargout = Accept_Button_Callback(h,~,handles,varargin)
%Code moved to function
%                                                 Andrej Filippow
    ipadr=get(handles.ip_edit,'String');
    remoteport=get(handles.remote_port_edit,'String');
    localport =get(handles.local_port_edit,'String');
    modeid    =get(handles.transmission_mode_popup,'Value');
    modes     =get(handles.transmission_mode_popup,'String');  %%TODO figure out what this does  
    varargout = checkUDP(ipadr, str2double(remoteport), str2double(localport), modes{modeid});
end

function varargout = Cancel_Button_Callback(h,~,handles,varargin)
h = findall(0,'Name','UDP Settings');
delete(h);
end



