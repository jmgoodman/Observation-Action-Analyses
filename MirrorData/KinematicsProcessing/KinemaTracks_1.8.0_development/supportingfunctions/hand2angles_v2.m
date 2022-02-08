function [angles angID] = hand2angles_v2(localpos, globalpos, handside)

%%%%%%%%%%%%%% calculate finger angles from position data %%%%%%%%%%%%%%%%%
%
%   By K. Menz. Based on Stefan Schaffelhofer's hand2angles.m
%   
%   01.09.2015  Added to Kinematracks by Andres Agudelo-Toro    
%   29.06.2012  unnecessary multip taken away in l.60 (PIP calculation)
%   04.07.2012  condition for v1 in spread calculation added
%               calculation of shoulder roll changed
%   16.01.2013  calculation of wrist roll restricted: calculate wrist roll
%               only, if elbow angle > and <179deg. otherwise a normal on
%               elbow can't be calculated accurately, on which wrist roll
%               is compared to
%   23.06.2013  restriction from 16.jan deleted. when using the smoothed
%               data, NaNs are not interpolated afterwards and therefore
%               there should no NaNs be produced in this code. And
%               apparently the angles calculated without this restriction
%               seem to be fine, too.
%   27.05.2013  correction in calculation of wrist roll: normal vector was
%               calculated with elbow-shoulder vector (local) and
%               elbow-wrist-vector (global) and compared to local y-axis.
%               BUT: arm vectors have to be both local, which is now the
%               case.
%   09.07.2013  shoulder yaw (DOF #25) is now calculated by projecting
%               Shoulder-Elbow-vector into x-y-plane and taking the angle
%               to the y-axis intead of to the x-axis. With the old way,
%               the angle tended to jump between -180 and +180 deg,
%               although it is a continuous movement
%   15.07.2013  spread is no longer [-90 90] (compared to pos or neg z-axis, 
%               depending on which is closer to AB, i.e. if AB(3) > or <
%               0), but [-180 180] since it is always compared to positive
%               z-axis
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

angles = nan(27,1);

%% FINGER ANGLES

ll = 1;
for ff = 1:12:60          %jeder durchgang ein finger, angefangen mit daumen
    
    % get local joints of fingers    
    AB = localpos(ff+3:ff+5)  -localpos(ff:ff+2);
    BC = localpos(ff+6:ff+8)  -localpos(ff+3:ff+5);
    CT = localpos(ff+9:ff+11) -localpos(ff+6:ff+8);

    % SPREAD
    v1 = [0 0 1];
    v2 = [AB(1) 0 AB(3)];
    if handside == 1
        if AB(1) > 0
            multip = 1;
        else
            multip = -1;
        end
    else
        if AB(1) > 0
            multip = -1;
        else
            multip = 1;
        end
    end
 
    angles(ll) = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2)))); 
    if ~isreal(angles(ll))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
        angles(ll) = real(angles(ll));
    end    
 
    
    % MCP
    if AB(2) < 0    %AB ist oberhalb von horizontaler ebene (x-z-ebene)
        multip = -1;
    else
        multip = 1;
    end
    
    mcpref=[AB(1); 0; AB(3)];         %projiziere AB in horizontale ebene. winkel zu x- und z-ebene bleibt gleich
    angles(ll+1) = multip*rad2deg(acos(dot(mcpref,AB)/(norm(mcpref)*norm(AB))));     %winkel von AB zu y-z-ebene
    %acos-formel ist hier ok, da auf grund der wahl von mcpref angles(ll+1) nur zwischen 0 und 90° liegen kann
    if ~isreal(angles(ll+1))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
        angles(ll+1) = real(angles(ll+1));
    end
        
    % PIP
    angles(ll+2) = rad2deg(acos(dot(BC,AB)/(norm(BC)*norm(AB))));  
    if ~isreal(angles(ll+2))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
        angles(ll+2) = real(angles(ll+2));
    end

    % DIP  
    fingNo = ll;
    angles(ll+3) = fingAngDIP(BC, CT, fingNo, handside);

    ll=ll+4;

end


%% HAND ANGLES
EW = localpos(64:66)-localpos(67:69); % EW=W(rist)-E(lbow)  
% This vector (lower arm vector) was transformed into the coordinate system of the hand
% EW = vector pointing from elbow to wrist        %!!!!!!!! "elbow to wrist" instead of "wrist to elbow"

%Wrist Yaw
if handside == 1
    if EW(1) < 0
        multip = -1;
    else 
        multip = 1;
    end
else
    if EW(1) < 0
        multip = 1;
    else
        multip = -1;
    end
end
v1 = [EW(1) 0 EW(3)];       %projiziere Unterarm in x-z-Ebene, um Winkel zur z-Achse bestimmen zu können
v2 = [0 0 1];
angles(21) = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2))));  %Winkel zw v1 und z-Achse
if ~isreal(angles(21))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(21) = real(angles(21));
end


