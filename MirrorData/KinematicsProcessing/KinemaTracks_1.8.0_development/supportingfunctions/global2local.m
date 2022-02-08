function [LHO,Mlg]=global2local(LHO,GHO)

global GST;

reference=GHO.reference;
globaljoints=GHO.fingerjoints;
localjoints=LHO.fingerjoints;
globalshoulder=GHO.shoulder;
sensorlength=GHO.lengthsensor;

if numel(sensorlength) == 1
    sensorlength = repmat(sensorlength,1,5);
else
end

lengthdorsum=LHO.lengthdorsum;
% lengthlowerarm=get(LHO,'lengthlowerarm');

ct=LHO.lengthct;
% Mlg = momo_mex(reference(1,4:7),reference(1,1:3));
Mlg = momo(reference(1,4:7),reference(1,1:3));

LHO.reference=[0,0,0]; % reference is at point 0;


% TRANSFORM HAND/FINGERS
numFingers=size(globaljoints,1);
Wtemp=zeros(4,numFingers);
Utemp=zeros(4,numFingers);
Otemp=zeros(4,numFingers);

% TO REMEMBER local = Mlg \ global
for ss=1:numFingers
    %transformation into frame of the sensor
    tempmomo=momo(globaljoints(ss,1,4:7),globaljoints(ss,1,1:3));
    
    % ADDED: also transform the sensor tip
    Otemp(1:4,ss)=[0,0,0,1];
    Otemp(:,ss)=tempmomo*[Otemp(1:3,ss);1];
    Otemp(:,ss)=Mlg\[Otemp(1:3,ss);1];
    localjoints(ss,1,1:3)=Otemp(1:3,ss)';
        
    %cylinder edge of distal phalanx
    Wtemp(1:3,ss)=[0,0,+sensorlength(ss)];
    Wtemp(:,ss)=tempmomo*[Wtemp(1:3,ss);1];
    Wtemp(:,ss)=Mlg\[Wtemp(1:3,ss);1];
    localjoints(ss,2,1:3)=Wtemp(1:3,ss)';

    %point on outer joint radius of distal joint (C)
    Utemp(1:3,ss)=[0,0,-(ct(ss)-sensorlength(ss))];
    Utemp(:,ss)=tempmomo*[Utemp(1:3,ss);1];
    Utemp(:,ss)=Mlg\[Utemp(1:3,ss);1];
    localjoints(ss,3,1:3)=Utemp(1:3,ss)';
    
    % Case when the thumb sensor is flat
    if (GST.flatf1sens && ss == 1)
        % position of sensor in ref sensor frame
        sxtemp = squeeze(localjoints(ss,1,1:3))-squeeze(localjoints(ss,7,1:3));
        srtemp = tempmomo*[0;0;1;0];
        srtemp = Mlg\srtemp;
        n = cross(srtemp(1:3), sxtemp(1:3));
        n = n/norm(n);
        fingerdirection = -cross(srtemp(1:3),n(1:3));
        fingerdirection = fingerdirection / norm(fingerdirection);
        Wtemp(1:3,ss) = squeeze(localjoints(ss,1,1:3)) + sensorlength(ss)*fingerdirection;
        Utemp(1:3,ss) = squeeze(localjoints(ss,1,1:3)) - (ct(ss)-sensorlength(ss))*fingerdirection;
        localjoints(ss,2,1:3)=Wtemp(1:3,ss)';
        localjoints(ss,3,1:3)=Utemp(1:3,ss)';
    end
    
    % ALSO ADDED: transform the orientation of the sensor
    % represented by a unit quaternion
    % which we need to transform into rotation matrix shape, then back
    % because you can not transform quaternion rotations directly
    Qi = momo([0; 0; 1; 0], [0; 0; 0]); %unit rotation
    Qi = tempmomo*Qi;
    Qi = Mlg\Qi;
    Qi(1:3,4) = 0;
    localjoints(ss,1,4:7) = rot2quat(Qi);
end
LHO.fingerjoints=localjoints;

% TRANSFORM ARM
if ~isempty(globalshoulder)
    STemp=Mlg\[globalshoulder(1:3)';1];
    localshoulder=STemp(1:3)'; 

%     armjoints(1,1:3)=[0;+15;0-lengthdorsum]; % local coordinates of wrist
%     armjoints(5,1:3)=[20,+15,0-lengthdorsum]; % this vector points into X-axis of reference sensor and will be set to the wrist as an help point, indication the pronation supination of the hand
    LHO.shoulder=localshoulder;
%     LHO.armjoints=armjoints;
end




