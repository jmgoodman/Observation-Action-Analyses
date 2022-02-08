function [SY] = tracking(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 ENABLE TRACKING                
%
% DESCRIPTION:
% 
% HELPFUL INFORMATION:  -
%                       -
% SYNTAX: 
%
% EXAMPLE:
%
% Author: ©Stefan Schaffelhofer, German Primate Center              Nov09 %
%                                                      last update  Jun10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ERROR CHECK %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    error('Too less input arguments.');
end
if nargin > 3
    error('Too much input arguments.');
end

if isa(varargin{1},'sysobj')
    SY=varargin{1};
else
    error('Wrong input argument: input argument must be a system-object.');
end

if isa(varargin{2},'serial')
    SO=varargin{2};
else
    error('Wrong input argument: input argument must be a system-object.');
end

if ischar(varargin{3})
    if strcmp(varargin{3},'start') || strcmp(varargin{3},'stop') 
        selectedmode=varargin{3};
    else
        error(['Unknown tracking mode: ''' varargin{3} '''']);
    end
else
    error('Wrong input argument: input argument must be of type ''char''.');
end
   
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SELECTION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

device=get(SY,'device');
switch selectedmode
    case 'start'
        currentmode=get(SY,'mode');
        if ~strcmp(currentmode,'Tracking') % check if system is already in tracking mode
            switch device
                case 'Aurora'

                    fprintf(SO, 'TSTART ');
                    ret=fscanf(SO);
                    errorcheck(ret);
                    SY=set(SY,'mode','Tracking');
                    disp('Tracking has started.');
                    warning('off', 'MATLAB:singularMatrix'); % switch warning off, to stop annoying NaN warnings.
                case 'Wave'
                    fprintf(SO, 'TSTART 40');
                    ret=fscanf(SO);
                    errorcheck(ret);
                    SY=set(SY,'mode','Tracking');
                    disp('Tracking has started.');
                    warning('off', 'MATLAB:singularMatrix'); % switch warning off, to stop annoying NaN warnings.
                otherwise
                    error(['Device ''' device ''' is unknowen.']);
            end
        else
            disp('System already in ''Tracking-Mode''');
        end % end if
    case 'stop'
        currentmode=get(SY,'mode');
        if strcmp(currentmode,'Tracking') % check if system is already in tracking mode
            fprintf(SO, 'TSTOP ');                                                    % Start Tracking (API help page 57)
            ret=fscanf(SO);
            errorcheck(ret);
            SY=set(SY,'mode','Setup');
            disp('Tracking has stopped.');
            warning('on', 'MATLAB:singularMatrix');
        else
            disp('Tracking already stopped.');
        end
        
    otherwise
        warning('on', 'MATLAB:singularMatrix');
        error('Command not found.');
end
       
end



