% Batch_extractfeatures.m
% This batch is modelling hand and arm movements out of raw kinematic
% recordings.
% Running the batch will do the following steps (if enabled)
% 1) Modelling hand and arm (extracting positions of all joints in global
% and local coordinate system (devices and hand's coordinate system
% respectively)
% 2) Extracting joint angles in degree and other features as apertur
% 3) Interpolating position and orientation
%
% Author: Stefan Schaffelhofer                                     April 12
% Updated by James Goodman 2020 Jan 15
% Primarily to prevent saving of unnecessary files & instead append to
% existing MATLAB variables with each call

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global LHO; % important!
global GHO; % important!
global REC; % important!
global extractoption; % this is set up by the GUI 
global TO; % can be empty (normally a "trial object" to help with synching)
global ST; % can be empty (normally an "epoch object", with focus on the raw digital I/Os, to help with synching)
global DI; % can be empty (normally an "epoch object", with focus on the interpreted states, to help with synching. Why is this a separate input though? Did Stefan make two separate "epochobjs", each with its own special information, for each session? this is nutty...)
global lastfile; % the name of the file with the kinematic data (clunkily loaded by starting the "player")
% conspicuously absent: anything dealing with "calibdata".

sb=extractoption.statusbar;
guih=extractoption.gui;
sb.setVisible(true);

%check if the complete recording should be processed:
if extractoption.timeselect
    tfrom=extractoption.tfrom;
    tto=extractoption.tto;
    
    sfrom=find(REC(:,1,2)>=tfrom,1,'first');
    sto  =find(REC(:,1,2)<=tto,1,'last');
    numsamples=sto-sfrom+1;    
else
    numsamples = size(REC,1); % number of samples that will be extracted
    sfrom=1;
    sto =size(REC,1);
end

%% -------------------------Eliminate Errors---------------------------------

warning off;

% Eliminate system errors of WAVE. Sometimes WAVE does not update the new
% position of the reference sensor and delivers the latest position. This
% short part of the script finds equal positions and eliminates them and
% avoids computational errors of the hand caused by this bug.


if extractoption.elimerrors % of error elimination is enabled
   
    errorcount=0;
    refold=zeros(1,size(REC,3));
    refnew=zeros(size(refold));
    unlock=1;
    for ii=sfrom:sto-1;
        
        if mod(ii,1000)==0;
           statusbar(guih,'Eliminate repition errors (%.1f%%)...',100*(ii-sfrom)/numsamples);
           set(sb.ProgressBar,'Minimum',1, 'Maximum',numsamples, 'Value',ii-sfrom)
        end
        
        
        if unlock
            refold(:,:)=REC(ii,2,:);
        end
        refnew(:,:)=REC(ii+1,2,:);

        if refold==refnew
            unlock=0; 
            REC(ii+1,2,:)=NaN; 
            errorcount=errorcount+1;
        else
            unlock=1;
        end

    end
    
end


%% ------------------------------Modelling-----------------------------------

angles    =NaN(9,numsamples);
globalpos =NaN(93,numsamples);
localpos  =NaN(78,numsamples);
aperture1 =NaN(1,numsamples);
aperture2 =NaN(1,numsamples);
speed     =NaN(1,numsamples);
globalposid =createpositionid('GL');
localposid  =createpositionid('LO');
angleid     =createangleid();

data=zeros(size(REC,2),size(REC,3));

GHO2=struct(GHO);
LHO2=struct(LHO);

reference=zeros(1,3);
armjoints=zeros(1,12);
shoulder =zeros(1,3);

cerebus_starttime(1,1)=REC(1,1,2); 
t_kinematracks=REC(sfrom:sto,1,1);
ktimes        =REC(sfrom:sto,1,2);
deltat=t_kinematracks(2:end)-t_kinematracks(1:end-1);


% -------------------cut out parts of recording----------------------------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if extractoption.trialplot; plottrials(TO); end; % ah plottrials isn't even included in the kinematracks folder, but rather in Stefan's "GraspAnalyze" suite!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tc=[];

if ~extractoption.notrialinfo
    % load cut out times:
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    tc = getcutouts(extractoption.subject,extractoption.session); % this is much like "getgraspinfo". Again, not included in the KinemaTracks files per se, but rather in Stefan's GraspAnalyze suite (and buried in the "User Files" folder at that!)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

if ~isempty(tc)
    [problems] = istrialconflict(TO,ST,DI,tc,'Cue','Post Hold');
    if problems==0
        statusbar(guih,'No conflicts with trials found.');
        disp('No conflicts with trials found.');
    else
        error('There is a trial conflict.');
    end
end

