function [SY] = initsystem(SY,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 INITIALIZATION OF TRACKING SYSTEM                 
%
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center              Nov09 %
% last modified: Stefan Schafelhofer 1.6.2011
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

try
%########################CHECK INPUT PARAMETERS############################

if ~isa(SY,'sysobj') 
    error('Wrong input argument: input argument must be a serial-object.');
end
if isa(varargin{1},'serial')
    SO=varargin{1};
else
    error('Wrong input argument: input argument must be a serial-object.');
end

if nargin>2
    error('To many input arguements.');
end

if nargin<=1
    error('Not enought input arguements.');
end

hwb=waitbar(0,'1','Name','System initializing...');                        
steps=8;                                                                  


waitbar(1/steps,hwb,sprintf('%c','Reset Baudrate...'));
baudrate_user=get(SO,'BaudRate');                                          
set(SO,'BaudRate',9600);                                                                                       
  
waitbar(2/steps,hwb,sprintf('%c','Reset System...'));
serialbreak(SO);
reset=fscanf(SO);
errorcheck(reset);
    


waitbar(3/steps,hwb,sprintf('%c','Set Baudrate...'));
switch baudrate_user                                                       
    case 9600
        brtID = '00000';
    case 14400
        brtID = '10000';
    case 19200
        brtID = '20000';
    case 38400
        brtID = '30000';
    case 57600
        brtID = '40000';
    case 115200
        brtID = '50000';
    case 921600
        brtID = '60000'; 
    case 1228739
        brtID = '70000';

    otherwise
        error(['The selected Baud-Rate cant be used for receiving/'...
              'transmitting data. The available baudrates are: 9600,'...
              ' 14400, 19200, 38400, 57600 and 115200 and for WAVE ' ...
              'optional 921600 and 1228739']);

end
        
fprintf(SO, ['COMM ' brtID]);                                              
systemreturn=fscanf(SO);
errorcheck(systemreturn);
set(SO,'BaudRate',baudrate_user);                                          



waitbar(4/steps,hwb,sprintf('%c','Check if System started correctly...'));
fprintf(SO, 'INIT ');                                                    
systemreturn=fscanf(SO);
errorcheck(systemreturn);
SY=set(SY,'mode','Setup');

waitbar(5/steps,hwb,sprintf('%c','Get measurement volumes...'));
fprintf(SO,'SFLIST 03'); 
systemreturn=fscanf(SO);
if strcmp(systemreturn(1:5),'01400')
   error('No Fieldgenerator connected.'); 
else
errorcheck(systemreturn);
SY=set(SY,'numvolumes',str2double(systemreturn(1)));
split = textscan(systemreturn(2:end-5), '%s', 'EndOfLine', sprintf('\n'));
SY=set(SY,'volumesavailable',split{1});
end

waitbar(6/steps,hwb,sprintf('%c','Get API version...'));
fprintf(SO,'APIREV '); 
systemreturn=fscanf(SO);
errorcheck(systemreturn);
SY=set(SY,'APIrevision',systemreturn);

waitbar(7/steps,hwb,sprintf('%c','Get SCU-version...'));
fprintf(SO,'VER 4'); 
systemreturn = fscanf(SO);
errorcheck(systemreturn);
split = textscan(systemreturn(2:end-5), '%s', 'EndOfLine', sprintf('\n'));
split = split{1};
SY=set(SY,'SCUserialnumber',split{6});
SY=set(SY,'SCUfirmwarerevision',split{14});
SY=set(SY,'SCUcharactarizationdate',split{9});
SY=set(SY,'manufacturer',split{4});

if strcmp(split{14}(1:7),'007.014')
    SY=set(SY,'device','Wave');
else
    SY=set(SY,'device','Aurora');
end

waitbar(8/steps,hwb,sprintf('%c','Get generator-version...'));
fprintf(SO,'VER 7');                                                      
systemreturn = fscanf(SO);
errorcheck(systemreturn);
split = textscan(systemreturn, '%s', 'EndOfLine', sprintf('\n'));
split = split{1};
SY=set(SY,'GENserialnumber',split{5});
SY=set(SY,'GENmodel',[split{10} ' ' split{11}]);
SY=set(SY,'GENcharacterizationdate',split{14});

waitbar(8/steps,hwb,sprintf('%c','Get SIU-version...'));
fprintf(SO,'VER 8');                                                      
systemreturn = fscanf(SO);
errorcheck(systemreturn);
idx=findstr(systemreturn,'Port');

SIUrevision{1}=systemreturn(idx(1)+8:idx(2)-1);                            
SIUrevision{2}=systemreturn(idx(2)+8:idx(3)-1);                            
SIUrevision{3}=systemreturn(idx(3)+8:idx(4)-1);                            
SIUrevision{4}=systemreturn(idx(4)+8:end-5);                              

SY=set(SY,'SIUrevision',SIUrevision);

close(hwb);                                                                
catch exception  
    
    status=get(SO,'Status');
    if strcmp(status,'open');
        fclose(SO);
    end 
    
                                      
    rethrow(exception);
    close(hwb);
end

