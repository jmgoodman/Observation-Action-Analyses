function [LHO,sd] = calibratestatic(LHO,calibdata)

joints=get(LHO,'fingerjoints');
numFingers=size(calibdata,2);

for ii=1:numFingers
    correct=find(~isnan(calibdata(:,ii,1)));
    x=mean(calibdata(correct,ii,1));
    y=mean(calibdata(correct,ii,2));
    z=mean(calibdata(correct,ii,3));
    sd=std([x;y;z;]);
    
    joints(ii,7,1)=mean(x);
    joints(ii,7,2)=mean(y);
    joints(ii,7,3)=mean(z);
    
    mcp(ii,1)=mean(x);
    mcp(ii,2)=mean(y);
    mcp(ii,3)=mean(z);
    
end

LHO=set(LHO,'fingerjoints',joints);
LHO=set(LHO,'metacarpaljoints',mcp);