% Batch_Test_cart2transmat
% Author: Stefan Schaffelhofer                                       MAR 12


% Example 1
p=[1.5; 1; 0;1];
dist=[0,-2,0];
ex=[1,1,0];
ey=[-1,1,0];
ez=[0,0,1];
[tm,dcm]=cart2transmat(dist,ex,ey,ez);
tm\p



notvalid= abs(globalpos)>500;
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
sr=50;

[globalpos_os_n time_n] =interpolatekinematic(globalpos_os,ktimes,sr,0.2);


kin2opensim(globalpos_os_n_pre,time,'C:\Users\Neurobiologie\Desktop\Recording36_HOS.trc');





