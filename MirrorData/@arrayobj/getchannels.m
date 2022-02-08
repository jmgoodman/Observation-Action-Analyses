function [chmatrix] = getchannels(AO,area)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    GET CHANNEL MATRIX FOR AREA              
%
% DESCRIPTION:
% This function loads the array settings of an experimental setup.
% 
%
% SYNTAX:     chmatrix = getchannels(AO,area);
%        
%        AO             ... arrayobj
%        area           ... name of brain area
%                       
%
% EXAMPLE:   chmatrix = getchannels(AO,'F5-med');
%
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center              FEB12 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check ARRAYOBJ
if isobject(AO) == 0                                                       % check if third input argument is an object
    error('Wrong input argument: Input argument has to be an OBJ');
else
    if strcmpi(class(AO), 'arrayobj') == 0
        error('Wrong input argument: Input argument has to be a ARRAYOBJ.');
    end
end

if ~ischar(area)
    error('Input must be char.');
end

areas=AO.name;
ID=AO.ID;
channelmap=AO.channelmap;
search = strncmp(areas,area,length(area));
arrID = ID(search);

if sum(strncmp(areas,area,1))==0
     error(['No channel information found for area: ' area '.']);          % error if no statistics were found for the epoch obj
else
    chmatrix=channelmap{arrID};
end

    
    
    


