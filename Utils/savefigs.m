function savefigs(filename,h)

if nargin == 1
    h = gcf; % set figure handle to be the current figure
else
end

if ispc
    set(h,'paperposition',[0 0 6 4])
elseif ismac
    set(h,'paperposition',[0 0 16 12])
end

% filename should be a full path, but LACK a suffix
print(h,[filename,'.tif'],'-dtiff','-r300')
pause(1)
print(h,[filename,'.svg'],'-dsvg')
pause(1)
saveas(h,[filename,'.fig'])
pause(1)