%% this script is basically done! now to integrate it with MirrorData (& figure out a way to establish compatibility across MATLAB versions, even if it means calling the old version of MATLAB from a newer version of it... UGH)
clear,clc,close all

restoredefaultpath
addpath(genpath('/Users/jgoodman/Dropbox/Mirror Local/Code/Software/GraspAnalyze/'))
% addpath(genpath('/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/KinemaTracks_1.7.4_Stable'))
addpath(genpath('/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/KinemaTracks_1.8.0_development')) % finally captures all the custom "hacks" I made and appropriately calls it a new version of KinemaTracks.

% thesse paths are required for the trc manipulations at the end (not to
% mention the IK step!)
addpath('/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/James Dissertation Code/')
addpath(genpath('/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/Template Files'))

%%
% ^ will need to change this if using a windows machine (or any machine
% other than my own! I'll need to document this...)

%% start writing the kinematics pipeline!
% ---read in the files you have from Zara's folder
% ---create a project file from the GHO & LHO structs contained therein
% (with the appropriate modifications so that it actually works!)
% ---run KinemaTracks (any way to call the required procedures without the
% GUI? that'd be ideal...)
% ---import your opensim scripts related to your thesis, use them to write
% two trc files (one with kinematics, one with a snippet of static data for
% model scaling) and run IK.
%
%% step 1: read in kinematics files

kin_directory = []; % allow this to be a string or an empty array

if isempty(kin_directory)
    kin_directory = uigetdir([],'Find the folder containing your kinematics file(s)');
else
    % pass
end

% now, begin to load in files one-by-one
% there are a few formats to keep in mind:
% _HTS
% Active / Passive subfolders with _HT appended
% containing the date/time string of the recording and simply ending with
% an underscore

% so, here's the regular expression that will selectively identify these
% cases
kinfile_regexp = '_(HT)?(S)?\.mat$';

% now, we trawl the current directory & any subdirectories for files
D  = dir(kin_directory);
kd = repmat({kin_directory},size(D,1),size(D,2));
[D.source_dir] = kd{:};

% remove the first two entries
D_sansdots = D(3:end);

% enter all sub-directories (don't go more than one level deep, though, as
% that's laborious, likely to require spooky potentially infinite while
% loops, and probably not necessary given how Stefan and, indeed, how any reasonable person would organize these files)
Dsubinds  = arrayfun(@(x) x.isdir,D_sansdots);
Dsubnames = arrayfun(@(x) x.name,D_sansdots(Dsubinds),'uniformoutput',false);
Dsub = cell(sum(Dsubinds),1);

for ii = 1:numel(Dsub)
    Dsub{ii} = dir(fullfile(kin_directory,Dsubnames{ii}));
    kd_      = repmat({fullfile(kin_directory,Dsubnames{ii})},...
        size(Dsub{ii},1),size(Dsub{ii},2));
    [Dsub{ii}.source_dir] = kd_{:};
end

% pool them all together
Dall = vertcat(D,Dsub{:});

% and find the files that match the format in kinfile_regexp
is_kinfile = arrayfun(@(x) ~isempty(regexpi(x.name,kinfile_regexp,'once')),...
    Dall);
D_kinfiles = Dall(is_kinfile);

kincell = cell(size(D_kinfiles));
% now grab those files!
for ii = 1:numel(D_kinfiles)
    ff = fullfile(D_kinfiles(ii).source_dir,D_kinfiles(ii).name);
    kincell{ii} = load(ff);
end


%% okay now what?
% answer: use Bart's project file & Zara's HTS files from Session 47 as a
% template to format each of the structs you just loaded.
%
% the idea being to create two sets of structs: one being the hand objects,
% and one being the dang data!

% yeah... you might want to make these paths parameters so that future
% users (or future YOU-sers... heh) can change where this code looks as
% needed (and also adjust the file name format depending on whether a
% Windows or Mac machine is being used).
Template_Data    = load(...
    '/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/Template Files/Zara Recording/Recording47_HTS.mat');
Template_Project = load(...
    '/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/Template Files/Bart Project/Bart.mat');

% =========================================================================
% =========================================================================
% loading these arrays results in a bunch of warnings where classes
% 'instrument' and 'icinterface' and 'udp' fail to be loaded. as far as I
% can tell, these are important only during recording of kinematics (and
% may require even OLDER versions of MATLAB to function), so this shouldn't
% cause too many problems. I'm writing this for posterity, though, in case
% a problem DOES arise, so that whoever is using this code has a lead of
% *some* sort
% =========================================================================
% =========================================================================

project_cells = cell(size(kincell));
data_cells    = cell(size(kincell));

for ii = 1:numel(kincell)
    kc = kincell{ii};
    
    temp_data    = Template_Data;
    
    % go through each field of the DATA and replace it with what's present
    % in kc
    fn = fieldnames(temp_data);
    for jj = 1:numel(fn)        
        % check to see if it's numeric first
        tdfld = temp_data.(fn{jj});
        kcfld = kc.(fn{jj});
        
        if isnumeric(tdfld)
            if isnumeric(kcfld)
                temp_data.(fn{jj}) = kcfld;
            else
                % pass & keep the default values...
            end
            continue % don't run the rest of the code then, which assumes a sub-structure rather than double!
        else
            % pass & move on to the next step
        end
        
        fn_ = fieldnames(temp_data.(fn{jj}));
        
        for kk = 1:numel(fn_)
            tdfield = temp_data.(fn{jj}).(fn_{kk});
            kcfield = kc.(fn{jj}).(fn_{kk});
            
            % check to see if the sizes & types match up
            tdsz    = size(tdfield);
            tdclass = class(tdfield);
            
            kcsz    = size(kcfield);
            kcclass = class(kcfield);
            
            if ~strcmpi(tdclass,kcclass)
                % default to the temporary value
                fprintf('Subfield %s of field %s is not of a consistent class; maintaining "default" values of the template data',...
                    fn_{kk},fn{jj});
            else
                if ischar(kcfield) % if a string
                    % replace with the string in the actual data (otherwise
                    % the metadata get real confusing real fast)
                    temp_data.(fn{jj}).(fn_{kk}) = kcfield;
                    
                elseif isnumeric(kcfield) % if numeric
                    if numel(kcsz) == numel(tdsz)
                        if all(kcsz == tdsz) % if the sizes are consistent
                            % replace with the string in the actual data
                            temp_data.(fn{jj}).(fn_{kk}) = kcfield;
                            continue
                        else
                            % pass
                        end
                    else
                        % pass
                    end
                    
                    % if the above are passed, we move on to here...
                    if numel(kcfield) == numel(tdfield) % if the sizes are inconsistent but the number of elements is
                        temp_data.(fn{jj}).(fn_{kk}) = reshape(kcfield,tdsz);
                    elseif all(kcsz==1) % if the sizes are not consistent and kcsz is scalar
                        temp_data.(fn{jj}).(fn_{kk}) = repmat(kcfield,tdsz);
                    else % otherwise just pick indices and fill them, leaving the rest of the indices to take their "default" values
                        ndims = numel(tdsz);
                        
                        dimcell = zeros(ndims,1);
                        for ll = 1:ndims
                            tdval = tdsz(ll);
                            
                            if ll <= numel(kcsz)
                                kcval = kcsz(ll);
                            else
                                kcval = 1;
                            end
                            
                            maxind = min(tdval,kcval);
                            dimcell(ll) = maxind;
                        end
                        
                        indstring = '(';
                        for ll = 1:ndims
                            tempstring = sprintf('1:%i',dimcell(ll));
                            indstring  = horzcat(indstring,tempstring); %#ok<*AGROW>
                            
                            if ll < ndims
                                indstring = horzcat(indstring,',');
                            end
                        end
                        indstring = horzcat(indstring,')');
                        
                        % this preserves the shape of temp_data and fills
                        % it with as much data from the kincell as possible
                        % (these fields generally just get overwritten by
                        % KinemaTracks anyway, so this hack is solely to
                        % get the properly-"shaped" inputs for
                        % KinemaTracks!!!)
                        %
                        % hmmmm... it seems that during the "mirror" task
                        % (i.e. the passive observation task), the
                        % "armjoints" field is conspicuously full of NaN!
                        % this... might be a problem. I hope not, but it
                        % probably will be...
                        eval(sprintf('temp_data.(fn{jj}).(fn_{kk})%s = kcfield%s;',...
                            indstring,indstring));
                    end
                else
                    % just keep it as the default value if you don't know
                    % what it is...
                end
            end
            
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % hard-coded special exception: if you're dealing with the LHO in
    % particular, replace those first three elements of the
    % first row of armjoints with the vector [0,0,-lengthdorsum]
    % hopefully this is enough
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    temp_data.LHO.armjoints(1,1:3) = [0,0,-temp_data.LHO.lengthdorsum];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    data_cells{ii} = temp_data;
end

% now go thru and use data_cells to reconstruct the information that should
% be in the project files

for ii = 1:numel(project_cells)
    dc = data_cells{ii};
    
    temp_project = Template_Project;
    fn = fieldnames(temp_project);
    
    for jj = 1:numel(fn)
        fieldname_ = fn{jj};
        
        if isa(temp_project.(fieldname_),'handobj') || ...
                isa(temp_project.(fieldname_),'sysobj')
            data_fieldname_ = fieldname_(1:(end-2)); % remove the _s
            
            fn_ = fieldnames(temp_project.(fieldname_));
            
            for kk = 1:numel(fn_)
                fieldname__ = fn_{kk};
                
                tdfield = temp_project.(fieldname_).(fn_{kk});
                kcfield = dc.(data_fieldname_).(fn_{kk});
                
                % check to see if the sizes & types match up
                tdsz    = size(tdfield);
                tdclass = class(tdfield);
                
                kcsz    = size(kcfield);
                kcclass = class(kcfield);
                
                if ~strcmpi(tdclass,kcclass)
                    % default to the temporary value
                    fprintf('Subfield %s of field %s is not of a consistent class; maintaining "default" values of the template data',...
                        fn_{kk},fn{jj});
                else
                    if ischar(kcfield) % if a string
                        % replace with the string in the actual data (otherwise
                        % the metadata get real confusing real fast)
                        temp_project.(fn{jj}).(fn_{kk}) = kcfield;
                        
                    elseif isnumeric(kcfield) % if numeric
                        if numel(kcsz) == numel(tdsz)
                            if all(kcsz == tdsz) % if the sizes are consistent
                                % replace with the string in the actual data
                                temp_project.(fn{jj}).(fn_{kk}) = kcfield;
                                continue
                            else
                                % pass
                            end
                        else
                            % pass
                        end
                        
                        % if the above are passed, we move on to here...
                        if numel(kcfield) == numel(tdfield) % if the sizes are inconsistent but the number of elements is
                            temp_project.(fn{jj}).(fn_{kk}) = reshape(kcfield,tdsz);
                        elseif all(kcsz==1) % if the sizes are not consistent and kcsz is scalar
                            temp_project.(fn{jj}).(fn_{kk}) = repmat(kcfield,tdsz);
                        else % otherwise just pick indices and fill them, leaving the rest of the indices to take their "default" values
                            ndims = numel(tdsz);
                            
                            dimcell = zeros(ndims,1);
                            for ll = 1:ndims
                                tdval = tdsz(ll);
                                
                                if ll <= numel(kcsz)
                                    kcval = kcsz(ll);
                                else
                                    kcval = 1;
                                end
                                
                                maxind = min(tdval,kcval);
                                dimcell(ll) = maxind;
                            end
                            
                            indstring = '(';
                            for ll = 1:ndims
                                tempstring = sprintf('1:%i',dimcell(ll));
                                indstring  = horzcat(indstring,tempstring); %#ok<*AGROW>
                                
                                if ll < ndims
                                    indstring = horzcat(indstring,',');
                                end
                            end
                            indstring = horzcat(indstring,')');
                            
                            % this preserves the shape of temp_data and fills
                            % it with as much data from the kincell as possible
                            % (these fields generally just get overwritten by
                            % KinemaTracks anyway, so this hack is solely to
                            % get the properly-"shaped" inputs for
                            % KinemaTracks!!!)
                            %
                            % hmmmm... it seems that during the "mirror" task
                            % (i.e. the passive observation task), the
                            % "armjoints" field is conspicuously full of NaN!
                            % this... might be a problem. I hope not, but it
                            % probably will be... (how prescient!)
                            eval(sprintf('temp_project.(fn{jj}).(fn_{kk})%s = kcfield%s;',...
                                indstring,indstring));
                        end
                    else
                        % just keep it as the default value if you don't know
                        % what it is...
                    end
                end
                
            end
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % hard-coded special exception: if you're dealing with the LHO in
            % particular, replace those first three elements of the
            % first row of armjoints with the vector [0,0,-lengthdorsum]
            % hopefully this is enough
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            temp_project.LHO_s.armjoints(1,1:3) = [0,0,-temp_project.LHO_s.lengthdorsum];
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            data_cells{ii}.(data_fieldname_) = temp_project.(fieldname_); % replace these with those formatted after bart's project, which is the one true good & cool one that definitely works
            
        else
            % pass
        end        
    end
    project_cells{ii} = temp_project;
end

%% okay NOW we have the data_cells and project_cells formatted properly
%% so if we can find the scripts that call KinemaTracks without having to go through the GUI, we should be golden
%% ...well time to debug & find which scripts get called by the GUI then!

%% debugging code: save each project & data structure separately
% % this is debugging because it's never needed for any reason unless you use
% % the GUI
% for ii = 1:numel(project_cells)
%     pc_ = project_cells{ii};
%     dc_ = data_cells{ii};
%     
%     % these are hard-coded to be named Zara68 for now (and probably
%     % forever, because again, this is just debugging script, not meant to
%     % be generally useful)
%     projname_2save = sprintf('Zara68_ProjectFile%i.mat',ii);
%     dataname_2save = sprintf('Zara68_DataFile%i.mat',ii);
%     
%     % now save the project
%     save(projname_2save,'-struct','pc_')
%     
%     % and the data
%     save(dataname_2save,'-struct','dc_')
% end
            
    
%% debugging code: calling kinematracks
% % you already have the graspanalyze and kinematracks folders in your
% % directory
% %
% % so, you can just call kinematracks from here
% 
% set(0,'defaultfigurewindowstyle','normal') % to avoid bugs related to graphics code
% KinemaTracks




%% set up 5 variables:
% LHO
% GHO
% REC
% extractoption

% just hard-code values that you would normally set by fiddling with the
% GUI. Omit properties that are deprecated in your implementation of
% Stefan's code (namely the features associated with the statusbar, the GUI
% handles, and the directory in which to save the feature extraction
% results). I'm preserving features related to "trialplot" and metadata
% (e.g., subject & session identifiers & the tfrom-tto fields, which
% require info from the TSQ files), as I may want to re-incorporate that at
% a later date.

% note also that this part of the code requires the KinemaTracks folder
% (and all sub-folders) to be part of the current MATLAB search path. If it
% ain't, it crashes.

global extractoption
extractoption.timeselect  = 0;
extractoption.sr          = 100;
extractoption.gap         = 0.200;
extractoption.elimerrors  = 1;
extractoption.elimgaps    = 1;
extractoption.angles      = 1;
extractoption.interpolate = 1;
extractoption.subject     = '';
extractoption.session     = '';
extractoption.trialplot   = 0;
extractoption.tfrom       = nan;
extractoption.tto         = nan;
extractoption.notrialinfo = 1;

global LHO
global GHO
global REC
global kinematics % ah okay this one has no steady sampling rate (it goes up & down depending on how heavy the load placed on the KinemaTracks system is) 
global kinematics_i

kinematics = [];
kinematics_i = [];

% hard-code a field called "GST" as well, which was only ever instantiated
% upon calling "loadProject". It's similarly hard-coded in there as well,
% so it seems more efficient to just re-hard-code it rather than load in a
% bunch of data. What a mess!
global GST
GST.plot_enable=1;
GST.udp_enable=0;
GST.flatf1sens=0;
GST.nopipinversion=0;

for ii = 1:numel(data_cells)
    dc = data_cells{ii};
    
    LHO = dc.LHO;
    GHO = dc.GHO;
    REC = dc.recording;
    
    Batch_extractfeatures_noStatusBar;
    
    % so, I already rigged the function above to create a struct that
    % appends to itself with successive calls. So I don't need to worry
    % about successive iterations "overwriting" anything, but I SHOULD
    % enforce that these variables are emptied before every re-run of this
    % script
end
    
    
%% and now we convert the interpolated kinematics into a format that can then be subsequently converted into an OpenSim trc file!
% this is taken from "snippets.m" from the "Kinematics Tutorial" folder

opensim_formatted_cells = cell(size(kinematics_i));

for ii = 1:numel(kinematics_i)
    posK = kinematics_i(ii).globalpos';
    time = kinematics_i(ii).time;
    arm  = kinematics_i(ii).globalhand.handside;
    
    % Transform from the KinemaTracks (k) frame to the OpenSim (os) frame
    % Xos=-Xk, Yos=-Zk, Zss=-Yk and recenter: OpenSim model is centered
    % at the shoulder (zero coords)
    posOS = posK;
    posOS(:,1:3:end) = -(posK(:,1:3:end) - nanmedian(posK(:,76)));
    posOS(:,2:3:end) = -(posK(:,3:3:end) - nanmedian(posK(:,78)));
    posOS(:,3:3:end) = -(posK(:,2:3:end) - nanmedian(posK(:,77)));
    % Remove dorsum, this is not required by OpenSim
    posOS(:,61:63) = [];
    
    % % Interpolate data to a homogeneous sampling rate and remove NaN
    % DT = 0.01;
    % timeSCi = time(1):DT:time(end);
    % posSCi = interp1(time, posOS, timeSCi, 'pchip');
    
    % (if you're already working with kinematics_i, this has already been done)
    timeSCi = time;
    posSCi  = posOS;
    
    %Add frame number and timestamps to the matrix
    poseTimeFrames = [(1:length(posSCi))', timeSCi',posSCi];
    
    % Some data is from the right arm but the model is left: horizontally
    % mirror it
    if strcmpi(arm, 'Right')
        poseTimeFrames(:,3:3:end) = -poseTimeFrames(:,3:3:end); % James Edit converted from posOS to poseTimeFrames
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % you've already done gap-filling, which should hopefully make the
    % process of deleting NaNs that much easier. That said, if you run into
    % errors, come back to this, as it may be that Opensim doesn't like
    % this particular manner of handling NaN entries!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Okay you're going to need to be smarter about this. probably by using
    % a much more aggressive gap-filling protocol than Stefan's defaults.
    % Alternatively, you allow SOME NaN-frames to pass through, but delete
    % the obviously unusable FULL-NaN frames. (The latter feels more
    % palatable; doing too much interpolation is pretty wacky, and I doubt
    % Stefan's code handles it with the same template-based system that
    % Vicon used!) (UGH there's so many intermittent breaks... should I try
    % just deleting full-NaN snippets & seeing if Opensim has a problem
    % with the resultant non-uniform sampling rate? UGH gaps in a recording
    % are the FUCKING WORST)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % let's actually just try to remove the full-nan frames. the frames
    % with MOSTLY nan are probably going to be fucked up, but based on my
    % experience in Sliman's lab they shouldn't outright break Opensim.
    PTF = poseTimeFrames;
    nanframes = all(isnan(PTF(:,3:end)),2);
    PTF(nanframes,:) = [];
    poseTimeFrames = PTF;
    
    %     PTF = poseTimeFrames;
    %
    %     nanframes = sum(isnan(PTF(:,3:end)),2) >= sum(~isnan(PTF(:,3:end)),2);
    %     % exclude the first two columns, which are samples & times and should NEVER be NaN.
    %     % also, find frames with MORE NaN than non-NaN and exclude those, as
    %     % sometimes the shoulder & arm markers are inexplicably left remaining
    %     % even as the rest of the hand went kaput.
    %
    %     % find the largest block uninterrupted by frames with more NaN values
    %     % than actual numbers
    %     cumsum_with_resets = zeros(size(nanframes));
    %     current_val = 0;
    %     for sampind = 1:numel(nanframes)
    %         if ~nanframes(sampind)
    %             current_val = current_val + 1;
    %         else
    %             current_val = 0;
    %         end
    %
    %         cumsum_with_resets(sampind) = current_val;
    %     end
    %
    %     [maxval,maxind] = max(cumsum_with_resets);
    %     snippet_inds = (maxind-maxval+1):maxind;
    %
    %     poseTimeFrames = poseTimeFrames(snippet_inds,:);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Now you can open poseTimeFrames in the variables window and copy the data
    %into the trc files. For movement don't forget to adjust the number of
    %total frames on top!
    opensim_formatted_cells{ii} = poseTimeFrames;
end

%% PARAMETER SETTING
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find a way to automate file naming...
filenames = {'Zara_ControlandActive1.trc',...
    'Zara_Passive1.trc','Zara_Active2.trc','Zara_Passive2.trc',...
    'Zara_Active3.trc','Zara_Passive3.trc','Zara_Active4.trc',...
    'Zara_Passive4.trc'};

filenames_static = cellfun(@(x) strcat(x(1:(end-4)),'_static',x((end-3):end)),...
    filenames,'uniformoutput',false);

filenames_total = horzcat(filenames,filenames_static);

MarkerDirectory        = '/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode';
BaseModelFile          = '/Users/jgoodman/Dropbox/Mirror Local/KinematicsCode/Template Files/OpenSim Model/BaseArmModel.osim';
ScaleSetupTemplateFile = 'ScaleTool_Setup.xml';
IKSetupTemplateFile    = 'IKTool_Setup.xml';

OpenSimCMDLocation     = '/Applications/OpenSim\ 4.1/bin'; % nope, we still need this. 
% even though opening a Mac Terminal window recognizes "opensim-cmd" as a valid command, 
% calling bash through MATLAB fails to do so. There's a way to add the bash
% current path to MATLAB's search path and make it work that way, but I
% figure just defining the path where opensim-cmd is located works just
% fine. BTW I use a backslash to specify spaces here (as should you!) as
% otherwise bash gets confused and thinks spaces in file names are actually
% spaces denoting new inputs to the function. I only ever use this variable
% as an input to bash, hence why I just do it here rather than writing a
% routine that replaces all instances of ' ' with '\ ' like I did with the
% other file names above (which I use for purposes other than bash
% commands).

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% now convert to trc files
% first, read in the template trc file
s = readtrc('ScaleMarkersRalphie.trc');

% for each kinematics file
tic
for ii = 1:numel(opensim_formatted_cells)
    ss = s;
    
    % replace "data" field with the appropriate opensim-formatted cell
    ss.data = opensim_formatted_cells{ii};
    
    % replace datarate and camerarate and origdatarate with the appropriate numbers
    sr = kinematics_i(ii).samplrate;
    
    ss.header{3,1} = num2str(sr);
    ss.header{3,2} = num2str(sr);
    ss.header{3,6} = num2str(sr);
    
    % replace numframes and origdatastartframe and orignumframes with an appropriate number
    maxframe = max(opensim_formatted_cells{ii}(:,1));
    minframe = min(opensim_formatted_cells{ii}(:,1));
    nframes  = numel(opensim_formatted_cells{ii}(:,1)); %maxframe - minframe + 1; % indexed from 1
    
    ss.header{3,3} = num2str(nframes);
    ss.header{3,8} = num2str(maxframe);
    ss.header{3,7} = num2str(minframe);
    
    % replace number of markers with appropriate number
    nmrkr = ( size(opensim_formatted_cells{ii},2) - 2 )/3;
    ss.header{3,4} = num2str(nmrkr);
    
    % replace the file name with the one you intend to save it as
    ss.header{1,4} = filenames{ii};
    
    % don't bother with changing the units; I assume mm is the appropriate
    % unit here...
    
    % now write!
    sout = writetrc(filenames{ii},ss);
    toc
end

%% now we create a "static" trc to go with each "real" one
newfilenames = filenames;
for ii = 1:numel(filenames)
    s = readtrc(filenames{ii});
    
    % in the "data" field, find the 5s-long stretch with the smallest
    % variance (and NO NANS, so ignoring NAN values would actually be BAD 
    % because it'd mask where they are!)
    %
    % treat all markers equally...
    % UGHHHH I wish I could use movvar but I need to use a too-old version
    % of MATLAB to run KinemaTracks! UGH!!!
    % 
    % okay, when all is said and done, try this script in newer MATLAB.
    % Bypassing the GUI might bypass the "old MATLAB" requirement.
    %
    % THEN replace what's about to come with a simple call to "movvar".
    
    % grab the sampling rate
    sr = str2double(s.header{3,1});
    
    % determine the length of stretch you want
    stretch_length_seconds = 5;
    stretch_length_samples = stretch_length_seconds * sr;
    
    % here is how we make the filter one-sided so we can easily reconstruct
    % which stretch had the lowest variance... basically, each value of the
    % convolved variable will correspond with the first sample of the
    % target window (so bestind:(bestind+stretch_length_samples) is a valid
    % operation that does precisely what it hopes to: find the stretch with
    % the lowest variance!)
    rw                             = zeros(2*stretch_length_samples-1,1);
    rw(1:stretch_length_samples)   = 1;
    
    % yes, the separation into PIP and DIP is a misnomer for the thumb.
    % What is meant by those is MCP and IP, respectively. The "MCP" joint
    % is similarly misnamed; it should be called the thumb CMC joint.
    target_joints = {'Wrist_L','Thumb_MCP_L','Thumb_PIP_L',...
        'Thumb_DIP_L','Thumb_TIP_L','Index_MCP_L',...
        'Index_PIP_L','Index_DIP_L','Little_PIP_L',...
        'Ring_PIP_L','Middle_PIP_L','Middle_MCP_L',...
        'Ring_MCP_L','Little_MCP_L','Middle_DIP_L',...
        'Ring_DIP_L','Little_DIP_L','Index_TIP_L',...
        'Middle_TIP_L','Ring_TIP_L','Little_TIP_L',...
        'Elbow_L','Sholder_L','Point_E1_L','Point_W1_L'};
    header_joint_names   = s.header(4,:);
    are_empty            = cellfun(@(x) isempty(x),header_joint_names);
    unemptied            = header_joint_names;
    unemptied(are_empty) = cellfun(@(x) '',unemptied(are_empty),'uniformoutput',false);
    target_inds          = cellfun(@(x) ismember(x,target_joints),unemptied);
    target_inds          = [find(target_inds);find(target_inds)+1;find(target_inds)+2]; % get all 3 coordinates
    target_inds          = target_inds(:);
    
    % only use these target inds, as they are the only ones that will be
    % used by the IK model
    datavals      = s.data(:,target_inds);
    max_valid_ind = size(datavals,1) - stretch_length_samples; % any further than this and the zero-to-one balance of your convolution kernel is thrown off
    
    E_X2 = conv2(datavals.^2,rw,'same');
    EX_2 = conv2(datavals,rw,'same').^2;
    
    E_X2 = E_X2(1:max_valid_ind,:);
    EX_2 = EX_2(1:max_valid_ind,:);
    
    % calculate variance
    varvals = ( E_X2 - EX_2 ./ stretch_length_samples ) ./ (stretch_length_samples - 1);
    
    % and take their sum
    sumvarvals = sum(varvals,2);
    
    % find the minimum variance
    [minvar,minvarpoint] = min(sumvarvals);
    
    % and find the stretch with minimum variance
    target_stretch = s.data(minvarpoint:(minvarpoint+stretch_length_samples-1),:);
    
    % replace data in s with these
    s.data = target_stretch;
    
    % adjust the numframes property of the header appropriately
    s.header{3,3} = num2str(stretch_length_samples);
    
    % define a new file name
    %     [pathstr,name,ext] = fileparts(filenames{ii});
    %     newname = [name,'_static'];
    %     newfilename = fullfile(pathstr,[newname,ext]);
    newfilename = filenames_static{ii};
    
    % adjust the filename field appropriately
    s.header{1,4} = newfilename;
    
    % and save
    outstring    = writetrc(newfilename,s);
    newfilenames = horzcat(newfilenames,{newfilename}); %#ok<*AGROW>
end
    
    
    
    

%% now we use the Opensim command line utilities
% this is written for mac; windows should be similar, but do make sure you
% test it out. there WILL be bugs to fix.
%
% to use this part, one must first enable command line control using the
% instructions found here: https://simtk-confluence.stanford.edu/display/OpenSim/Command+Line+Utilities
%
% note that if you end up with a problem, you either don't have the
% opensim-cmd alias in your /usr/local/bin folder, or you have one that
% points to the wrong location. In this case, delete the opensim-cmd alias
% and re-create it.
%
% once you've gotten those set up, everything else should work fine. I
% created template files using the command line tool, e.g.,
%
% (base) MAC259:~ jgoodman$ opensim-cmd print-xml scale
%
% which then printed the template file to my home folder. I moved those
% files to the KinematicsCode folder so that users don't need to re-print
% these templates every time they want to use KinemaTracks on a new
% machine.

% we will only use static sessions for scaling
% we'll re-run it for each separate file / block
% because there's always a chance the markers shift around between blocks
% (due to the monkey knocking sensors off or pulling the glove off), and
% re-scaling can account for that. Plus, in the context of the "mirror
% neuron" datasets, it also accounts for switching back and forth between
% monkey & human hands (blocks were interleaved where the monkey performed
% the task, then the instrumented human handler while the monkey watched,
% then the monkey again, and so on).
% 
% we will, however, want to double-check that the scale factors across the
% different files are similar. Which may require us to look through .log
% files or whatever.
%
% ALSO NOTE THAT ON MAC, YOU MAY NEED TO SET UP OPENSIM 3 VIA WINE TO
% REPLAY THE VIDEO!!! Likely because of the old models
% navigate to your user folder, then /.wine/drive_c, and you'll find it (if
% you've used vanilla wine to install it that is!)
% 
% Download of old (and new) opensim can be done here: https://simtk.org/frs/?group_id=91
% Look under "previous releases" to find opensim 3.3

for ii = 1:numel(filenames_static)
    s = readtrc(filenames_static{ii});
    file2specify = fullfile(MarkerDirectory,filenames_static{ii});
    
    scaleXML = xmlread(ScaleSetupTemplateFile);
    
    scaleXML.getElementsByTagName('marker_file').item(0).getFirstChild.setNodeValue(file2specify);
    scaleXML.getElementsByTagName('marker_file').item(1).getFirstChild.setNodeValue(file2specify);

    scaleXML.getElementsByTagName('model_file').item(0).getFirstChild.setNodeValue(BaseModelFile);
    
    output_file = fullfile(MarkerDirectory,[filenames_static{ii}(1:(end-4)),'_scaledmodel.osim']);
    scaleXML.getElementsByTagName('output_model_file').item(0).getFirstChild.setNodeValue(output_file);
    scaleXML.getElementsByTagName('output_model_file').item(1).getFirstChild.setNodeValue(output_file);
    
    staticstart   = s.data(1,2);
    staticstop    = s.data(end,2);
    timerange     = [num2str(staticstart) ' ' num2str(staticstop)];
    scaleXML.getElementsByTagName('time_range').item(0).getFirstChild.setNodeValue(timerange);
    scaleXML.getElementsByTagName('time_range').item(1).getFirstChild.setNodeValue(timerange);
    
    scaleOutFile = fullfile(MarkerDirectory,[filenames_static{ii}(1:(end-4)),'_ScaleSet_Applied.xml']);
    scaleXML.getElementsByTagName('output_scale_file').item(0).getFirstChild.setNodeValue(scaleOutFile);
    
    setupfilename = fullfile(MarkerDirectory,[filenames_static{ii}(1:(end-4)),'_ScaleSetup.xml']);
    xmlwrite(setupfilename,scaleXML);
    pause(1)
    
    % take setupfilename and replace all spaces with backslash-spaces
    whitespace_locs = regexpi(setupfilename,'\s');
    replacement_string = '\ ';
    newfilename        = '';
    startind           = 1;
    for jj = 1:numel(whitespace_locs)
        current_snippet_loc = startind:(whitespace_locs(jj)-1);
        current_snippet     = setupfilename(current_snippet_loc);
        edited_snippet      = horzcat(current_snippet,replacement_string);
        newfilename         = horzcat(newfilename,edited_snippet); %#ok<*AGROW>
        startind = whitespace_locs(jj)+1;
    end
    
    current_snippet_loc = startind:numel(setupfilename);
    current_snippet     = setupfilename(current_snippet_loc);
    newfilename         = horzcat(newfilename,current_snippet);
        
    ScaleCommand = sprintf('%s/opensim-cmd run-tool %s',OpenSimCMDLocation,newfilename);
    pause(1)
    
    system(ScaleCommand);
    pause(1)
    
    % copy and rename files
    oldfilenames = {'err.log','out.log'};
    
    for ofind = 1:numel(oldfilenames)
        ofn = oldfilenames{ofind};
        
        if ~strcmpi(ofn(1),'_')
            ofn_ = ['_',ofn];
        else
            ofn_ = ofn;
        end
        
        [status,msg,msgid] = copyfile( ...
            fullfile(MarkerDirectory,ofn), ...
            fullfile(MarkerDirectory,sprintf('%s%s',filenames_static{ii}(1:(end-4)),ofn_)) ...
            );
        
        delete( fullfile(MarkerDirectory,ofn) )
    end
end


%% Okay, so we have a problem
% namely, the blocks where "Alex" performed the task in Zara68 are missing
% a couple of markers THROUGHOUT. Which means that scaling is all messed up
% (and as a result, so will the resulting inverse kinematics).
%
% UGHHHHH where the hell did this all go wrong?!? Why are "Alex"'s data
% like this? And what, if anything, can I do to fix the problem?
%
% the biggest red flag to me is that in the GHO, the "armjoints" field is
% populated ENTIRELY by NaNs in "Alex"'s data, whereas for Zara this field contains a row of numbers followed by 4 rows of NaN.
%
% ...yeah, that's the only thing I can see being different. The stupid
% thing is that all the information seems to be there otherwise, and that
% first row just gets overwritten by a point translated in the z direction
% relative to the origin by the length of the dorsum - no doubt the
% location of the wrist marker relative to the "reference" marker.
% Apparently, though, if that row is initially populated by NaN instead of
% values, then this over-writing never takes place and everything goes to
% shit.
%
% A way to test this? replace the first three entries in "armjoints" with
% the (row) vector I just described: [0 0 -lengthdorsum].
%
% Okay, I think I fixed it by replacing the first row of that
% constantly-overwritten field with the parameters dictating the size of
% the arm. As far as I can tell, this should be valid.
%
% Now, it's time to run IK


%% SIDE NOTE ABOUT THE MODEL
% because the shoulder position is treated, BY DEFINITION, as (0,0,0),
% there is NO need to apply a transformation operation WITHIN Opensim.
% (which is good, because the models on file have this coordinate removed!)

%% TIME FOR IK!
for ii = 1:numel(filenames)
    s = readtrc(filenames{ii});
    file2specify = fullfile(MarkerDirectory,filenames{ii});
    output_file  = fullfile(MarkerDirectory,[filenames{ii}(1:(end-4)),'_ik.mot']); % we only care about the movement file... so keep the naming consistent here! don't add a _static here ya big dingus, because those aren't the marker data you're using!!!
    model_file   = fullfile(MarkerDirectory,[filenames_static{ii}(1:(end-4)),'_scaledmodel.osim']); % that said, the way we scaled the models was with "static" files...
    starttime   = s.data(1,2);
    stoptime    = s.data(end,2);
    timerange   = [num2str(starttime) ' ' num2str(stoptime)];
    

    IKXML = xmlread(IKSetupTemplateFile);
    
    IKXML.getElementsByTagName('marker_file').item(0).getFirstChild.setNodeValue(file2specify);
    IKXML.getElementsByTagName('output_motion_file').item(0).getFirstChild.setNodeValue(output_file);
    
    % Yes, you need to specify these even though the parent directories are
    % specified in the full file paths themselves. No, I don't know why.
    IKXML.getElementsByTagName('results_directory').item(0).getFirstChild.setNodeValue(MarkerDirectory);
    IKXML.getElementsByTagName('input_directory').item(0).getFirstChild.setNodeValue(MarkerDirectory);
    
    IKXML.getElementsByTagName('model_file').item(0).getFirstChild.setNodeValue(model_file);
    IKXML.getElementsByTagName('time_range').item(0).getFirstChild.setNodeValue(timerange);
    
    IKXML.getElementsByTagName('report_errors').item(0).getFirstChild.setNodeValue('true');
    IKXML.getElementsByTagName('report_marker_locations').item(0).getFirstChild.setNodeValue('true');
    
    setupfilename = fullfile(MarkerDirectory,[filenames{ii}(1:(end-4)),'_IKSetup.xml']);
    xmlwrite(setupfilename,IKXML);
    pause(1)
    
    % take setupfilename and replace all spaces with backslash-spaces
    whitespace_locs = regexpi(setupfilename,'\s');
    replacement_string = '\ ';
    newfilename        = '';
    startind           = 1;
    for jj = 1:numel(whitespace_locs)
        current_snippet_loc = startind:(whitespace_locs(jj)-1);
        current_snippet     = setupfilename(current_snippet_loc);
        edited_snippet      = horzcat(current_snippet,replacement_string);
        newfilename         = horzcat(newfilename,edited_snippet); %#ok<*AGROW>
        startind = whitespace_locs(jj)+1;
    end
    
    current_snippet_loc = startind:numel(setupfilename);
    current_snippet     = setupfilename(current_snippet_loc);
    newfilename         = horzcat(newfilename,current_snippet);
    
    % yep, the very same command as for scaling the model. The XML file
    % itself dictates what operation (scaling, ik) to do.
    IKCommand = sprintf('%s/opensim-cmd run-tool %s',OpenSimCMDLocation,newfilename);
    pause(1)
    
    system(IKCommand);
    pause(1)
    
    % copy and rename files
    oldfilenames = {'_ik_marker_errors.sto','_ik_model_marker_locations.sto',...
        'err.log','out.log'};
    
    for ofind = 1:numel(oldfilenames)
        ofn = oldfilenames{ofind};
        
        if ~strcmpi(ofn(1),'_')
            ofn_ = ['_',ofn];
        else
            ofn_ = ofn;
        end
        
        [status,msg,msgid] = copyfile( ...
            fullfile(MarkerDirectory,ofn), ...
            fullfile(MarkerDirectory,sprintf('%s%s',filenames{ii}(1:(end-4)),ofn_)) ...
            );
        
        delete( fullfile(MarkerDirectory,ofn) )
    end
end

% out.log
% err.log
% _ik_model_marker_locations.sto
% _ik_marker_errors.sto
%
% all need to be renamed on each iteration