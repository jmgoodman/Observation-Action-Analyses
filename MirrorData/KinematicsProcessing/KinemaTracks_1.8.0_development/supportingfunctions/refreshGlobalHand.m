function [GHO]=refreshGlobalHand(GHO,data)

sensoridentifier=GHO.sensoridentifier;
armjoints=GHO.armjoints;
numFingers=max(sensoridentifier(sensoridentifier<6));
joints=NaN(numFingers,7,7); % number of joints, number of points per joint (W,U,T,C,B,A), coordinates: 4 quaternions 3 cartesians (in REVERSE order)
referencefound=0;
for ii=1:length(sensoridentifier)
        idx=sensoridentifier(ii);
        if ~(idx==0) % the sensoridentifier is zero if a port is not used, in this case ignore   
            switch idx
                case 8
                    referencefound=1; % okay, so this is the "reference" sensor (i.e., "S6" in Schaffelhofer & Scherberger 2012)
                    reference(1,1,1:7)=data(ii+1,1:7); % each element of the second index corresponds with a particular sensor (with the first index simply being time, hence the "+1" all over the place)
                    if abs(data(ii+1,1:3))>300
                        reference(1,1,1:7)=NaN;
                    end
                case 6 % I have to guess that at some point, an eighth sensor was added that permitted tracking of the proximal limb...
                    armjoints(1,1:7)=data(ii+1,1:7);  
                otherwise
                    joints(idx,1,1:7)  = data(ii+1,1:7);    % plus 1 because first row is reserved for time   
            end
        end
end

if referencefound
    GHO.fingerjoints = joints;
    GHO.reference    = reference;
    GHO.armjoints    = armjoints;
else
    error('No referece selected. Reconfigure your hand and try again!.');
end



% for ii=1:numTools 
%     idx=find(sensoridentifier==ii,1,'first'); % search the finger (idx) which should be assigned to the tool (ii)
%     if ~isempty(idx)                          % only assign tool to finger if the tools index has been defined!
%         hand.joints(ii,1:7)  = data(idx+1,1:7);    % plus 1 because first row is reserved for time      
%     else
%         hand.S(ii,1:7)  = NaN;
%     end  
% end

    

