function [SY] = inittools(varargin)

%##########################################################################
%
%                    INITIALIZE TRACKING TOOLS                 
%
%
% Author: Stefan Schaffelhofer ©DPZ                         created Nov09 %
%         Stefan Schaffelhofer                              updated May25 %
%
%##########################################################################

try

if nargin>2
    error('Too much input arguments.');
end
if nargin<2
    error('Too less input arguments.');
end

if isa(varargin{1},'sysobj')
    SY=varargin{1};
else
    error('Wrong input argument: input argument must be a serial-object.');
end
if isa(varargin{2},'serial')                                               
    SO=varargin{2};
else
    error('Wrong input argument: input argument must be a serial-object.');
end

ROMtype=get(SY,'ROMtype');
if ischar(ROMtype)                                                         
    switch ROMtype
        case 'srom'
            mode=ROMtype;
        case 'virtual'
            mode=ROMtype;
            ROMfile=get(SY,'ROMfile');
            if ~isempty(ROMfile)                                           
                numpath=size(ROMfile,2);                                   
                initports = zeros(1,4);                                    
                for ii=1:numpath                                           
                    if ~isempty(ROMfile{ii})                               
                        if exist(ROMfile{ii},'file')==2
                            initports(ii)=1;                               
                        else 
                            error(['File '' ' ROMfile{ii} ''' does not exist.']);
                        end
                    end
                end
            else
                error('ROM-file is empty. Could not initialize tools.');
            end
            
        otherwise
            error(['ROM-type ''' ROMtype ' '' not known.']);
    end
else
    error('ROM-type not known.');
end

    

fprintf(SO, 'PHSR 01');                                                    
phsr01=fscanf(SO);
errorcheck(phsr01);

if ~findstr(phsr01,'001414')                                               
    numportstobefreed=str2double(phsr01(1:2));
    for port=1:numportstobefreed
        startidx=2+port*5-4;                                               
        portID=phsr01(startidx:startidx+1);                                
        fprintf(SO, ['PHF ' portID]);                                      
        phf=fscanf(SO);
        errorcheck(phf);
    end
end


fprintf(SO, 'PHSR 02');                                                    
phsr02 = fscanf(SO);
errorcheck(phsr02);
numports=str2double(phsr02(1:2));
SY=set(SY,'numports',numports);

idx=1;
portID=cell(1,4);
for ii=1:4
    fprintf(SO, ['PHINF 0' dec2hex(9+ii) '0020']);
    physicalport = fscanf(SO);
    if ~strcmp(physicalport(1:7),'ERROR2B')
        portID{str2double(physicalport(11:12))}=['0' dec2hex(9+idx)];
        idx=idx+1;
    end
    fprintf(SO, ['PHINF 0' dec2hex(9+ii) '0001']);
    temp = fscanf(SO);
    fprintf(SO, ['PHINF 0' dec2hex(9+ii) '0004']);
    temp = fscanf(SO);
end


SY=set(SY,'portID',portID);

portdigitalIO  ={numports}; 
portnumswitches={numports};
portnumLED     ={numports};

for port=1:numports
    startidx=2+port*5-4;                                                   
    portID{port}=phsr02(startidx:startidx+1);                              
    tempdecs=hex2dec(phsr02(startidx+4));                                  
    tempbits=dec2bin(tempdecs,4);  
    gpio(1)  =str2double(tempbits(3));                                     
    gpio(2)  =str2double(tempbits(2));                                     
    gpio(3)  =str2double(tempbits(1));                                     
    portdigitalIO{port}=gpio;
    portnumswitches{port}=str2double(phsr02(startidx+2));                  
    portnumLED{port}=str2double(phsr02(startidx+1));                       
end
SY=set(SY,'portdigitalIO',portdigitalIO);
SY=set(SY,'portnumswitches',portnumswitches);
SY=set(SY,'portnumLED',portnumLED);

portsinitialized={0,0,0,0};
if strcmp(mode,'virtual')
    for ss=1:numports;
        if initports(ss)==1 
            [part]=readROMfile(ROMfile{ss});
            for cc=1:length(part) 
                fprintf(SO,['PVWR 0' dec2hex(ss+9) part(cc).chunck]);
                PVWR=fscanf(SO);
                errorcheck(PVWR);
            end
            hID=portID{ss};
            fprintf(SO, ['PINIT ' hID]);                                         
            pinit = fscanf(SO);
            errorcheck(pinit);
            portsinitialized{port}=1;
        end
    end
end    
SY=set(SY,'portsinitialized',portsinitialized);


fprintf(SO, 'PHSR 03');                                                  
phsr03=fscanf(SO);
numtoolsnotenabled=str2double(phsr03(1:2));                                
toolsnotenabled={numtoolsnotenabled};                                      
for tool=1:numtoolsnotenabled
    startidx=2+tool*5-4;                                                   
    toolsnotenabled{tool}=phsr03(startidx:startidx+1);
end

hwb=waitbar(0,'1','Name','Enable tools...');
enabledtools={0,0,0,0};
for tool=1:numtoolsnotenabled
    hID=toolsnotenabled{tool};
    fprintf(SO, ['PENA ' hID 'D']);
    ena=fscanf(SO);
    errorcheck(ena);
    enabledtools{tool}=1;
    waitbar(tool/numtoolsnotenabled,hwb, ...
            sprintf('%c',['Tool ' num2str(tool) ' OK.']));
end
SY=set(SY,'enabledtools',enabledtools);
toolID=cell(1,8);
toolNumID=zeros(1,8);
fprintf(SO, 'PHSR 04'); 
phsr04=fscanf(SO);
errorcheck(phsr04);
numtools=str2double(phsr04(1:2));

for tool=1:numtools
    startidx=2+tool*5-4;                                                   
    toolAdr=phsr04(startidx:startidx+1);                                   
    fprintf(SO, ['PHINF ' toolAdr '0020']);
    physicalport = fscanf(SO);
    port=str2double(physicalport(11:12));
    channel=str2double(physicalport(13:14));
    toolID{2*port-2+1+channel}=toolAdr;
    switch toolAdr
        case '0A'
            toolNumID(tool)=1;
        case '0B'
            toolNumID(tool)=2;
        case '0C'
            toolNumID(tool)=3;
        case '0D'
            toolNumID(tool)=4;
        case '0E'
            toolNumID(tool)=5;
        case '0F'
            toolNumID(tool)=6;
        case '10'
            toolNumID(tool)=7;
        case '11'
            toolNumID(tool)=8;
    end
end
SY=set(SY,'toolID',toolID);
SY=set(SY,'toolNumID',toolNumID);
SY=set(SY,'numtools',numtools);



toolpartnumber={'','','',''};
for tool=1:numtools
    hID=toolsnotenabled{tool};
    fprintf(SO, ['PHINF ' hID '0004']);
    PHINFtoolpartnumber = fscanf(SO);
    toolpartnumber{tool}=PHINFtoolpartnumber(1:20);
end
SY=set(SY,'toolpartnumber',toolpartnumber);


close(hwb); 
catch exception  
    status=get(SO,'Status');
    if strcmp(status,'closed');
     fopen(SO);
    end
    rethrow(exception);                                                                                         
end

