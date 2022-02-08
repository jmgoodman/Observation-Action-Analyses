function [LHO]=updateLocalArm(LHO,GHO)


reference=GHO.reference;
armjoints=GHO.armjoints;
shoulder=GHO.shoulder;
Mlg = momo_mex(reference(1,4:7),reference(1,1:3)); % it's weird how this script ostensibly involves quaternions but seems to revert to using matrix algebra & rotation matrices in the end. momo does just that: converts your "quaternion" into a vector & rotation matrix format.

%THE WRIST IS ALREADY COMPUTED
% % wrist
% Wtemp=armjoints(1,1:3);
% Wtemp=Mlg\[Wtemp(1:3)';1];
% armjoints(1,1:3)=Wtemp(1:3)'; 

% elbow
Etemp=armjoints(2,1:3);
Etemp=Mlg\[Etemp(1:3)';1];
LHO.armjoints(2,1:3)=Etemp(1:3);
W1temp=armjoints(3,1:3); % help point EE1 is a vector, pointing normal on the plane SEW (Shoulder, Elbow, Wrist)
W1temp=Mlg\[W1temp(1:3)';1];
LHO.armjoints(3,1:3)=W1temp(1:3);
E1temp=armjoints(4,1:3); % help point EE1 is a vector, pointing normal on the plane SEW (Shoulder, Elbow, Wrist)
E1temp=Mlg\[E1temp(1:3)';1];
LHO.armjoints(4,1:3)=E1temp(1:3);


% shoulder
if ~isempty(shoulder)
    Stemp=shoulder(1:3);
    Stemp=Mlg\[Stemp(1:3)';1];
    LHO.shoulder=Stemp(1:3)'; 
end


    
