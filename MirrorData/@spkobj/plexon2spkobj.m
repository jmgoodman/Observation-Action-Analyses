function SPK=plexon2spkobj(SPK,filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           CONVERT PLEXON FORMAT *.NEX INTO SPKOBJ
%
%DESCRIPTION: This routine imports the waveforms and spiketimes located in
%a *.NEX file into MATLAB and saves them as spkobj. NEX-files are a format
%of Plexon Offlinesorter
%
%SYNTAX: SPK = plexon2spkobj(SPK, filename, chpf)
%            
%            SPK      ... spkobj includes waveforms and time-stamps
%            filename ... path and filename of *.NEX file
%
%EXAMPLE: plexon2spkobj(SPK,'C:\Recording11_SPK_sorted.nex)
%
%AUTHOR: ©Stefan Schaffelhofer, German Primate Center            6.Dez 2011
%last modified: 
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ERROR-CHECKING

if ~(isobject(SPK) && strcmpi(class(SPK),'spkobj'))
    error('Wrong type of input argument.');
end

[pathstr, ~, ~]=fileparts(filename);
if ~isdir(pathstr)
    error('Path is non-existent or not a directory.');
end
disp('Importing NEX file ...')
nexstruct=readNex(filename);

num_ch_new=0; % because of invalidation of all spikes of a channel, plexon is deleting this channel. Therefore the wire number is not correct anymore. The correct wire number is still saved in the name of the struct.
for ww=1:length(nexstruct.waves)
    nametemp=nexstruct.waves{ww,1}.name;
    strt=strfind(nametemp,'sig')+3;
    stop=strfind(nametemp,'_wf')-2;
    chid=str2double(nametemp(strt:stop));
    nexstruct.waves{ww}.wireNumber=chid;
    if chid>num_ch_new
        num_ch_new=chid;
    end
end

numunits=size(nexstruct.waves,1);

% get number of channels
num_ch_old=max(SPK.channelID);

%get number of channels in new file

num_ch_new=0;
for nn=1:numunits
    if nexstruct.waves{nn,1}.wireNumber>num_ch_new
        num_ch_new=nexstruct.waves{nn,1}.wireNumber;
    end
end

if num_ch_new~=num_ch_old
    error('SPKOBJ does not fit to NEX file: Number of channels is not equal.');
end

% convert nex structure into SPKOBJ
waveforms=[];
spiketimes=[];
sortID=[];
channelID=[];

waveforms_ch=[];
spiketimes_ch=[];
sortID_ch=[];
channelID_ch=[];

lastunitofchannel=0; % flag: turns on when end of channel is detected

try
    h=waitbar(0,'Converting NEX to SPK format');
    for nn=1:numunits
        waitbar(nn/numunits);
        waveforms_temp=nexstruct.waves{nn,1}.waveforms'*1000; % multiply by 1000 (Plexon uses mV, SPK uses µV)
        spiketimes_temp=nexstruct.waves{nn,1}.timestamps;

        sortID_temp=int8(ones(length(spiketimes_temp),1))*(nexstruct.waves{nn,1}.unitNumber); 
        channelID_temp=uint16(ones(length(spiketimes_temp),1))*(nexstruct.waves{nn,1}.wireNumber);
        
        
        
        waveforms_ch=[waveforms_ch;waveforms_temp];
        spiketimes_ch=[spiketimes_ch;spiketimes_temp];
        sortID_ch=[sortID_ch;sortID_temp];
        channelID_ch=[channelID_ch;channelID_temp];
        
        if nn+1>numunits % last unit of file
             lastunitofchannel=1; 
        else
            if nexstruct.waves{nn+1,1}.wireNumber>nexstruct.waves{nn,1}.wireNumber;
             lastunitofchannel=1;
            end
        end
        
        nexstruct.waves{nn,1}=[];
        
        if lastunitofchannel % whenever the last unit of a channel is detected, order the waveforms, sortIDs along by time (as e.g. WaveClus does)
            
            [spiketimes_ch idx]=sort(spiketimes_ch); % sort the times of a channel and save order
            waveforms_ch=waveforms_ch(idx,:); % save waveforms with order of time
            sortID_ch=sortID_ch(idx); % save waveforms with order of time
            channelID_ch=channelID_ch(idx); % save waveforms with order of time

            waveforms=[waveforms; waveforms_ch];
            spiketimes=[spiketimes; spiketimes_ch];
            sortID=[sortID; sortID_ch];
            channelID=[channelID; channelID_ch];

            spiketimes_ch=[];
            waveforms_ch=[];
            sortID_ch=[];
            channelID_ch=[];

            lastunitofchannel=0; % reset end of channel
        end
 
    end
    close(h);
    
catch exception
    close(h);
    rethrow(exception);
end


SPK.waveforms=waveforms;
SPK.sortID   =sortID;
SPK.channelID=channelID;
SPK.spiketimes=spiketimes;

