% supplement to Call for control analyses I only thought to do later

%% setup
restoredefaultpath
analysis_setup

sessionsList       = {'Zara64'}; %{'Moe46','Moe50','Zara64','Zara70'}; % ignore Zara68, too few units to start with...

for seshind = 1:numel(sessionsList)
    thisSession = sessionsList{seshind};
    
    supplementalAnalysis(thisSession);
end