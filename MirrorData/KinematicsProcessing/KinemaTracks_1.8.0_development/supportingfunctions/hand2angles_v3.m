function angles = hand2angles_v3(localpos, globalpos, handside)

%%%%%%%%%%%%%% calculate finger angles from position data %%%%%%%%%%%%%%%%%
%
%   By Andres Agudelo-Toro. Based on the function from K. Menz (v2), which 
%   was based on Stefan Schaffelhofer's hand2angles.m (v1)
%
%   handside = 1 is left and handside = -1 is right
%   
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

% % Thumb (this calculation didn't work so well, the default finger
% calculation works also fine)

% % Get the local finger vectors and convert the kinematics frame (k) to the skeletal
% % model reference frame (Xf1=Xf1k, Yf1=-Zf1k, Zf1=Yf1k)
% 
% % MCP to CMC, skeletal model uses a negative Y axis
% BA = localpos(1:3) - localpos(4:6);
% BA = [BA(1) -BA(3) BA(2)];
% % IP to Tip, used to get the full orientation. This is more stable
% % than MCP to IP
% CT = localpos(10:12) - localpos(7:9);
% CT = [CT(1) -CT(3) CT(2)];
% 
% % Calculate thumb's Tait-Bryan angles as defined by the musculoskeletal 
% % model. Let the thumb's metacarpal frame be (Xf1’’’, Yf1’’’, Zf1’’’) on the 
% % reference frame (Xf1, Yf1, Zf1).
% % The sequence of rotations defined by the musculoskeletal model are 
% % (-Y, -Z'). See documentation of the real-time project for a better
% % description.
% 
% % Produce the thumb's metacarpal frame, Zf1 is not required
% Y_f1_ppp = BA/norm(BA);
% Z_f1_ppp = cross(BA, CT);
% Z_f1_ppp = Z_f1_ppp/norm(Z_f1_ppp);
% X_f1_ppp = cross(Y_f1_ppp, Z_f1_ppp);
% 
% % Calculate the Tait-Bryan angles for CMC
% angles(1) = atan2(X_f1_ppp(3), X_f1_ppp(1));
% angles(2) = -asin(X_f1_ppp(2));
% 
% % Thumb MCP (K. Menz code, that's ok)
% AB = localpos(4:6) - localpos(1:3);
% BC = localpos(7:9) - localpos(4:6);
% CT = localpos(10:12) - localpos(7:9);
% angles(3) = acos(dot(BC,AB)/(norm(BC)*norm(AB)));
% if ~isreal(angles(3))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
%     angles(3) = real(angles(3));
% end
% 
% % Thumb DIP (K. Menz code, that's ok)
% angles(4) = deg2rad(fingAngDIP(BC, CT, 1, handside));

% Rest of fingers (but now also the thumb!)
for i=0:4
    
    % Get the local finger vectors and convert the kinematics 
    % frame (k) to the skeletal model reference 
    % frame (Xf1=Xf1k, Yf1=-Zf1k, Zf1=Yf1k)

    % PIP to MCP, skeletal model uses a negative Y axis
    BA = localpos(i*12+(1:3)) - localpos(i*12+(4:6));
    BA = [BA(1) -BA(3) BA(2)];
    
    % Tip to DIP, TC is used instead of CB, BC or CT because
    % it provides a more stable cross product to calculate the X
    % component. This is also a result of how the glove was built. 
    % In most of the hand poses they are at an angle. 
    % Recall that parallel vectors produce a zero cross
    % product. CB, BC or CT also produce undesired X orientations.
    %
    % These are HOWEVER some known issues from getting the angles from
    % just the joint positions:
    %
    % - For the precision grip, it happens sometimes that TC and BA are 
    %   parallel and have the same direction, this is specially true for
    %   the index finger.
    % - In some rare cases, a full extended hand makes TC and BA parallel
    %   with opposite direction. This is however not common because of the
    %   way the glove is built.
    %     
    
    TC = localpos(i*12+(7:9)) - localpos(i*12+(10:12));
    TC = [TC(1) -TC(3) TC(2)];
        
    % Calculate Tait-Bryan angles for the base of the finger (MCP joint)
    % as defined by the musculoskeletal model. Let the fingers's PP frame 
    % be (Xfn’’’, Yfn’’’, Zfn’’’) on the reference frame (Xfn, Yfn, Zfn), 
    % n = {2,3,4,5}. The sequence of rotations defined by the
    % musculoskeletal model are (Z, -X'). See documentation of 
    % the real-time project for a better description.
    
    Y_fn_ppp = BA/norm(BA);
    X_fn_ppp = cross(TC, BA);
    
    % This quick hack handles the case when BA and TC cross the 0 or 180 deg
    % angles. Should be improved
    
    if i == 0
        %fprintf('X %.1f %.1f %.1f',X_fn_ppp);
        % Thumb is special, check orientation by comparing to Z axis
        % which points down of palm in the musculoskeletal coordinates
        if dot(X_fn_ppp, [0 0 1]) < 0
            if norm(X_fn_ppp) < 3
                fprintf('*');
            end
            %fprintf(' dotXZ<0 %f %f %f\n', X_fn_ppp);
            %X_fn_ppp = cross(BA, TC);
            %fprintf(' dotXZ<0 %f %f %f\n\n', X_fn_ppp);
        end
        %fprintf('\n');
    elseif i == 4
        % Little is special because tends to be oriented differently
        if handside == 1
            % Left
            if dot(X_fn_ppp, [1 0 -0.5]) < 0
                X_fn_ppp = cross(BA, TC);
            end
        else
            % Right
            %if dot(X_fn_ppp, [1 0 -0.5]) < 0
            %    X_fn_ppp = cross(BA, TC);
            %end
        end
    else
        % Rest of fingers
        if handside == 1
            % Left            
            if dot(X_fn_ppp, [1 0 0]) < 0
                X_fn_ppp = cross(BA, TC);
            end
        else
            % Left            
            %if dot(X_fn_ppp, [1 0 0]) < 0
            %    X_fn_ppp = cross(BA, TC);
            %end
        end
    end

    Z_fn_ppp = cross(X_fn_ppp, Y_fn_ppp);

    % Calculate the Tait-Bryan angles for MCP
    angles(i*5+1) = -atan2(Y_fn_ppp(1), Y_fn_ppp(2));
    angles(i*5+2) = -asin(Y_fn_ppp(3));
    angles(i*5+3) = atan2(X_fn_ppp(3), Z_fn_ppp(3));
    
    % PIP (K. Menz code, that's ok for most angles)
    AB = localpos(i*12+(4:6)) - localpos(i*12+(1:3));
    BC = localpos(i*12+(7:9)) - localpos(i*12+(4:6));
    CT = localpos(i*12+(10:12)) - localpos(i*12+(7:9));
    angles(i*5+4) = acos(dot(BC,AB)/(norm(BC)*norm(AB)));
    if ~isreal(angles(i*5+4))         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
        angles(i*5+4) = real(angles(i*5+4));
    end
    
    % Note (6.2.2017): fingAngDIP fails for the right hand! 
    
    % DIP (K. Menz code, that's ok)
    angles(i*5+5) = deg2rad(fingAngDIP(BC, CT, i+1, handside));

    % Quick fix after new thum orientation. Don't know why yet
    if i == 0
        angles(i*5+5) = -angles(i*5+5);
    end
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
% This offset makes the variable a little nicer for decoding. It has to be 
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
% atan2 jumps to -180. Robots and decoders dont like those jumps...
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
