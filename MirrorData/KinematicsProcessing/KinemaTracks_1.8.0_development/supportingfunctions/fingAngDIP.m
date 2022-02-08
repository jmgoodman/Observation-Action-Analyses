function [ang] = fingAngDIP(v1,v2, fingNo, handside)

% %%%%%%%%%%%%%%%%%%%%%%%% CALCULATE DIP ANGLE %%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% v1 = BC
% v2 = CT
% fingNo = number of finger (1 = th, 2 = index, ...)
% 
% calculate angle between v1 and v2
% 
% determine correct sign of angle:
% - create a orthogonal vector on v1 and v2. depending on the position of
%   v1 to v2 (which we want to find out) the normal vector goes in one or
%   the opposite direction.
% - compare the normal vector to local y-axis (for thumb) or local x-axis
%
% 
% AUTHOR: ©Katharina Menz, German Primate Center                 FEB 2012
% last modified: Katharina Menz 
%                26.04.2012
%                03.05.2012
%                18.05.2012
%                30.05.2012
%                03.07.2012 more conditions added to thumb 
%                01.04.2014 adjust calculation of sign in thumb to right
%                           hand
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% determine sign of angle

normal = cross(v1,v2);
if fingNo == 1
    xax = [1 0 0];
    xang = 90-rad2deg(acos(dot(normal,xax)/(norm(normal)*norm(xax))));
    xang = norm(xang);
    yax = [0 1 0];
    yang = 90-rad2deg(acos(dot(normal,yax)/(norm(normal)*norm(yax))));
    yang = norm(yang);
    zax = [0 0 1];
    zang = 90-rad2deg(acos(dot(normal,zax)/(norm(normal)*norm(zax))));
    zang = norm(zang);
    angs = [xang yang zang];
    [~, indmax] = max(angs);
    if indmax == 1   %fingerplane is closest to local y-z-plane
        if normal(1) < 0
            multip = 1;
        else
            multip = -1;
        end
    elseif indmax == 2;     %fingerplane is closest to x-z-plane
        if normal(2) < 0
            multip = handside*1;
        else
            multip = handside*(-1);
        end
    elseif indmax == 3;
        if normal(3) > 0
            multip = handside*1;
        else
            multip = handside*(-1);
        end
    else
        error('Somethings"s wrong! max can"t find an entry!');
    end
        

else
    if normal(1) < 0
        multip = 1;
    else
        multip = -1;
    end
end
    
%% calculate angle
ang = multip*rad2deg(acos(dot(v1,v2)/(norm(v1)*norm(v2))));     
if ~isreal(ang)         %if dot(v1,v2)/(norm(v1)*norm(v2)) > 1 because of inaccuracy, acos produces complex value
    ang = real(ang);
end





