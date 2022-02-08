%%
clearvars %-except q 
clc,close all
restoredefaultpath;

%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% begin user input
%% global inputs

Animal = 'Jameson_L';
Session = 1; % use only completed sessions here...
SessionStructRunOutputDir = 'F:\'; % probably best to set this to a local directory; this is a large local data drive for me (>2TB)
network_mapped_drive_server_users_dir = 'B:\'; % you'll need to map a network drive to work with Vicon...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %auto-set
    server_users_dir  = '\\bensmaia-lab\LabSharing\';
    master_output_dir = [SessionStructRunOutputDir,sprintf('%sSession%0.2iStructRunOutput\\',Animal,Session)];
    session_data_dir  = sprintf('%sProprioception\\%s\\Session %0.2i\\',network_mapped_drive_server_users_dir,...
        Animal,Session); % watch for whether this is a space or an underscore between "Session" and the number!
    extended_data_dir = sprintf('%sProprioception\\%s\\Session %0.2i\\',server_users_dir,...
        Animal,Session); % watch for whether this is a space or an underscore between "Session" and the number!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Vicon Voltages Inputs
% note: Vicon 2.x needs to be ACTIVELY RUNNING in a separate window for
% this to work!

run_vicon_voltages = false;


vicon_matlab_dir = 'C:\Program Files (x86)\Vicon\Nexus2.0\SDK\Win64\Matlab\'; % varies by machine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %auto-set
    session_dir                    = [session_data_dir,sprintf('Vicon\\Session %0.2i\\',Session)];
    vicon_voltage_output_file      = [master_output_dir,'vicon_voltage_pulses.mat'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% cerebus inputs

run_cerebus_voltages = false;
run_spike_time_fetch = true; % note: this will auto-fetch the first NEV file (alphabetically) from the NEV directory. Make sure to remove the unsorted NEV from the Neural folder prior to running this script!!
% welp. looks like this spikes still need to be sorted...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % auto-set
    neurdir_           = [session_data_dir,'Neural\'];
    cerebus_matlab_dir = '..\tools\Blackrock\'; % located on the server so it should be constant

    D = dir(neurdir_);
    whichisdir = find(arrayfun(@(x) x.isdir,D(3:end)))+2; % 3:end removes relative path entries
    neurdir    = [neurdir_,D(whichisdir(1)).name,'\'];

    D = dir(neurdir);
    islfp = find(arrayfun(@(x) ~isempty(regexpi(x.name,'^.*\.ns3$','once')),D));
    isnev = find(arrayfun(@(x) ~isempty(regexpi(x.name,'^.*\.nev$','once')),D));

    lfp_file_name = [neurdir,D(islfp(1)).name];
    nev_file_name = [neurdir,D(isnev(1)).name];

    cerebus_voltage_output_file  = [master_output_dir,'cerebus_voltage_pulses.mat'];
    spike_time_output_file       = [master_output_dir,'cerebus_spike_times.mat'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% shape data inputs

run_shape_fetch = false;


DataToolboxDir  = 'C:\DataToolbox\'; % again, this may vary by machine
RepositoryDir   = 'C:\somlab\repository\'; % something about my local copy of the repository jibes better with our nev files... something to do with tcv processing...
hardCodedTrials = [];
hardCodedObjIDs = {}; % should have the same number of entries as hardCodedTrials; these should either be shape-replacement strings OR numbers; numbers indicate that a lag occurs between stimcontrol & vicon at that trial, with the lag being n trials long

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % auto-set
    behav_fldr = [extended_data_dir,'Behavioral\'];

    D = dir(behav_fldr);

    is_sbf  = find(arrayfun(@(x) ~isempty(regexpi(x.name,'^.*\.sbf$','once')),D));
    datenos = arrayfun(@(x) x.datenum,D);

    valid_datenos = datenos(is_sbf);
    [~,mostrecentind] = max(valid_datenos);
    whichsbf = is_sbf(mostrecentind);

    sbf_file_name = [behav_fldr,D(whichsbf).name];
    shape_output_file = [master_output_dir,'shape_info.mat'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Neural Sync Times Fetch

% NOTE: this may be incomplete as of 07/27/2017: it's possible that I will
% need to implement a way to hard-code in the number of "cancelled" trials
% prior to each of these trials, as my simulated annealing optimization may
% be off by a few trials (we'll see how well the classification stacks
% up to see how necessary this is...)

run_sync = false; % this is always the scariest part... I hope it works this time!!! It's especially scary for Jameson Session 01, because NO NOTES were taken!!!
time_between_trials_in_s = 4.5; % may need to tweak this; the higher it is, the more points will be thrown out due to occurring too soon since the previous pulse, but conversely more points will be accepted due to a looser threshold
sign_arg = -1; % use this for Jameson's most recent data; prior to this, all the pulses were +ve deflections, but here, they're -ve...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % auto-set
    files_flag        = false;
    sync_output_file  = [master_output_dir,'sync_times.mat'];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%% IK

run_ik           = true;


gait_extract_dir = 'C:\Users\James\Proprioception_GitStuff\KinematicsExtract\'; % this may need to be local & not a server location (matlab c3d scripts may run into permissions issues, for instance)
osim_dir      = 'C:\Opensim 3.3\';
templates_dir = 'C:\Users\James\Proprioception_GitStuff\KinematicsExtract\Template_Files\';
model_file = 'C:\Users\James\Proprioception_GitStuff\KinematicsExtract\Model\BASE.osim'; % this is not relative to anything (osim dir is the program itself, not the model!)
rightflag  = false; % flips marker data so right-handed data can be used with left-handed models. set to false if the hand is left (i.e., the hemisphere is right)
muscleflag = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % auto-set
    ik_output_dir       = [master_output_dir,'ik\'];
    vicon_folder        = session_dir; % where the c3d files live
    ik_output_file      = 'IKstruct.mat'; % this will ALWAYS be relative to the output_dir input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% array info

% give target electrodes in terms of channel #s; unit counts will be
% automatically deduced

% see older versions of "MasterProcess" for unit IDs of older sessions

% % Jameson Session 12
% targs.area3a     = [];
% targs.prop2      = [68,71]';
% targs.cM1        = [];
% targs.rM1        = [2,5,6,14,15,18,19,22,25,26,27,59,61,63,106,115,121,125,127]';
% targs.cutaneous  = [42,45,53,55,60,65,66,67,69,75,77,78,81,83,87]';
% targs.PPC        = [];

% % Jameson Session 20 
% targs.area3a     = [];
% targs.prop2      = [42,69,79]';
% targs.cM1        = [];
% targs.rM1        = [4,14,15,18,21,24,25,104,106,113,117]';
% targs.cutaneous  = [92,39,41,47,48,49,53,55,57,75,85,58,91,38,51,78,80,82,88]';
% targs.PPC        = [];

% Jameson Session 01
targs.area3a     = [];
targs.prop2      = [34,44,58,65,78,79,80,82,96]'; % all on the posterior end of the array! that's good!
targs.cM1        = [];
targs.rM1        = [1,2,9,15,17,20,23,25,26,31,63,64,97,99,104,105,106,108,110,112,121,127]';
targs.cutaneous  = [35,39,42,48,51,52,54,55,56,57,62,67,69,72,73,77,87,91]';
targs.PPC        = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % auto-set
    % do NOT use the GMR coordinates for utah data (i.e., Jameson_L)
    ElectrodeCoords = []; %GMR_Spatial_Layout(rightflag); % right hand, left hemisphere, output is L(-)-to-R(+) (X) and P(-)-to-A(+)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    


%% 

%% end user input
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% start calling methods

% vicon voltages
if run_vicon_voltages
    vv = saveViconVoltages(vicon_matlab_dir,session_dir,vicon_voltage_output_file,100);
else
    vv = load(vicon_voltage_output_file); %#ok<*UNRCH>
    vv = vv.vv;
end

% cerebus voltages & LFP
if run_cerebus_voltages
    cv = loadCerebusVoltages(cerebus_matlab_dir,lfp_file_name,cerebus_voltage_output_file);
else
    cv = load(cerebus_voltage_output_file);
    cv = cv.vv;
end


% spike times
if run_spike_time_fetch
    nn = loadNEVdata(cerebus_matlab_dir,nev_file_name,spike_time_output_file);
else
    nn = load(spike_time_output_file);
    nn = nn.nn;
end


% shape data
if run_shape_fetch
    ss = loadShapeData(DataToolboxDir,RepositoryDir,sbf_file_name,shape_output_file,hardCodedTrials,hardCodedObjIDs);
else
    ss = load(shape_output_file);
    ss = ss.ss;
end


% sync times (adjusted as of 2019_06_17 - old simulated annealing process wasn't working well for large numbers of "missed" trials) (which means it probably wasn't working well to begin with, BUT the low mis-alignment means that, statistically speaking, it wasn't a huge deal that should substantially change our results) (which is evidenced by the very good-looking rasters with those trial alignments & registrations)
% because remember - you pruned the sessions with extremely bad-looking nonstationarities! and the worst ones were always jameson & ransom, never bacardi!!!
if run_sync
    Sync_Struct = TrialAlign_(vv,cv,files_flag,sync_output_file,time_between_trials_in_s,sign_arg);
else
    Sync_Struct = load(sync_output_file);
    Sync_Struct = Sync_Struct.Sync_Struct;
end


% IK
if run_ik
    IK = callIK(gait_extract_dir,ik_output_dir,vicon_folder,osim_dir,...
        templates_dir,model_file,ik_output_file,rightflag,muscleflag);
else
    IK = load([ik_output_dir,ik_output_file]);
    IK = IK.IK;
end

%% ArrayInfo
ArrayInfo.MetaTags         = nn.NEV.MetaTags;
ArrayInfo.ElectrodesInfo   = nn.NEV.ElectrodesInfo;
ArrayInfo.Electrodes       = nn.Electrodes;
ArrayInfo.VoltsPerDigit    = 2.5e-4*ones(96,1);
ArrayInfo.ExcludeIntervals = []; % not used anymore; sorting is done without removing between-trial intervals

fn = fieldnames(targs);
for i = 1:numel(fn)
    counts = zeros(size(targs.(fn{i})));
    
    for j = 1:numel(counts)
        elecno = targs.(fn{i})(j);
        are_elec = nn.Electrodes(:,1) == elecno;
        counts(j) = sum(are_elec);
    end
    
    targs.(fn{i}) = [targs.(fn{i}),counts];
end

ArrayInfo.TargetElectrodes = targs;

ArrayInfo.RelatvieElectrodeCoords_mm = ElectrodeCoords;
ArrayInfo.ElectrodeCoordColumnNames  = {'electrode number','L(-)/R(+) coordinate','P(-)/A(+) coordinate'};


%% Trials

Trials = struct('ViconTrial',{},'Object',{},'Events',{},'Kinematics',...
    {},'MuscTendLengths',{},'MuscleFiberLengths',{},'TendonLengths',{},...
    'MarkerXYZ',{},'Spikes',{},'LFP',{},'CerebusRange',{});

Ntrials = numel(IK.TrialNumber);

smoothDur = 0.050; % smooth with a 50ms-wide kernel (similar to the length of time used by the moving-average "smooth" function)

smoothMat = @(X,n) conv2(X,rectwin(n),'same')./conv2(ones(size(X)),rectwin(n),'same');

for i = 1:Ntrials
    %     tempStruct = struct('ViconTrial',{[]},'Object',{[]},'Events',{[]},'Kinematics',...
    %         {[]},'MuscTendLengths',{[]},'MuscleFiberLengths',{[]},'TendonLengths',{[]},...
    %         'MarkerXYZ',{[]},'Spikes',{[]},'LFP',{[]},'CerebusRange',{[]});
    
    SR = 1/median(diff(IK.TimeBins{i}));
    smoothSamples   = round(SR*smoothDur);
    
    Tno = IK.TrialNumber(i);
    which_trial = find(arrayfun(@(x) x.TrialNumber==Tno, Sync_Struct));
    
    if isempty(which_trial)
        continue
    end
    
    tempStruct.ViconTrial = Tno;
    tempStruct.Object     = ss{Tno}; % may need to tweak this in the event of off-by-1 syncing of Vicon trials to StimControl trials (although loadShapeData should tentatively have something in place to handle this... IK files will be numbered according to Vicon trials, and neural data alignment to the Vicon trials should account for misalignments by skipping over NS3 pulses with its simulated annealing optimization)
    
    
    CN = IK.JointNames;
    CN = vertcat('time',CN); % in s
    
    tb = IK.TimeBins{i};
    
    PosTemp = IK.JointAngle{i};
    SmoothedPosTemp = smoothMat(PosTemp,smoothSamples);
    
    VelTemp = IK.JointVelocity{i}; % default output of IK converts from deg/sample to deg/s, so watch out! these numbers will look different!
    SmoothedVelTemp = smoothMat(VelTemp,smoothSamples); % default output of IK makes Vel struct that has the same number of points as Pos, so beware of weird dependencies on the size of Vel w.r.t. Pos!
    
    SpeedTemp = abs(VelTemp);
    SmoothedSpeedTemp = smoothMat(SpeedTemp,smoothSamples);
    
     
    
    tempKinStruct.ColumnNames = CN;
    tempKinStruct.Pos = [tb,PosTemp];
    tempKinStruct.Vel = [tb,VelTemp]; % this and SpeedTemp are now in terms of deg/s AND have the same # of points as Pos (by virtue of running filtfilt with the haar waveform instead of just running it forward in time)
    tempKinStruct.Spd = [tb,SpeedTemp];
    tempKinStruct.SmoothedPos = [tb,SmoothedPosTemp];
    tempKinStruct.SmoothedVel = [tb,SmoothedVelTemp];
    tempKinStruct.SmoothedSpd = [tb,SmoothedSpeedTemp];
    tempKinStruct.PCA         = struct(); % PCA was generally empty even in Gregg's script
    
    
    tempStruct.Kinematics     = tempKinStruct;
    
    
    tempMTL                   = IK.MuscleLength{i}.MusculoTendon*1000; % default units are m; convert to mm for an order of magnitude that makes sense to analyze
    tempML                    = IK.MuscleLength{i}.MuscleFiber*1000;
    tempTL                    = IK.MuscleLength{i}.Tendon*1000;
    
    tempMTLrate               = IK.MuscleRate{i}.MusculoTendon*1000; % default units are m/s; convert to mm/s for an order of magnitude that makes sense to analyze
    tempMLrate                = IK.MuscleRate{i}.MuscleFiber*1000;
    tempTLrate                = IK.MuscleRate{i}.Tendon*1000;
    
    MTLS                      = smoothMat(tempMTL,smoothSamples);
    MLS                       = smoothMat(tempML,smoothSamples);
    TLS                       = smoothMat(tempTL,smoothSamples);
    
    MTLRS                     = smoothMat(tempMTLrate,smoothSamples);
    MLRS                      = smoothMat(tempMLrate,smoothSamples);
    TLRS                      = smoothMat(tempTLrate,smoothSamples);
    
    MuscColN                  = IK.MuscleNames;
    MuscColN                  = vertcat('time',MuscColN);  % in s
    
    
    tempMTLstruct.ColumnNames       = MuscColN;
    tempMTLstruct.Data              = [tb,tempMTL];
    tempMTLstruct.SmoothedData      = [tb,MTLS];
    tempMTLstruct.Rate              = [tb,tempMTLrate];
    tempMTLstruct.SmoothedRate      = [tb,MTLRS];
    
    
    tempMLstruct.ColumnNames       = MuscColN;
    tempMLstruct.Data              = [tb,tempML];
    tempMLstruct.SmoothedData      = [tb,MLS];
    tempMLstruct.Rate              = [tb,tempMLrate];
    tempMLstruct.SmoothedRate      = [tb,MLRS];
    
    
    tempTLstruct.ColumnNames       = MuscColN;
    tempTLstruct.Data              = [tb,tempTL];
    tempTLstruct.SmoothedData      = [tb,TLS];
    tempTLstruct.Rate              = [tb,tempTLrate];
    tempTLstruct.SmoothedRate      = [tb,TLRS];
    
    
    tempStruct.MuscTendLengths    = tempMTLstruct;
    tempStruct.MuscleFiberLengths = tempMLstruct;
    tempStruct.TendonLengths      = tempTLstruct;
    
    
    tempXYZ.ColumnNames = strtrim(IK.MarkerNames(:));
    tempXYZ.ColumnNames = vertcat('time',tempXYZ.ColumnNames);
    tempXYZ.Pos = IK.MarkerXYZPosition{i};
    tempXYZ.Vel = IK.MarkerXYZVelocity{i};
    
    fn = fieldnames(tempXYZ.Pos);
    for j = 1:numel(fn)
        tempXYZ.SmoothedPos.(fn{j}) = smoothMat(tempXYZ.Pos.(fn{j}),smoothSamples);
        tempXYZ.SmoothedVel.(fn{j}) = smoothMat(tempXYZ.Vel.(fn{j}),smoothSamples);
    end
    
    for j = 1:numel(fn)
        tempXYZ.Pos.(fn{j}) = [tb,tempXYZ.Pos.(fn{j})(1:numel(tb),:)]; % off-by-1 errors in # of time points is not uncommon for XYZ data, so this corrects for that
        tempXYZ.Vel.(fn{j}) = [tb,tempXYZ.Vel.(fn{j})(1:numel(tb),:)];
        tempXYZ.SmoothedPos.(fn{j}) = [tb,tempXYZ.SmoothedPos.(fn{j})(1:numel(tb),:)];
        tempXYZ.SmoothedVel.(fn{j}) = [tb,tempXYZ.SmoothedVel.(fn{j})(1:numel(tb),:)];
    end
    
    
    tempStruct.MarkerXYZ = tempXYZ;
    
    
    % handle neural data now... spike times & binned spike counts...
    % step 1: get trial start times from Sync_Struct, add duration of kins
    % file to get trial end times.
    Sync_Info   = Sync_Struct(which_trial);
    trialdur    = numel(tb)./SR; % in S
    trialdur_inNS3 = (trialdur*Sync_Info.NS3SamplingRate); % mult by sampling rate to get indices
    trialdur_inNEV = (trialdur*nn.samplingRate);
    
    StartTime_inNS3 = (Sync_Info.NS3Stream_TrialStartInds);
    EndTime_inNS3   = (StartTime_inNS3 + trialdur_inNS3);
    
    StartTime_inNEV = (StartTime_inNS3*nn.samplingRate/Sync_Info.NS3SamplingRate);
    EndTime_inNEV   = (StartTime_inNEV + trialdur_inNEV);
    
    StartTime_inNS3 = round(StartTime_inNS3);
    EndTime_inNS3   = round(EndTime_inNS3); % only round afterward to minimize rounding errors
    
    StartTime_inNEV  = round(StartTime_inNEV);
    EndTime_inNEV    = round(EndTime_inNEV);
    
    
    % step 2: find all timestamps that are both "real spikes" according to
    % the nn struct AND are within the aforementioned start-stop times
    % (converted to the proper sampling rate ofc)
    spikes_of_this_trial = nn.NEV.Data.Spikes.Timestamps >= StartTime_inNEV & ...
        nn.NEV.Data.Spikes.Timestamps < EndTime_inNEV;
    
    LFP_of_this_trial = cv.LFP.Data(1:96,StartTime_inNS3:EndTime_inNS3)';
    LFP_times         = ((1:size(LFP_of_this_trial,1))-1)./Sync_Info.NS3SamplingRate;
    
    % step 3: partition spike times into cells according to
    % nn.numElectrodes & the [Electrode Unit] pairs within nn.Electrodes,
    % and convert from timestamps to s
    
    Nelec = nn.numElectrodes;
    spikeTimesCell = cell(1,Nelec);
    
    for j = 1:Nelec
        Eind = nn.Electrodes(j,1);
        Uind = nn.Electrodes(j,2);
        
        spikes_of_this_unit = nn.NEV.Data.Spikes.Electrode == Eind & ...
            nn.NEV.Data.Spikes.Unit == Uind;
        
        spikes_we_care_about = spikes_of_this_trial & spikes_of_this_unit;
        
        spikeTimes_inNEV = double(nn.NEV.Data.Spikes.Timestamps(spikes_we_care_about));
        spikeTimes_aligned = spikeTimes_inNEV - StartTime_inNEV;
        
        spikeTimes_in_s = spikeTimes_aligned ./ nn.samplingRate; % samples / (samples/s) = s
        
        spikeTimesCell{j} = spikeTimes_in_s;
    end
    
    % step 4: histcounts on each cell (with tb being the bin edges) to get
    % binned spike counts
    spikeCountsMat = zeros(numel(tb),Nelec);
    
    for j = 1:Nelec
        tempVec = histcounts(spikeTimesCell{j},[tb;max(tb)+1/SR]);
        spikeCountsMat(:,j) = tempVec;
    end
    
    tempStruct.Spikes.Timestamps = spikeTimesCell;
    tempStruct.Spikes.Bins       = spikeCountsMat;
    
    tempStruct.Events.FirstVicon = 0;
    tempStruct.Events.Present    = Sync_Struct(i).StartStartInds./Sync_Struct(i).NS3SamplingRate; % vicon voltage sampling rate = 1000 Hz, but this is converted within Trial_Align to the sampling rate of the NS3 file (2kHz) (see lines 102-105)
    tempStruct.Events.Retract    = Sync_Struct(i).EndStartInds./Sync_Struct(i).NS3SamplingRate;
    tempStruct.Events.LastVicon  = trialdur;
    
    tempStruct.LFP.Time = LFP_times(:);
    tempStruct.LFP.Data = LFP_of_this_trial;
    
    tempStruct.CerebusRange = [StartTime_inNEV./nn.samplingRate, EndTime_inNEV./nn.samplingRate];
    
    Trials = vertcat(Trials,tempStruct); %#ok<*AGROW>
    clear tempStruct
end

%% add event times (Alex)
% Trials = AddEventFinal(Trials);

%% save struct
save([master_output_dir,sprintf('%s_Session_%0.2i_diss.mat',Animal,Session)],'Trials','ArrayInfo','-v7.3')






















