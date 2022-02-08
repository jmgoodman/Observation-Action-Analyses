function [varargout] = findTrackingPort(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 FIND SERIAL PORT OF AURORA SYSTEM                 
%
% This routine searches for connected hardware on serial port 1-50. The
% port where Aurora is detected is returned as a strin in the following
% format:
%           "COMxy"     xy.....port number
%
% Ensure Tracking System works on Baudrate 9600.
%
% Helpful information:
%                       -http://de.wikipedia.org/wiki/EIA-232
%                       -Matlab help: "What is a serial communication?".
%
% Author: Stefan Schaffelhofer                                      Nov09 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin==1 % check for only one port
    fromCOM=varargin{1};
    toCOM  =varargin{1};
elseif nargin==2
    fromCOM=varargin{1};
    toCOM  =varargin{2};
end
COM='';                                                                    % allocate variable
% numofports= size(INSTRFIND,2);

for ii=fromCOM:toCOM                                                                % search from port 1 to 50
    sh=serial(['COM' num2str(ii)], 'BaudRate', 9600,'Terminator','CR','Timeout',0.5);
    try 
        status=get(sh,'Status'); 
        if strcmp(status,'closed');
            fopen(sh);                                                     % open port to see if port exist. if the port does not exist, the error is catched and the next port will be tried to open.
        end
        serialbreak(sh);
        pause(1.0);                                                 
        reset = fscanf(sh);                                                % reset the system to ensure same baudrate and defined status  
        fprintf(sh,'ECHO AreYouADevice?');                                 % if a port is found, check if device is Aurora. This is done by the typical command "ECHO "
        echo = fscanf(sh);                                  
        if findstr(echo,'AreYouADevice?');
            COM=['COM' num2str(ii)];  
            varargout{1}=COM;
            status=get(sh,'Status');                                       % save port if the device is identified          
            if strcmp(status,'open');
                fclose(sh); % close port when finished!
            end

                                                   
            break; % break when port is found 
        else
            if strcmp(status,'open');
                fclose(sh);                                                % close port, even when the device is not the one you are searching for
            end
        end
    catch exception
        if strcmp(status,'open');
            fclose(sh);
        end  
        rethrow(exception); % output error
                                                              % output error
    end 
                                                                           % close all opend ports, especiall when no device is connected.
end

if isempty(COM)                                                            % if now device was found: error
    varargout{1}='';
end

