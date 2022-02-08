function [SPK1 SPK2 SPK3 SPK4 SPK5 SPK6] = raw_to_spkobj(spkobj, path)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                  TAKES RAWDATA AND CREATES A SPKOBJ
%
%DESCRIPTION: This routine takes the raw data of several channels stored in
% path, makes spike sorting and creates a spkobj out of it (one for each 
% array). (Each spkobj can be stored in a separate mat-file named
% SPK_arrayNo.)
% At the end the rawobj are deleted.
%
%HELPFUL INFORMATION: 
%
%SYNTAX: [[SPK1 SPK2 SPK3 SPK4 SPK5 SPK6]] = raw_to_spkobj(path)
%            spkobj ...... SPKOBJ
%            path ........ path were the mat-files with the rawobj are 
%                          stored (string)
%
%EXAMPLE: [[SPK1 SPK2 SPK3 SPK4 SPK5 SPK6]] = 
%                   raw_to_spkobj('/Recordings/Neuronal/Recording1a')
%
%AUTHOR: ©Katharina Menz, German Primate Center                     Aug2011
%last modified: Katharina Menz          09.08.2011
%                                       17.08.2011
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%######################## CHECK INPUT PARAMETERS ##########################

if isdir(path) == 0             %check if path is a folder
    error('Wrong input argument: "Path" has to be an existing folder');
end


%################## GET ALL RAWOBJECTS FROM FOLDER ########################

cd(path)

[pathstr, folder, ext] = fileparts(path);

dir_content = dir(path);                                                    %creates structure array with name, date, bytes, isdir,..
files = {dir_content.name};                                                 %..datenum as fields
list = strfind(files, '_raw_ch');
indFull = cellfun('isempty', list);
indMat = find(indFull == 0);                      
if isempty(indMat) == 1
    error('There are no mat-files in the specified folder.');
end

matFiles = files(indMat);

name = matFiles{1};
ind = strfind(name, '_raw');
filename = name(1:ind-1);
% eval([filename '_el1_SPK = spkobj;']);
% eval([filename '_el2_SPK = spkobj;']);
% eval([filename '_el3_SPK = spkobj;']);
% eval([filename '_el4_SPK = spkobj;']);
% eval([filename '_el5_SPK = spkobj;']);
% eval([filename '_el6_SPK = spkobj;']);
SPK1 = spkobj;
SPK2 = spkobj;
SPK3 = spkobj;
SPK4 = spkobj;
SPK5 = spkobj;
SPK6 = spkobj;

spiketimes1 = [];
spiketimes2 = [];
spiketimes3 = [];
spiketimes4 = [];
spiketimes5 = [];
spiketimes6 = [];
waveforms1 = [];
waveforms2 = [];
waveforms3 = [];
waveforms4 = [];
waveforms5 = [];
waveforms6 = [];
sortID1 = [];
sortID2 = [];
sortID3 = [];
sortID4 = [];
sortID5 = [];
sortID6 = [];
channelID1 = [];
channelID2 = [];
channelID3 = [];
channelID4 = [];
channelID5 = [];
channelID6 = [];
count1 = 0;
count2 = 0;
count3 = 0;
count4 = 0;
count5 = 0;
count6 = 0;

for ii = 1:length(matFiles)
    matname = matFiles{ii};
    eval(['load ' matname]);
    
    indDot = find(matname == '.');
    objname = matname(1:indDot-1);
    
    
