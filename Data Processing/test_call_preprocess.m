clear M
restoredefaultpath
addpath(genpath('..'))
% load('Moe32_JUSTKinematics.mat')
load('Zara70_JUSTKinematics.mat') % only 2 blocks processed... didn't break though, just left the sessions without data as NANs
ppd = preprocess(M);

%% test alignment
KD = cellfun(@(x) x.KinematicData,ppd{1},'uniformoutput',false);
align_names = cellfun(@(x) x.Alignment,ppd{1},'uniformoutput',false);

% plot all joints at movement onset
KD_move_onset  = KD{5};
bintimes       = ppd{1}{5}.BinTimes;
jointnames     = ppd{1}{1}.KinematicColNames;
subplotsidelen = ceil( sqrt(numel(jointnames)) );

if subplotsidelen*(subplotsidelen-1) >= numel(jointnames)
    ht = subplotsidelen;
    wd = subplotsidelen-1;
else
    ht = subplotsidelen;
    wd = subplotsidelen;
end 

utt = unique(ppd{1}{1}.TrialTypes);


for ttype = 1:numel(utt)
    figure
    for jind = 1:numel(jointnames)
        thesetrials = ismember(ppd{1}{1}.TrialTypes,utt{ttype});
        subplot(ht,wd,jind)
        jdata = squeeze(KD_move_onset(:,jind,thesetrials));
        plot(bintimes(:),jdata,'k-')
    end
end
    
    
    