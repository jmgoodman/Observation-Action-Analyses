function angles = hand2angles_v5(localpos, globalpos, handside)

%%%%%%%%%%%%%% Calculate finger angles from position data %%%%%%%%%%%%%%%%%
%
%   Note: handside = 1 is left and handside = -1 is right
%
%   V.5 Combines ideas from V.3 and V.4
%   V.4 Andrej Filippow
%   V.3 Andres Agudelo-Toro
%   V.2 Katharina Menz
%   V.1 Stefan Schaffelhofer
%
%   09.10.2017  Changed to support new rotation order of the fingers.
%               It takes ideas from v3 and v4. 
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

% Fingers

% For the fingers the convention ABCT is used, A is the MCP joint, B is the PIP joint,
% C is the DIP joint and T is the tip. For the thumb A is the CMC joint, B is the MCP
% joint and C is the IP joint but the thumb is treated here as all the other fingers. 
% See also http://chionline.com/anatomy/anat4.html

% All fingers
for i=0:4
    
    % Get the local finger vectors and convert the kinematics 
    % frame (k) to the skeletal model reference 
    % frame (X=Xk, Y=-Zk, Z=Yk)

    % PIP to MCP
    BA = localpos(i*12+(1:3)) - localpos(i*12+(4:6));
    BA = [BA(1) -BA(3) BA(2)];    
    % DIP to PIP
    CB = localpos(i*12+(4:6)) - localpos(i*12+(7:9));
    CB = [CB(1) -CB(3) CB(2)];    
    % PIP to DIP
    BC = -CB;    
    % Tip to DIP
    TC = localpos(i*12+(7:9)) - localpos(i*12+(10:12));
    TC = [TC(1) -TC(3) TC(2)];
    % DIP to Tip
    CT = -TC;    
    % DIP to Sensor
    CS = localpos(78+i*3+(1:3)) - localpos(i*12+(7:9));
    CS = [CS(1) -CS(3) CS(2)];
    
    % Calculate Tait-Bryan angles for the base of the finger (MCP joint)
    % as defined by the musculoskeletal model. The fingers's fully rotated
    % proximal phalange frame is called (Xmcp’’’, Ymcp’’’, Zmcp’’’) on the reference 
    % frame of MCP (X, Y, Z).
    % CS is used instead of CB, BC, CT or TC because
    % it provides a more stable cross product to calculate the X
    % component. This is a very safe way to determine orientation
    % as the sensor position respect to DIP (and Tip) 
    % is fixed regardless of the finger pose
    Y_mcp_ppp = BA/norm(BA);
    X_mcp_ppp = cross(CT, CS);   
    X_mcp_ppp = X_mcp_ppp/norm(X_mcp_ppp);    
    Z_mcp_ppp = cross(X_mcp_ppp, Y_mcp_ppp);
    Z_mcp_ppp = Z_mcp_ppp/norm(Z_mcp_ppp);

    % Calculate the Tait-Bryan angles for MCP
    
    % Old rotation order: Z, -X, -Y (i.e. spread, flexion, rotation)
    %angles(i*5+1) = -atan2(Y_mcp_ppp(1), Y_mcp_ppp(2));
    %angles(i*5+2) = -asin(Y_mcp_ppp(3));
    %angles(i*5+3) = atan2(X_mcp_ppp(3), Z_mcp_ppp(3));
    
    % New rotation order: -X, Z, -Y (i.e. flexion, spread, rotation)
    angles(i*5+1) = -atan2(Y_mcp_ppp(3), Y_mcp_ppp(2));
    angles(i*5+2) = -asin(Y_mcp_ppp(1));
    angles(i*5+3) = -atan2(Z_mcp_ppp(1), X_mcp_ppp(1));

    % Now calculate the PIP frame and angle.
    % This uses the idea from A. Filippow to calculate the angle
    % based on the reference frame. There are two differences:
    % first, the frame is calculated in a cheaper way using the cross
    % product instead of matrix multiplications. Second, it
    % uses atan2 instead of acos because is not restricted to two 
    % quadrants only
    Y_pip_ppp = CB/norm(CB);
    X_pip_ppp = cross(CT, CS);
    X_pip_ppp = X_pip_ppp/norm(X_pip_ppp);
    Z_pip_ppp = cross(X_pip_ppp, Y_pip_ppp);
    Z_pip_ppp = Z_pip_ppp/norm(Z_pip_ppp);
    
    angles(i*5+4) = atan2(dot(BC,Z_mcp_ppp), -dot(BC,Y_mcp_ppp));
    
    % Now also find the flexion for DIP using the same principle
    % as in the PIP
    angles(i*5+5) = atan2(dot(CT,Z_pip_ppp), -dot(CT,Y_pip_ppp));

    %{    
    % TEMP debug plot
    if i == 4 && 0

        DEBUGAXES = get(figure(1000),'CurrentAxes');
        if isempty(DEBUGAXES)
            DEBUGAXES = axes();
        end
        axis equal;

        A = [localpos(i*12+1) -localpos(i*12+3) localpos(i*12+2)];
        B = [localpos(i*12+4) -localpos(i*12+6) localpos(i*12+5)];
        C = [localpos(i*12+7) -localpos(i*12+9) localpos(i*12+8)];
        T = [localpos(i*12+10) -localpos(i*12+12) localpos(i*12+11)];
        ABCT = [A; B; C; T];
    
        %disp(localpos(78+i*3+(1:3)));
        %disp(ABCT);
        %disp(angles(i*5+1:5));
        
        cla(DEBUGAXES);
        hold(DEBUGAXES,'on');
        u=X_mcp_ppp;
        v=Y_mcp_ppp;
        w=Z_mcp_ppp;
        quiver3(DEBUGAXES,B(1),B(2),B(3),u(1),u(2),u(3),'r');
        quiver3(DEBUGAXES,B(1),B(2),B(3),v(1),v(2),v(3),'g');
        quiver3(DEBUGAXES,B(1),B(2),B(3),w(1),w(2),w(3),'b');
        u=X_pip_ppp;
        v=Y_pip_ppp;
        w=Z_pip_ppp;
        x=Z_Y_pip_ppp;
        y=CT/norm(CT);
        quiver3(DEBUGAXES,C(1),C(2),C(3),u(1),u(2),u(3),'r');
        quiver3(DEBUGAXES,C(1),C(2),C(3),v(1),v(2),v(3),'g');
        quiver3(DEBUGAXES,C(1),C(2),C(3),w(1),w(2),w(3),'b');
        quiver3(DEBUGAXES,C(1),C(2),C(3),x(1),x(2),x(3));
        quiver3(DEBUGAXES,C(1),C(2),C(3),y(1),y(2),y(3));
        plot3(DEBUGAXES,ABCT(:,1),ABCT(:,2),ABCT(:,3),':');
        %axis(DEBUGAXES,[-5,5,-5,5,-5,5]);
        axis(DEBUGAXES,'auto');
    
    end
    %}
end

% Emergency replace angle
%good = 3;
%bad = 4;
%angles(bad*5+(1:5)) = angles(good*5+(1:5));

% Elbow

% Uses K. Menz code
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

% Wrist

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
angles(28) = atan2(Z_w_ppp(2), Y_w_ppp(2));

if ~isreal(angles(27))
    warning('Wrist angle 27 is complex');
    angles(27) = real(angles(27));
end

% The first wrist angle (angle(26)) can be sometimes over 180 deg and
% atan2 jumps to -180. Robots and decoders don't like those jumps...
if angles(26) < 0
    angles(26) = pi + pi + angles(26);
end

% Make the variable a little nicer for decoding (as in elbow). 
% This has to be properly reverted for the model and VR
angles(26) = angles(26) - 3/4*pi;

% Shoulder

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
