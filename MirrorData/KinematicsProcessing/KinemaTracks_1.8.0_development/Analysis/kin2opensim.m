function [] = kin2opensim(motiondata,time,filename)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                    EXPORT KINEMATICS TO OpenSIM              
%
% DESCRIPTION:
% This function exports the motion data of constant sampling rate (from 
% global coordinate system) to an OpenSim compatible file (trc-file).
%
% SYNTAX:    kin2opensim(globalpos,time,'C:\Recording11_HOS.trc');
%
%        motiondata  ... joint positions (X,Y,Z)
%        time        ... time in seconds
%                     
%                       
% EXAMPLE:   kin2opensim(globalpos,time,'C:\Recording11_HOS.trc');
%
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center             MAY 12 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[pathstr, name, ext]= fileparts(filename);

if ~exist(pathstr,'dir')
    error('Destination folder does not exist.');
end

% Check for constant sampling rate
srates=round((time(2:end)-time(1:end-1))*100)/100;
srates=srates-srates(1);
if sum(srates)~=0
    sr=100;
    time=0:0.01:0.01*(length(time)-1);
else
    sr=1/(time(2)-time(1)); % calc sampling rate
    clear srates;
end
motiondata([61 62 63],:)=[];
motiondata=motiondata'; % transpose motiondata to fit SimTK file format

numMarkers=size(motiondata,2)/3; % get the amount of markers saved in the file
if mod(numMarkers,1)~=0
    error('Invalid length of data');
end
numFrames=size(motiondata,1); % get the amount of frames



fID = fopen(filename,'w'); % create a text for with wirte access

% 1st line of header
fprintf(fID,'%c','PathFileType');
fprintf(fID,'\t');
fprintf(fID,'%c',num2str(4));
fprintf(fID,'\t');
fprintf(fID,'%c','(X/Y/Z)');
fprintf(fID,'\t');
fprintf(fID,'%c',[name ext]);
fprintf(fID,'%c\r\n','');

% 2nd line of header
fprintf(fID,'%c','DataRate');
fprintf(fID,'\t');
fprintf(fID,'%c','CameraRate');
fprintf(fID,'\t');
fprintf(fID,'%c','NumFrames');
fprintf(fID,'\t');
fprintf(fID,'%c','NumMarkers');
fprintf(fID,'\t');
fprintf(fID,'%c','Units');
fprintf(fID,'\t');
fprintf(fID,'%c','OrigDataRate');
fprintf(fID,'\t');
fprintf(fID,'%c','OrigDataStartFrame');
fprintf(fID,'\t');
fprintf(fID,'%c','OrigNumFrames');
fprintf(fID,'%c\r\n','');

% 3rd line of header
fprintf(fID,'%c',num2str(sr));
fprintf(fID,'\t');
fprintf(fID,'%c',num2str(sr));
fprintf(fID,'\t');
fprintf(fID,'%c',num2str(numFrames));
fprintf(fID,'\t');
fprintf(fID,'%c',num2str(numMarkers));
fprintf(fID,'\t');
fprintf(fID,'%c','mm');
fprintf(fID,'\t');
fprintf(fID,'%c',num2str(sr));
fprintf(fID,'\t');
fprintf(fID,'%c',num2str(numFrames));
fprintf(fID,'%c\r\n','');

% 4th line of header
fourthline={'Frame#','Time','Thumb_MCP_L','','','Thumb_PIP_L','','','Thumb_DIP_L','','','Thumb_TIP_L','','','Index_MCP_L','','','Index_PIP_L','','','Index_DIP_L','','','Index_TIP_L','','','Middle_MCP_L','','','Middle_PIP_L','','','Middle_DIP_L','','','Middle_TIP_L','','','Ring_MCP_L','','','Ring_PIP_L','','','Ring_DIP_L','','','Ring_TIP_L','','','Little_MCP_L','','','Little_PIP_L','','','Little_DIP_L','','','Little_TIP_L','','','Wrist_L','','','Elbow_L','','','Point_W1_L','','','Point_E1_L','','','Shoulder_L','','','Point_F1_L','','','Point_F2_L','','','Point_F3_L','','','Point_F4_L','','','Point_F5_L','',''};

for ii=1:length(fourthline)
    fprintf(fID,'%c',fourthline{ii});
    fprintf(fID,'\t');
end
fprintf(fID,'%c\r\n','');


% 5th line of header
fprintf(fID,'\t\t');
for ii=1:numMarkers
    fprintf(fID,'%c',['X' num2str(ii)]);
    fprintf(fID,'\t');
    fprintf(fID,'%c',['Y' num2str(ii)]);
    fprintf(fID,'\t');
    fprintf(fID,'%c',['Z' num2str(ii)]);
    fprintf(fID,'\t');
end
fprintf(fID,'%c\r\n','');
% Create Data Block
data=nan(size(motiondata,1),size(motiondata,2)+1);

data(:,1)=time;
data(:,2:end)=motiondata;

for dd=1:size(data,1)
    fprintf(fID, '%u\t', dd);
    fprintf(fID, '%f\t', data(dd,:));
    fprintf(fID, '%c\r\n','');
end
fclose(fID); % close 

