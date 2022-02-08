function SPK = cut(SPK,cuttimes)
% cut out a specified time-window from 

tstart=cuttimes(1,1);
tstop =cuttimes(1,2);

time      = SPK.spiketimes(:,1);

if tstart<=min(time) || tstop>=max(time)
    error('Time frame longer than available data.');
end

sel = time>=tstart & time<=tstop;

if ~isempty(SPK.waveforms)
    SPK.waveforms  = SPK.waveforms(sel,:);
end

SPK.spiketimes = SPK.spiketimes(sel,1);
SPK.sortID     = SPK.sortID(sel,1);
SPK.channelID  = SPK.channelID(sel,1);