%######################## DO SPIKE SORTING ################################
    
    eval(['[waveforms spiketimes sortID triggertime] = spike_sort_rawdata(' objname ');']);
    
    ind0 = find(sortID == 0);                                             %eliminate unassigned spikes
    waveforms(ind0,:) = [];
    spiketimes(ind0)  = [];
    sortID(ind0)    = [];
    
    cd(path)                                                                %go back to original directory since spike_sort_rawdata changes..
                                                                            %..into SpikeSort folder
    eval(['ch = ' objname '.channelID;']);                                  %get channel ID out of the rawobj
    el = ceil(ch/32);                                                       %electrode ID
    
    switch el
        case 1
            spiketimes1 = [spiketimes1; spiketimes];
            waveforms1  = [waveforms1; waveforms];
            sortID1   = [sortID1; sortID];
            channelID1  = [channelID1; ch*ones(length(spiketimes),1)];
            count1 = count1+1;
        case 2
            spiketimes2 = [spiketimes2; spiketimes];
            waveforms2  = [waveforms2; waveforms];
            sortID2   = [sortID2; sortID];
            channelID2  = [channelID2; ch*ones(length(spiketimes),1)];
            count2 = count2+1;
        case 3
            spiketimes3 = [spiketimes3; spiketimes];
            waveforms3  = [waveforms3; waveforms];
            sortID3   = [sortID3; sortID];
            channelID3  = [channelID3; ch*ones(length(spiketimes),1)];
            count3 = count3+1;
        case 4
            spiketimes4 = [spiketimes4; spiketimes];
            waveforms4  = [waveforms4; waveforms];
            sortID4   = [sortID4; sortID];
            channelID4  = [channelID4; ch*ones(length(spiketimes),1)];
            count4 = count4+1;
        case 5
            spiketimes5 = [spiketimes5; spiketimes];
            waveforms5  = [waveforms5; waveforms];
            sortID5   = [sortID5; sortID];
            channelID5  = [channelID5; ch*ones(length(spiketimes),1)];
            count5 = count5+1;
        case 6
            spiketimes6 = [spiketimes6; spiketimes];
            waveforms6  = [waveforms6; waveforms];
            sortID6   = [sortID6; sortID];
            channelID6  = [channelID6; ch*ones(length(spiketimes),1)];
            count6 = count6+1;
    end
    
    delete([path '/' matname]);                                             %delete rawobj since it is not needed anymore
end                                                                         

delete([path '/SpikeSort/*.run']);
delete([path '/SpikeSort/*.mat*']);
delete([path '/SpikeSort/*.txt']);
delete([path '/SpikeSort/*dg_01*']);
delete([path '/SpikeSort/*.jpg']);

indLine = find(objname == '_');
recordingname = objname(1:indLine(end-1)-1);
mkdir('/Volumes/Groups/project1/sschaffelhofer/Recordings/Neuronal', recordingname);   %create a new folder
cd(['/Volumes/Groups/project1/sschaffelhofer/Recordings/Neuronal/' recordingname]);    %go into the new folder

%el1
if count1 > 0
    if count1 > 1                                                           %sorting for electrode 1
        [spiketimes1 ind1] = sort(spiketimes1);
        waveforms1 = waveforms1(ind1);
        sortID1  = sortID1(ind1);
        channelID1 = channelID1(ind1);
    end
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'waveforms' char(39) ',   waveforms1);']);
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'spiketimes' char(39) ',   spiketimes1);']);
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'sortID' char(39) ',   sortID1);']);
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'electrodeID' char(39) ',   ones(length(spiketimes1),1));']);
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'channelID' char(39) ',   channelID1);']);
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'triggertime' char(39) ',   triggertime);']);
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'physicalunit' char(39) ',' char(39) 'µV' char(39) ');']);
%     eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
%     eval([filename '_el1_SPK = set(' filename '_el1_SPK, ' char(39) 'samplingrate' char(39) ',   sr);']);
    SPK1 = set(SPK1, 'waveforms', waveforms1);
    SPK1 = set(SPK1, 'spiketimes', spiketimes1);
    SPK1 = set(SPK1, 'sortID', sortID1);
    SPK1 = set(SPK1, 'electrodeID', ones(length(spiketimes1),1));
    SPK1 = set(SPK1, 'channelID', channelID1);
    SPK1 = set(SPK1, 'triggertime', triggertime);
    SPK1 = set(SPK1, 'physicalunit', 'µV');
    eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
    SPK1 = set(SPK1, 'samplingrate', sr);
end
%eval(['save(' char(39) filename '_el1_SPK.mat' char(39) ',' char(39) filename '_el1_SPK' char(39) ')']);
%eval(['SPK1 = ' filename '_el1_SPK;']);


