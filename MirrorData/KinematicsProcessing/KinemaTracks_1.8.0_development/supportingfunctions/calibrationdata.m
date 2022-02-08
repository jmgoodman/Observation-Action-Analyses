function [calibdata]=calibrationdata2(LHO,GHO,calibdata,kk)



[LHO,Mlg]=global2local(LHO,GHO);                        %transform global Sensor data to local coordinate system

%##########################################################################
localjoints  = LHO.fingerjoints;
globaljoints = GHO.fingerjoints;
fingerradius = LHO.fingerradius;
lengthab = LHO.lengthab;
lengthbc = LHO.lengthbc;
lengthct = LHO.lengthct;

sensorlength = LHO.lengthsensor;

numJoints=size(localjoints,1);

for ff=1:numJoints
        if ~isnan(globaljoints(ff,1,1))
            Alocal=zeros(1,4);
            Alocal(1:3) =[0,0,-(lengthab(ff)+lengthbc(ff)+lengthct(ff)-sensorlength/2)]; % find meta-carpal joint.
            Alocal(:)=momo(globaljoints(ff,1,4:7),globaljoints(ff,1,1:3))*[Alocal(1:3)';1];
            Alocal(1:3)=[Alocal(1), Alocal(2),Alocal(3)];
            Alocal(:)=Mlg\[Alocal(1:3)';1];
            calibdata(kk,ff,1:3)=[Alocal(1), Alocal(2)+fingerradius(ff), Alocal(3)]; %shift axe into center of finger
        else
            calibdata(kk,ff,1:3)=NaN;
        end
end
end


% for ff=1:numJoints
%         if ~isnan(globaljoints(ff,1,1))
%             Alocal=zeros(1,4);
%             Alocal(1:3) =[0,0,-(lengthab(ff)+lengthbc(ff)+lengthct(ff)-sensorlength/2)]; % find meta-carpal joint.
%             Alocal(:)=momo(globaljoints(ff,1,4:7),globaljoints(ff,1,1:3))*[Alocal(1:3)';1];
% %             Alocal(1:3)=[Alocal(1), Alocal(2), Alocal(3)];
%             Alocal(1:3)=[Alocal(1), Alocal(2),Alocal(3)+1*fingerradius(ff)];
%             Alocal(:)=Mlg\[Alocal(1:3)';1];
% %             lh.A(ff,1:3)=Alocal(1:3);
%             calibdata(kk,ff,1:3)=[Alocal(1), Alocal(2), Alocal(3)]; %shift axe into center of finger
%         else
%             calibdata(kk,ff,1:3)=NaN;
%         end
% end
% end


% 
%    Wtemp(1:3,ss)=[0,0,+lh.sensorhalf];
%    Wtemp(:,ss)=momo(gh.S(ss,1:4),gh.S(ss,5:7))*[Wtemp(1:3,ss);1];
%    Wtemp(:,ss)=Mlg\[Wtemp(1:3,ss);1];
%    lh.W(ss,1:3)=Wtemp(1:3,ss)';