%-----parameters for arm checking:
nonvalidframes=false(1,size(globalpos,2));
% If no trial info is available (Added by Andres on 15.1.16)
if ~extractoption.notrialinfo
    eventtimes=extracttime(TO,DI,ST,{'movementstart','holdoff'});
    tcorr=TO.trialCorrect;
    trNr=1:length(tcorr);
    corrTrID=trNr(tcorr==1);
    eventimes=eventtimes(tcorr==1,:);
end
%---
tic

% ------------------- MODELLING -------------------------------------------
for ii=sfrom:sto
    
    if mod(ii,100)==0;
       statusbar(guih,'Hand modelling (%.1f%%)...',100*(ii-sfrom+1)/numsamples);
       set(sb.ProgressBar,'Minimum',1, 'Maximum',numsamples, 'Value',ii-sfrom+1)
    end
    kk=ii-sfrom+1;
    
    data(:,:)  = REC(ii,:,:); % each element along the first index indeed corrsponds with a sample
    GHO2       = refreshGlobalHand(GHO2,data);
    LHO2       = updateLocalHand(LHO2,GHO2);
    GHO2       = updateGlobalHand(GHO2,LHO2);
    GHO2       = updateGlobalArm(GHO2,LHO2); 
    LHO2       = updateLocalArm(LHO2,GHO2);

    % GLOBAL HAND/ARM JOINTS
    fingerjoints=reshape(permute(GHO2.fingerjoints(:,[7,6,5,4],1:3),[3,2,1]),1,60);
    reference(1,:)=GHO2.reference(1,1:3);
    armjoints(1,:)=reshape(permute(GHO2.armjoints(1:4,1:3),[2,1]),12,1);
    shoulder(1,:) =GHO2.shoulder(1,1:3);
    helppoints(1,:)=reshape(GHO2.helpvector,numel(GHO2.helpvector),1);
    globalpos(:,kk)=[fingerjoints, reference, armjoints, shoulder, helppoints]; % note: these elements are NOT all of the same type! elements can be EITHER cartesian coordinates OR surface normal vectors / quaternions! be careful if naively messing around with these values!

    % LOCAL HAND/ARM JOINTS
    fingerjoints=reshape(permute(LHO2.fingerjoints(:,[7,6,5,4],1:3),[3,2,1]),1,60);
    reference(1,:)=LHO2.reference(1,1:3);
    armjoints(1,:)=reshape(permute(LHO2.armjoints(1:4,1:3),[2,1]),12,1);
    shoulder(1,:) =LHO2.shoulder(1,1:3);
    localpos(:,kk)=[fingerjoints, reference, armjoints, shoulder];
    
    aperture1(1,kk)=norm(localpos(10:12,kk)-localpos(22:24,kk));
    
    aperture2(1,kk)=mean([...
                         norm(localpos(13:15,kk)-localpos(22:24,kk)), ...
                         norm(localpos(25:27,kk)-localpos(34:36,kk)), ...
                         norm(localpos(37:39,kk)-localpos(46:48,kk)), ...
                         norm(localpos(49:51,kk)-localpos(58:60,kk))]);
                         
    if kk<=numsamples-1
        % SPEED
        speed(1,kk)=norm(globalpos(64:66,kk)-globalpos(64:66,kk+1))/deltat(kk);
    end
    
    % ----report if there are arm problems immediatly (errors are removed later
    % in this code).
    armlength=GHO.lengthlowerarm+GHO.lengthupperarm;
    W=globalpos(64:66,ii);
    S=globalpos(76:78,ii);
    WS=norm(W-S)/100*102;
    if ~extractoption.notrialinfo
        if WS>=armlength
             for tt=1:length(corrTrID); 
                if ktimes(ii)>=eventtimes(tt,1) && ktimes(ii)<=eventtimes(tt,2)
                    disp(['Conflinct with trial ' num2str(corrTrID(tt)) '; distance: ' num2str(WS-armlength) 'mm ; @t=' num2str(ktimes(ii)) 'sec. ']);
                end
             end
        end
    end
end
toc
%---------------------ELIMINATE  INCORRECT HIGH VALUES---------------------

%  In some cases WAVE delivers very high and incorrect values.
%  Find values of globalpos that exeed 500 mm and eliminate them.

notvalid= abs(globalpos)>1000;
globalpos(notvalid)=NaN;
disp(['Numbers of smaples removed due to incorrect high values: ' num2str(sum(sum(notvalid)))]);


%--------------REMOVE SAMPLES in WHICH ARM EXEEDS MAXIMAL LENGTH-----------