%el2
if count2 > 0
    if count2 > 1                                                           %sorting for electrode 2
        [spiketimes2 ind2] = sort(spiketimes2);
        waveforms2 = waveforms2(ind2);
        sortID2  = sortID2(ind2);
        channelID2 = channelID2(ind2);
    end
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'waveforms' char(39) ',   waveforms2);']);
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'spiketimes' char(39) ',   spiketimes2);']);
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'sortID' char(39) ',   sortID2);']);
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'electrodeID' char(39) ', 2*ones(length(spiketimes2),1));']);
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'channelID' char(39) ',   channelID2);']);
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'triggertime' char(39) ',   triggertime);']);
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'physicalunit' char(39) ',' char(39) 'µV' char(39) ');']);
%     eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
%     eval([filename '_el2_SPK = set(' filename '_el2_SPK, ' char(39) 'samplingrate' char(39) ',   sr);']);
    SPK2 = set(SPK2, 'waveforms', waveforms2);
    SPK2 = set(SPK2, 'spiketimes', spiketimes2);
    SPK2 = set(SPK2, 'sortID', sortID2);
    SPK2 = set(SPK2, 'electrodeID', 2*ones(length(spiketimes2),1));
    SPK2 = set(SPK2, 'channelID', channelID2);
    SPK2 = set(SPK2, 'triggertime', triggertime);
    SPK2 = set(SPK2, 'physicalunit', 'µV');
    eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
    SPK2 = set(SPK2, 'samplingrate', sr);
end
%eval(['save(' char(39) filename '_el2_SPK.mat' char(39) ',' char(39) filename '_el2_SPK' char(39) ')']);
%eval(['SPK2 = ' filename '_el2_SPK;']);


%el3
if count3 > 0
    if count3 > 1                                                           %sorting for electrode 3
        [spiketimes3 ind3] = sort(spiketimes3);
        waveforms3 = waveforms3(ind3);
        sortID3  = sortID3(ind3);
        channelID3 = channelID3(ind3);
    end
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'waveforms' char(39) ',   waveforms3);']);
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'spiketimes' char(39) ',   spiketimes3);']);
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'sortID' char(39) ',   sortID3);']);
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'electrodeID' char(39) ', 3*ones(length(spiketimes3),1));']);
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'channelID' char(39) ',   channelID3);']);
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'triggertime' char(39) ',   triggertime);']);
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'physicalunit' char(39) ',' char(39) 'µV' char(39) ');']);
%     eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
%     eval([filename '_el3_SPK = set(' filename '_el3_SPK, ' char(39) 'samplingrate' char(39) ',   sr);']);
    SPK3 = set(SPK3, 'waveforms', waveforms3);
    SPK3 = set(SPK3, 'spiketimes', spiketimes3);
    SPK3 = set(SPK3, 'sortID', sortID3);
    SPK3 = set(SPK3, 'electrodeID', 3*ones(length(spiketimes3),1));
    SPK3 = set(SPK3, 'channelID', channelID3);
    SPK3 = set(SPK3, 'triggertime', triggertime);
    SPK3 = set(SPK3, 'physicalunit', 'µV');
    eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
    SPK3 = set(SPK3, 'samplingrate', sr);
end
%eval(['save(' char(39) filename '_el3_SPK.mat' char(39) ',' char(39) filename '_el3_SPK' char(39) ')']);
%eval(['SPK3 = ' filename '_el3_SPK;']);


%el4
if count4 > 0
    if count4 > 1                                                           %sorting for electrode 4
        [spiketimes4 ind4] = sort(spiketimes4);
        waveforms4 = waveforms4(ind4);
        sortID4  = sortID4(ind4);
        channelID4 = channelID4(ind4);
    end
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'waveforms' char(39) ',   waveforms4);']);
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'spiketimes' char(39) ',   spiketimes4);']);
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'sortID' char(39) ',   sortID4);']);
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'electrodeID' char(39) ', 4*ones(length(spiketimes4),1));']);
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'channelID' char(39) ',   channelID4);']);
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'triggertime' char(39) ',   triggertime);']);
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'physicalunit' char(39) ',' char(39) 'µV' char(39) ');']);
%     eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
%     eval([filename '_el4_SPK = set(' filename '_el4_SPK, ' char(39) 'samplingrate' char(39) ',   sr);']);
    SPK4 = set(SPK4, 'waveforms', waveforms4);
    SPK4 = set(SPK4, 'spiketimes', spiketimes4);
    SPK4 = set(SPK4, 'sortID', sortID4);
    SPK4 = set(SPK4, 'electrodeID', 4*ones(length(spiketimes4),1));
    SPK4 = set(SPK4, 'channelID', channelID4);
    SPK4 = set(SPK4, 'triggertime', triggertime);
    SPK4 = set(SPK4, 'physicalunit', 'µV');
    eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
    SPK4 = set(SPK4, 'samplingrate', sr);
