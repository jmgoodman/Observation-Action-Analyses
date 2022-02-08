function [SY]=selectvolume(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 SELECT VOLUME OF MAGNETIC FLUX                
%
% This function reads selectes a specific volume of magnitic field used for
% tracking. The volume information of the selected volume is returned in
% the aurora object.
%
% Helpful information:  -Aurora Application Program Interface Guid (Nov 07)
%
%
% Example:      [aurora]=selectvolume(aurora,SO,volumeid)
%               aurora ............. aurora object 
%               SO   ............. serial object
%               volumeid............ id of selected volume
%
% Author: Stefan Schaffelhofer                             created  Nov09 %
%         Stefan Schaffelhofer                             updated  May09 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try

if nargin>2
    error('Too much input arguements.');
end
if nargin <2
    error('Not enougth input arguements.');
end
if isa(varargin{1},'sysobj') 
    SY=varargin{1}; %check if input arguement is of type "sySO"
else
    error('Wrong input argument: input argument must be a serial-object.');
end
if isa(varargin{2},'serial') %check if input arguement is of type "serial"
    SO=varargin{2};
else
    error('Wrong input argument: input argument must be a serial-object.');
end

if isempty(get(SY,'volumeselected'))
    error('No volume selcted yet.')
else
    volumeid=get(SY,'volumeselected');
end
%############################# SELECT VOLUME ##########################

fprintf(SO, ['VSEL ' num2str(volumeid)]);                                %select volume, volumes can be listed with SFLIST
systemreturn = fscanf(SO);
errorcheck(systemreturn);
SY=set(SY,'volumeselected',volumeid);

%###################### GET VOLUME INFORMATION ##########################

fprintf(SO,'SFLIST 03'); 
systemreturn=fscanf(SO);
errorcheck(systemreturn);
SY=set(SY,'numvolumes',str2double(systemreturn(1)));
selectedvolinfo=systemreturn(1+volumeid*74-73:1+volumeid*74);
volumetype=selectedvolinfo(1);
switch volumetype
    case '9'
    SY=set(SY,'volumetype','Cube');
    case 'A'
    SY=set(SY,'volumetype','Dome');

end
volumedefinition   =    [str2double(systemreturn(3:9)),   ...              % get definition of volume accordingly to Norther Digital API, page 53.
                         str2double(systemreturn(10:16)), ...
                         str2double(systemreturn(17:23)), ...
                         str2double(systemreturn(24:30)), ...
                         str2double(systemreturn(31:37)), ...
                         str2double(systemreturn(38:44)), ...
                         str2double(systemreturn(45:51)), ...
                         str2double(systemreturn(52:58)), ...
                         str2double(systemreturn(59:65))]; 
volumedefinition=volumedefinition./100;                      % .. in mm
SY=set(SY,'volumedefinition',volumedefinition);

%##########################################################################
catch exception  % if error occured ...
    fclose(SO);                                                          % close the port properly if an error occurs!                                        
    rethrow(exception); % output error                                          
end