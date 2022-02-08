function [SPK] = wClus2spkobj(SPK,NO, tank)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               TAKES WAVE_CLUS-FILES AND CREATES A SPKOBJ
%
%DESCRIPTION: This routine takes the the waveClus-files of all channels in
% 'tank' and stores them in a spkobj and neuronobj.
%
%HELPFUL INFORMATION: 
%
%SYNTAX: SPK = wClus2spkobj(spkobj, tank)
%            necessary inputs are marked with *
%            spkobj*    ... SPKOBJ
%            neuronobj* ... NEURONOBJ
%            tank*      ... path string where the channel-folders with the
%                      WaveClus-files are stored
%
%EXAMPLE: [Recording2a_SPK Recording2a_NO] = wClus2spkobj(spkobj, 
%                       'Volumes/data/Tanks/Zara/Recording2a/Wave_Clus')
%
%AUTHOR: ©Katharina Menz, German Primate Center                     Aug2011
%last modified: Katharina Menz                                   22.08.2011
%               Stefan Schaffelhofer                             20.09.2011
%               Stefan Schaffelhofer                             12.12.2011
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

c = tic;

%######################## CHECK INPUT PARAMETERS ##########################

if nargin ~= 3                   %check number of input arguments
    error(['Not enough or too many inpug arguments: Input parameters are "spik" and "tank", where the channel-folders' ...
       ' with WaveClus-files are stored.']);
end


%check spkobj input
if isobject(SPK) == 0        %check if spkobj is an object
    error('Wrong input parameter: First input parameter has to be a spkobj.');
else
    if strcmpi(class(SPK), 'spkobj') == 0    %check if spkobj is a spkobj
        error('Wrong input parameter: First input parameter has to be a spkobj.');
    end
end

%check neuronobj input
if isobject(NO) == 0        %check if neuronobj is an object
    error('Wrong input parameter: Second input parameter has to be a neuronobj.');
else
    if strcmpi(class(NO), 'neuronobj') == 0    %check if spkobj is a neuronobj
        error('Wrong input parameter: Second input parameter has to be a neuronobj.');
    end
end

%check tank input
if ischar(tank) == 0            %check if tank is a string
    error('Wrong input argument: Second input parameter has to be a string specifying a folder.')
end

if isdir(tank) == 0             %check if tank is a folder
    error('Wrong input argument: Second input parameter has to be an existing folder.');
end


%############################ SAVE AS SPK ##############################


content = dir(tank);                                                        %list all files folders in "tank"
numfiles=length(content);

idx=1;
for ff=1:numfiles                                                          % scan file names
    tempname=content(ff,1).name;
    charpos=strfind(tempname,'Channel');
    if ~isempty(charpos)
      channels(idx)=str2double(tempname(charpos+7:end));                   % save the number of each channel folder
      idx=idx+1;
    end
end

channels=sort(channels);                                                   % sort the channel numbers in ascending order

parent1 = fileparts(tank);
[~, rec_name] = fileparts(parent1);       
neuron=1;
for ii = 1:length(channels)
    ch=channels(ii);
    display(['Scanning folder "Channel' num2str(ch) '".'])                 % display what channel is processed at the movement
    
    load([tank '\Channel' num2str(ch) '\times_Ch' ...
          num2str(ch) '_spikes.mat'],'cluster_class','spikes', 'par')               % load sort ids and spike times from WaveClus file
    
    load([tank '\Channel' num2str(ch) '\Ch' ...
          num2str(ch) '_spikes.mat'],'info');
    
    % spike times
    spkt=SPK.spiketimes;
    spkt=[spkt; single(cluster_class(:,2)/1000)];
    SPK.spiketimes=spkt;
         
    % sort ID
    sortid=SPK.sortID;
    sortid=[sortid; int8(cluster_class(:,1))];
    SPK.sortID=sortid;
    
    % channel ID
    len = length(cluster_class);
    channelid=SPK.channelID;
    channelid=[channelid; uint16(ch*ones(len,1))];
    SPK.channelID=channelid;
    
    % waveforms
    wf=SPK.waveforms;
    wf=[wf; single(spikes)];
    SPK.waveforms=wf;
    
    % threshold
    th=SPK.threshold;
    th{1,ch}=info.par.thr;
    SPK.threshold=th;
    
    % pretrigger
    pretrig=SPK.pretrigger;
    pretrig{1,ch}=info.par.w_pre;
    SPK.pretrigger=pretrig;

    % posttrigger
    posttrig=SPK.posttrigger;
    posttrig{1,ch}=info.par.w_post;
    SPK.posttrigger=posttrig;
    
    % noiselevel
    nl=SPK.noiselevel;
    nl{1,ch}=info.par.noisestd;
    SPK.noiselevel=nl;
    
%     numspikes=size(cluster_class(:,1),1);                                  % number of overall spikes of unit
%     numunits=max(cluster_class(:,1));                                      % number of units per channel
%    
%     for nn=1:numunits    % preparing neuron object
%         nidx=find(cluster_class==nn);
%         numspkperunit=length(nidx);
%         
%         times=cluster_class(nidx,2)/1000;
%         recordingtime=max(times);
%         interspiketimes=times(2:end)-times(1:end-1);
%         refperiod=sum(interspiketimes<=0.003);
%         waveforms=spikes(nidx,:);                                          
%         mwf=mean(waveforms);                                               % mean waveforms
%         stdev=std(waveforms);                                              % standard deviation of waveforms
%         numspksinperc=numspkperunit*100/numspikes;                         % calculates the number of spikes (in percent in respect to all detected spikes)
%         basef=numspkperunit/recordingtime;                                 % baseline frequency in Hz
%         
%         neuronID=get(NO,'neuronID');
%         NO=set(NO,'neuronID',[neuronID,neuron]);
%         
%         sortID=get(NO,'sortID');
%         NO=set(NO,'sortID',[sortID,nn]);
%         
%         channelID=get(NO,'channelID');
%         NO=set(NO,'channelID',[channelID,ch]);
%         
%         totalSpikesRatio=get(NO,'totalSpikesRatio');
%         NO=set(NO,'totalSpikesRatio',[totalSpikesRatio,numspksinperc]);
%         
%         spksinrefperiod=get(NO,'spksInRefPeriod');
%         NO=set(NO,'spksInRefPeriod',[spksinrefperiod,refperiod]);
%         
%         meanWaveform=get(NO,'meanWaveform');
%         NO=set(NO,'meanWaveform',[meanWaveform;mwf]);
%         
%         stDevFromWaveform=get(NO,'stDevFromWaveform');
%         NO=set(NO,'stDevFromWaveform',[stDevFromWaveform;stdev]);
%         
%         baselineFreq=get(NO,'baselineFreq');
%         NO=set(NO,'baselineFreq',[baselineFreq,basef]);
%         
%         ISIT=get(NO,'ISIT');
%         NO=set(NO,'ISIT',[ISIT,interspiketimes]);
%         
%         neuron=neuron+1;
%     end    
end

sr = par.sr;
SPK = set(SPK, 'samplingrate', sr);

w_pre = par.w_pre;
triggertime = w_pre/sr;
SPK = set(SPK, 'physicalunit', 'µV');


%############################ Create Neuronobj ############################

t = toc(c);
display(['Creation of SPK took ' num2str(t) ' sec, which is ' num2str(t/60) ' min.'])
display(['SPKOBJ was extracted sucessfully.']);
