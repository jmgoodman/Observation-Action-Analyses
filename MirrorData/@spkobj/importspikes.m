function [SPK varargout] = importspikes(SPK,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 IMPORT OF SPIKE EVENTS                
%
% DESCRIPTION:
% This routine imports spike events, including waveforms, channel-ID,
% electrode ID, and spike-times. Additionally, epoche events  recoded into
% the same file can be accessed. The function supports several system 
% such as Tucker Davis Technologies or Blackrock. 
% 
% HELPFUL INFORMATION:  -How to import TDT Tank into Matlab.pdf
%                       -Tank format.pdf
%
% SYNTAX:    [SPK dIO] = import(SPK,'path',path,'system',system,...
%                         'option',option);
%
%        SPK       ... spkobj
%        path      ... char(path of file or tank) 
%        system    ... char(identifier of system;'TDT' Tucker Davis Techn.
%                                                 'BR'  Blackrock Microsys.
%        option    ... char(read in option) 
%                      'all' reads in spiketimes, IDs, waveforms, and
%                      'spikeevents' reads in everything expt. wavef.
%                      (optional input arguement)
%        spkname   ... identifier name of spikes (eg. 'eNeA', 'eNeu', ...
%                      only on spikename is allowed at one time
%        epoch     ... char or cell(read in recorded epoch events)
%                      char or cell include the names of the epoch events
%                      if not specified, nothing is returned by the func.
%                      (optional input arguement)
%                       
%
% EXAMPLE:   SPK = import(SPK,'path','C:\TANK1\Block-16','system','TDT',...
%                         'spikename','eNeu',option,'all',...
%                          epoch,{'LabV','Behav'});
%
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center              JUN11 %
% modified: Stefan Schaffelhofer  10.6.2011
% modified: Stefan Schaffelhofer  11.7.2011
% modified: Stefan Schaffelhofer  04.8.2011
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tic;
% Error check:
if ~isa(SPK,'spkobj') %check if input arguement is of type "sysobj"
    error('Wrong class of input arguement.');
end
if nargin<5
    error('Not enough input arguements.');
end
if nargin>11
    error('Too many input arguements.');
end

pathok   = 0;
systemok = 0;
optionok = 0;
epochok  = 0;
spkok    = 0;

% Check if all necessary input parameters are there
for ii=1:numel(varargin)
    if strcmpi(varargin{ii},'path')
        pathok=1;
        pathid=ii+1;
    elseif strcmpi(varargin{ii},'system')
        systemok=1;
        systemid=ii+1;
    elseif strcmpi(varargin{ii},'option')
        optionok=1;
        optionid=ii+1;
    elseif strcmpi(varargin{ii},'epoch')
        epochok=1;
        epochid=ii+1;
    elseif strcmpi(varargin{ii},'spikename')
        spkok=1;
        spkid=ii+1;
    end
    
end

if ~(pathok && systemok)
    error('Not enought input arguements. Path and import-system must be defined.');
end

% Check if system is known
if isa(varargin{systemid},'char')
    if strcmpi(varargin{systemid},'TDT')                                   % Tucker Davis Technologies
        system='TDT';
        if ~spkok
            error('Not enought input arguements. Spike name (identifier) must be defined for TDT');
        else
            if ~ischar(varargin{spkid})
                error('Spike name must be of type char with 4 characters');
            else
                if length(varargin{spkid})~=4
                    error('Spike name must be of type char with 4 characters');
                else
                    spkname=varargin{spkid};
                end
            end
        end
                    
    elseif strcmpi(varargin{systemid},'BL')                                % Blackrock
        system='BL';
    else
        error('Unknown system.')
    end
else
    error(['Wrong option of ' varargin{systemid-1} '- parameter.']); 
end

% Check if folder/file, or tank exists
if isa(varargin{pathid},'char')
    switch system
        case 'TDT'                                                         % Check if folders/files exist
                if exist(varargin{pathid},'dir')
                   thispath=varargin{pathid};
                   tsqfiles=dir([thispath '/*.tsq']);
                   tevfiles=dir([thispath '/*.tev']);
                   if numel(tsqfiles)==1 && numel(tevfiles)==1
                       tsq_path=[thispath '/' tsqfiles.name];
                       tev_path=[thispath '/' tevfiles.name];
                   else
                       error('Two or more *.tsq or *.tev files.');
                   end
                else
                    error([system '-tank not found.']);
                end
        case 'BL'
    end

end

% Check for read-in-option

if optionok==1
    if isa(varargin{optionid},'char') &&  ...
           (strcmpi(varargin{optionid},'all') || ...
            strcmpi(varargin{optionid},'spikeevents'))
        readoption=varargin{optionid};
    else
        error('Option unknown or of wrong option.');
    end  
else
    readoption='';
end

if epochok==1
switch system
    case 'TDT'
        epochnames=varargin{epochid};
        if iscell(epochnames)
            nrepochnames=numel(epochnames);
            for ii=1:nrepochnames
                testname=epochnames{ii};
                if numel(testname)>4
                    error(['Epoch names are not allowed ' ...
                          'to have more then 4 characters.']);
                end
            end
        elseif ischar(epochnames)
            epochnames={epochnames};
            nrepochnames=1;
        else
            error('Wrong input type for epochnames.');
        end
    case 'BL'
end
end

% IMPORT data
switch system
    case 'TDT'                                                             % Import for Tucker Davis Technologies
    % open the files
    tev = fopen(tev_path,'r');                                             % open with read only access
    tsq = fopen(tsq_path,'r'); 
    fseek(tsq, 0, 'eof');
    ntsq = ftell(tsq);                                                     % ... and tell the position (=number of bytes from beginning). Dividing the number of bytes of the file by the number of bytes for a header blocks gives back the number of headers.
    fseek(tsq, 0, 'bof');                                                  % go back to the start of the file
    disp('Load TSQ file ...');
    TSQ=fread(tsq,'uint8=>uint8');                                         % load the whole TSQ-file (faster then to read only spike-relevant parts)
    disp('TSQ loaded.')
    disp('TSQ spike extraction started...');
    % Name
    mask=false(ntsq,1);                                                    % creat mask for names. Always the 9th, 10th, 11th, 12th byte of event-header. Name (4-charecter event name)
    mask(9:40:end) =1;
    mask(10:40:end)=1;
    mask(11:40:end)=1;
    mask(12:40:end)=1;
    name=TSQ(mask);
    name=typecast(name,'uint32');    
    clear mask;                                                            % clear memory

    namesearcheNeu = 256.^(0:3)*double(spkname)';                           % convert names to numeric identifiers
    
    % READ IN SPIKE TIMES AND SPIKE IDS

    snipIDs        = find(name==namesearcheNeu);
    if ~isempty(snipIDs)                  
        nrspikes       = numel(snipIDs);                                   % nr of recorded spikes

        headers=uint8(zeros(40,nrspikes));
        for ii=1:nrspikes                                                  % read out the headers, but only of spike-relevant events
            pointer=snipIDs(ii)*40;
            headers(:,ii)=TSQ(pointer-39:pointer);
        end

        nam   =typecast(reshape(headers( 9:12,:),nrspikes*4,1),'uint32');   % convert names, channel, sort-code, and timestamps
        chan  =typecast(reshape(headers(13:14,:),nrspikes*2,1),'uint16');       
        nid   =typecast(reshape(headers(15:16,:),nrspikes*2,1),'uint16');
        tst   =typecast(reshape(headers(17:24,:),nrspikes*8,1),'double');

        tstart=typecast(TSQ(57:64),'double');
        tst   = tst - tstart;
        fsamp = typecast(headers(37:40,1),'single');

        ele=zeros(nrspikes,1);
        ele(nam==namesearcheNeu)=1;                                        % assign array IDs for each detected spike

        SPK.spiketimes = tst;                                              % assign values to object
        SPK.sortID     = nid;
        SPK.electrodeID= ele;
        SPK.channelID  = chan;
        SPK.physicalunit='µV';
        SPK.samplingrate=fsamp;        
        
        % WAVEFORMS
        if strcmp(readoption,'all') || optionok==0                         % read in waveforms
            % spike waveforms
            fp_loc=typecast(reshape(headers(25:32,:),nrspikes*8,1),'int64');
            fp_loc=double(fp_loc);

            fseek(tev, 0, 'bof');
            disp('Load TEV file...');
            A=fread(tev,'uint8=>uint8'); 
            disp('TEV waveform extraction started...');% read in the whole TEV-file
            spkidx=false(size(A));
            for ii=1:length(fp_loc)
                spkidx(fp_loc(ii,1)+1:fp_loc(ii,1)+120)=true;
            end
            clear fp_loc;
            B=A(spkidx);
            clear A; clear spkidx;
            A=typecast(B,'single');  
            clear B;
            waveforms=reshape(A,30,numel(A)/30);                           % parse TEV-file and load spike-waveforms

            SPK.waveforms = waveforms; 
            disp('TEV waveform extraction finished.');
        end
    end % if isempty(snipIDs)
    
    disp('TSQ spike extraction finished.');
   
    % DIGITAL INPUTS
    if epochok % read in digital inputs
        disp('TSQ digital input extraction started...');
        epoch.times=[];
        epoch.value=[];
        epoch.name =[];
        for ee=1:nrepochnames
            epochname=epochnames{ee};
            namesearchepoch = 256.^(0:3)*double(epochname)';
            epochs = find(name==namesearchepoch);
            nrepochs = numel(epochs);                                      % nr of recorded spikes

            headere=uint8(zeros(40,nrepochs));
            for ii=1:nrepochs                                              % read out the headers, but only of spike-relevant events
                pointer=epochs(ii)*40;
                headere(:,ii)=TSQ(pointer-39:pointer);
            end
            tstart=typecast(TSQ(57:64),'double');
            epoch.times   =typecast(reshape(headere(17:24,:),nrepochs*8,1),'double')-tstart;
            epoch.value   =typecast(reshape(headere(25:32,:),nrepochs*8,1),'double');
            epoch.name    =epochname;
            varargout{ee}  =epoch;
        end
        disp('TSQ digital input extraction finished.');
    else
        varargout{1}=[];
    end
    
    
    
    
    fclose(tsq);                                                           % close files
    fclose(tev);
    
    case 'BL'                                                              % Import for Blackrock
end

t=toc;
disp(['Spikes imported in ' num2str(t) ' sec.']);
end





