function varargout = CerebusSettings(varargin)
%m-function for the GUI KinemaTracks

%set globals
global CER;

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Cerebus Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'Cerebus Settings');
        set(fig,'NumberTitle','off', 'Name','Cerebus Settings');
        set(fig,'Visible','off');
        
        % Generate a structure of handles to pass to callbacks, and store it.
        handles = guihandles(fig);
        
        COMport =get(CER,'Port');
        if strcmp(COMport,'COM100')
            COMport='';
        end
        BaudRate =get(CER,'Baudrate');
        StopBits =get(CER,'StopBits');
        DataBits =get(CER,'DataBits');
        
        set(handles.com_port_edit,'String',COMport);
        set(handles.stop_bits_edit,'String',DataBits);
        set(handles.data_bits_edit,'String',StopBits);
        set(handles.baude_rate_edit,'String',BaudRate);
        
        
        % Generate a structure of handles to pass to callbacks, and store it.
        guihandles(fig);

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
global CER;
global FL;

check=0;
COMport=get(handles.com_port_edit,'String');
comfound=findstr(COMport,'COM');
if ~isempty(comfound) && length(COMport)>=4 && ~isnan(str2double(COMport(4:end)))
    check=1;
end

if check    
    set(CER,'Port',COMport);
    FL.cerebusok=1;
    mainhandle=findall(0,'Name','KinemaTracks');
    handles=guihandles(mainhandle);
    refreshselectivity(FL,handles);
    h = findall(0,'Tag','Cerebus Settings'); % delete GUI and it's handles
    delete(h);
else
    %error
end


end

function [] = Cancel_Button_Callback(h,~,handles,varargin) 
% delete the GUI and do not take over any settings
h = findall(0,'Name','Cerebus Settings');
delete(h);
end



