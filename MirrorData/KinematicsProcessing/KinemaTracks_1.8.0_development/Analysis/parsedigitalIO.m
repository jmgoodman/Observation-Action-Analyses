function [channels state trial]=parsedigitalIO(dIO)

% find double or trible values in digitalIO stream and remove them (only
% for Blackrocksystems that are making troubles

didx=zeros(length(dIO.Data),1);
for ii=1:length(dIO.Data)-1
    if dIO.Data(ii)==dIO.Data(ii+1)
        didx(ii)=1;
    end
end

% remove the double / trible values

idx=find(didx==1);
dIO.Data(idx)        =[];
dIO.TimeStamp(idx)   =[];
dIO.TimeStampSec(idx)=[];


% parse the digitalIO data for complete trials and save the header
% information, start and stop times
trstart = find(dIO.Data==253);
notcompletedTrials=0;
tr=1; % set first trial
cr=1;
for ii=1:length(trstart)-1  
    thisstart=trstart(ii);
    nextstart=trstart(ii+1);
    hdstidx = find(dIO.Data(thisstart:nextstart)==255);
    hdedidx = find(dIO.Data(thisstart:nextstart)==254);
    
    if numel(hdstidx)==1 && numel(hdedidx)==1
%         trial(tr).start=dIO.TimeStampSec(thisstart);
%         trial(tr).end  =dIO.TimeStampSec(hdedidx);
        header{tr}=native2unicode(dIO.Data(thisstart+hdstidx:thisstart+hdedidx-2))';
        tempheader=header{tr};
        correct=str2num(tempheader(findstr(tempheader,'Trial corect')+length('Trial corect')+1:findstr(tempheader,'Trial corect')+length('Trial corect')+2)); %#ok<ST2NM>
        
        if correct
            if cr==202;
                stop=1;
            end
            trial.start(cr)=dIO.TimeStampSec(thisstart);
            trial.end(cr)  =dIO.TimeStampSec(thisstart+hdedidx);
            trial.grip(cr) =str2num(tempheader(findstr(tempheader,'Grip Type')+length('Grip Type')+1:findstr(tempheader,'Grip Type')+length('Grip Type')+2)); %#ok<ST2NM>
            cr=cr+1;
        end
        
        dIO.Data(thisstart+hdstidx:thisstart+hdedidx-2)=266; % marker for header
        tr=tr+1;
    else
        notcompletedTrials=notcompletedTrials+1;
    end
end

% delete the samples that are header samples in order to delete them

headeridx=find(dIO.Data==266);
dIO.Data(headeridx)=[];
dIO.TimeStamp(headeridx)=[];
dIO.TimeStampSec(headeridx)=[];


% the resuming data is parsed to get digitalIO channnels and state channel

ss  =1;  %state sample
ch1 =1;  %channel 1 sample
ch2 =1;  %channel 2 sample
ch3 =1;  %...
ch4 =1;
ch5 =1;
ch6 =1;
ch7 =1;

for ii=1:length(dIO.Data)
    cn=dIO.Data(ii);
    tt=dIO.TimeStampSec(ii);
    if (cn>0 && cn<=15) % 1-15 are reserved values for the behavioural state in the task
        cn=1; 
    end
    switch cn  
        case 1 % for all states
            state.data(ss)=dIO.Data(ii);
            state.time(ss)=tt;
            ss=ss+1;
        case 31 % for digital input 1 "high"
            channel(1).data(ch1)=1;
            channel(1).time(ch1)=tt;
            ch1=ch1+1;
        case 32 % for digital input 1 "low'
            channel(1).data(ch1)=0;
            channel(1).time(ch1)=tt;
            ch1=ch1+1;
        case 33
            channel(2).data(ch2)=1;
            channel(2).time(ch2)=tt;
            ch2=ch2+1;
        case 34
            channel(2).data(ch2)=0;
            channel(2).time(ch2)=tt;
            ch2=ch2+1;
        case 35
            channel(3).data(ch3)=1;
            channel(3).time(ch3)=tt;
            ch3=ch3+1;
        case 36
            channel(3).data(ch3)=0;
            channel(3).time(ch3)=tt;
            ch3=ch3+1;
        case 37
            channel(4).data(ch4)=1;
            channel(4).time(ch4)=tt;
            ch4=ch4+1;
        case 38
            channel(4).data(ch4)=0;
            channel(4).time(ch4)=tt;
            ch4=ch4+1;
        case 39
            channel(5).data(ch5)=1;
            channel(5).time(ch5)=tt;
            ch5=ch5+1;
        case 40
            channel(5).data(ch5)=0;
            channel(5).time(ch5)=tt;
            ch5=ch5+1;
        case 41
            channel(6).data(ch6)=1;
            channel(6).time(ch6)=tt;
            ch6=ch6+1;
        case 42
            channel(6).data(ch6)=0;
            channel(6).time(ch6)=tt;
            ch6=ch6+1;
        case 43
            channel(7).data(ch7)=1;
            channel(7).time(ch7)=tt;
            ch7=ch7+1;
        case 44
            channel(7).data(ch7)=0;
            channel(7).time(ch7)=tt;
            ch7=ch7+1;
        otherwise
    end
end

channels.channel=channel;
channels.name{1,1}='Pull';
channels.name{2,1}='Light Barrier Handle';
channels.name{3,1}='Button Precision Left';
channels.name{4,1}='Button Precision Right';
channels.name{5,1}='Handrest Right';
channels.name{6,1}='Handrest Left';
channels.name{7,1}='Light Barrier Object Lift';


state.name{1,1}='Trial Start';
state.name{1,2}=0;
state.name{2,1}='Handrest';
state.name{2,2}=1;
state.name{3,1}='Optional Reward';
state.name{3,2}=2;
state.name{4,1}='Motor';
state.name{4,2}=3;
state.name{5,1}='Fixation Period';
state.name{5,2}=4;
state.name{6,1}='Cue';
state.name{6,2}=5;
state.name{7,1}='Memory Period';
state.name{7,2}=6;
state.name{8,1}='Reaction Time';
state.name{8,2}=7;
state.name{9,1}='Grasping Go';
state.name{9,2}=8;
state.name{10,1}='Hold';
state.name{10,2}=9;
state.name{11,1}='Initiate Reward';
state.name{11,2}=10;
state.name{12,1}='Reward';
state.name{12,2}=11;
state.name{13,1}='Intertrial Interval';
state.name{13,2}=12;
state.name{14,1}='Wait After Error';
state.name{14,2}=13;
state.name{15,1}='Trial End';
state.name{15,2}=14;
state.name{16,1}='Pause';
state.name{16,2}=15;


















