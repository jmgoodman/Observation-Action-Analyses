function [ang] = vectors2angle3(vec1,vec2)
% This function calculates angle vectors between two vectors in a given
% refpane is the normal vector pointing onto the plane the vectors should
% be rotated to

ref=[0,0,1];
r = vrrotvec(vec1, ref); % calculate the rotation between the plane of the two vectors and the reference frame
if ~isnan(r(4)) % last element (r(4) defines the angle of rotation
    normal = r(1:3); % get rotation axis
    ang = r(4); % angle of rotation in rad
    % create rotation matrix
    rotmat = [cos(ang)+normal(1)^2*(1-cos(ang)), normal(1)*normal(2)*(1-cos(ang))-normal(3)*sin(ang), normal(1)*normal(3)*(1-cos(ang))+normal(2)*sin(ang); ...
        normal(2)*normal(1)*(1-cos(ang))+normal(3)*sin(ang), cos(ang)+normal(2)^2*(1-cos(ang)), normal(2)*normal(3)*(1-cos(ang))-normal(1)*sin(ang); ...
        normal(3)*normal(1)*(1-cos(ang))-normal(2)*sin(ang), normal(3)*normal(2)*(1-cos(ang))+normal(1)*sin(ang), cos(ang)+normal(3)^2*(1-cos(ang))];

    vec1b = rotmat*vec1; % rotate both vectors into the plance of the reference frame
    vec2b = rotmat*vec2;

    angle=cart2pol(vec2b(1),vec2b(2)); % now both vectors are transformed to the reference plane, compute angle of the rotated vector2b
    ang=rad2deg(angle);
end

enable=0;
if enable
    
n2=cross(vec1b,vec2b)/norm(cross(vec1b,vec2b));

figure()

plot3([0 vec1(1)],[0 vec1(2)],[0 vec1(3)]); % plot vector-1 in blue (reference vector)
hold on;
plot3([0 vec2(1)],[0 vec2(2)],[0 vec2(3)],'r'); % plot vecotor-2 in blue 
hold on;
plot3([0 vec1b(1)],[0 vec1b(2)],[0 vec1b(3)],':'); % plot vector-1 rotated to the 
hold on;
plot3([0 vec2b(1)],[0 vec2b(2)],[0 vec2b(3)],':r');
hold on;
plot3([0 n(1)],[0 n(2)],[0 n(3)],'g');
grid on;
plot3([0 n2(1)],[0 n2(2)],[0 n2(3)],'y');
grid on;

xlabel('X');
ylabel('Y');
zlabel('Z');
set(gca,'DataAspectRatio',[1 1 1]);
close(gcf)
end



% % % ab_ref = [-1 1 0];
% % % targetvec = [1 0 0];
% % % 
% % % r = vrrotvec(ab_ref, targetvec);
% % % normal = r(1:3)
% % % ang = r(4)
% % % 
% % % rotmat = [cos(ang)+normal(1)^2*(1-cos(ang)), normal(1)*normal(2)*(1-cos(ang))-normal(3)*sin(ang), normal(1)*normal(3)*(1-cos(ang))+normal(2)*sin(ang); ...
% % %     normal(2)*normal(1)*(1-cos(ang))+normal(3)*sin(ang), cos(ang)+normal(2)^2*(1-cos(ang)), normal(2)*normal(3)*(1-cos(ang))-normal(1)*sin(ang); ...
% % %     normal(3)*normal(1)*(1-cos(ang))-normal(2)*sin(ang), normal(3)*normal(2)*(1-cos(ang))+normal(1)*sin(ang), cos(ang)+normal(3)^2*(1-cos(ang))]
% % % 
% % % vec1a = rotmat*ab_ref'          %vec1a liegt auf targetvec
% % % 
% % % 
% % % vec2=[-1 1 -1];
% % % 
% % % vec2a = rotmat*vec2'            %drehung des zweiten vektors
% % % 
% % % ang = acos(dot(ab_ref,vec2)/(norm(ab_ref)*norm(vec2)))  %winkel zw ab_ref & vec2
% % % ang = acos(dot(vec1a,vec2a)/(norm(vec1a)*norm(vec2a)))  %winkel zw vec1a & vec2a
% % % 
% % % 
% % % wink = cart2pol(vec2a(1), vec2a(3))
% % % wink = rad2deg(wink)