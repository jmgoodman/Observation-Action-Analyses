function varargout = ExtractFeatures(varargin)
%m-function for the GUI KinemaTracks

%set globals
global SY;
global SO;
global FL;
global lastdir;
global extractoption;

if nargin == 0  % LAUNCH GUI
    
    %check if figure already exists
    h = findall(0,'tag','Extract Feature Settings');
    
    if (isempty(h))
        %Launch the figure
        fig = openfig(mfilename,'reuse');
        set(fig,'NumberTitle','off', 'Tag' ,'Extract Feature Settings');
        set(fig,'NumberTitle','off', 'Name','Extract Feature Settings');
        set(fig,'Visible','off');
        
        if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
        
        % Generate a structure of handles to pass to callbacks, and store it.
        handles = guihandles(fig);
        set(handles.directory_edit,'String',lastdir);
        
        if ~(isfield(extractoption,'timeselect')) % if field does not exist
           extractoption.timeselect=true; % default value; 
        end
        
        if extractoption.timeselect
            set(handles.timeselect_checkbox,'Value',1);
            set(handles.timeselect_checkbox,'String','Extract all samples');
            set(handles.tfrom_edit,'Visible','off');
            set(handles.tto_edit,'Visible','off');
            set(handles.from_text,'Visible','off');
            set(handles.to_text,'Visible','off');
        else
            set(handles.timeselect_checkbox,'Value',0);
            set(handles.timeselect_checkbox,'String','Extract samples ');
            set(handles.tfrom_edit,'Visible','on');
            set(handles.tto_edit,'Visible','on');
            set(handles.from_text,'Visible','on');
            set(handles.to_text,'Visible','on');
        end
        
        if ~(isfield(extractoption,'sr'))
           extractoption.sr=20; % default value; 
        end
        set(handles.sr_edit,'String',num2str(extractoption.sr));   
        
        if ~(isfield(extractoption,'gap'))
           extractoption.gap=0.2; % default value; 
        end
        set(handles.gap_edit,'String',num2str(extractoption.gap));
       
        if ~(isfield(extractoption,'elimerrors'))
           extractoption.elimerrors=true; % default value; 
        end
        set(handles.elimerrors_checkbox,'Value',extractoption.elimerrors);
        
        if ~(isfield(extractoption,'elimgaps'))
           extractoption.elimgaps=true; % default value; 
        end
        set(handles.elimgaps_checkbox,'Value',extractoption.elimgaps); 
        
        if ~(isfield(extractoption,'angles'))
           extractoption.angles=true; % default value; 
        end
        set(handles.angles_checkbox,'Value',extractoption.angles);
        
        if ~(isfield(extractoption,'interpolate'))
           extractoption.interpolate=true; % default value; 
        end
        set(handles.interpolate_checkbox,'Value',extractoption.interpolate);
        
        if extractoption.interpolate
            set(handles.sr_edit,'Enable','on');
        else
            set(handles.sr_edit,'Enable','off');
        end
        
        if ~(isfield(extractoption,'export'))
           extractoption.export=true; % default value; 
        end
        set(handles.export_checkbox,'Value',extractoption.export); 
        
        
        
        
        
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Here is where pressing "Run" brings you (unsurprisingly)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [] = Run_Button_Callback(~,~,handles,varargin)
global extractoption;
global REC;
h = findall(0,'tag','Extract Feature Settings');
sb=statusbar(h,'Processing'); % create statusbar
extractoption.statusbar=sb;
extractoption.gui=h;

% PATH
savedir=get(handles.directory_edit,'String');
if isdir(savedir)
    extractoption.directory=savedir;
else
    error('Directory not found!');
end


extractoption.subject=get(handles.subject_edit,'String');
extractoption.session=get(handles.session_edit,'String');

extractoption.trialplot=get(handles.trialplot_checkbox,'Value');


% TIME
if isempty(REC)
   error('Load Recording before running the Batch!');
end
if get(handles.timeselect_checkbox,'Value') % check for times:
    extractoption.tfrom=NaN;
    extractoption.tto=NaN;
    extractoption.timeselect=0;
