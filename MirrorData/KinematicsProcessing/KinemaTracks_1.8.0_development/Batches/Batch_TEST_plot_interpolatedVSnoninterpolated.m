tfrom = 10;
tto   = 13;

samplefrom1=find(ktimes>=tfrom,1,'first');
sampleto1  =find(ktimes>=tto,1,'first');

samplefrom2=tfrom*sr;
sampleto2=tto*sr;

plot(ktimes(samplefrom1:sampleto1),globalpos(61,samplefrom1:sampleto1),'r')
hold on;
plot(samplefrom2/sr-1/sr:1/sr:sampleto2/sr-1/sr, globalpos_n(61,samplefrom2:sampleto2),'b')
hold on;
plot(samplefrom2/sr-1/sr:1/sr:sampleto2/sr-1/sr, globalpos_os_n(61,samplefrom2:sampleto2),'g');