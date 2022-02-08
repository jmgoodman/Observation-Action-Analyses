function varargout = RecordSettings(varargin)
%m-function for the GUI KinemaTracks

%set globals
global STO;


if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Record Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Name','Record Settings');
        set(fig,'Visible','off');
        
    else
        
        %Figure exists ==> error
        troubles('Not allowed to start multiple windows.',' Window is already open.');
        %bring figure to front
        figure(h);
        return
        
    end;

    % Generate a structure of handles to pass to callbacks, and store it.
    handles = guihandles(fig);
    rec_filename=get(STO,'filenamerecording');
    
    folder_found=exist(rec_filename,'dir');
    
    if folder_found==7
        set(handles.filename_recordings_edit,'String',rec_filename);
    else
        set(handles.filename_recordings_edit,'String','');
    end
    
    set(fig,'Visible','on');

elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
    try
        [varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
    catch exception
        rethrow(exception); % output error   
    end

end
end %end of KinemaTracks


%########################### EXIT MENUE ###################################

function [] = Accept_Callback(~,~,handles,varargin)
global STO;
global FL;
rec_path=get(handles.filename_recordings_edit,'String');
if exist(rec_path)==7
    STO=set(STO,'filenamerecording',rec_path);
end
    
mainhandle=findall(0,'Name','KinemaTracks');
handles=guihandles(mainhandle);
refreshselectivity(FL,handles); % update GUI, enable new features available through ROM-settings

h = findall(0,'Name','Record Settings');
delete(h);

end

function [] = Cancel_Callback(h,~,handles,varargin) 
% delete the GUI and do not take over any settings
h = findall(0,'Name','Record Settings');
delete(h);
end

function [] = Browse_Record_Callback(h,~,handles,varargin) 
[pathname] = uigetdir(cd,'Select directory for record saving...');

if ischar(pathname)
set(handles.filename_recordings_edit,'String',pathname);
end
end



