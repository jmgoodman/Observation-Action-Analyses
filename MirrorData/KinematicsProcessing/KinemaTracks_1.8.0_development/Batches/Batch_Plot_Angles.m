% Batch Plot angles

clc; clear;
% path of tank
tank='C:\Users\Neurobiologie\Dropbox\Sample Data\Zara\';
recname='Recording71';
folder=[recname '\'];

load([tank folder recname '_DI.mat'],'DI');                                % load neuronobj
load([tank folder recname '_TO.mat'],'TO');                                % load trialobj
load([tank folder recname '_ST.mat'],'ST');                                % load states (epochobj)
load([tank folder recname '_KINI.mat'],'kin_i');                           % load states (epochobj)


ang=kin_i.angles;

for ii=1:size(ang,1)
    ii
    ang(ii,:)=smooth(ang(ii,:),'moving',5);

end
kin_i.angles=ang;


       


plotangles(kin_i,[9 21],{'Index','Thumb','Middle','Wrist','Elbow','Shoulder'},...
           TO,ST,DI,{'holdon','holdoff'})

fh =gcf;
speed=0.5;
frsec=30 ;
filename='C:\Users\Neurobiologie\Desktop\test.avi';
quality=90;

% figure2movie(fh,filename,frsec,speed,quality)








    