% for ii=1:size(globalpos,2)
%     W=globalpos(64:66,ii);
%     S=globalpos(76:78,ii);
%     WS=norm(W-S)/100*102;
%     if WS>=armlength
%         globalpos(67:69,ii)= [NaN NaN NaN]; 
%         localpos(67:69,ii) = [NaN NaN NaN]; 
%         globalpos(73:75,ii)= [NaN NaN NaN]; 
%                                            
%     end
%     
%     D=globalpos(61:63,ii);
%     E=globalpos(67:69,ii);
%     if sum(isnan(D))>1 || sum(isnan(E))>1% if the reference 
%         nonvalidframes(ii)=true;
%     end 
%     
%     if sum(sum(isnan(globalpos([10,22,34,46,58],ii))))>2
%         nonvalidframes(1,ii)=true;
%     end
%     
% end
% 
% globalpos(:,nonvalidframes)=[];
% localpos(:,nonvalidframes)=[];
% speed(:,nonvalidframes)=[];
% aperture1(:,nonvalidframes)=[];
% aperture2(:,nonvalidframes)=[];
% ktimes(nonvalidframes,:)=[];

%----------------CUT OUT USER DEFINED PARTS OF THE RECORDING---------------

cutoutframes=false(1,size(globalpos,2)); % run through the user defined cut out sections
for ll=1:size(tc,1)
    scfrom=find(ktimes>=tc(ll,1),1,'first');
    scto  =find(ktimes<=tc(ll,2),1,'last');
    cutoutframes(1,scfrom:scto)=true; 
end
globalpos(:,cutoutframes)=[];
localpos(:,cutoutframes) =[];
speed(:,cutoutframes)    =[];
aperture1(:,cutoutframes)=[];
aperture2(:,cutoutframes)=[];
ktimes(cutoutframes,:)   =[];

% note to myself: disabled, for mirror task
% check if the cut out data is in confilct with correct trials
% trid=trialgapcheck(globalpos,ktimes,extractoption.gap,TO,DI,ST,{'movementstart','holdoff'});



%% -------------------------Extract Angles-----------------------------------

if extractoption.angles % if angle extraction is enabled
%     switch LHO.handside
%         case 'left'
%             handside=1;
%         case 'right'
%             handside=-1;
%         otherwise 
%             error('Hand side not determinded');
%     end
% 
% 
% 
%     for ii=sfrom:sto
%         if mod(ii,100)==0;
%            statusbar(guih,'Extract angles (%.1f%%)...',100*ii/numsamples);            %statusbar('Eliminate repition errors %d of %d (%.1f%%)...',ii,size(REC,1),100*ii/size(REC,1));
%            set(sb.ProgressBar,'Minimum',1, 'Maximum',numsamples, 'Value',ii) 
%         end
%         %JOINT ANGLES
%         angles(:,ii)=hand2angles(localpos(:,ii),globalpos(:,ii),handside);
% 
%     end
%     statusbar(guih,'Angles were extracted successfully.');
end



%% 1) Extract features with Matlab code

%--------------------------Interpolate Data--------------------------------

notvalid=abs(globalpos)>1000; % Find and remove invalid samples;
globalpos(notvalid)=NaN;
localpos(notvalid)=NaN;



if mod(ii,100)==0;
   statusbar(guih,'Interpolate Kinematracks Data.');
   set(sb.ProgressBar,'Visible',false)
end
if extractoption.interpolate
    
    
    [globalpos_n time_n] = interpolatekinematic(globalpos,ktimes,extractoption.sr,extractoption.gap);
    localpos_n   = interpolatekinematic(localpos,ktimes,extractoption.sr,extractoption.gap);
    speed_n      = interpolatekinematic(speed,ktimes,extractoption.sr,extractoption.gap);
    aperture1_n  = interpolatekinematic(aperture1,ktimes,extractoption.sr,extractoption.gap);
    aperture2_n  = interpolatekinematic(aperture2,ktimes,extractoption.sr,extractoption.gap);

    if extractoption.angles
        [angles_n] = interpolatekinematic(angles,ktimes,extractoption.sr,extractoption.gap);
    end

    disp('Interpolation finished');
end



%--------------------Prepare Data for further analysis---------------------

statusbar(guih,'Save Kinematic Data.');
% prepare filename
%fname=dir([extractoption.directory '*Rec*.mat']);
%fname=fname(1,1).name;
% Now a different target folder is allowed
[path, fname, ext]=fileparts(fullfile(extractoption.directory,lastfile));
fname=fname(1:strfind(fname,'_')-1);

% save non interpolated data
global kinematics
if isempty(kinematics)
    kinematics=struct;
    kinematics.time=ktimes;
    kinematics.posinfo=globalposid;
    kinematics.anginfo=angleid;
    kinematics.samplrate=NaN; % no stable sampling rate
    kinematics.globalpos=globalpos;
    kinematics.localpos =localpos;
    kinematics.speed =speed;
    kinematics.aperture1=aperture1;
    kinematics.aperture2=aperture2;
    kinematics.globalhand=GHO;
    kinematics.localhand=LHO;
    kinematics.angles = [];
