figure();
anglearray=cell(1,27);

warning off;
power=find(trial.grip==1);
prec =find(trial.grip==0);

powertimes=zeros(length(power),2);
prectimes =zeros(length(prec),2);

% rewardtimes=state.time(state.data==8);

for ii=1:length(power)
    idx=power(ii);
    aligntime=state.time(state.time>trial.start(idx) & state.time<trial.end(idx) & state.data==5);
    if ~isempty(aligntime) 
        powertimes(ii,:)=aligntime(1);
    end
end

for ii=1:length(prec)
    idx=prec(ii);
    aligntime=state.time(state.time>trial.start(idx) & state.time<trial.end(idx) & state.data==5);
    if ~isempty(aligntime)
        prectimes(ii,:)=aligntime(1);
    end
end

powertimes=round(powertimes*100)/100;
prectimes =round(prectimes*100) /100;

angid=5;
clear a;
samplesminus=40;
samplesplus=40;
range=[];
stdof=[];
for ll=1:27
    kk=1;
    ii=1;
    subplot(7,4,ll);
    cut=nan(100,samplesminus+1+samplesminus);
    
    while kk<=100
        sample=angles_n(ll,powertimes(ii,1)*100-samplesminus:powertimes(ii,1)*100+samplesplus);
        if ~sum(isnan(sample)>=1)
            plot(sample)
            hold on;
            a(kk)=mean(sample);
            cut(kk,:)=sample;
            kk=kk+1;
        end
        anglearray{1,ll}=cut;
        ii=ii+1;
    end
    
    b=[mean(a(1:10)),mean(a(11:20)),mean(a(21:30)),mean(a(31:40)),mean(a(41:50)),mean(a(51:60)),mean(a(61:70)),mean(a(71:80)),mean(a(81:90)),mean(a(91:100))];
    range(ll)=max(b)-min(b);
    stdof(ll)=std(b);
end

r=mean(range)
s=mean(stdof)




% for ii=1:100
%     plot(angles_n(angid,prectimes(ii,1)*100:prectimes(ii,2)*100),'r')
%     a2(ii)=mean(angles_n(angid,prectimes(ii,1)*100:prectimes(ii,2)*100));
%     hold on;
% end


