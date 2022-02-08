function correct = checkUDP(ipadr, remoteport, localport, mode)
%CHECKUDP Make sure UDP receiver port and address are good
%   This used to be exclusively part of UDPSettings.m, which forced users
%   to open the dialog once before the UDP button became enabled. 
%   As a fuction, checkUDP should also be called whenever a project is
%   loaded. All code left untouched otherwise. 
%                                                       Andrej Filippow
global FL;
global UDP1;
check=zeros(1,3);
% Check IP Address

correct = {0};

if ischar(ipadr) 
    if ~isempty(ipadr)
        % Allows IPs and any kind of address without spaces
        idx=findstr(ipadr,' ');
        if numel(idx) == 0
              check(1,1)=1;
        end
    end

%         % This check blocks broadcast and pc names, so it is useless
%         idx=findstr(ipadr,'.');
%         if numel(idx)==3
%             if str2double(ipadr(1:idx(1)))<255 && ...
%                str2double(ipadr(idx(1)+1:idx(2)))<255 && ...
%                str2double(ipadr(idx(2)+1:idx(3)))<255 && ...
%                str2double(ipadr(idx(3)+1:end))<255 
%            
%               check(1,1)=1;
%             end
%         end

end


% Check Remote port

% if isdouble(remoteport) 
%     if ~isempty(remoteport)
%         if ~isnan(str2double(remoteport))
%             check(1,2)=1;
%         end
%     end
% end
% 
% % Check Local port
% 
% if isdouble(localport) 
%     if ~isempty(localport)
%         if ~isnan(str2double(localport))
%             check(1,3)=1;
%         end
%     end
% end

% If all setting are correct , save 
if check(1,1)==1
    set(UDP1, 'RemoteHost', ipadr);
    set(UDP1, 'RemotePort', remoteport);
    set(UDP1, 'LocalPort', localport);

    set(UDP1,'UserData',mode);
    FL.udpok=1; % set flag for successful UDP setup
    mainhandle=findall(0,'Name','KinemaTracks');
    handles=guihandles(mainhandle);
    refreshselectivity(FL,handles);
    h = findall(0,'Name','UDP Settings');
    delete(h);
    correct = {1};
else
    disp('Check for consistency of input arguments.');
end



end

