%Prerequisites:
% a loaded kinematracks project
% a raw recording


clc
%%%%%%%%%%%%%%%%%%%% EXTRACT ANGLES AND POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%
load static1;
clear globalpos;
% h = findall(0,'tag','KinemaTracks');
% handles = guihandles(h);
switch LHO.handside
    case 'left'
        handside=1;
    case 'right'
        handside=-1;
    otherwise 
        error('Hand side not determinded');
end
numsamples = size(recording,1);
angles=NaN(28,numsamples);
globalpos=NaN(78,numsamples);
localpos=NaN(78,numsamples);
aperture=NaN(1,numsamples);
speed   =NaN(1,numsamples);
globalposid =createpositionid('GL');
localposid  =createpositionid('LO');
angleid     =createangleid();

data=zeros(size(recording,2),size(recording,3));

GHO2=struct(GHO);
LHO2=struct(LHO);

reference=zeros(1,3);
armjoints=zeros(1,12);
shoulder =zeros(1,3);

cerebus_starttime(1,1)=recording(1,1,2); % get the first time sampled with cerebus
t_kinematracks=recording(:,1,1);
t_cerebus     =recording(:,1,2);
to=5000;

tic % stop the process
for ii=1:numsamples
    
    data(:,:)=recording(ii,:,:);
    GHO2       = refreshGlobalHand(GHO2,data);
    LHO2       = updateLocalHand(LHO2,GHO2);
    GHO2       = updateGlobalHand(GHO2,LHO2);
    GHO2       = updateGlobalArm(GHO2,LHO2); 
    LHO2       = updateLocalArm(LHO2,GHO2);
%     plotHand(LHO2,GHO2,handles)
%     drawnow;
    %GLOBAL HAND/ARM JOINTS
    fingerjoints=reshape(permute(GHO2.fingerjoints(:,[7,6,5,4],1:3),[3,2,1]),1,60);
    reference(1,:)=GHO2.reference(1,1:3);
    armjoints(1,:)=reshape(permute(GHO2.armjoints(1:4,1:3),[2,1]),12,1);
    shoulder(1,:) =GHO2.shoulder(1,1:3);
    globalpos(:,ii)=[fingerjoints, reference, armjoints, shoulder];

    %LOCAL HAND/ARM JOINTS
    fingerjoints=reshape(permute(LHO2.fingerjoints(:,[7,6,5,4],1:3),[3,2,1]),1,60);
    reference(1,:)=LHO2.reference(1,1:3);
    armjoints(1,:)=reshape(permute(LHO2.armjoints(1:4,1:3),[2,1]),12,1);
    shoulder(1,:) =LHO2.shoulder(1,1:3);
    localpos(:,ii)=[fingerjoints, reference, armjoints, shoulder];
    
    %JOINT ANGLES
    angles(:,ii)=hand2angles(localpos(:,ii),globalpos(:,ii),handside);
    
    %APERTURE
    aperture(1,ii)=norm(localpos(10:12,ii)-localpos(22:24,ii));
    

    
end

deltat=t_kinematracks(2:end)-t_kinematracks(1:end-1);
for ii=1:numsamples-1
%     SPEED
    speed(1,ii)=norm(globalpos(64:66,ii)-globalpos(64:66,ii+1))/deltat(ii);
end

speed_static=speed;
mcp_static=angles(6,:);
pip_static=angles(7,:);
dip_static=angles(8,:);



load dynamic1;



clc
%%%%%%%%%%%%%%%%%%%% EXTRACT ANGLES AND POSITION %%%%%%%%%%%%%%%%%%%%%%%%%%%

clear globalpos;
h = findall(0,'tag','KinemaTracks');
handles = guihandles(h);
switch LHO.handside
    case 'left'
        handside=1;
    case 'right'
        handside=-1;
    otherwise 
        error('Hand side not determinded');
end
numsamples = size(recording,1);
angles=NaN(28,numsamples);
globalpos=NaN(78,numsamples);
localpos=NaN(78,numsamples);
aperture=NaN(1,numsamples);
speed   =NaN(1,numsamples);
globalposid =createpositionid('GL');
localposid  =createpositionid('LO');
angleid     =createangleid();

data=zeros(size(recording,2),size(recording,3));

GHO2=struct(GHO);
LHO2=struct(LHO);

reference=zeros(1,3);
armjoints=zeros(1,12);
shoulder =zeros(1,3);

cerebus_starttime(1,1)=recording(1,1,2); % get the first time sampled with cerebus
t_kinematracks=recording(:,1,1);
t_cerebus     =recording(:,1,2);
to=5000;

tic % stop the process
for ii=1:numsamples
    data(:,:)=recording(ii,:,:);
    GHO2       = refreshGlobalHand(GHO2,data);
    LHO2       = updateLocalHand(LHO2,GHO2);
    GHO2       = updateGlobalHand(GHO2,LHO2);
    GHO2       = updateGlobalArm(GHO2,LHO2); 
    LHO2       = updateLocalArm(LHO2,GHO2);
