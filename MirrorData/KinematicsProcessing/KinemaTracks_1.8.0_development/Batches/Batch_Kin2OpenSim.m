% Batch_Kin2opensim
% This batch transforms global handtracking signals of KinemaTracks into
% the coordinate system of Opensim, interpolates the data to get a constant
% sampling rate and exports the data to an TRC file
% load globalpos and sample times before!

notvalid = abs(globalpos)>500; % ####### repition settings
globalpos(notvalid)=NaN;
disp(['Numbers of smaples removed: ' num2str(sum(sum(notvalid)))]);

ex=[-1,0,0]; % axis of open SIM seen from WAVE coordinate system
ey=[0,0,-1];
ez=[0,-1,0];
dist=globalpos(76:78,find(~isnan(globalpos(76,:)) & ~isnan(globalpos(77,:)) & ~isnan(globalpos(78,:)),1,'first')); % distance of SIM origin from WAVE origin (=shoulder coordinates)
[tm,dcm]=cart2transmat(dist,ex,ey,ez);

globalpos_os=nan(size(globalpos));

for jj=1:3:size(globalpos,1)
    for ss=1:size(globalpos,2)
        temp=tm\[globalpos(jj:jj+2,ss);1];
        globalpos_os(jj:jj+2,ss)=temp(1:3,1);
    end
end

notvalid=abs(globalpos_os)>500;
globalpos_os(notvalid)=NaN;
sr=20;

[globalpos_os_n time_n] =interpolatekinematic(globalpos_os,ktimes,sr,0.2);
notvalid=abs(globalpos_os_n)>500;
globalpos_os_n(notvalid)=NaN;

% --------------------------- Extract Examples ----------------------------

tfrom = 0;
tto   = 4060.74;

samplefrom=tfrom*sr+1;
sampleto=tto*sr;

kinematic=globalpos_os_n(:,samplefrom:sampleto);
time=time_n(:,samplefrom:sampleto);

kin2opensim(kinematic,time,'C:\Users\Neurobiologie\Desktop\Recording70_all.trc');