function [LHO]  = updateLocalHand(LHO,GHO)
global GST;
LHO=global2local(LHO,GHO);

joints=LHO.fingerjoints;
angles=LHO.fingerangles;
fingerradius=LHO.fingerradius;
ab=LHO.lengthab;
bc=LHO.lengthbc;


[joints, angles, helpvector]=calculateJointPhalanxMedialis(...
    joints,angles,fingerradius,ab,bc,GST.flatf1sens,GST.nopipinversion); % located in "supportingfunctions" folder.
LHO.fingerjoints=joints;
LHO.fingerangles=angles;
LHO.helpvector=helpvector;
end

%%%%%%%%%%%%%%%RUECKRECHNEN%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%(Momo(globalHand.S6(4:7)',globalHand.S6(1:3)')*[localHand.S3(1:3)';1]
%%%%%%%%%%%%%%%RUECKRECHNEN%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

