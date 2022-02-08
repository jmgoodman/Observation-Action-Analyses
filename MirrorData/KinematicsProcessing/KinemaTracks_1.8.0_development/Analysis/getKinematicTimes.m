function [ktimes digitalIO]=getKinematicTimes(digitalIO,marker)

idx1=find(digitalIO.Data==marker(1));
idx2=find(digitalIO.Data==marker(2));

diff=abs(numel(idx1)-numel(idx2));
if diff>1
    disp('Possible data loss during transmission of Kinematic Data.');
end

idx=find(digitalIO.Data==marker(1) | digitalIO.Data==marker(2));


ktimes=zeros(1,numel(idx));
ktimes(1,:)=digitalIO.TimeStampSec(idx);

digitalIO.Data(idx)=[];
digitalIO.TimeStamp(idx)=[];
digitalIO.TimeStampSec(idx)=[];
