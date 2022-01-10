restoredefaultpath % if you don't add this, you might end up putting irrelevant junk in your pathdef file on startup.

% where am I? these lines figure that out for me.
mfp = mfilename('fullpath');
[mfd,~,~]= fileparts(mfp);
manoptdir = fullfile(mfd,'manopt');

% "installs" manopt if you haven't done it already
if ~exist('pathdef.m','file')
    olddir = cd(manoptdir);
    importmanopt;
    
    cd(olddir)
    savepath('pathdef.m');
else
    % pass
end

% adds manopt path
path(path,pathdef)