%     plotHand(LHO2,GHO2,handles)
%     drawnow;
    %GLOBAL HAND/ARM JOINTS
    fingerjoints=reshape(permute(GHO2.fingerjoints(:,[7,6,5,4],1:3),[3,2,1]),1,60);
    reference(1,:)=GHO2.reference(1,1:3);
    armjoints(1,:)=reshape(permute(GHO2.armjoints(1:4,1:3),[2,1]),12,1);
    shoulder(1,:) =GHO2.shoulder(1,1:3);
    globalpos(:,ii)=[fingerjoints, reference, armjoints, shoulder];

    %LOCAL HAND/ARM JOINTS
    fingerjoints=reshape(permute(LHO2.fingerjoints(:,[7,6,5,4],1:3),[3,2,1]),1,60);
    reference(1,:)=LHO2.reference(1,1:3);
    armjoints(1,:)=reshape(permute(LHO2.armjoints(1:4,1:3),[2,1]),12,1);
    shoulder(1,:) =LHO2.shoulder(1,1:3);
    localpos(:,ii)=[fingerjoints, reference, armjoints, shoulder];
    
    %JOINT ANGLES
    angles(:,ii)=hand2angles(localpos(:,ii),globalpos(:,ii),handside);
    
    %APERTURE
    aperture(1,ii)=norm(localpos(10:12,ii)-localpos(22:24,ii));
    

    
end

speed_dynamic=speed;
mcp_dynamic=angles(6,:);
pip_dynamic=angles(7,:);
dip_dynamic=angles(8,:);

deltat=t_kinematracks(2:end)-t_kinematracks(1:end-1);
for ii=1:numsamples-1
%     SPEED
    speed(1,ii)=norm(globalpos(64:66,ii)-globalpos(64:66,ii+1))/deltat(ii);
end

temp=speed;
speed_s=interp1(t_kinematracks(not(isnan(temp))),speed(not(isnan(temp))),t_kinematracks);

temp=mcp_dynamic;
mcp_dynamic_s=interp1(t_kinematracks(not(isnan(temp))),angles(6,not(isnan(temp))),t_kinematracks);

temp=pip_dynamic;
pip_dynamic_s=interp1(t_kinematracks(not(isnan(temp))),angles(7,not(isnan(temp))),t_kinematracks);

temp=dip_dynamic;
dip_dynamic_s=interp1(t_kinematracks(not(isnan(temp))),angles(8,not(isnan(temp))),t_kinematracks);


dip_stat_mean=mean(dip_static(~isnan(dip_static)));
pip_stat_mean=mean(pip_static(~isnan(pip_static)));
mcp_stat_mean=mean(mcp_static(~isnan(mcp_static)));

dip_absoluteerrors=abs(dip_dynamic_s-dip_stat_mean);
dip_absolutemeanerror=mean(dip_absoluteerrors);
dip_std=std(dip_dynamic_s-dip_stat_mean);

disp(['DIP absolte mean error: ' num2str(dip_absolutemeanerror) ', sdt: ' num2str(dip_std)]);

mcp_absoluteerrors=abs(mcp_dynamic_s-mcp_stat_mean);
mcp_absolutemeanerror=mean(mcp_absoluteerrors);
mcp_std=std(mcp_dynamic_s-mcp_stat_mean);

disp(['MCP absolte mean error: ' num2str(mcp_absolutemeanerror) ', sdt: ' num2str(mcp_std)]);

pip_absoluteerrors=abs(pip_dynamic_s-pip_stat_mean);
pip_absolutemeanerror=mean(pip_absoluteerrors);
pip_std=std(pip_dynamic_s-pip_stat_mean);

disp(['PIP absolte mean error: ' num2str(pip_absolutemeanerror) ', sdt: ' num2str(pip_std)]);

[R,P]=corrcoef(speed_s(1:end-1),dip_absoluteerrors(1:end-1));

step=200;
cc=1;
for ii=0:step:3000
    idx{cc}=find(speed_s>ii & speed_s<=(ii+step));
    speedaxis(cc)=ii+step;
    error1(cc)=mean(mcp_absoluteerrors(idx{cc}));
    std1(cc)  =std(mcp_absoluteerrors(idx{cc}));
    error2(cc)=mean(pip_absoluteerrors(idx{cc}));
    std2(cc)  =std(pip_absoluteerrors(idx{cc}));
    error3(cc)=mean(dip_absoluteerrors(idx{cc}));
    std3(cc)  =std(dip_absoluteerrors(idx{cc}));
    cc=cc+1;
end

figure(1)
speedaxis=speedaxis/100;
% errorbar(error1(1,:),std1(:),'-*','Color','r'); hold on;
% errorbar(error2(1,:),std2(:),'-*','Color','b'); hold on;
% errorbar(error3(1,:),std3(:),'-*','Color','g'); 

plot(speedaxis,error1(1,:),'-*','Color','r'); hold on;
plot(speedaxis,error2(1,:),'-*','Color','b'); hold on;
plot(speedaxis,error3(1,:),'-*','Color','g'); hold on;




idx2=find(speed_s>0 & speed_s<=100);
dip_absoluteerrors_ls=abs(dip_dynamic_s(idx2)-dip_stat_mean);
dip_absolutemeanerror_ls=mean(dip_absoluteerrors_ls)
dip_std=std(dip_absoluteerrors_ls)









