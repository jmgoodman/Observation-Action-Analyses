function [varargout] = synchronizehand(path,ht)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         UPDATE HAND RECORDING WITH NEURONAL RECORDING TIMES          
%
% DESCRIPTION:
% Ths routine merges the hand tracking record with their sampling times,
% recorded on the electrophysiological recording system. In this way,
% electrophyisological data and hand tracking get synchronized.
% 
%
% SYNTAX:    ok = import(path)
%
%         path ...  path of data tank (hand tracking has to be copied into
%                   to this location and must have the following file name:
%                   tank_recordingname_HT; eg: Zara_Recording1_HT
%         ht   ...  hand tracking times recorded on el. phy. recording
%                   system + identifier
%         ok   ...  retursn 1 if synchoization worked successfully.
%        
%
% EXAMPLE:   [ok] = synchronizehand('D:\Tanks\Zara\Test_Handtracker')
%
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center              AUG11 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if exist(path,'dir')
   thispath=path;
   file=dir([thispath '/*_HT.mat']);                                       % check if KinemaTracks recording is located in the data tank with correct file names
   if numel(file)==1
       HT_path=[thispath '/' file.name];

   else
       error('Two or more handtracking recordings exist.');
   end
else
   error([system '-tank not found.']);
end

load(HT_path, 'recording','LHO','GHO','SY','calibdata');                                                % load recording of KinemaTracks

if ht.value(1)==0
    ht.value(1)=[];
    ht.times(1)=[];
end

recording(:,1,2:end)=NaN;                                                  % create space for times
checksum=sum(ht.value(2:end)-ht.value(1:end-1)-1);                         % check if id's are continously increasing by one. 

if checksum==0
    recording(ht.value(1):ht.value(end),1,2)=ht.times;
    nonrecorded=isnan(recording(:,1,2));
    recording(nonrecorded,:,:)=[];
    
else
    error('');
end

[pathstr,name,ext]=fileparts(HT_path);                                     % get fileparts 

save([pathstr '\' name 'S' ext],'recording','LHO','GHO','SY','calibdata');