else
    clear tempstruct
    tempstruct.time=ktimes;
    tempstruct.posinfo=globalposid;
    tempstruct.anginfo=angleid;
    tempstruct.samplrate=NaN; % no stable sampling rate
    tempstruct.globalpos=globalpos;
    tempstruct.localpos =localpos;
    tempstruct.speed =speed;
    tempstruct.aperture1=aperture1;
    tempstruct.aperture2=aperture2;
    tempstruct.globalhand=GHO;
    tempstruct.localhand=LHO;
    tempstruct.angles   = [];
    
    kinematics = vertcat(kinematics,tempstruct);
end
    

if extractoption.angles
    kinematics(end).angles=angles;
else
    kinematics(end).angles=[];
end

% path2save = fullfile(path,[fname,'_KIN.mat']);
% save(path2save, 'kinematics');


% global kinematics_os
global kinematics_i %#ok<*TLEV>

if extractoption.interpolate
    if isempty(kinematics_i)
        kinematics_i=struct;
        kinematics_i.time=time_n;
        kinematics_i.posinfo=globalposid;
        kinematics_i.anginfo=angleid;
        kinematics_i.samplrate=extractoption.sr;
        kinematics_i.globalpos=globalpos_n;
        kinematics_i.localpos =localpos_n;
        kinematics_i.speed =speed_n;
        kinematics_i.aperture1=aperture1_n;
        kinematics_i.aperture2=aperture2_n;
        kinematics_i.globalhand=GHO;
        kinematics_i.localhand=LHO;
        kinematics_i.angles = [];
    else
        clear tempstruct
        tempstruct=struct;
        tempstruct.time=time_n;
        tempstruct.posinfo=globalposid;
        tempstruct.anginfo=angleid;
        tempstruct.samplrate=extractoption.sr;
        tempstruct.globalpos=globalpos_n;
        tempstruct.localpos =localpos_n;
        tempstruct.speed =speed_n;
        tempstruct.aperture1=aperture1_n;
        tempstruct.aperture2=aperture2_n;
        tempstruct.globalhand=GHO;
        tempstruct.localhand=LHO;
        tempstruct.angles = [];
        
        kinematics_i = vertcat(kinematics_i,tempstruct);
    end
        
    if extractoption.angles
        kinematics_i(end).angles=angles_n;
    else
        kinematics_i(end).angles=[];
    end
    
    %     path2save = fullfile(path,[fname,'_KINi.mat']);
    
    %     save(path2save, 'kinematics_i');

    %     kinematics_os=kinematics_i; % either use interpolated data for open sim...
else
    %     kinematics_os=kinematics; % or unfiltered and raw data
    if isempty(kinematics_i)
        kinematics_i=struct;
        kinematics_i.time=nan;
        kinematics_i.posinfo=nan;
        kinematics_i.anginfo=nan;
        kinematics_i.samplrate=nan;
        kinematics_i.globalpos=nan;
        kinematics_i.localpos =nan;
        kinematics_i.speed =nan;
        kinematics_i.aperture1=nan;
        kinematics_i.aperture2=nan;
        kinematics_i.globalhand=nan;
        kinematics_i.localhand=nan;
        kinematics_i.angles = nan;
    else
        clear tempstruct
        tempstruct=struct;
        tempstruct.time=nan;
        tempstruct.posinfo=nan;
        tempstruct.anginfo=nan;
        tempstruct.samplrate=nan;
        tempstruct.globalpos=nan;
        tempstruct.localpos =nan;
        tempstruct.speed =nan;
        tempstruct.aperture1=nan;
        tempstruct.aperture2=nan;
        tempstruct.globalhand=nan;
        tempstruct.localhand=nan;
        tempstruct.angles = nan;
        
        kinematics_i = vertcat(kinematics_i,tempstruct);
    end
end

    statusbar('Done. Your are great! I love you Stefan.');
    
%% 2) Prepare Data for extracting features OS

if extractoption.export
%     test
%     ex=[1,0,0]; % axis of open SIM seen from WAVE coordinate system
%     ey=[0,1,1];
%     ez=[0,0,1];
%     dist=kinematics_os.globalpos(76:78,find(~isnan(kinematics_os.globalpos(76,:)) & ~isnan(kinematics_os.globalpos(77,:)) & ~isnan(kinematics_os.globalpos(78,:)),1,'first')); % distance of SIM origin from WAVE origin (=shoulder coordinates)
% 
%     globalpos_os=nan(size(kinematics_os.globalpos));
% 
%     statusbar('Save exported data.');
%     
%         save([path fname '_' extractoption.appendix  '.mat'],
%         'kinematics_os');
%      
end


