function [varargout]=saveHand(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       SAVE HAND SETTINGS               
%
% Descrition
% 
% Helpful information:  
%
% Author: ©Stefan Schaffelhofer, German Primate Center              May10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

%############################# ERROR CHECK ################################
if nargin>4
    error('To many input arguements.');
end

if nargin<4
    error('Not enought input arguements.');
end
    
    
if isa(varargin{1},'handobj') %check if input arguement is of type "sysobj"
    LHO=varargin{1};
else
    error('Wrong input argument: input argument must be a system-object.');
end
if isa(varargin{2},'handobj') %check if input arguement is of type "sysobj"
    GHO=varargin{2};
else
    error('Wrong input argument: input argument must be a serial-object.');
end

if isa(varargin{3},'settingsobj') %check if input arguement is of type "sysobj"
    STO=varargin{3};
else
    error('Wrong input argument: input argument must be a serial-object.');
end

if ischar(varargin{4})
    status=varargin{4};
    if ~((strcmp(status,'SAVE')) || (strcmp(status,'SAVEAS')))
        error('Wrong Status requested');
    end
else
    error('Wrong input argument: input argument must be a string.');
end

%############################# SAVE or SAVE AS ############################


%check if the Object has been saved already
fileName = get(STO,'filenamehand');

if isempty(fileName)  
    status = 'SAVEAS';%Object has never been saved (no filename in the Object), change status to SAVEAS
else     
    [pathname,name,exte,ver]=fileparts(fileName); %get fileparts
end

%correct name of objects for saving

LHO_s = LHO;
GHO_s = GHO;

%add the current time and date to the Cutting Object
STO_S.savetime = datestr(clock,0);

switch status
    case 'SAVE'
        %check for file overwrite
        if exist(fileName,'file')==2
            button = questdlg(['File already existis! ',...
                'Do you want to overwrite it?'],'Confirm Save','Yes','No','Yes');
            if strcmp(button,'Yes')  %save it
                %add filename and project objects
                STO_S.filename = fileName;
                save(fileName,'LHO_s','GHO_s');
            end
        else
            STO_S.filename = fileName;
            save(fileName,'LHO_s','GHO_s');
        end
        %add cutdate and return CUTO
        STO.filename = fileName;
        STO.savetime = datestr(clock,0);
        varargout{1} = STO;

    case 'SAVEAS'
        [fileN,pathN] = uiputfile({'*.mat','MAT Files (*.mat)';...
            '*.*','All Files (*.*)'},'Save as');
        if isequal([fileN,pathN],[0,0])  %user cancel
            return
        else         %file selected
            fileName = fullfile(pathN,fileN);  %construct new filename for object
            STO_S.filename = fileName;
            STO_S.savetime = datestr(clock,0);
            save(fileName,'LHO_s','GHO_s');     %save it                
            STO = set(STO,'FILENAMEHAND',fileName);    %set new filename
        end

        %add cutdate and return CUTO
        STO.filename = fileName;
        STO.savetime = datestr(clock,0);
        varargout{1} = STO;
end

catch exception
    rethrow(exception);
end