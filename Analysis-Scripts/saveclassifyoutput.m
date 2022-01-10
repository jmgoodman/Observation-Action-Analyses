function [] = saveclassifyoutput(seshstr,cstruct,copts)

%%
% SLOW SLOW SLOW!!! don't save REGULAR snapshots...
olddir = cd( fullfile('..','Analysis-Outputs') );
cd(seshstr);
save(sprintf('classification_results_%s.mat',seshstr),'cstruct','copts','-v7.3')
save(sprintf('classification_results_%s_.mat',seshstr),'cstruct','copts','-v7.3') % save two copies so that if execution is ever terminated mid-save, you have an uncorrupted backup copy
cd(olddir);


end