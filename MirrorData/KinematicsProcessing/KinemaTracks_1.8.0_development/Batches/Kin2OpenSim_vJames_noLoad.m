function Kin2OpenSim_vJames_noLoad(kindata,savefile)
%KIN2OPENSIM_VJAMES takes kinematic data processed by the GUI and does yet
%ANOTHER format conversion to facilitate use in OpenSim
%
%DESCRIPTION
%   This routine takes a file name (specified by kinfile), takes the
%   therein-contained kinematics or kinematics_i struct, and converts its
%   contents into an OpenSim-usable .trc file. Note: .trc files simply
%   contain marker positions. You still need to run OpenSim's inverse
%   kinematics to get joint angles!!!
%
%SYNTAX
%   Kin2OpenSim_vJames(kinfile,savefile)
%   kindata     ... a "kinematics" struct with 12 fields created by
%   Batch_extractfeatures.
%   savefile    ... specifies full path where the trc file will be saved.
%   Can also be empty (default). If empty, a GUI will guide selection of
%   the target file.
%
%EXAMPLE
%   Kin2OpenSim_vJames(kindata,'MyDir/MyFile.trc')
%
%AUTHOR
%   by Stefan Schaffelhofer
%   adapted and updated by James Goodman, 2020 January 15, DPZ


if nargin == 0
    error('Not enough inputs')
elseif nargin == 1
    savefile = [];
else
end

%%
% making sure the inputs are of proper format
if ~isempty(kindata)
    assert(isstruct(kindata),'kindata must be a struct created by Batch_extractfeatures.m!')
else
    error('Not enough inputs')
end

if ~isempty(savefile)
    assert(ischar(savefile) || isempty(savefile),'kinfile must either be an empty array or be a valid string specifying a .mat file location!')
else
    [Fname,Pname] = uiputfile('*.trc','Specify location and name of file to which to save the resultant .trc file.');
    
    if isnumeric(Fname) || isnumeric(Pname) || islogical(Fname) || islogical(Pname) % i.e., if "cancel" is pressed
        error('No file selected, cannot continue')
    else
        savefile = fullfile(Pname,Fname);
    end
end

%%
% extracting the variable of interest
% if exist('kinematics','var')
%     globalpos = kinematics.globalpos;
%     ktimes    = kinematics.time;
% elseif exist('kinematics_i','var')
%     globalpos = kinematics_i.globalpos;
%     ktimes    = kinematics_i.time;
% else
%     error('this... wasn''t the right type of .mat file, was it? I can''t find the necessary variables to continue')
% end

globalpos = kindata.globalpos;
ktimes    = kindata.time;


notvalid = abs(globalpos)>500; % ####### repition settings
globalpos(notvalid)=NaN;
disp(['Number of samples removed: ' num2str(sum(sum(notvalid)))]);

ex=[-1,0,0]; % axis of open SIM seen from WAVE coordinate system
ey=[0,0,-1];
ez=[0,-1,0];
dist=globalpos(76:78,find(~isnan(globalpos(76,:)) & ~isnan(globalpos(77,:)) & ~isnan(globalpos(78,:)),1,'first')); % distance of SIM origin from WAVE origin (=shoulder coordinates)
[tm,dcm]=cart2transmat(dist,ex,ey,ez); %#ok<ASGLU>

globalpos_os=nan(size(globalpos));

for jj=1:3:size(globalpos,1)
    for ss=1:size(globalpos,2)
        temp=tm\[globalpos(jj:jj+2,ss);1];
        globalpos_os(jj:jj+2,ss)=temp(1:3,1);
    end
end

notvalid=abs(globalpos_os)>500;
globalpos_os(notvalid)=NaN;
sr=20;

[globalpos_os_n time_n] =interpolatekinematic(globalpos_os,ktimes,sr,0.2); %#ok<NCOMMA>
notvalid=abs(globalpos_os_n)>500;
globalpos_os_n(notvalid)=NaN;

kin2opensim(globalpos_os_n,time_n,savefile)
% the 5 "helper points" do not MATTER, they're not instantiated ANYWHERE in
% the opensim model!!!

% --------------------------- Extract Examples ----------------------------

% tfrom = 0;
% tto   = 4060.74;
%
% samplefrom=tfrom*sr+1;
% sampleto=tto*sr;
%
% kinematic=globalpos_os_n(:,samplefrom:sampleto);
% time=time_n(:,samplefrom:sampleto);
%
% kin2opensim(kinematic,time,'C:\Users\Neurobiologie\Desktop\Recording70_all.trc');

end