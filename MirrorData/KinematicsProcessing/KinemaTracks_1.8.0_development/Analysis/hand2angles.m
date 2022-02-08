function [angles]=hand2angles(localpos,globalpos,handside)

angles=nan(28,1);

Rz=[0,0,1];
Rx=[1,0,0];
Ry=[0,1,0];


%% FINGER ANGLES

ll=1;
for ff=1:12:60 % calculate angles for all fingers, each finger consist of 12 values, some of them are the joints used for angle computation (such as A (mcp), B(pip), C(dip), and T (finger tip)
    
% get local joints of fingers    
AB=localpos(ff+3:ff+5)  -localpos(ff:ff+2); % copy the required joint positions out of the localpos (joint positions in reference to the the reference sensor (hand dorsum) matrix
BC=localpos(ff+6:ff+8)  -localpos(ff+3:ff+5);
CT=localpos(ff+9:ff+11) -localpos(ff+6:ff+8);
% AT=localpos(ff+6:ff+8)  -localpos(ff+9:ff+11);


refplane=handside*[-1;0;0]; % define a reference frame within the local coordinate system. this vector will be used to extract 
mcpref=[AB(1);0;AB(3)];% for computing the mcp flexion extension, the vector AB (mcp to pip) is projected to the plane of the wrist (X-Z plane). The angle between AB and its X-Z-projection returns the mcp flexion/extension angle
   
% SPREAD
v1=[0,1,0];
v2=[AB(1),abs(AB(3)),0];
angles(ll)=handside*vectors2angle(v1,v2); %checked for correctness by Stefan for both hands
% angles(ll)=handside*vectors2angle2([0;0;1],AB,[0;1;0]);

% MCP
if AB(3)<0 % if the flexion is so strong, that AB get's negative, invert the mcpref vector (otherwise angle is not correct)
  angles(ll+1)=vectors2angle2(-1*mcpref,AB,refplane);  
else
  angles(ll+1)=vectors2angle2(mcpref,AB,refplane);
end

% PIP
angles(ll+2)= vectors2angle2(AB,BC,refplane);

% DIP
angles(ll+3)= vectors2angle2(BC,CT,refplane);


ll=ll+4;

end


%% ARM ANGLES
EW=localpos(64:66)-localpos(67:69); % EW=W-E  This vector (lower arm vector) was transformed into the coordinate system of the hand
% EW=vectgor pointing from wrist to elbow
%Wrist Yaw
v1=[EW(3),EW(1),0];
v2=[Rz(3),Rz(1),0];
angles(21) = handside*vectors2angle(v1,v2); % %checked for correctness by Stefan for both hands

% Wrist Pitch 
v1=[EW(3),EW(2),0];
v2=[Rz(3),Rz(2),0];

angles(22) = vectors2angle(v1,v2); %checked for correctness by Stefan for both hands

% Wrist Roll 
WW1=localpos(70:72)-localpos(64:66); % Vector EE1 the local-transformed vector of a global vector pointing normal on plane ESW (Sholder, Elbow, and Wrist)
v1=[0,1,0];
v2=[WW1(1),WW1(2),0];
angles(23) = handside*vectors2angle(v1,v2); %checked for correctness by Stefan for both hands


%% ARM ANGLES

% Elbow
EW=globalpos(64:66)-globalpos(67:69);
ES=globalpos(76:78)-globalpos(67:69); % x axis of shoulder coordinate system
angles(24)=rad2deg(atan2(norm(cross(EW,ES)),dot(EW,ES))); %checked for correctness by Stefan for both hands

% SEE1    rossproduct(E-S,W-S); % Plane SEW described by points S (shoulder), E (elbow), and W (wrist)
% nSEW=SEW/norm(SEW);  %normal vector on plane SEW
% W1=W+nSEW*200;  %help point normal on point E of plane SEW




% Shoulder Yaw
%
%           R   subject   L
%     -y                       y+          x+
%
%                WAVE
%
%                                          x-
E=globalpos(67:69);
S=globalpos(76:78);
W=globalpos(64:66);

[tm,dcm]=cart2transmat([S(1),S(2),S(3)],[-1 0 0],[0,-1,0],[0,0,-1]);
E1=tm\[E;1];
E1=E1(1:3);
S1=tm\[S;1];
S1=S1(1:3);
W1=tm\[W;1];
W1=W1(1:3);

% S1=[0,0,0];
% E1=[0,0,-150];
% W1=[150,150,-150];

ex=(E1-S1)/norm(E1-S1);
ez=(cross(E1-S1,E1-W1)/norm(cross(E1-S1,E1-W1)))/(norm(cross(E1-S1,E1-W1)/norm(cross(E1-S1,E1-W1)))); % calculate unity vector onto place vec1-vec2
ey=(cross(ex,ez)/norm(cross(ex,ez)))/(norm(cross(ex,ez)/norm(cross(ex,ez))));


[~,dcm]=cart2transmat([0,0,0],ex,ey,ez);
% hold off;
% plot3([0,1]*100,[0,0]*100,[0,0]*100,'r'); hold on;
% plot3([0,0]*100,[0,1]*100,[0,0]*100,'b'); hold on;
% plot3([0,0]*100,[0,0]*100,[0,1]*100,'g'); hold on;
% 
% plot3([0,ex(1)]*100,[0,ex(2)]*100,[0,ex(3)]*100,'r'); hold on;
% plot3([0,ey(1)]*100,[0,ey(2)]*100,[0,ey(3)]*100,'b'); hold on;
% plot3([0,ez(1)]*100,[0,ez(2)]*100,[0,ez(3)]*100,'g'); hold on;
% plot3([S(1),E(1),W(1)],[S(2),E(2),W(2)],[S(3),E(3),W(3)]); hold on;
% plot3([S1(1),E1(1),W1(1)],[S1(2),E1(2),W1(2)],[S1(3),E1(3),W1(3)],'r'); hold on;
% xlabel('x'); ylabel('y'); zlabel('z');
% set(gca,'DataAspectRatio',[1 1 1],'Xlim',[-350 350],'YLim',[-200,200],'ZLim',[-350 150]);
% grid on;
% drawnow;


[yaw,pitch,roll]=dcm2angle(dcm,'ZYX');
% [eul]=dcm2eul(dcm);
% % 
% rad2deg(yaw) 
% rad2deg(pitch) 
% rad2deg(roll)

angles(25)=rad2deg(yaw);
angles(26)=rad2deg(pitch);
angles(27)=rad2deg(roll);
 

end



