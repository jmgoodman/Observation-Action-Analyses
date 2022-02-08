function [tm,dcm]=cart2transmat(dist,ex,ey,ez)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                     COMPUTE TRANSFORMATION MATRIX
% DESCRIPTION: 
%
% Create transformation matrix for trasfmorming a point p from original
% coordinate system (A) to a new coordinate system (B) : p(A) -> p(B)
%
% The coordinate system B is described ey its axes units vectors, ex, ey,
% and ez, and ey its distance to the origin to system A (B-A), dx, dy, 
% and dz. 
%
% The returned transformation matrix tm can be used to transform a point
% p(A) into system B ey:
% p(B) = tm\[px(A);py(A);pz(A);1]
%
% To transform a point from system B into system A the same transformation
% matrix can be used:
% p(A) = tm*[px(B);py(B);pz(B);1]
% 
% SYNTAX:  [tm,dcm]=cart2transmat(dx,dy,dz,ex,ey,ez)
%            
%            INPUT:
%            dist     ... distance from A to B in x,y,z direction from A
%            ex       ... unity vector of x-axis of system B seen from A
%            ey       ... unity vector of y-axis of system B seen from A
%            ez       ... unity vector of z-axis of system B seen from A
% 
%            OUTPUT:
%            tm       ... transformation matrix (rotation, translation)
%            dcm      ... direction cosine matrix (rotation only)
%            
% EXAMPLE:
%    [tm,dcm]=cart2transmat(2,-1,3,[0.7071,0.7071,0.7071],[0.7071,0.7071,
%                           0.7071],[0,0,1]);
%
% last modified: Stefan Schaffelhofer                            26.09.2011
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% if norm(ex)~=1 || norm(ey)~=1 || norm(ez)~=1
%     warning('Axe vectors are no unity vectors. They get normalized.');
%     ex=ex/norm(ex); % make unity vectors out of them
%     ey=ey/norm(ey);
%     ez=ez/norm(ez);
% end

b(1,1:3)=ex;
b(2,1:3)=ey;
b(3,1:3)=ez;

a(1,1:3)=[1,0,0]; % ax
a(2,1:3)=[0,1,0]; % ay
a(3,1:3)=[0,0,1]; % az

dcm=nan(3,3);
for bb=1:3 % create cosine matrix
    for aa=1:3
        dcm(aa,bb)=dot(a(aa,:),b(bb,:));
    end
end

tm=zeros(4,4);
tm(1:3,1:3)=dcm;
tm(:,end)=[dist(1); dist(2); dist(3);1];

end % end of function

% EXAMPLE







