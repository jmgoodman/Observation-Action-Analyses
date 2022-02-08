function ok=spkobj2plexon(SPK,filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           CONVERT SPKOBJ INTO PLEXON FORMAT *.NEX
%
%DESCRIPTION: This routine exports the waveforms and spiketimes located in
%a spkobj into a *.NEX file. NEX files can be read by Plexon Offline
%Sorter. 
%
%
%SYNTAX: ok = spkobj2plexon(SPK, filename, chpf)
%            
%            SPK      ... spkobj includes waveforms and time-stamps
%            filename ... path and filename of *.NEX file
%            chpf     ... channels per file. e.g. 64
%
%EXAMPLE: ok = raw2wClus(Recording2a_raw_ch151, 
%                       'Volumes/data/Tanks/Zara/Recording2a/Wave_Clus')
%
%AUTHOR: ©Stefan Schaffelhofer, German Primate Center            6.Dez 2011
%last modified: 
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ERROR-CHECKING

if ~(isobject(SPK) && (strcmpi(class(SPK),'spkobj') || isstruct(SPK)))
    error('Wrong type of input argument.');
end

[pathstr, ~, ~]=fileparts(filename);
if ~isdir(pathstr)
    error('Path is non-existent or not a directory.');
end



% CREATING NEX STRUCTURE
sr=SPK.samplingrate;
nexstruct.version=101;
nexstruct.comment='';
nexstruct.freq=sr;
nexstruct.tbeg=0;
nexstruct.tend=max(SPK.spiketimes);


% EXTRACTING SPIKES FROM SPKOBJ
nch=max(SPK.channelID);
nexstruct.waves=cell(nch,1);

sortid=SPK.sortID+1;                                                   % add 1 to sort id because: plexon saves unsorted spikes with sortid 1, in SPKOBJ, unsorted spikes are marked with zeros;

if isempty(sortid) || max(sortid)==1 % if spikes are unsorted 
    for ii=1:nch
        disp(['Extracting Ch' num2str(ii)]);
        ids=SPK.channelID==ii;
    %     sortids_temp=SPK.sortids(ids,:);
        waveforms_temp=SPK.waveforms(ids,:)/1000; % divided by 1000 to get MV
        spiketimes_temp=SPK.spiketimes(ids,:);

        nexstruct.waves{ii,1}.waveforms=waveforms_temp';
        nexstruct.waves{ii,1}.timestamps=spiketimes_temp;
        nexstruct.waves{ii,1}.wireNumber=ii-1;
        nexstruct.waves{ii,1}.unitNumber=1;  % 1 is unsorted in NEX Format
        nexstruct.waves{ii,1}.name=['sig' num2str(ii)];
        nexstruct.waves{ii,1}.varVersion=101;
        nexstruct.waves{ii,1}.NPointsWave=size(waveforms_temp,2);
        nexstruct.waves{ii,1}.WFrequency=sr;
        
        nexstruct.waves{ii,1}.MVOfffset=0;
        
        wmin = min(min(waveforms_temp));
        wmax = max(max(waveforms_temp));
        c = max(abs(wmin),abs(wmax));
        if (c == 0)
            c = 1;
        else
            c = c/32767;
        end
        ADtoMV=c;
        nexstruct.waves{ii,1}.ADtoMV=ADtoMV;

    end
else % if spikes are already pre-sorted
    ll=1;
    for ii=1:nch % for all channels
        disp(['Extracting Ch' num2str(ii)]);
        ids=SPK.channelID==ii;
        waveforms_temp=SPK.waveforms(ids,:)/1000; % divided by 1000 to get MV
        spiketimes_temp=SPK.spiketimes(ids,:);
        sortids_temp=sortid(ids,:);% sort ids of a channel
        nrid=max(sortids_temp); % number of units found on this channel
        
        wmin = min(min(waveforms_temp));
        wmax = max(max(waveforms_temp));
        c = max(abs(wmin),abs(wmax));
        if (c == 0)
            c = 1;
        else
            c = c/32767;
        end
        ADtoMV=c;
        
        
        for nn=1:nrid% for all neurons of a channel
            ids2=sortids_temp==nn;
            waveforms_temp2=waveforms_temp(ids2,:);
            spiketimes_temp2=spiketimes_temp(ids2,:);
            
            nexstruct.waves{ll,1}.waveforms=waveforms_temp2';
            nexstruct.waves{ll,1}.timestamps=spiketimes_temp2;
            nexstruct.waves{ll,1}.wireNumber=ii-1; % wire number starts at 0 in NEX format
            nexstruct.waves{ll,1}.unitNumber=nn;  % 1 is unsorted in NEX Format
            nexstruct.waves{ll,1}.name=['sig' num2str(ii)];
            nexstruct.waves{ll,1}.varVersion=101;
            nexstruct.waves{ll,1}.NPointsWave=size(waveforms_temp,2);
            nexstruct.waves{ll,1}.WFrequency=sr;
            nexstruct.waves{ll,1}.ADtoMV=ADtoMV;
            nexstruct.waves{ll,1}.MVOfffset=0;
            ll=ll+1;
        end % end for neurons
    end % end for ch
        
end
clear SPK;
disp('Start writing NEX file ...');
ok=writeNex(nexstruct,filename);
disp('NEX export finished!');