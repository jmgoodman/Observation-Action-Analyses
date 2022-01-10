%% startup script
set(0,'defaultfigurewindowstyle','docked')

rng('shuffle','twister')

disp('It worked! Your startup script worked!')

webutils.htmlrenderer('basic'); % for some reason your help documentation fails unless you do this...

restoredefaultpath
%% asdf