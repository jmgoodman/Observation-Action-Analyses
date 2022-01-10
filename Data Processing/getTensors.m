%% DO NOT DO THIS
% these tensors take up WAY more memory than you think
% loading in more than one at once will lead to very sad times

%% cleanup
% clear
% clc
% close all
% restoredefaultpath
% 
% %% path setting
% mfp           = mfilename('fullpath');
% [fldr,nm,ext] = fileparts(mfp);
% fsepinds      = regexp(fldr,filesep);
% lastfsepind   = fsepinds(end);
% 
% targetfldr    = fldr(1:lastfsepind);
% 
% addpath(genpath(targetfldr))
% 
% %% initialization
% setup_manifold_env
% 
% %%
% % create data tensors with appropriate labels
% % grab data from a full 1s surrounding each alignment and put that in your tensors
% % this way you have enough buffer to play around with cross-correlations and such
% % (don't do that with a window that surrounds each alignment with wings of 2s duration though - you don't have enough memory for that!)
% 
% wingwidth  = 1000; % ugh these windows are too big and ppd is ballooning out of control. Takes up the full 32 GB of RAM to process a session? fucking REALLY?!?? Just... fucking WHY?!? I'm not doing anything THAT ridiculous...
% Wins       = {    [-1,1]*wingwidth,          [-1,1]*wingwidth,   [-1,1]*wingwidth+700,        [-1,1]*wingwidth,      [-1,1]*wingwidth,          [-1,1]*wingwidth,      [-1,1]*wingwidth   };
% alignments = {'fixation_achieve_time','cue_onset_time','cue_onset_time','go_phase_start_time','movement_onset_time','hold_onset_time','reward_onset_time'};
% 
% 
% session_names = {'Moe46','Zara64','Zara68'};
% 
% for seshind = 1:numel(session_names)
%     seshname = session_names{seshind};
%     
%     clear MirrorDataObject
%     MirrorDataObject = load([seshname,'.mat']);
%     fn = fieldnames(MirrorDataObject);
%     MirrorDataObject = MirrorDataObject.(fn{1});
%     
%     emptycell  = cell(2,2);
%     clear datastruct
%     datastruct = struct('normalizationInfo',emptycell,'baselineInfo',emptycell,'tensor',emptycell,'tensorTT1',emptycell);
%     
%     normvals  = {'soft-normalized rates','rates in ips units'};
%     blsubvals = {'differences relative to baseline','unreferenced firing rates'};
%     
%     for normind = 1:2
%         for blsubind = 1:2
%             clear tempstruct
%             datastruct(normind,blsubind).normalizationInfo = normvals{normind};
%             datastruct(normind,blsubind).baselineInfo      = blsubvals{blsubind};
%             
%             normswitch  = normind==1;
%             blsubswitch = blsubind==1;
%             
%             ppd = preprocess(MirrorDataObject,'removebaseline',blsubswitch,'sigma',50,...
%                 'samplingrate',100,'normalize',normswitch,'windows',Wins);
%             
%             if normind == 1 && blsubind == 1 % this should NOT change across different runs of ppd, otherwise you have bigger problems...
%                 areaorder     = cellfun(@(x) x{1}.ArrayIDs{1},ppd,'uniformoutput',false);
%                 nneur_by_area = cellfun(@(x) size(x{1}.Data,2),ppd);
%                 repareanames  = cellfun(@(x,y) repmat({x},y,1),areaorder,num2cell(nneur_by_area),'uniformoutput',false);
%                 areanames     = vertcat(repareanames{:});
%             else
%                 % pass
%             end
%             
%             datastruct(normind,blsubind).tensor    = tensorize(ppd);
%             datastruct(normind,blsubind).tensorTT1 = tensorizeTT1(ppd);
%             clear ppd
%         end
%     end
%     
%     save([seshname,'_tensors.mat'],'datastruct','areanames','alignments')
% end
            
            
            
            
            
            
            
            
            
            
            
            