function LHO=determinewrist(LHO,varargin)
% Stefan Schaffelhofer 
% APR 2013

if isempty(varargin)
    methode='replace';
else
    methode=lower(varargin{1});
end


%figure out mcp depth of fingers and take the average depth (z-direction)
%as depth for the wrist
metacarpaljoints=LHO.metacarpaljoints;
mcpdepth=mean(metacarpaljoints(2:end,2));

%compute wrist according to notes on page 19

mcp=metacarpaljoints(:,[1 3]);

p = polyfit(mcp(2:end,1),mcp(2:end,2),1); % calcualte regression line through mcp joints

m5=[mcp(5,1) mcp(5,1)*p(1)+p(2)]; % get mcp 5 on regression line
m1=[mcp(2,1) mcp(2,1)*p(1)+p(2)]; % get mcp 2 on regression line
mc=m1+0.5*(m5-m1);                % get center of digit mcps on regression line


switch LHO.handside % the regression line gets rotated. according to the hand, rotations are computed
    case 'left'
        theta=90;
        d=20;
    case 'right'
        theta=-90;
        d=-20;
end


v = [1 p(1)];                     % the vector defining the regression line
R = [cosd(theta) -sind(theta); sind(theta) cosd(theta)]; % rotation matrix
vR= v * R; % rotate vector
vR=vR*LHO.lengthdorsum;   % x and y direction from mc
w=mc+vR; % get wrist position

vn=v/norm(v);






switch methode
    case 'replace'  % replace old wrist values completely
        wh=w+vn*d; % 20 millimeter along regression axis
        armjoints=LHO.armjoints;
        armjoints(1,1:3)=[w(1)  mcpdepth w(2)];
        armjoints(5,1:3)=[wh(1) mcpdepth wh(2)];
        LHO.armjoints=armjoints;
        
    case 'keep' % use new vectors and old wrist to find wh, but keep old wirst coordinates
        w_keep = LHO.armjoints; w_keep=w_keep(1,1:3);
        wh=w_keep([1 3])+vn*d;
        armjoints=LHO.armjoints;
        armjoints(5,1:3)=[wh(1) w_keep(2) wh(2)];
        LHO.armjoints=armjoints;
        
        
        
        
    otherwise
        error('Methode unknown.');
end
        

% figure(99);
% plot(mcp(:,1),mcp(:,2),'+');
% set(gca,'DataAspectRatio',[1 1 1]);
% 
% hold on;
% line([m5(1) m1(1)],[m5(2) m1(2)]);
% plot(mc(1),mc(2),'+','Color','r')
% 
% 
% plot(w(1),w(2),'+','Color','g')
% hold off;