function [spktimes] = getspktimes(SPK,ch,sortid,timewin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               GET SPIKE TIMES WITHIN GIVEN TIME WINDOW 
% DESCRIPTION: 
%
% Tis function returns the spike event times of a specified neuron and a
% specified time window
%
% SYNTAX:   [spiketimes] = getspikes(SPK,ch,sortid,[tstart, tstop])
%            
%            SPK       ... SPKOBJ
%            ch        ... channel
%            sortid    ... sort ID neuron on channel ch
%            timewin   ... vector of size (1,2) inclding tstart and tstop
%            
%            
%
% EXAMPLE: [spiketimes] = getspikes(SPK,3,2,[33, 34])
%
% ©Stefan Schaffelhofer                                            FEB 2012
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if timewin(1,1)>timewin(1,2)
    error('Time window is not specified correctly.');
end

spktimes=SPK.spiketimes;
channels=SPK.channelID;
sID  =SPK.sortID;

timeidx=spktimes>=timewin(1,1) & spktimes<timewin(1,2);
spktimes=spktimes(timeidx);
channels=channels(timeidx);
sID  =sID(timeidx);

spktimes=spktimes(channels==ch & sID==sortid);




