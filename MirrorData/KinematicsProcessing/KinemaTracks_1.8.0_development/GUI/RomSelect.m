function varargout = RomSelect(varargin)
%m-function for the GUI KinemaTracks

%set globals
global SY;


if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','ROM Select');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Name','ROM Select');
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
    
    ROMtype=get(SY,'ROMtype');
    ROMfile=get(SY,'ROMfile');
    
    if ~isempty(ROMtype) % if ROM is already available, set the GUI to this value
        if strcmp(ROMtype,'virtual')
            set(handles.virtual_enable_checkbox,'Value',1);
            set(handles.srom_enable_checkbox,'Value',0);
            set(handles.filename_port1_edit,'Enable','on');
            set(handles.filename_port2_edit,'Enable','on');
            set(handles.filename_port3_edit,'Enable','on');
            set(handles.filename_port4_edit,'Enable','on');
            if ~isempty(ROMfile) % if files were already saved
                ROMfile=get(SY,'ROMfile');
                numfiles=numel(ROMfile);
                for ii=1:numfiles
                    eval(sprintf('set(handles.filename_port%u_edit,''String'',ROMfile{%u})',ii,ii));
                end
            end
            
            
        end
        
        if strcmp(ROMtype,'srom')
            set(handles.virtual_enable_checkbox,'Value',0);
            set(handles.srom_enable_checkbox,'Value',1);
            set(handles.filename_port1_edit,'Enable','off');
            set(handles.filename_port2_edit,'Enable','off');
            set(handles.filename_port3_edit,'Enable','off');
            set(handles.filename_port4_edit,'Enable','off');

        end
        
    else % set default values if nothing has been set before
            set(handles.virtual_enable_checkbox,'Value',1);
            set(handles.srom_enable_checkbox,'Value',0);
            set(handles.filename_port1_edit,'Enable','on');
            set(handles.filename_port2_edit,'Enable','on');
            set(handles.filename_port3_edit,'Enable','on');
            set(handles.filename_port4_edit,'Enable','on');

    end
    
    if ~isempty(ROMfile) % if ROM is already available, set the GUI to this value
    else
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
global SY;
global FL;
value=get(handles.virtual_enable_checkbox,'Value');

switch value
    case 0
        ROMtype='srom';
        SY=set(SY,'ROMtype',ROMtype);
        ROMfile={4};
        SY=set(SY,'ROMfile',ROMfile);
        FL.romset=1;
    case 1 
        ROMtype='virtual';
        SY=set(SY,'ROMtype',ROMtype);
        ROMfile=get(SY,'ROMfile');
        ROMfile{1}=get(handles.filename_port1_edit,'String');
        ROMfile{2}=get(handles.filename_port2_edit,'String');
        ROMfile{3}=get(handles.filename_port3_edit,'String');
        ROMfile{4}=get(handles.filename_port4_edit,'String');
        
        if (isempty(ROMfile{1}) && isempty(ROMfile{2}) && isempty(ROMfile{3}) && isempty(ROMfile{4}))
            error('No ROM-file selected.');
        else %if ROM files are selected, save them to the system object
            SY=set(SY,'ROMfile',ROMfile);
        end
        FL.romset=1;
end
mainhandle=findall(0,'Name','KinemaTracks');
handles=guihandles(mainhandle);
refreshselectivity(FL,handles); % update GUI, enable new features available through ROM-settings

h = findall(0,'Name','ROM Select');
delete(h);

end

function [] = Cancel_Callback(h,~,handles,varargin) 
% delete the GUI and do not take over any settings
h = findall(0,'Name','ROM Select');
delete(h);
end

function [] = Browse_Port1_Callback(h,~,handles,varargin) 
[FileName,PathName,FilterIndex] = uigetfile('*.rom','Select ROM file...');
if FilterIndex==1
set(handles.filename_port1_edit,'String',[PathName FileName ]);
end
end

function [] = Browse_Port2_Callback(h,~,handles,varargin) 
[FileName,PathName,FilterIndex] = uigetfile('*.rom','Select ROM file...');
if FilterIndex==1
    set(handles.filename_port2_edit,'String',[PathName FileName ]);
end
end

function [] = Browse_Port3_Callback(h,~,handles,varargin) 
[FileName,PathName,FilterIndex] = uigetfile('*.rom','Select ROM file...');
if FilterIndex==1
    set(handles.filename_port3_edit,'String',[PathName FileName ]);
end
end

function [] = Browse_Port4_Callback(h,~,handles,varargin) 
[FileName,PathName,FilterIndex] = uigetfile('*.rom','Select ROM file...');
if FilterIndex==1
    set(handles.filename_port4_edit,'String',[PathName FileName ]);
end
end

function [] = Virtual_Enable_Callback(h,~,handles,varargin) 
value=get(handles.virtual_enable_checkbox,'Value');
switch value
    case 0
    set(handles.virtual_enable_checkbox,'Value',0);
    set(handles.srom_enable_checkbox,'Value',1);
    set(handles.filename_port1_edit,'Enable','off');
    set(handles.filename_port2_edit,'Enable','off');
    set(handles.filename_port3_edit,'Enable','off');
    set(handles.filename_port4_edit,'Enable','off'); 
    set(handles.browse_port1_button,'Enable','off');
    set(handles.browse_port2_button,'Enable','off');
    set(handles.browse_port3_button,'Enable','off');
    set(handles.browse_port4_button,'Enable','off');
    case 1
    set(handles.virtual_enable_checkbox,'Value',1);
    set(handles.srom_enable_checkbox,'Value',0);
    set(handles.filename_port1_edit,'Enable','on');
    set(handles.filename_port2_edit,'Enable','on');
    set(handles.filename_port3_edit,'Enable','on');
    set(handles.filename_port4_edit,'Enable','on');
    set(handles.browse_port1_button,'Enable','on');
    set(handles.browse_port2_button,'Enable','on');
    set(handles.browse_port3_button,'Enable','on');
    set(handles.browse_port4_button,'Enable','on');
 
end
    
end

function [] = SROM_Enable_Callback(h,~,handles,varargin) 
value=get(handles.srom_enable_checkbox,'Value');
switch value
    case 0
    set(handles.srom_enable_checkbox,'Value',0);
    set(handles.virtual_enable_checkbox,'Value',1);
    set(handles.filename_port1_edit,'Enable','on');
    set(handles.filename_port2_edit,'Enable','on');
    set(handles.filename_port3_edit,'Enable','on');
    set(handles.filename_port4_edit,'Enable','on');
    set(handles.browse_port1_button,'Enable','on');
    set(handles.browse_port2_button,'Enable','on');
    set(handles.browse_port3_button,'Enable','on');
    set(handles.browse_port4_button,'Enable','on');
    case 1
    set(handles.srom_enable_checkbox,'Value',1);
    set(handles.virtual_enable_checkbox,'Value',0);
    set(handles.filename_port1_edit,'Enable','off');
    set(handles.filename_port2_edit,'Enable','off');
    set(handles.filename_port3_edit,'Enable','off');
    set(handles.filename_port4_edit,'Enable','off'); 
    set(handles.browse_port1_button,'Enable','off');
    set(handles.browse_port2_button,'Enable','off');
    set(handles.browse_port3_button,'Enable','off');
    set(handles.browse_port4_button,'Enable','off');
 
end
end