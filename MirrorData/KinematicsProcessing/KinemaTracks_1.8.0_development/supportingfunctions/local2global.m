function [GHO] = local2global(GHO,LHO)

reference=GHO.reference;
% Mlg = momo_mex(reference(1,4:7),reference(1,1:3));
Mlg = momo(reference(1,4:7),reference(1,1:3));

localfingerjoints=LHO.fingerjoints;
globalfingerjoints=GHO.fingerjoints;
globalhelpvector=nan(3,5);
localarmjoints=LHO.armjoints;
globalarmjoints=GHO.armjoints;

helpvector=LHO.helpvector;

% localshoulder=get(LHO,'shoulder');
% lengthlowerarm=get(LHO,'lengthlowerarm');
% 
% globalarmjoints=get(GHO,'armjoints');


% TRANSFORM FINGERS
numFingers=size(localfingerjoints,1);
tempfinger=zeros(3,1);

for ss=1:numFingers
    tempfinger(:,1)=localfingerjoints(ss,4,1:3);
    temp=Mlg*[tempfinger;1];
    globalfingerjoints(ss,4,1:3)=temp(1:3)'; % T (tip)
    
    tempfinger(:,1)=localfingerjoints(ss,5,1:3);
    temp=Mlg*[tempfinger;1];
    globalfingerjoints(ss,5,1:3)=temp(1:3)'; % C (dip hinge) (ip hinge for thumb)
    
    tempfinger(:,1)=localfingerjoints(ss,6,1:3);
    temp=Mlg*[tempfinger;1];
    globalfingerjoints(ss,6,1:3)=temp(1:3)'; % B (pip hinge) (mcp hinge for thumb)
    
    tempfinger(:,1)=localfingerjoints(ss,7,1:3);
    temp=Mlg*[tempfinger;1];
    globalfingerjoints(ss,7,1:3)=temp(1:3)'; % A (mcp hinge) (cmc hinge for thumb)
    
    tempfinger(:,1)=helpvector(:,ss); % help vector pointing on the fingers plance for each finger (i.e., the common orientation vector, of U and V. These have consistent orientation corresponding to the normal of the fingernail surface, but are offset, with U lying over the dip and V lying over the fingertip). There are 5 of these, one for each finger
    temp=Mlg*[tempfinger;1];
    globalhelpvector(:,ss)=temp(1:3)';
end



temp=Mlg*[localarmjoints(1,1:3)';1];
globalarmjoints(1,1:3)=temp(1:3)'; % W

temp=Mlg*[localarmjoints(5,1:3)';1];
globalarmjoints(3,1:3)=temp(1:3)'; % help vector, pointing along the +X-axis of the reference from W (wrist)


globalarmjoints(5,1:3)=temp(1:3)';
GHO.fingerjoints=globalfingerjoints;
GHO.armjoints=globalarmjoints;
GHO.helpvector=globalhelpvector;
end