
% 
% for ii=1:27
%     
% 
% 
% 
% b=[mean(a(1:10)),mean(a(11:20)),mean(a(21:30)),mean(a(31:40)),mean(a(41:50)),mean(a(51:60)),mean(a(61:70)),mean(a(71:80)),mean(a(81:90)),mean(a(91:100))];
% range(ll)=max(b)-min(b);
% stdof(ll)=std(b);
% 
% 
% r=mean(range)
% s=mean(stdof)


for ii=1:27
    subplot(7,4,ii)
    plot(mean(real(anglearray1{1,ii})),'r');
    hold on;
    plot(mean(real(anglearray2{1,ii})),'b'); 
    hold on;
    plot(mean(real(anglearray3{1,ii})),'g');
    hold on;
    plot(mean(real(anglearray4{1,ii})),'y');
end

for ii=1:27
    ang1=real(anglearray1{1,ii});
    ang2=real(anglearray2{1,ii});
    ang3=real(anglearray3{1,ii});
    ang4=real(anglearray4{1,ii});
    
    ang1=ang1(ii,:);
    ang2=ang2(ii,:);
    ang3=ang3(ii,:);
    ang4=ang4(ii,:);
    
    b=[mean(ang1),mean(ang2),mean(ang3),mean(ang4)];
    
    range(ii)=max(b)-min(b);
    s(ii)=std(b);
end

rangem=mean(range)
sm=mean(s)
