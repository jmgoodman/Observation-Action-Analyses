%Batch, Import Digital IO from NEV files. Only for Kinematic Recordings

path='C:\Users\S.Schaff\Desktop\Kinematic Recordings\Kinematics Recording Day7\';
recfile={'recording7a.mat','recording7b.mat'};
nevfile={'recording7a.nev','recording7b.nev'};

m1=128; % rec10,9,8,7,6
m2=131; %

for ii=1:length(recfile)
    load([path recfile{ii}]);
    [spikes digitalIO]=import([path nevfile{ii}],'Blackrock');

    [ktimes digitalIO]=getKinematicTimes(digitalIO,[m1 m2]);
    [recordingtemp]=merger(recording,ktimes);
    recordingtemp(end,2:8,:)=nan;
    recarray{ii}=recordingtemp;

    [channelstemp statetemp trialtemp]=parsedigitalIO(digitalIO);
    statearray{ii}=statetemp;
    trialarray{ii}=trialtemp;
    
end

recording=recarray{1};
trial=trialarray{1};
state=statearray{1};

if length(recfile)>=2

for ll=1:length(recfile)-1    
    maxtime=max(max(recording(:,1,2)),max(trial.end))+60;
    
    rectemp=recarray{ll+1};
    rectemp(:,1,2)=rectemp(:,1,2)+maxtime;
    recording=[recording;rectemp];
    
    statetemp=statearray{ll+1};
    trialtemp=trialarray{ll+1};
    trialtemp.start=trialtemp.start+maxtime;
    trialtemp.end  =trialtemp.end  +maxtime;
    statetemp.time =statetemp.time +maxtime;
    
    state.data=[state.data statetemp.data];
    state.time=[state.time statetemp.time];
    
    trial.start=[trial.start trialtemp.start];
    trial.end  =[trial.end   trialtemp.end];
    trial.grip =[trial.grip  trialtemp.grip];
end

else
    recording=recarray{1};
    state    =statearray{1};
    trial    =trialarray{1};
end


% % make 1 file:
% 
% maxtime1=max(max(recording1(:,1,2)),max(trial1.end))+60;
% recording2(:,1,2)=recording2(:,1,2)+maxtime1;
% recording=nan(size(recording1,1)+size(recording2,1),8,7);
% 
% recording(1:size(recording1,1),:,:)=recording1;
% recording(size(recording1,1)+1:end,:,:)=recording2;
% 
% 
% state2.time =state2.time+maxtime1;
% trial2.start=trial2.start+maxtime1;
% trial2.end  =trial2.end+maxtime1;
% 
% % state.data=nan(1,size(state2.time,2)+size(state1.time,2));
% % state.time=nan(1,size(state2.time,2)+size(state1.time,2));
% 
% state.data=[state1.data state2.data];
% state.time=[state1.time state2.time];
% state.name=state1.name;
% 
% trial.start=[trial1.start trial2.start];
% trial.end=[trial1.end trial2.end];
% trial.grip=[trial1.grip trial2.grip];
% 
save([path 'Rec_merged.mat'],'GHO','LHO','SY','state','trial','recording')







