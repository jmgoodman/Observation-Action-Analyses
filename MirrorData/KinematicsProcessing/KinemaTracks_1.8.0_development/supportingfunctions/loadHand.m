function [varargout] = loadHand(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                       LOAD HAND               
%
% Descrition
% 
% Helpful information:  
%
% Author: ?Stefan Schaffelhofer, German Primate Center              May10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
global lastdir
try

   
%############################# LOAD PROJECT ############################
switch nargin
    case 0  % file is selected by user
            if isempty(lastdir) || isnumeric(lastdir); lastdir=[cd '\']; end;
            [file,path]=uigetfile(...
            [lastdir '*.mat'],'Select Hand-file');
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
    matFileContent = whos('-file',filename);


    if (size(matFileContent,1))==2 && ...
       strcmp(matFileContent(1,1).class,'handobj') && ...
       strcmp(matFileContent(2,1).class,'handobj')

        load(filename,'LHO_s','GHO_s');
        LHO=LHO_s;
        GHO =GHO_s;
    
        varargout{1}=1; % successfully load file type 1
        varargout{2}=LHO;
        varargout{3}=GHO;
        varargout{4} = [];
    elseif (size(matFileContent,1))==5 && ...
            strcmp(matFileContent(1,1).class,'handobj') && ...
            strcmp(matFileContent(2,1).class,'handobj') && ...
            strcmp(matFileContent(5,1).name,'recording')
        
        % allow for loading this OTHER type of file...
        load(filename,'GHO','LHO','recording')
        
        varargout{1} = 2; % successfully load file type 2
        varargout{2} = LHO; %#ok<*NODEF>
        varargout{3} = GHO;
        varargout{4} = recording;
        
    else
        varargout{1}=0; % file failer
        varargout{2}=[];
        varargout{3}=[];
        varargout{4}=[];
    end
else
    varargout{1}=-1; % abort by user
    varargout{2}=[];
    varargout{3}=[];
    varargout{4}=[];
end

catch exception
    rethrow(exception);
end