else
    extractoption.timeselect=1;
    extractoption.tfrom=str2double(get(handles.tfrom_edit,'String'));
    extractoption.tto  =str2double(get(handles.tto_edit,'String'));
    
    if extractoption.tfrom>=extractoption.tto
        error('Start time must be smaller then stop time!');
    end
    
    if extractoption.tfrom<0
        error('Start time can not be negative.');
    end
    
    if extractoption.tto>REC(end,1,2)
        warning('Recording time is shorter then the selected time.');
    end
end

if get(handles.timeselect_checkbox,'Value')
    sr=str2double(get(handles.sr_edit,'Value'));
    gap=str2double(get(handles.gap_edit,'Value'));
    if sr<0
        error('Sampling rate can not be negative.');
    end
    if gap<0
        error('Gap sie can not be nagative.');
    end
else
    extractoption.sr=NaN;
    extractoption.gap=NaN;
end

% ELIMINATE WAVE ERRORS
extractoption.elimerrors=get(handles.elimerrors_checkbox,'Value');
% DO NOT USE TRIAL INFO
extractoption.notrialinfo=get(handles.notrialinfo_checkbox,'Value');
% ELIMINATE TIME GAPS
extractoption.elimgaps=get(handles.elimgaps_checkbox,'Value');
% ANGLES
extractoption.angles=get(handles.angles_checkbox,'Value');
% INTERPOLATE
extractoption.interpolate=get(handles.interpolate_checkbox,'Value');
if extractoption.interpolate
    extractoption.sr=str2double(get(handles.sr_edit,'String'));
    extractoption.gap=str2double(get(handles.gap_edit,'String'));
else
    extractoption.sr=NaN;
    extractoption.gap=NaN;
end


%EXPORT
% if extractoption.interpolate && isnumeric(extractoption.sr) && isnumeric(extractoption.gap)
     extractoption.export=get(handles.export_checkbox,'Value');
% else
%     error('Export requires interpolation.');
% end
app_val=get(handles.appendix_edit,'Value');
app_str=get(handles.appendix_edit,'String');
extractoption.appendix=app_str{app_val};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% and here we find it. Batch_extractfeatures. It looks like the GUI exists
% solely to be a wrapper for this, the holy grail.
% Although it has "Batch" in its name, it's actually located in the
% supportingfunctions folder. Weird.
Batch_extractfeatures;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

h = findall(0,'Tag','Extract Feature Settings');

% delete(h);

end

function [] = Cancel_Button_Callback(h,~,handles,varargin) 
% delete the GUI and do not take over any settings
h = findall(0,'Name','Extract Feature Settings');
delete(h);
end

function [] = Browse_Callback(~,~,handles,varargin)
global lastdir;
global extractoption;

if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
[PathName] = uigetdir(lastdir ,'Select Save Path...');
if PathName~=0;
    lastdir=PathName;
end

extractoption.directory = PathName;
set(handles.directory_edit,'String',PathName);
end

function [] = Interpolate_Callback(~,~,handles,varargin)
val=get(handles.interpolate_checkbox,'Value');
if val
    set(handles.sr_edit,'Enable','on');
    set(handles.export_checkbox,'Value',1);
else
    set(handles.sr_edit,'Enable','off');
    set(handles.export_checkbox,'Value',1);
end
end

function [] = Timeselect_Callback(~,~,handles,varargin)
    val=get(handles.timeselect_checkbox,'Value');
    
    if val
        set(handles.timeselect_checkbox,'Value',1);
        set(handles.timeselect_checkbox,'String','Extract all samples');
        set(handles.tfrom_edit,'Visible','off');
        set(handles.tto_edit,'Visible','off');
        set(handles.from_text,'Visible','off');
        set(handles.to_text,'Visible','off');
    else
        set(handles.timeselect_checkbox,'Value',0);
        set(handles.timeselect_checkbox,'String','Extract samples ');
        set(handles.tfrom_edit,'Visible','on');
        set(handles.tto_edit,'Visible','on');
        set(handles.from_text,'Visible','on');
        set(handles.to_text,'Visible','on');
    end
        
end

function [] = Tfrom_Callback(~,~,handles,varargin)
end

function [] = Tto_Callback(~,~,handles,varargin)
end




function [] = Edit_Interpolate_Callback(~,~,handles,varargin)


end