% Wrist Pitch 
if EW(2) > 0                
    multip = 1;
else
    multip = -1;
end
v1 = [0 EW(2) EW(3)] ;      %projiziere Unterarm in y-z-Ebene, um Winkel zur z-Achse bestimmen zu können
angles(22) = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2))));  %Winkel zw v1 und z-Achse
if ~isreal(angles(22))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(22) = real(angles(22));
end

% Elbow
EW = globalpos(64:66)-globalpos(67:69);   %wrist - elbow -> vector pointing from elbow to wrist
ES = globalpos(76:78)-globalpos(67:69);   %shoulder - elbow -> vector pointing from elbow to shoulder
angles(24) = rad2deg(acos(dot(EW,ES)/(norm(EW)*norm(ES))));
if ~isreal(angles(24))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(24) = real(angles(24));
end

% Wrist Roll 
%if angles(24) > 1 && angles(24) < 179   %otherwise normal on elbow can't be calculated correctly
    ES = localpos(76:78) - localpos(67:69);     %shoulder-elbow: vector pointing from elbow to shoulder
    EW = localpos(64:66) - localpos(67:69);   %wrist - elbow -> vector pointing from elbow to wrist
    nor = cross(ES, EW);    %vector that is normal to shoulder-elbow-wrist plane and is points in local neg. y-axis in 0° roll
    if handside == 1
        if nor(1) < 0
            multip = 1;
        else
            multip = -1;
        end
    else
        nor = (-1)*nor;     %nor points in pos. local y-axis without correction of *(-1)
        if nor(1) < 0
            multip = -1;
        else
            multip = 1;
        end
    end
    v1 = [0 -1 0];          %vergleiche y-achse mit arm-ebenen orientierung
    v2 = [nor(1) nor(2) 0];
    angles(23) = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2))));
    if ~isreal(angles(23))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
        angles(23) = real(angles(23));
    end
%end


%% ARM ANGLES

% Shoulder Yaw
SE = globalpos(67:69)-globalpos(76:78);   %elbow - shoulder -> vector pointing from shoulder to elbow
v1 = [0,1,0];
v2 = [SE(1),SE(2),0];     %project upper arm into global x-y-plane

if handside == 1    %left
    multip2 = 1;
    if SE(1) > 0
        multip = -1;
    else
        multip = 1;
    end
else
    multip2 = -1;
    if SE(1) > 0
        multip = -1;
    else
        multip = 1;
    end
end
angles(25) = multip*rad2deg(acos(dot(multip2*v1,v2)/(norm(multip2*v1)*norm(v2))));
if ~isreal(angles(25))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(25) = real(angles(25));
end

%Shoulder Pitch
v1 = [-1 0 0];
v2 = [SE(1) 0 SE(3)];
if SE(3) > 0            %oberarm liegt unterhalb der horizontalen ebend
    multip = -1;
else
    multip = 1;
end
angles(26) = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2))));
if ~isreal(angles(26))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(26) = real(angles(26));
end



% Shoulder Roll   
%nor2 = cross(ES, EW);   %vector normal to ESW plane
if handside == 1
    if SE(2) > 0
        multip = 1;
    else
        multip = -1;
    end
else
    if SE(2) > 0
        multip = -1;
    else
        multip = 1;
    end
end

% v1 = [0 1 0];
% v2 = [0 nor2(2) nor2(3)];
v1 = [0 0 1];
v2 = [0 SE(2) SE(3)];
angles(27) = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2))));
if ~isreal(angles(27))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(27) = real(angles(27));
end


angID = cell(27,1);
angID{1,1} = 'Thumb spread';
angID{2,1} = 'Thumb MCP';
angID{3,1} = 'Thumb PIP';
angID{4,1} = 'Thumb DIP';
angID{5,1} = 'Index spread';
angID{6,1} = 'Index MCP';
angID{7,1} = 'Index PIP';
angID{8,1} = 'Index DIP';
angID{9,1} = 'Middle spread';
angID{10,1} = 'Middle MCP';
angID{11,1} = 'Middle PIP';
angID{12,1} = 'Middle DIP';
angID{13,1} = 'Ring spread';
angID{14,1} = 'Ring MCP';
angID{15,1} = 'Ring PIP';
angID{16,1} = 'Ring DIP';
angID{17,1} = 'Little spread';
angID{18,1} = 'Little MCP';
angID{19,1} = 'Little PIP';
angID{20,1} = 'Little DIP';
angID{21,1} = 'Wrist yaw';
angID{22,1} = 'Wrist pitch';
angID{23,1} = 'Wrist roll';
angID{24,1} = 'Elbow';
angID{25,1} = 'Shoulder yaw';
angID{26,1} = 'Shoulder pitch';
angID{27,1} = 'Shoulder roll';
end