end
%eval(['save(' char(39) filename '_el4_SPK.mat' char(39) ',' char(39) filename '_el4_SPK' char(39) ')']);
%eval(['SPK4 = ' filename '_el4_SPK;']);


%el5
if count5 > 0
    if count5 > 1                                                           %sorting for electrode 5
        [spiketimes5 ind5] = sort(spiketimes5);
        waveforms5 = waveforms5(ind5);
        sortID5  = sortID5(ind5);
        channelID5 = channelID5(ind5);
    end
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'waveforms' char(39) ',   waveforms5);']);
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'spiketimes' char(39) ',   spiketimes5);']);
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'sortID' char(39) ',   sortID5);']);
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'electrodeID' char(39) ', 5*ones(length(spiketimes5),1));']);
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'channelID' char(39) ',   channelID5);']);
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'triggertime' char(39) ',   triggertime);']);
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'physicalunit' char(39) ',' char(39) 'µV' char(39) ');']);
%     eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
%     eval([filename '_el5_SPK = set(' filename '_el5_SPK, ' char(39) 'samplingrate' char(39) ',   sr);']);
    SPK5 = set(SPK5, 'waveforms', waveforms5);
    SPK5 = set(SPK5, 'spiketimes', spiketimes5);
    SPK5 = set(SPK5, 'sortID', sortID5);
    SPK5 = set(SPK5, 'electrodeID', 5*ones(length(spiketimes5),1));
    SPK5 = set(SPK5, 'channelID', channelID5);
    SPK5 = set(SPK5, 'triggertime', triggertime);
    SPK5 = set(SPK5, 'physicalunit', 'µV');
    eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
    SPK5 = set(SPK5, 'samplingrate', sr);
end
%eval(['save(' char(39) filename '_el5_SPK.mat' char(39) ',' char(39) filename '_el5_SPK' char(39) ')']);
%eval(['SPK5 = ' filename '_el5_SPK;']);

%el6
if count6 > 0
    if count6 > 1                                                           %sorting for electrode 6
        [spiketimes6 ind6] = sort(spiketimes6);
        waveforms6 = waveforms6(ind6);
        sortID6  = sortID6(ind6);
        channelID6 = channelID6(ind6);
    end
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'waveforms' char(39) ',   waveforms6);']);
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'spiketimes' char(39) ',   spiketimes6);']);
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'sortID' char(39) ',   sortID6);']);
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'electrodeID' char(39) ', 6*ones(length(spiketimes6),1));']);
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'channelID' char(39) ',   channelID6);']);
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'triggertime' char(39) ',   triggertime);']);
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'physicalunit' char(39) ',' char(39) 'µV' char(39) ');']);
%     eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
%     eval([filename '_el6_SPK = set(' filename '_el6_SPK, ' char(39) 'samplingrate' char(39) ',   sr);']);
    SPK6 = set(SPK6, 'waveforms', waveforms6);
    SPK6 = set(SPK6, 'spiketimes', spiketimes6);
    SPK6 = set(SPK6, 'sortID', sortID6);
    SPK6 = set(SPK6, 'electrodeID', 6*ones(length(spiketimes6),1));
    SPK6 = set(SPK6, 'channelID', channelID6);
    SPK6 = set(SPK6, 'triggertime', triggertime);
    SPK6 = set(SPK6, 'physicalunit', 'µV');
    eval(['sr = ' objname '.samplingrate;']);                               %get sampling rate out of the rawobj
    SPK6 = set(SPK6, 'samplingrate', sr);
end
%eval(['save(' char(39) filename '_el6_SPK.mat' char(39) ',' char(39) filename '_el6_SPK' char(39) ')']);
%eval(['SPK6 = ' filename '_el6_SPK;']);

                                               