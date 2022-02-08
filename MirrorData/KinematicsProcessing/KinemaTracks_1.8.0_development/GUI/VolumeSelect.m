function varargout = VolumeSelect(varargin)
%m-function for the GUI KinemaTracks

%set globals
global SY;

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Volume Select');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Name','Volume Select');
        set(fig,'Visible','off');
        
    else
        
        %Figure exists ==> error
        disp('Not allowed to start multiple Windows.',' Window is already open.');
        %bring figure to front
        figure(h);
        return
        
    end;

    % Generate a structure of handles to pass to callbacks, and store it.
    handles = guihandles(fig);
    
    %check
    volumesavailable=get(SY,'volumesavailable');
    volumeselected=get(SY,'volumeselected');
    
    if isempty(volumeselected);
        set(handles.select_volume_popup,'Value',1);
    else
        set(handles.select_volume_popup,'Value',volumeselected); % if volumeselected is already there (because of load of project or previous settings) use this value
    end
    
    set(handles.select_volume_popup,'String',volumesavailable);
    set(fig,'Visible','on');

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch exception
        disp('The action you are trying to perform causes an error! Fix the problem descibed below and try again.',exception);
    end

end
end %end of KinemaTracks


%########################### EXIT MENUE ###################################

function varargout = Accept_Button_Callback(h,~,handles,varargin)
global SY;
volumeselected=get(handles.select_volume_popup,'Value');
SY=set(SY,'volumeselected',volumeselected); %save Value to system object
h = findall(0,'Name','Volume Select');
delete(h);
end

function varargout = Cancel_Button_Callback(h,~,handles,varargin)
h = findall(0,'Name','Volume Select');
delete(h);
end



