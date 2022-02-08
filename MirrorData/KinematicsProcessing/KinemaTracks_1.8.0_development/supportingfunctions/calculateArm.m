function [GHO]=calculateArm(GHO,LHO)
% Author: Stefan Schaffelhofer
% 
global FL;
lengthlowerarm=GHO.lengthlowerarm;
lengthupperarm=GHO.lengthupperarm;
globalarmjoints=GHO.armjoints;
localshoulder=LHO.shoulder;
globalshoulder=GHO.shoulder;


% TRANSFORM ARM
if ~isempty(localshoulder) && sum(sum(isnan(globalarmjoints(1,:))))<1   % only compute arm is shoulder is defined,and if the wrist sensor was tracked
    tempmomo=momo_mex(globalarmjoints(1,4:7),globalarmjoints(1,1:3)); 
    
    if isstruct(FL)
    
        if FL.wristinvert

            STemp=tempmomo*[0;0;+lengthlowerarm;1]; % only plus if sensor is pointing into direction of elbow-joint

        else
            STemp=tempmomo*[0;0;-lengthlowerarm;1]; % only plus if sensor is pointing into direction of elbow-joint
        end
        
    else
        STemp=tempmomo*[0;0;-lengthlowerarm;1]; % only plus if sensor is pointing into direction of elbow-joint
    end
        
    globalarmjoints(2,1:3)=STemp(1:3)'; % local coordinates of wrist
    
    W(1:3,1)=globalarmjoints(1,1:3);
    S(1:3,1)=globalshoulder(1:3);
    Eh=globalarmjoints(2,1:3)'; % This is the estimated Elbow angle, projecetion along wrist sensor
    
    SEhW=crossproduct(Eh-S,W-S); % Plane SEW described by points S (shoulder), Eh (estimated elbow), and W (wrist)
    nSEhW=SEhW/norm(SEhW);  %normal vector on plane SEW
    Wh = W + nSEhW;
   
    
    % Plane described by point S (shoulder), W (wrist) and Wh (normal
    % vector onto wirst)
    SWWh=crossproduct(W-S,Wh-S); 
    nSWWh=SWWh/norm(SWWh); % vector, pointing directly into E
    
    % calculate triangle Elbow, Shoulder, Wrist
    SW=norm(W-S);
    beta=acos((SW^2+lengthlowerarm^2-lengthupperarm^2)/(2*SW*lengthlowerarm));
    if ~isreal(beta)
        beta=0;
    end
    
    lx=lengthlowerarm*cos(beta);
    ly=lengthlowerarm*sin(beta);
    nWS=(S-W)/norm(S-W);
    Es=W+nWS*lx;
    E =Es+nSWWh*ly;
%     E2 =Es-nSWWh*ly;
    
%     if abs(norm(E1-Eh))<abs(norm(E2-Eh)) % the solution with shortest distance to Eh will be choosen
%         E=E1;
%     else
%         E=E2;
%     end
    globalarmjoints(2,1:3)=E;
%     globalarmjoints(2,1:3)=Eh; % this line is just for testing!!
    
    SEW=crossproduct(E-S,W-S); % Plane SEW described by points S (shoulder), Eh (estimated elbow), and W (wrist)
    nSEW=SEW/norm(SEW);  %normal vector on plane SEW

    E1=E+nSEW*20;
    globalarmjoints(4,1:3)=E1;
    
%     ref=nan(1,3);
%     ref(1,1:3)=GHO.reference(1,1,1:3);
%     refx=globalarmjoints(5,1:3); % calculate the x-axis of reference sensor in global coordinates
%     W1=W+(refx-ref)'; % place the global x-axis vector onto wrist as a help vector
%     globalarmjoints(3,1:3)=W1;
    
    
    
else
    globalarmjoints(2,1:3)=NaN;
    globalarmjoints(4,1:3)=NaN;
end

GHO.armjoints=globalarmjoints;
