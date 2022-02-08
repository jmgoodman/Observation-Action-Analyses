function [recording]=merger(recording,ktimes)

if ~(size(recording,1)==numel(ktimes))
    error('Data does not fit!');
else
    
    recording(:,1,2)=ktimes;
    recording(:,1,3)=0;
    recording(:,1,4)=0;
    recording(:,1,5)=0;
    recording(:,1,6)=0;
    recording(:,1,7)=0;
    
end
end

