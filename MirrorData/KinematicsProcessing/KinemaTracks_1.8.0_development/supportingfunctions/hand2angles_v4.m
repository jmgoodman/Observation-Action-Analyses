function angles = hand2angles_v4(localpos, globalpos, handside)

%%%%%%%%%%%%%% Calculate finger angles from position data %%%%%%%%%%%%%%%%%
%
%   Note: handside = 1 is left and handside = -1 is right
%
%   Next Iteration by Andrej Filippow. Based on the function from 
%   A. Agudelo-Toro (v3), which was based on K. Menz (v2) and Stefan 
%   Schaffelhofer's hand2angles.m (v1)
%   28.09.2017  Instead of comparing angles to each other, angles are
%               back-transformed into the frame of the MCP, then measured
%               against a vector out of natural motion range
%   01.10.2015  Fully rewritten to use Tait-Bryan Angles in radians as in the 
%               musculoskeletal model instead of projections in degrees 
%               as handled in previous versions.
%   01.09.2015  Added to Kinematracks by Andres Agudelo-Toro for the
%               realtime project.
%   15.07.2013  spread is no longer [-90 90] (compared to pos or neg z-axis, 
%               depending on which is closer to AB, i.e. if AB(3) > or <
%               0), but [-180 180] since it is always compared to positive
%               z-axis
%   09.07.2013  shoulder yaw (DOF #25) is now calculated by projecting
%               Shoulder-Elbow-vector into x-y-plane and taking the angle
%               to the y-axis intead of to the x-axis. With the old way,
%               the angle tended to jump between -180 and +180 deg,
%               although it is a continuous movement
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
%   16.01.2013  calculation of wrist roll restricted: calculate wrist roll
%               only, if elbow angle > and <179deg. otherwise a normal on
%               elbow can't be calculated accurately, on which wrist roll
%               is compared to
%   04.07.2012  condition for v1 in spread calculation added
%               calculation of shoulder roll changed
%   29.06.2012  unnecessary multip taken away in l.60 (PIP calculation)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

angles = nan(32,1);

%% Fingers

% For the fingers the convention ABCT is used, A is the MCP joint, B is the PIP joint,
% C is the DIP joint and T is the tip. For the thumb A is the CMC joint, B is the MCP
% joint and C is the IP joint. See also
% http://chionline.com/anatomy/anat4.html

for i=0:4
    % Spread
    % Spread is measured against the horizontal, since no finger should go
    % past that (not even thumb AB)
    AB =  localpos(i*12+(4:6)) - localpos(i*12+(1:3)); % first phalanx
    ABprojection = [AB(1);0;AB(3)];
    if norm(ABprojection) > 0.01;
        angles(i*5+1) = acos(ABprojection'*[-1;0;0]/(norm(ABprojection)))-pi/2;
    else
        angles(i*5+1) = 0;
    end

    % MCP flexion
    a = angles(i*5+1);
    SPRDtransform = ...
        [cos(a), 0, sin(a);...
        0,1,0;...
        -sin(a),0,cos(a)];
    
%     if handside == -1
  % MCP is measured against horz. vector pointing towards back of hand
        baseline = SPRDtransform*[0;1;0];    
        angles(i*5+2) = -acos(baseline'*(AB')/norm(AB))+pi/2;
%     else
%         baseline = SPRDtransform*[0;-1;0];
%         angles(i*5+2) = acos(baseline'*(ABtemp')/norm(ABtemp))-pi/2;
%     end
    
    % Rotation
    % I suspect that normal fingers cannot rotate longitudinally at all,
    % and the thumb only marginally, but this extra degree of freedom
    % somewhat counteracts the fact that we do not model transversal hand
    % flexion (mobility of e.g. pinky and index MCP relative to the others)
    
    % Rotation is measured at the medial or distal phalanx, since the
    % proximal phalanx is the rotation axis itself
    BC = localpos(i*12+(7:9)) - localpos(i*12+(4:6)); %BC
    CT = localpos(i*12+(10:12)) - localpos(i*12+(7:9)); %CT
    b =  angles(i*5+2);
    MCPtransform = ...
        [1,0,0;...
        0, cos(b), sin(b);...
        0, -sin(b), cos(b)];
    
    % Reverse mcp and spread transforms
    % [TODO] this order works, i need to check why this one, and not the
    % opposite
    phalanx = MCPtransform\(SPRDtransform\BC');

    phalanx(3) = 0; % project on x-y plane
    if norm(phalanx) < 0.01;   %since apparently some primates can bend only their DIP at will
        phalanx = MCPtransform\(SPRDtransform\CT');
        phalanx(3) = 0;
    end

    baseline = [1;0;0];
    % if both medial and distal phalanx have negligible x-y projections,
    % the finger must be straight and rotation does not matter at all
    if norm(phalanx) >= 0.01;
        phalanx = phalanx/norm(phalanx);
        angles(i*5+3) = acos(baseline'*phalanx);
        if angles(i*5+3) > pi
            angles(i*5+3) = 2*pi - angles(i*5+3);
            disp('angles(i*5+3) > pi');
        end
        angles(i*5+3) =  angles(i*5+3)-pi/2;
    end
    if isnan(norm(phalanx))
        angles(i*5+3) = NaN;
    end
    if norm(phalanx) < 0.01;
        angles(i*5+3) = 0;
    end 
    AB = localpos(i*12+(4:6)) - localpos(i*12+(1:3));
    BC = localpos(i*12+(7:9)) - localpos(i*12+(4:6));
    CT = localpos(i*12+(10:12)) - localpos(i*12+(7:9));
    
    % PIP 
    c =  angles(i*5+3);
    ROTtransform = ...
        [cos(c), -sin(c), 0;...
        sin(c),cos(c),0;...
        0,0,1];
    baseline = [0; -1; 1];
    temp = SPRDtransform*MCPtransform*ROTtransform*baseline;
    angles(i*5+4) = -pi/4 + acos(dot(BC,temp)/(norm(BC)*norm(temp)));

    % DIP just use the same as PIP
    % Note: this fails for angles above 45 deg 
    % which happens sometimes when the monkey is
    % in the hand rest position or he glove slides
    d =  angles(i*5+4);
    PIPtransform = ...
        [1,0,0;...
        0, cos(d), sin(d);...
        0, -sin(d), cos(d)];
    temp = SPRDtransform*MCPtransform*ROTtransform*PIPtransform*baseline;
    angles(i*5+5) = -pi/4 + acos(dot(CT,temp)/(norm(CT)*norm(temp)));

end

%% Elbow (K. Menz code, has to be checked)

EW = globalpos(64:66)-globalpos(67:69);   %wrist - elbow -> vector pointing from elbow to wrist
ES = globalpos(76:78)-globalpos(67:69);   %shoulder - elbow -> vector pointing from elbow to shoulder
angles(29) = acos(dot(EW,ES)/(norm(EW)*norm(ES)));
if ~isreal(angles(29))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    angles(29) = real(angles(29));
end

% For the elbow with the previous method 90 deg is the arm in hadrest and
% 0 deg is the arm pointing up (as when one touches one's elbow)
% This offset makes the variable a little nicer for decoding. This has to be 
% properly reverted for the VR and skeletal model. This was introduced on 19.9.17
angles(29) = pi/2 - angles(29);

%% Wrist

% Get local vectors for wrist and elbow (hand frame), they will be used to
% produce the hand angles
EW = localpos(64:66) - localpos(67:69);   %wrist - elbow -> vector pointing from elbow to wrist
EhE = localpos(73:75) - localpos(67:69);   %elbow helping point - elbow -> vector pointing from elbow to elbow helping point

% Produce the wrist kinematics frame from the local hand frame 
Zwk = EW/norm(EW);
Ywk = EhE/norm(EhE);
Xwk = cross(Ywk, Zwk);

% The wrist kinematics frame is defined respect to the hand kinematics 
% reference frame. Find now the hand frame respect to the wrist frame 
% using the transform matrix. There are better ways to do this but 
% the original code already has this weird local reference frame for 
% the hand. 
hTw = [Xwk' Ywk' Zwk'];
wTh = inv(hTw);
X_wk_ppp = wTh(:,1);
Y_wk_ppp = wTh(:,2);
Z_wk_ppp = wTh(:,3);

% Map the hand frame (transformed wrist frame) to the musculoskeletal 
% model convention Xw=Xwk, Yw=-Zwk, Zw=Ywk.

X_wk_ppp = [X_wk_ppp(1) -X_wk_ppp(3) X_wk_ppp(2)];
Y_wk_ppp = [Y_wk_ppp(1) -Y_wk_ppp(3) Y_wk_ppp(2)];
Z_wk_ppp = [Z_wk_ppp(1) -Z_wk_ppp(3) Z_wk_ppp(2)];

% Note not only the wrist reference frame has to be mapped but
% also the child frame (Xw’’’, Yw’’’, Zw’’’)

X_w_ppp = X_wk_ppp;
Y_w_ppp = -Z_wk_ppp;
Z_w_ppp = Y_wk_ppp;

% Calculate wrist's Tait-Bryan angles as defined by the musculoskeletal 
% model. Let the wrist transformed frame (hand) be (Xw’’’, Yw’’’, Zw’’’) on the 
% shoulder's reference frame (Xw, Yw, Zw).
% The sequence of rotations defined by the musculoskeletal model are 
% (-Y, Z', -X’’). See documentation of the real-time project for a better
% description.

% Calculate the Tait-Bryan angles
angles(26) = atan2(X_w_ppp(3), X_w_ppp(1));
angles(27) = asin(X_w_ppp(2));
if ~isreal(angles(27))
    warning('Wrist angle 27 is complex');
    angles(27) = real(angles(27));
end
angles(28) = atan2(Z_w_ppp(2), Y_w_ppp(2));

% The first wrist angle (angle(26)) can be sometimes over 180 deg and
% atan2 jumps to -180. Robots and decoders don't like those jumps...
if angles(26) < 0
    angles(26) = pi + pi + angles(26);
end

% Make the variable a little nicer for decoding (as in elbow). 
% This has to be properly reverted for the model and VR
angles(26) = angles(26) - 3/4*pi;

%% Shoulder

% Get the global vectors and convert the kinematics frame (k) to the skeletal
% model shoulder reference frame (Xs=-Xsk, Ys=-Zsk, Zs=-Ysk)
ES = globalpos(76:78) - globalpos(67:69);   %shoulder - elbow -> vector pointing from elbow to shoulder
ES = [-ES(1) -ES(3) -ES(2)];
EW = globalpos(64:66) - globalpos(67:69);  %wrist - elbow -> vector pointing from elbow to wrist
EW = [-EW(1) -EW(3) -EW(2)];

% Calculate shoulder's Tait-Bryan angles as defined by the musculoskeletal 
% model. Let the shoulder transformed frame (upper arm) be (Xs’’’, Ys’’’, Zs’’’)
% on the shoulder's reference frame (Xs, Ys, Zs).
% The sequence of rotations defined by the musculoskeletal model are 
% (Zs, -Xs’, -Ys’’). See documentation of the real-time project for a better
% description.

% Produce shoulder's transformed frame (Xs’’’, Ys’’’, Zs’’’)
Y_s_ppp = ES/norm(ES);
Z_s_ppp = cross(EW,ES);
Z_s_ppp = Z_s_ppp/norm(Z_s_ppp);
X_s_ppp = cross(Y_s_ppp,Z_s_ppp);
X_s_ppp = X_s_ppp/norm(X_s_ppp);

% Calculate Tait-Bryan angles
angles(30) = -atan2(Y_s_ppp(1), Y_s_ppp(2));
angles(31) = -asin(Y_s_ppp(3));
angles(32) = atan2(X_s_ppp(3), Z_s_ppp(3));

end
