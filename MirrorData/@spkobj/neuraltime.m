function [nstruct] = neuraltime(varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                   PREPARE MATRIX FOR POPULATION PCA ANALYSIS
% DESCRIPTION: 
%
% This function prepares a matrix for performing pca analysis over time.
% This matrix includes gauss-smoothed firing rate over time (t) of each neuron (n) 
% and each grip/trial (c). Therefore the matrix dimensions are (n x t x c).
%
% 
% SYNTAX:  []=poppca()
%            
%
% EXAMPLE:
%    []=poppca()
%
% last modified: Stefan Schaffelhofer                            30.09.2012
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% ----------------------ERROR CHECKING------------------------------------

%check SPKOBJ
if isobject(varargin{1}) == 0                                              %check if third input argument is an object
    error('Wrong input argument: Third input argument has to be a SPKOBJ.');
else
    if strcmpi(class(varargin{1}), 'spkobj') == 0
        error('Wrong input argument: Third input argument has to be a SPKOBJ.');
    else
    SPK = varargin{1};
    end
end

%check TRIALOBJ
if isobject(varargin{2}) == 0                                              %check if second input argument is an object
    error('Wrong input argument: Second input argument has to be a TRIALOBJ.');
else
    if strcmpi(class(varargin{2}), 'trialobj') == 0
        error('Wrong input argument: Second input argument has to be a TRIALOBJ.');
    else
        TO = varargin{2};
    end
end
 
%check EPOCHOBJ
if isobject(varargin{3}) == 0                                              %check if fourth input argument is an object
    error('Wrong input argument: 3rd input argument has to be an EPOCHOBJ.');
else
    if strcmpi(class(varargin{3}), 'epochobj') == 0
        error('Wrong input argument: 3rd input argument has to be an EPOCHOBJ.');
    else
    ST = varargin{3};
    end
end

%check NEURONOBJ
if isobject(varargin{4}) == 0                                              %check if third input argument is an object
    error('Wrong input argument: 4th input argument has to be a NEURONOBJ.');
else
    if strcmpi(class(varargin{4}), 'neuronobj') == 0
        error('Wrong input argument: 4th input argument has to be a NEURONOBJ.');
    else
    NO = varargin{4};
    end
end


sigmacheck   = 0;
timescheck   = 0;
aligncheck   = 0;
savecheck    = 0;
srcheck      = 0;

for ii = 1:numel(varargin)
    if strcmpi(varargin{ii}, 'sig')
        sigid       = ii+1;
        sigmacheck  = 1;
    elseif strcmpi(varargin{ii}, 'times')
        timesid    = ii+1;
        timescheck = 1;
    elseif strcmpi(varargin{ii}, 'alignment')
        alignid     = ii+1;
        aligncheck  = 1;
    elseif strcmpi(varargin{ii}, 'sr')
        srid     = ii+1;
        srcheck  = 1;
    end
end

%check 'alignment' input
if aligncheck == 0
    error('Not enough input paramaters: "Alignment" must be given.');
else
    alignment = varargin{alignid};
end

%check 'sig' input
if sigmacheck == 0      
    sig = 0.050;                                                           %default value for sig
else
    sig = varargin{sigid};
end

if isnumeric(sig) == 0
    error('Wrong input argument: "sig" has to be a number.');
end

if srcheck == 0      
    sr = 50;                                                           %default value for sig
else
    sr = varargin{srid};
end

if isnumeric(sr) == 0
    error('Wrong input argument: "sig" has to be a number.');
end

%check 'time window' input      
if timescheck == 0
    error('Not enough input parameters: Time window must be given as a two-dim. vector.');
else 
    T1 = varargin{timesid};
    if isnumeric(T1) == 0                                                   %check if time window-input argument is a not a string
        error('Wrong input argument: Input argument for "time window" has to be a 2dim row vector with start and end time (in ms).');
    end

    if isequal(size(T1,2), 2) == 0                                          %check if time window-input argument is an 2-dim row vector
        error('Wrong input argument: Input argument for "time window" has to be a 2dim row vector with start and end time (in ms).');
    end
    
    for ll=1:size(T1,1)
        if isequal(size(T1), [1 2]) == 1
            if T1(ll,1) > T1(ll,2)                                           %check if specified time window is valid
                error('Wrong input argument: First component in the input argument for "time window" has to be smaller than the second component, since this vector specifies a time window.');
            end

            if T1(ll,1) == T1(ll,2)                                          %check if specified time window has a duration greater than zero
                error('Wrong input argument: Specified time window has a duration of zero.');
            end
        end
        T2(ll,1) = T1(ll,1)-8*sig; 
        T2(ll,2) = T1(ll,2)+8*sig;
    end
    
end
T=1/sr;
edges=-4*sig:1/sr:4*sig; 
kernel = normpdf(edges,0,sig);
kernel=kernel*1/sr;
center=ceil(length(edges)/2);

%%---------------------------------PLOT------------------------------------

st=ST.value; % states over time
numneurons = numel(NO.neuronID);
numtrials  = numel(TO.trialCorrect==1);

trialNr=1:numtrials;
ctr=trialNr(TO.trialCorrect==1);

gt=TO.gripType;
gt=gt(ctr);

numctr=numel(ctr);
channelID=SPK.channelID;
spiketimes=SPK.spiketimes;

nochannelid=NO.channelID;
nosortid   =NO.sortID;
numalign=size(alignment,2);


pcaarray=cell(numalign,8);

for al=1:numalign
    align=alignment{al};                                               % get alignment
     switch align                                                           
        case 'cue'
            alignInd     = st(:,2) == 5;
            aligntimes   = st(alignInd,1); 
        case 'mem'
            alignInd     = st(:,2) == 6;
            aligntimes   = st(alignInd,1); 
        case 'go'
            alignInd     = st(:,2) == 8;
            aligntimes   = st(alignInd,1); 
        case 'hold'
            alignInd     = st(:,2) == 9;
            aligntimes   = st(alignInd,1); 
     end
    
    time=T2(al,1):T:T2(al,2);
    timeid=time>=T1(al,1) & time<=T1(al,2);
    numsamples=sum(timeid);
    datamatrix=nan(numctr,numneurons,numsamples);
    markermatrix=nan(numctr,5);
    markernames={'Center time','Fixation','Cue','Memory','Go','Hold','Hold off'};
     
    fixtimes =st(st(:,2)==4);
    cuetimes =st(st(:,2)==5);
    memtimes =st(st(:,2)==6);
    gotimes  =st(st(:,2)==8);
    holdtimes=st(st(:,2)==9);
    rewtimes =st(st(:,2)==10);
    
    
    time=T2(al,1):T:T2(al,2);

    for nn=1:numneurons
        ch=nochannelid(nn); % get channel id of this neuron
        sID=nosortid(nn);   % get sort id of this neuron

        idn=channelID==ch & SPK.sortID==sID; % use channel and sort id to identify the spiketimes of this unint within the spikeobject 
        spktimes=spiketimes(idn); % save spike times

        trialTimes(:,1) = TO.trialStart;                               % trialTimes: each row gives start and stop time of trial
        trialTimes(:,2) = TO.trialStop;                                       

        for tr=1:numctr % for all correct trials
                
                trid=ctr(tr);
                trialTime = trialTimes(trid,:);                                 % take only correct trials with right griptype

                at         = aligntimes(aligntimes>=trialTime(1,1) & aligntimes<=trialTime(1,2));
                fixmarker  = fixtimes(fixtimes>=trialTime(1,1) & fixtimes<=trialTime(1,2))-at;
                cuemarker  = cuetimes(cuetimes>=trialTime(1,1) & cuetimes<=trialTime(1,2))-at;
                memmarker  = memtimes(memtimes>=trialTime(1,1) & memtimes<=trialTime(1,2))-at;
                gomarker   = gotimes(gotimes>=trialTime(1,1) & gotimes<=trialTime(1,2))-at;
                holdmarker = holdtimes(holdtimes>=trialTime(1,1) & holdtimes<=trialTime(1,2))-at;
                rewmarker  = rewtimes(rewtimes>=trialTime(1,1) & rewtimes<=trialTime(1,2))-at;

                spikesInd=(spktimes>=(at+T2(al,1))) & (spktimes<=(at+T2(al,2)));
                spikes=spktimes(spikesInd);                               % spike times of a neuron for given time window
                spikes=spikes - at;

                
                spikesbin=histc(spikes,time);
                
                s=conv(spikesbin,kernel);
                s=s(center:end-center); % s does now have the same length as time, both s and time are cut out later to be in range T1
                
                s=s(timeid);
                
                f=s*sr;
                datamatrix(tr,nn,:)=f;
                
                if nn==1 % do it only for the first unit, since the trial times are identical for all units
                    markermatrix(tr,1)=at;
                    markermatrix(tr,2)=fixmarker;
                    markermatrix(tr,3)=cuemarker;
                    markermatrix(tr,4)=memmarker;
                    markermatrix(tr,5)=gomarker;
                    markermatrix(tr,6)=holdmarker;
                    markermatrix(tr,7)=rewmarker;
                end
                

                

        end  % of trials
   
    end % of neurons
    
    pcaarray{al,1}=align;
    pcaarray{al,2}=datamatrix;
    pcaarray{al,3}=markermatrix;
    pcaarray{al,4}=markernames;
    pcaarray{al,5}=ctr;
    pcaarray{al,6}=gt;
    pcaarray{al,7}=time(timeid);
    pcaarray{al,8}=nochannelid;
    pcaarray{al,9}=[];
    
end %

nstruct=cell2struct(pcaarray,{'alignname','data','marker','markernames','trid','gripid','time','channelid','sd'},2);





















