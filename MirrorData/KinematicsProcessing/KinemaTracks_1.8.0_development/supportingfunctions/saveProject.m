function [varargout]=saveProject(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       SAVE TRACKING PROJECT                
%
% Descrition
% 
% Helpful information:  
%
% Author: ©Stefan Schaffelhofer, German Primate Center              May10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global lastdir;
try

%############################# ERROR CHECK ################################
if nargin>9
    error('To many input arguments.');
end

if nargin<9
    error('Not enought input arguments.');
end
    
if isa(varargin{1},'settingsobj') %check if input arguement is of type "sysobj"
    STO=varargin{1};
else
    error('Wrong input argument: input argument must be a system-object.');
end
if isa(varargin{2},'sysobj') %check if input arguement is of type "sysobj"
    SY=varargin{2};
else
    error('Wrong input argument: input argument must be a serial-object.');
end
if isa(varargin{3},'serial') %check if input arguement is of type "sysobj"
    SO=varargin{3};
else
    error('Wrong input argument: input argument must be a setting-object.');
end
if isa(varargin{4},'handobj') %check if input arguement is of type "sysobj"
    LHO=varargin{4};
else
    error('Wrong input argument: input argument must be a hand-object.');
end
if isa(varargin{5},'handobj') %check if input arguement is of type "sysobj"
    GHO=varargin{5};
else
    error('Wrong input argument: input argument must be a hand-object.');
end


UDP1=varargin{6};

if isa(varargin{7},'serial') %check if input arguement is of type "sysobj"
    CER=varargin{7};
else
    error('Wrong input argument: input argument must be a hand-object.');
end

GST = varargin{8};

if ischar(varargin{9})
    status=varargin{9};
    if ~((strcmp(status,'SAVE')) || (strcmp(status,'SAVEAS')))
        error('Wrong Status requested');
    end
else
    error('Wrong input argument: input argument must be a string.');
end

%############################# SAVE or SAVE AS ############################

%check if the Object has been saved already
fileName = get(STO,'filenameproject');

if isempty(fileName)  
    status = 'SAVEAS'; %Object has never been saved (no filename in the Object), change status to SAVEAS
else     
    [pathname,name,exte]=fileparts(fileName); %get fileparts
end

%correct name of objects for saving
SY_s   = SY;
SO_s   = SO;
STO_s  = STO;
LHO_s  = LHO;
GHO_s  = GHO;
UDP1_s = UDP1;
CER_s  = CER;
GST_s = GST;

%add the current time and date to the Cutting Object
STO_S.savetime = datestr(clock,0);

set(UDP1_s,'Status','closed');

switch status
    case 'SAVE'
        %check for file overwrite
        if exist(fileName,'file')==2
            button = questdlg(['File already existis! ',...
                'Do you want to overwrite it?'],'Confirm Save','Yes','No','Yes');
            if strcmp(button,'Yes')  %save it
                %add filename and project objects
                STO_S.filename = fileName;
                save(fileName,'STO_s','SY_s','SO_s','LHO_s','GHO_s','UDP1_s','CER_s','GST_s');
            end
        else
            STO_s.filenameproject = fileName;
            save(fileName,'STO_s','SY_s','SO_s','LHO_s','GHO_s','UDP1_s','CER_s','GST_s');
        end
        %add cutdate and return CUTO
        STO.filenameproject = fileName;
        STO.savetime = datestr(clock,0);
        varargout{1} = STO;

    case 'SAVEAS'
       if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
        [fileN,pathN] = uiputfile([lastdir '*.mat'],'Save as');
        if isequal([fileN,pathN],[0,0])  %user cancel
            return
        else         %file selected
            fileName = fullfile(pathN,fileN);  %construct new filename for object
            STO_S.filenameproject = fileName;
            STO_S.savetime = datestr(clock,0);
            save(fileName,'STO_s','SY_s','SO_s','LHO_s','GHO_s','UDP1_s','CER_s','GST_s');     %save it                
            STO = set(STO,'filenameproject',fileName);    %set new filename
            lastdir=pathN;
        end

        %add cutdate and return CUTO
        STO.filenameproject = fileName;
        STO.savetime = datestr(clock,0);
        varargout{1} = STO;
end

catch exception
    rethrow(exception);
end