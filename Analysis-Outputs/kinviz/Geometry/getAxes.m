% getAxes
% for each segment with an unknown axis of rotation (i.e., each mcp joint)
% extract the vertices from the vtp file
% chop off the bit that looks like the articulation surface
% run pca on that
% visualize pcs overlaid on top of the data
% first, second, and third pcs will be rbg, respectively
% pick the axes that align with flexion and abduction, respectively
clear,clc,close all
rot_axes   = zeros(3,6);
col_labels = {'d3 flex','d3 abduction','d4 flex','d4 abduction','d5 flex','d5 abduction'};
k = 0;
for i = 3:5
    k = k+1;
    fn  = sprintf('%dmidph_l.vtp',i);
    h   = fopen(fn);
    dat = textscan(h,'%s','delimiter','\n','bufsize',60000);
    
    % find the vertices array
    targstr  = '<Points>';
    istarg   = cellfun(@strcmp,dat{1},repmat({targstr},size(dat{1})));
    startind = find(istarg)+2; % get past header crap
    
    targstr  = '</Points>';
    istarg   = cellfun(@strcmp,dat{1},repmat({targstr},size(dat{1})));
    endind   = find(istarg) - 2; % get past end tag crap
    
    inds = startind:endind;
    x = zeros(numel(inds),1);
    y = zeros(numel(inds),1);
    z = zeros(numel(inds),1);
    for j = 1:numel(inds)
        td   = regexp(dat{1}{inds(j)},'  ');
        x(j) = str2double(dat{1}{inds(j)}(1:(td(1)-1)));
        y(j) = str2double(dat{1}{inds(j)}((td(1)+1):(td(2)-1)));
        z(j) = str2double(dat{1}{inds(j)}((td(2)+1):end));
    end
    
    % now we plot
    clors = hsv(numel(inds));
    figure
    for j = 1:numel(inds)
        hold all
        plot3(x(j),y(j),z(j),'kx','markersize',4,'linewidth',2,'color',clors(j,:))
    end
    axis equal, grid on
    xlabel('x'),ylabel('y'),zlabel('z')
    title(sprintf('vertices of %s',fn))
    
    disp('select cropping points to isolate articular surface')
    xt.min  = input('set x min for crop (enter value):');
    xt.max  = input('set x min for crop (enter value):');
    yt.min  = input('set y min for crop (enter value):');
    yt.max  = input('set y max for crop (enter value):');
    zt.min  = input('set z min for crop (enter value):');
    zt.max  = input('set z max for crop (enter value):');
    
    inds    = eval(sprintf('x > %d & x < %d & y > %d & y < %d & z > %d & z < %d;',xt.min,xt.max,yt.min,yt.max,zt.min,zt.max));
    xn = x(inds);
    yn = y(inds);
    zn = z(inds);
    
    % run pca on these guys
    
    [~,S,V] = svd(bsxfun(@minus,[xn yn zn],mean([xn yn zn])),0);
    S = diag(S);
    
    % plot the articular surface with pc vectors
    figure
    for j = 1:sum(inds)
        hold all
        plot3(xn(j),yn(j),zn(j),'kx','markersize',6,'linewidth',2)
    end    
    axis equal, grid on
    xlabel('x'),ylabel('y'),zlabel('z')
    title(sprintf('vertices of articular surface of %s',fn))
    
    clors = {'red','blue','green'};
    for j = 1:3
        valext = 2*S(j)./sum(S)*sqrt(sum(var([xn yn zn])))*[-1; 1]*V(:,j)' + repmat(mean([xn yn zn]),2,1);
        hold all
        plot3(valext(:,1),valext(:,2),valext(:,3),'k-','linewidth',2,'color',clors{j})
    end
    
    
    disp('PC1 = red, PC2 = blue, PC3 = green')
%     sa = input('Which axis is axial?:');
    fa = input('Which axis looks like flexion?:');
    aa = input('Which axis looks like abduction?:');
    
    rot_axes(:,k) = V(:,fa);
    k = k+1;
    rot_axes(:,k) = V(:,aa);
%     rot_axes(:,k) = V(:,sa);
end

clearvars -except rot_axes col_labels
clc,close all