function AO = loadarray(AO,specification)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      LOAD ARRAY SPECIFICATIONS              
%
% DESCRIPTION:
% This function loads the array settings of an experimental setup.
% 
%
% SYNTAX:    AO = loadarray(AO,specification);
%        
%        AO             ... arrayobj
%        specification  ... name, under the user has saved the array
%                           specifications
%                       
%
% EXAMPLE:   epochtypes = getepochtypes('Setup1a')
%
% AUTHOR: �Stefan Schaffelhofer, German Primate Center              JUL11 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%check arrayobj
if isobject(AO) == 0                                              %check if third input argument is an object
    error('Wrong input argument: Input argument has to be an OBJECT.');
else
    if strcmpi(class(AO), 'arrayobj') == 0
        error('Wrong input argument: Input argument has to be an ARROBJ.');
    end
end

%check speficication
if ~ischar(specification)
    error('Wrong input arguement.');
else
    specification=lower(specification);
end

%--------------------------------------


switch specification
    case 'zara'
        ID=[1,2,3,4,5,6];
        name={'F5-med','F5-lat','AIP-med','AIP-lat','M1-lat','M1-med'};
        position={[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]};
        dim={[4,8], [4,8],   [4,8],   [4,8],   [4,8],   [4,8]}; 
        
        ch_ID=cell(1,6); % array x row x column
        matrix=[ 31, 29, 27, 25, 32, 30, 28, 26; ...
                 24, 22, 20, 18, 23, 21, 19, 17; ...
                 15, 13, 11, 9,  16, 14, 12, 10; ...
                       8,6,4,2,7,5,3,1 ]; % specification not correct yet, waiting for microprobe
        ch_ID{1,1} = matrix;
        ch_ID{1,2} = matrix+32;
        ch_ID{1,3} = matrix+64;
        ch_ID{1,4} = matrix+96;
        ch_ID{1,5} = matrix+128;
        ch_ID{1,6} = matrix+160;
        
        numCh=[32, 32, 32, 32, 32, 32];
        manufacturer='Microprobe';
        
        AO=set(AO,'ID',ID);
        AO=set(AO,'name',name);
        AO=set(AO,'dim',dim);
        AO=set(AO,'pos',position);
        AO=set(AO,'channelmap',ch_ID);
        AO=set(AO,'numCh',numCh);
        AO=set(AO,'manufacturer',manufacturer);
        
        
    case 'moe_left'
        
        ID=[1,2,3,4,5]; % only 160 channels for this array!!!
        name={'M1-med','M1-lat','F5-med','AIP-lat','AIP-med'};
        position={[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]};
        ch_ID=cell(1,6); % array x row x column
        matrix=[ 31, 29, 27, 25, 32, 30, 28, 26; ...
                 24, 22, 20, 18, 23, 21, 19, 17; ...
                 15, 13, 11, 9,  16, 14, 12, 10; ...
                       8,6,4,2,7,5,3,1 ]; % specification not correct yet, waiting for microprobe
        
        dim={[4,8], [4,8],   [4,8],   [4,8],   [4,8]};        
        ch_ID{1,1} = matrix;
        ch_ID{1,2} = matrix+32;
        ch_ID{1,3} = matrix+64;
        ch_ID{1,4} = matrix+96;
        ch_ID{1,5} = matrix+128;

        numCh=[32, 32, 32, 32, 32, 32];
        manufacturer='Microprobe';
        
        AO=set(AO,'ID',ID);
        AO=set(AO,'name',name);
        AO=set(AO,'dim',dim);
        AO=set(AO,'pos',position);
        AO=set(AO,'channelmap',ch_ID);
        AO=set(AO,'numCh',numCh);
        AO=set(AO,'manufacturer',manufacturer);
        
    case 'moe'
        
        ID=[1,2,3,4,5,6];
        name={'F5-lat','F5-med','M1-lat','M1-med','AIP-med','AIP-lat'};
        position={[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0],[0,0,0]};
        dim={[4,8], [4,8],   [4,8],   [4,8],   [4,8],   [4,8]}; 
        
        ch_ID=cell(1,6); % array x row x column
        matrix=[ 31, 29, 27, 25, 32, 30, 28, 26; ...
                 24, 22, 20, 18, 23, 21, 19, 17; ...
                 15, 13, 11, 9,  16, 14, 12, 10; ...
                       8,6,4,2,7,5,3,1 ]; % specification not correct yet, waiting for microprobe
        ch_ID{1,1} = matrix;
        ch_ID{1,2} = matrix+32;
        ch_ID{1,3} = matrix+64;
        ch_ID{1,4} = matrix+96;
        ch_ID{1,5} = matrix+128;
        ch_ID{1,6} = matrix+160;
        
        numCh=[32, 32, 32, 32, 32, 32];
        manufacturer='Microprobe';
        
        AO=set(AO,'ID',ID);
        AO=set(AO,'name',name);
        AO=set(AO,'dim',dim);
        AO=set(AO,'pos',position);
        AO=set(AO,'channelmap',ch_ID);
        AO=set(AO,'numCh',numCh);
        AO=set(AO,'manufacturer',manufacturer);
        
           
    otherwise
        error('Specification not found.');
end
 