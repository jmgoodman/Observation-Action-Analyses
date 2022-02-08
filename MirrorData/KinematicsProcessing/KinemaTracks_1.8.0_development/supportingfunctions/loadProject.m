function [varargout] = loadProject(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       LOAD TRACKING PROJECT                
%
% Descrition
% 
% Helpful information:  
%
% Author: ©Stefan Schaffelhofer, German Primate Center              May10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global lastdir;  

try

%############################# LOAD PROJECT ############################
switch nargin
    case 0  % file is selected by user
        
        if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
            [file,path]=uigetfile(...
            [lastdir '*.mat'],'Select Project-file');
            %Otherwise construct the full filename and check and load the file.
            if ischar(file) % check if file is really loaded or 0
                filename=fullfile(path,file); 
                if exist(filename,'file'); % check if file exist
                    correct=1; % set flag if file exist
                    lastdir=path;
                end
            else
                correct=0;
            end
    case 1  % file has been forwarded by function
            if ischar(varargin{1})
                if exist(varargin{1},'file')==2
                    filename=varargin{1};
                    correct=1; %set file if exit
                else
                    error('File not found.');
                end

            else
                error('Wrong input argument: input argument must be a string.');
            end
    otherwise
            error('Wrong number of input arguments.');
end

if correct

    load(filename,'STO_s','SY_s','SO_s','LHO_s','GHO_s','UDP1_s','CER_s','GST_s');

    STO =STO_s; %
    SY  =SY_s;
    SO  =SO_s;
    LHO =LHO_s;
    GHO =GHO_s;        
    CER =CER_s;

    % After addition of the new UDP object for Matlab 2015 or superior
    if isfield(UDP1_s,'icinterface')
        warning('The project contains an old UDP object that cannot be loaded. Using default values with new object type.');
        UDP1 = udpobj('172.21.255.255', 'RemotePort', 4600, 'LocalPort', 8600);
        UDP1.UserData = 'Robot';
    else
        UDP1 = UDP1_s;
    end

    % After adition of new GUI settings
    if ~exist('GST_s','var')
        GST.plot_enable=1;
        GST.udp_enable=0;
        GST.flatf1sens=0;
        GST.nopipinversion=0;
    else
        GST = GST_s;
    end

    ipadr = get(UDP1,'RemoteHost');
    remoteport = get(UDP1,'RemotePort');
    localport = get(UDP1,'LocalPort');
    mode = get(UDP1,'UserData');
    %Added the fuction so users dont have to open and close UDP
    %settings window every time                         Andrej Filippow
    checkUDP(ipadr, remoteport, localport, mode);

    STO=set(STO,'filenameproject',filename);     %   
    varargout{1}=1; % successfully load
    varargout{2}=STO; %
    varargout{3}=SY;
    varargout{4}=SO;
    varargout{5}=LHO;
    varargout{6}=GHO;
    varargout{7}=UDP1;
    varargout{8}=CER;
    varargout{9}=GST;

else
    varargout{1}=-1; % abort by user
    varargout{2}=[];
    varargout{3}=[];
    varargout{4}=[];
    varargout{5}=[];
    varargout{6}=[];
    varargout{7}=[];
    varargout{8}=[];
    varargout{9}=[];
end

catch exception
    rethrow(exception);
end