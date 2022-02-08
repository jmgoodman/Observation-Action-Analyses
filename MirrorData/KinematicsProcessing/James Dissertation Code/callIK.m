function IK = callIK(gait_extract_dir,output_dir,vicon_folder,osim_dir,templates_dir,model_file,output_file,rightflag,muscleflag,yakoflag)

if nargin < 10
    yakoflag = false;
else
end

%% clean up input directory names & set up matlab path
gait_extract_dir = dirslash(gait_extract_dir);
output_dir       = dirslash(output_dir);
vicon_folder     = dirslash(vicon_folder);
osim_dir         = dirslash(osim_dir);
templates_dir    = dirslash(templates_dir);

pp = path;
addpath(genpath(gait_extract_dir))


%% set up the ik output directory & other directories you'll need to mess with
orig_dir = cd(gait_extract_dir);
trcdir = [output_dir,'trcFiles\'];
trc_backup_dir = [output_dir,'trcFiles_backup\'];
trc_process_dir = [gait_extract_dir,'OtherScripts\'];
iksetupdir = [output_dir,'iksetup\'];
ikmotdir   = [output_dir,'ikmotfiles\'];
scalesetupdir  = [output_dir,'scalesetup\'];
mlsetupdir = [output_dir,'musclesetup\'];
mlmotdir   = [output_dir,'musclestofiles\'];

scaled_mdl_file = [scalesetupdir,'scaled_model.osim'];
scale_setup_file = [scalesetupdir,'ScaleSetup.xml'];

iktemplatefile = [templates_dir,'Template_test_IK_Setup.xml'];
mltemplatefile = [templates_dir,'Template_test_Analysis_Setup.xml'];



TF = tcd(output_dir);

D = dir(output_dir); % assumes output directory is empty or nonexistent on a fresh run of a session

Nfldr = numel(D)-2; % note: this also includes the output file

try
    %% step 1: create trc files from c3ds in the vicon folder
    
    if Nfldr <= 1
        tcd(trcdir);
        
        D = dir(vicon_folder);
        E = dir(trcdir);
        numslist = [];
        staticslist = [];
        trialnames = {};
        staticnames = {};
        
        tic
        for i = 1:numel(D)
            isfile  = regexp(D(i).name,'^Trial\s+\d\d\d\.c3d$','once');
            
            processedname = D(i).name;
            spacetokens   = find(D(i).name == ' ');
            keeptokens    = [];
            
            for j = 1:numel(spacetokens)
                if ~any(abs(spacetokens(j)-keeptokens)<=1)
                    keeptokens = [keeptokens,spacetokens(j)];
                end
            end
            
            remtokens = spacetokens(~ismember(spacetokens,keeptokens));
            processedname(remtokens) = [];
            
            isexist = ismember(processedname(1:(end-3)),arrayfun(@(x) x.name(1:(end-3)),E,'uniformoutput',false)); % if you've already run trc creation, don't run it again!
            if ~isempty(isfile)
                numslist = horzcat(numslist,str2double(D(i).name((end-6):(end-4)))); %#ok<*AGROW>
                if ~isexist
                    trialnames = vertcat(trialnames,D(i).name);
                end
            else
            end
            
            isStatic = regexp(D(i).name,'^Static\s+\d\d\d\.c3d$','once');
            if ~isempty(isStatic)
                staticslist = horzcat(staticslist,str2double(D(i).name((end-6):(end-4))));
                if ~isexist
                    staticnames = vertcat(staticnames,D(i).name);
                end
            else
            end
            toc
        end
        
        numslist    = sort(numslist);
        staticslist = sort(staticslist);
        
        cd(gait_extract_dir)
        
        if ~isempty(trialnames)
            callGaitExtract(vicon_folder,trcdir,trialnames);
        else
        end
        
        if ~isempty(staticnames)
            callGaitExtract(vicon_folder,trcdir,staticnames);
        end
        
        % rename every file there to make sure only one space is present for
        % each trial...
        D = dir(trcdir);
        for i = 1:numel(D)
            fname = D(i).name;
            
            if ~isempty(regexpi(fname,'^.*\.trc$','once'))
                spacetokens = find(fname == ' ');
                keeptokens  = [];
                
                for j = 1:numel(spacetokens)
                    if ~any(abs(spacetokens(j) - keeptokens)<=1)
                        keeptokens = [keeptokens, spacetokens(j)];
                    end
                end
                
                remtokens = spacetokens(~ismember(spacetokens,keeptokens));
                newfname  = fname;
                newfname(remtokens) = [];
                
                if ~strcmpi(newfname,fname)
                    copyfile([trcdir,fname],[trcdir,newfname]);
                    delete([trcdir,fname]);
                else
                end
            end
        end
        
        
        % create TRC backups because we will then go thru & process those TRC files
    else
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % 2019.07.05: you will need "staticslist" to do things later on, so DO find a way to make that variable here, even if you don't re-make all your TRC files!!!
        tcd(trcdir);
        
        D = dir(vicon_folder);
        E = dir(trcdir);
        numslist = [];
        staticslist = [];
        trialnames = {};
        staticnames = {};
        
        tic
        for i = 1:numel(D)
            isfile  = regexp(D(i).name,'^Trial\s+\d\d\d\.c3d$','once');
            
            processedname = D(i).name;
            spacetokens   = find(D(i).name == ' ');
            keeptokens    = [];
            
            for j = 1:numel(spacetokens)
                if ~any(abs(spacetokens(j)-keeptokens)<=1)
                    keeptokens = [keeptokens,spacetokens(j)];
                end
            end
            
            remtokens = spacetokens(~ismember(spacetokens,keeptokens));
            processedname(remtokens) = [];
            
            isexist = ismember(processedname(1:(end-3)),arrayfun(@(x) x.name(1:(end-3)),E,'uniformoutput',false)); % if you've already run trc creation, don't run it again!
            if ~isempty(isfile)
                numslist = horzcat(numslist,str2double(D(i).name((end-6):(end-4)))); %#ok<*AGROW>
                if ~isexist
                    trialnames = vertcat(trialnames,D(i).name);
                end
            else
            end
            
            isStatic = regexp(D(i).name,'^Static\s+\d\d\d\.c3d$','once');
            if ~isempty(isStatic)
                staticslist = horzcat(staticslist,str2double(D(i).name((end-6):(end-4))));
                if ~isexist
                    staticnames = vertcat(staticnames,D(i).name);
                end
            else
            end
            toc
        end
        
        numslist    = sort(numslist);
        staticslist = sort(staticslist);
        
        cd(gait_extract_dir)
        
        
        % rename every file there to make sure only one space is present for
        % each trial...
        D = dir(trcdir);
        for i = 1:numel(D)
            fname = D(i).name;
            
            if ~isempty(regexpi(fname,'^.*\.trc$','once'))
                spacetokens = find(fname == ' ');
                keeptokens  = [];
                
                for j = 1:numel(spacetokens)
                    if ~any(abs(spacetokens(j) - keeptokens)<=1)
                        keeptokens = [keeptokens, spacetokens(j)];
                    end
                end
                
                remtokens = spacetokens(~ismember(spacetokens,keeptokens));
                newfname  = fname;
                newfname(remtokens) = [];
                
                if ~strcmpi(newfname,fname)
                    copyfile([trcdir,fname],[trcdir,newfname]);
                    delete([trcdir,fname]);
                else
                end
            end
        end
        
        
        
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    end
    
    if Nfldr <= 2
        TF = tcd(trc_backup_dir);
        
        if TF == 0
            copyfile(trcdir,trc_backup_dir);
        else
            % only copy over files that weren't originally in the backup
            % directory
            D = dir(trcdir);
            E = dir(trc_backup_dir);
            
            tic
            for i = 1:numel(D)
                if ~ismember(D(i).name,arrayfun(@(x) x.name,E,'uniformoutput',false))
                    copyfile([trcdir,D(i).name],trc_backup_dir)
                else
                end
                toc
            end
            
            % replace everything in the trcdir with their backups so your
            % processing script doesn't result in un-flipping things (or
            % messing up the nanhandling by passing it thru twice)
            %
            % there's no good way to test whether the nanhandling & flipping
            % have already occurred (it would take just as long to check as it
            % would to just re-run everything), so the best I can do is make
            % sure the old backup files replace the potentially processed trc
            % files so that any flipping is not undone and any potential
            % second-pass nanhandler glitches are kept to a minimum
            olddir = cd(output_dir);
            rmdir('.\trcFiles\','s')
            pause(0.5)
            tcd(trcdir);
            copyfile(trc_backup_dir,trcdir)
            cd(olddir);
        end
    end
    
    % now process those TRCs
    cd(trc_process_dir)
    
    file_start_stop = struct('start',{},'stop',{},'filename',{});
    D = dir(trcdir);
    
    tic
    for i = 1:numel(D)
        if ~isempty(regexpi(D(i).name,'^.*\.trc$','once'))
            trc_filename = D(i).name;
            
            if Nfldr <= 7
                try
                    s            = readtrc([trcdir,trc_filename],rightflag); % if true, you flip the Z axis so that the left-handed kinematic model will work; otherwise, leave it alone
                catch err
                end
            end
            
            if Nfldr <= 2 % you'll want to do this every time... as if you don't replace your main trc with the backup every time you re-run, you end up with errors...
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                % comment this out if you need to test stuff & don't want to
                % spend forever reading & writing TRCs
                s_new        = nanhandler(s,'all');
                %             s_new = s; % for testing muscle analysis only
                
                writetrc([trcdir,trc_filename],s_new); % comment out for testing
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            end
            
            if Nfldr <= 7
                tempstruct.start = s.data(1,2);
                tempstruct.stop  = s.data(end,2);
            else
                tempstruct.start = [];
                tempstruct.stop  = [];
            end
            
            tempstruct.filename = trc_filename;
            
            
            file_start_stop = vertcat(file_start_stop,tempstruct);
        else
        end
        toc
    end
    
    %% run auto-scaling
    if Nfldr <= 3
        scaleSetupFile = [templates_dir,'Template_test_Scale_Setup.xml'];
        tcd(scalesetupdir);
        nslash = sum(scalesetupdir=='\'); %#ok<*NASGU>
        
        scaleXML       = xmlread(scaleSetupFile);
        
        % find the static session in question & find the start & stop inds
        tic
        for i = 1:numel(file_start_stop)
            if ~isempty(regexpi(file_start_stop(i).filename,'^.*Static\s+\d\d\d','once'))
                if str2double(file_start_stop(i).filename((end-6):(end-4))) == max(staticslist)
                    staticstart = file_start_stop(i).start;
                    staticstop  = file_start_stop(i).stop;
                    lastStatic  = file_start_stop(i).filename;
                    break
                end
            end
            toc
        end
        
        mdlfile_lastslash = find(model_file=='\',1,'last');
        
        if ~isempty(mdlfile_lastslash)
            model_file_ = model_file((mdlfile_lastslash+1):end);
            model_dir_  = model_file(1:mdlfile_lastslash);
        else
            model_file_ = model_file;
            model_dir_  = '.\';
        end
        
        % copy files over to your target directory (scaling for some reason
        % always appends the directory of the xml to every file, so unless
        % everything is in the scaling xml directory, it'll throw an error)
        copyfile([trcdir,lastStatic],scalesetupdir);
        copyfile([model_dir_,'Geometry\'],[scalesetupdir,'Geometry\']);
        copyfile(model_file,scalesetupdir);
        
        % and set those file properties
        scaleXML.getElementsByTagName('marker_file').item(0).getFirstChild.setNodeValue(lastStatic);
        scaleXML.getElementsByTagName('marker_file').item(1).getFirstChild.setNodeValue(lastStatic);
        scaleXML.getElementsByTagName('model_file').item(0).getFirstChild.setNodeValue(model_file_);
        scaleXML.getElementsByTagName('output_model_file').item(0).getFirstChild.setNodeValue('scaled_model.osim');
        scaleXML.getElementsByTagName('output_model_file').item(1).getFirstChild.setNodeValue('scaled_model.osim');
        
        scaleXML.getElementsByTagName('time_range').item(0).getFirstChild.setNodeValue([num2str(staticstart) ' ' num2str(staticstop)]);
        scaleXML.getElementsByTagName('time_range').item(1).getFirstChild.setNodeValue([num2str(staticstart) ' ' num2str(staticstop)]);
        xmlwrite([scalesetupdir,'ScaleSetup.xml'],scaleXML);
        
        
        
        
        % aaaand run it
        ScaleCommand = sprintf('"%sbin\\scale.exe" -S "%s"',osim_dir,scale_setup_file);
        system(ScaleCommand);
    end
    
    %% set up batch IK
    if Nfldr <= 5
        tcd(iksetupdir);
        
        tcd(ikmotdir);
                
        xmlDoc = xmlread(iktemplatefile);
        
        tic
        for i = 1:numel(file_start_stop)
            if ~isempty(regexpi(file_start_stop(i).filename,'^.*Trial\s+\d\d\d','once'))
                fname = file_start_stop(i).filename(1:(end-4));
                
                %             fprintf(['Generating setup file for Trial # ',appendno,'\n']);
                xmlDoc.getElementsByTagName('marker_file').item(0).getFirstChild.setNodeValue([trcdir,fname,'.trc']);
                xmlDoc.getElementsByTagName('output_motion_file').item(0).getFirstChild.setNodeValue([ikmotdir,fname,'_ik.mot']);
                xmlDoc.getElementsByTagName('results_directory').item(0).getFirstChild.setNodeValue(ikmotdir);
                xmlDoc.getElementsByTagName('input_directory').item(0).getFirstChild.setNodeValue(trcdir);
                xmlDoc.getElementsByTagName('model_file').item(0).getFirstChild.setNodeValue(scaled_mdl_file);
                xmlDoc.getElementsByTagName('time_range').item(0).getFirstChild.setNodeValue([num2str(file_start_stop(i).start) ' ' num2str(file_start_stop(i).stop)]);
                
                xmlwrite([iksetupdir,fname,'_IKsetup.xml'], xmlDoc);
            else
            end
            toc
        end
        
        
        
        %% and run it
        D = dir(iksetupdir);
        
        tic
        for i = 1:numel(D)
            if ~isempty(regexpi(D(i).name,'^.*_IKsetup.xml$','once'))
                IKcommand = sprintf('"%sbin\\ik.exe" -S "%s%s"',osim_dir,iksetupdir,D(i).name);
                system(IKcommand);
            end
            toc
        end
    end
    
    %% now do the same for muscles
    
    if muscleflag % only if you want to spend the time running it...
        % setup
        
        if Nfldr <= 7
            tcd(mlsetupdir);
            tcd(mlmotdir);
            
            xmlDoc         = xmlread(mltemplatefile);
            
            tic
            for i = 1:numel(file_start_stop)
                if ~isempty(regexpi(file_start_stop(i).filename,'^.*Trial\s+\d\d\d','once'))
                    fname = file_start_stop(i).filename(1:(end-4));
                    
                    %             fprintf(['Generating setup file for Trial # ',appendno,'\n']);
                    xmlDoc.getElementsByTagName('model_file').item(0).getFirstChild.setNodeValue(scaled_mdl_file);
                    xmlDoc.getElementsByTagName('results_directory').item(0).getFirstChild.setNodeValue([mlmotdir,fname,'\']);
                    xmlDoc.getElementsByTagName('initial_time').item(0).getFirstChild.setNodeValue(num2str(file_start_stop(i).start));
                    xmlDoc.getElementsByTagName('final_time').item(0).getFirstChild.setNodeValue(num2str(file_start_stop(i).stop));
                    xmlDoc.getElementsByTagName('start_time').item(0).getFirstChild.setNodeValue(num2str(file_start_stop(i).start));
                    xmlDoc.getElementsByTagName('end_time').item(0).getFirstChild.setNodeValue(num2str(file_start_stop(i).stop));
                    xmlDoc.getElementsByTagName('start_time').item(1).getFirstChild.setNodeValue(num2str(file_start_stop(i).start));
                    xmlDoc.getElementsByTagName('end_time').item(1).getFirstChild.setNodeValue(num2str(file_start_stop(i).stop));
                    xmlDoc.getElementsByTagName('coordinates_file').item(0).getFirstChild.setNodeValue([ikmotdir,fname,'_ik.mot']);
                    
                    xmlwrite([mlsetupdir,fname,'_MLsetup.xml'], xmlDoc);
                else
                end
                toc
            end
            
            %% analyze
            D = dir(mlsetupdir);
            
            tic
            for i = 1:numel(D)
                if ~isempty(regexpi(D(i).name,'^.*_MLsetup.xml$','once'))
                    MLcommand = sprintf('"%sbin\\analyze.exe" -S "%s%s"',osim_dir,mlsetupdir,D(i).name);
                    system(MLcommand);
                end
                toc
                
                
            end
            
        end
    else
    end
    
    %% pack it into a convenient struct (ALWAYS run this at least...)
    cd(orig_dir);
    IK = struct('JointAngle',{{}},'JointVelocity',{{}},'JointNames',{{}},'MuscleLength',{{}},'MuscleRate',{{}},'MuscleNames',{{}},...
        'MarkerXYZPosition',{{}},'MarkerXYZVelocity',{{}},'MarkerNames',{{}},'TimeBins',{{}},'TrialNumber',{[]});
    tic
    %     DK = dir(ikmotdir);
    %     DM = dir(mlmotdir);
    for i = 1:numel(file_start_stop)
        if ~isempty(regexpi(file_start_stop(i).filename,'^.*Trial\s+\d\d\d','once'))
            fn = file_start_stop(i).filename(1:(end-4));
            try
                TN = str2double(fn((end-2):end));
                
                kindata  = motRead([ikmotdir,fn,'_ik.mot']);
                MTL      = stoRead([mlmotdir,fn,'\Session001_MuscleAnalysis_Length.sto']); % sto files have 1 extra header row but are otherwise the same as mot files
                ML       = stoRead([mlmotdir,fn,'\Session001_MuscleAnalysis_FiberLength.sto']);
                TL       = stoRead([mlmotdir,fn,'\Session001_MuscleAnalysis_TendonLength.sto']); % MTL need not be ML + TL due to pennation (although ML <= ML + TL should hold)
                
                xyz      = readtrc([trc_backup_dir,fn,'.trc'],false); % we're not processing IK anymore, so let's retrieve the OG marker positions with all their foibles & fix them in post if we must
                % Opensim IK appears to do some kind of smart thing that interpolates between frames... otherwise the "last-frame" issue that nanhandler solves would not, in fact, be a problem
                % in the same vein, it's also why you can be missing entire frames and still get kinematics interpolated for those frames that were missing... (it has camera rate metadata in the trc file to help with this!)
                
                % next, extract the data & put it nice & formatted into the struct
                tbins = kindata.data(:,1);
                
                if ~yakoflag
                    [joi,moi] = ObjsOfInterest; % these should be pre-sorted in the order that they appear
                else
                    % tell it which angles & muscles you want
                    joi = {'ra_el_e_f','ra_wr_s_p','ra_wr_e_f','ra_cmc1_ad_ab','ra_cmc1_f_e','ra_mcp1_f_e','ra_ip1_f_e',...
                        'ra_mcp2_e_f','ra_pip2_e_f','ra_dip2_e_f','ra_mcp3_e_f','ra_pip3_e_f','ra_dip3_e_f',...
                        'ra_mcp4_e_f','ra_pip4_e_f','ra_dip4_e_f','ra_mcp5_e_f','ra_pip5_e_f','ra_dip5_e_f'};
                    moi = {'TRI_LAT','TRI_M','ANC','BR','BRR','SUP','PT','PQ','ECR_LO','ECR_BR','ECU','FCR','FCU','PL',...
                        'FDS5','FDS4','FDS3','FDS2','FDP5','FDP4','FDP3','FDP2','EDM','ED5','ED4','ED3','ED2','EIND',...
                        'EPL','EPB','FPB','FPL','APL','OP','APB','ADPT'};
                end
                
                jinds = find(ismember(kindata.columnNames,joi));
                minds = find(ismember(MTL.columnNames,moi));
                
                markerNames = xyz.header(4,3:3:93);
                
                sRate = 1/median(diff(tbins));
                JA = kindata.data(:,jinds); %#ok<*FNDSB>
                JV = robustDiff(JA)*sRate;
                
                Lengths.MusculoTendon = MTL.data(:,minds);
                Lengths.MuscleFiber   = ML.data(:,minds);
                Lengths.Tendon        = TL.data(:,minds);
                
                Rates.MusculoTendon = robustDiff(MTL.data(:,minds))*sRate;
                Rates.MuscleFiber   = robustDiff(ML.data(:,minds))*sRate;
                Rates.Tendon        = robustDiff(TL.data(:,minds))*sRate;
                
                MarkerCoords.X      = xyz.data(:,3:3:93);
                MarkerCoords.Y      = xyz.data(:,4:3:94);
                MarkerCoords.Z      = xyz.data(:,5:3:95);
                
                MarkerVels.X        = robustDiff(MarkerCoords.X)*sRate;
                MarkerVels.Y        = robustDiff(MarkerCoords.Y)*sRate;
                MarkerVels.Z        = robustDiff(MarkerCoords.Z)*sRate;
                
                IK.JointAngle    = vertcat(IK.JointAngle,JA);
                IK.JointVelocity = vertcat(IK.JointVelocity,JV);
                
                IK.JointNames = joi;
                
                IK.MuscleLength = vertcat(IK.MuscleLength,Lengths);
                IK.MuscleRate   = vertcat(IK.MuscleRate,Rates);
                
                IK.MuscleNames  = moi;
                
                IK.MarkerXYZPosition = vertcat(IK.MarkerXYZPosition,MarkerCoords);
                IK.MarkerXYZVelocity = vertcat(IK.MarkerXYZVelocity,MarkerVels);
                
                IK.MarkerNames = markerNames;
                
                IK.TimeBins = vertcat(IK.TimeBins,tbins);
                IK.TrialNumber = vertcat(IK.TrialNumber,TN);
            catch err
                warning('skipping: %s',fn)
            end
            toc
        end
    end
    
    
    
    
    
    %% save it all to an IK struct
    % JointAngle
    % JointVelocity
    % JointNames
    % MuscleLength
    % MuscleRate
    % MuscleNames
    % MarkerXYZPosition
    % MarkerXYZVelocity
    % MarkerNames
    % TimeBins
    % TrialNumber
    save([output_dir,output_file],'IK','-v7.3')
    
    
    %% cleanup
    cd(orig_dir)
    path(pp);
    
catch err
    cd(orig_dir);
    path(pp);
    rethrow(err)
end


%% subfunctions
    function callGaitExtract(ViconDir,OutputDir,FileNames)
        
        for ii = 1:numel(FileNames)
            try
                ViconDir = dirslash(ViconDir);
                OutputDir = dirslash(OutputDir);
                
                %             if ~strcmpi(TrialPrefix(end),' ') % for when different inputs were defined (generative file names instead of hard-coded ones)
                %                 TrialPrefix = [TrialPrefix,' '];
                %             else
                %             end
                
                %             TrialNumber = sprintf('%0.3d',TrialNos(ii)); % this adds the requisite leading zeros
                %             c3dName     = [ViconDir,TrialPrefix,TrialNumber,'.c3d'];
                
                c3dName     = [ViconDir,FileNames{ii}];
                direction   = -2;
                
                C3Dkey      = getEvents(c3dName, direction);
                %             C3Dkey.TargetFile = [OutputDir,TrialPrefix,TrialNumber];
                C3Dkey.TargetFile = [OutputDir,FileNames{ii}(1:(end-4))];
                
                markerSetName = 'markersJameson';
                markers       = getMarkers(C3Dkey, markerSetName);
                
                
                % generate .trc
                % --------------------------------------------------------------------
                % Usage: generateTrcFile(C3Dkey, markerpos, markerset, normTime)
                % --------------------------------------------------------------------
                %
                % Inputs:   C3Dkey: the C3D key structure from getEvents
                %           markerpos = array of marker positions
                %                   for M markers: should contain 1+3M columns
                %                   (time + XYZ of each marker)
                %           markerset = cell array of strings containing the names of markers
                %                   e.g. markerset = {'M1', 'M2', 'M3'};
                %           normTime = flag to normalize time between 0 and 100%
                %                      1 = original time, 2 = normalized time
                %
                % Outputs:  output trc file
                
                glab = [];
                loadLabels;
                
                if ~isempty(markers.FAILED)                    
                    % contingency plan for failed extractions: insert NANs rather than truncating the data
                    datatemp = nan(size(markers.data,1),3*numel(glab.markersJameson));
                    datatemp = horzcat(markers.data(:,1),datatemp);
                    
                    for qq = 1:numel(markers.SUCCESS)
                        new_mkr = find(ismember(glab.markersJameson,markers.SUCCESS{qq}));
                        new_ind = 3*(new_mkr-1)+2;
                        old_ind = 3*(qq-1)+2;
                        datatemp(:,new_ind:(new_ind+2)) = markers.data(:,old_ind:(old_ind+2));
                    end
                    
                    markers.data = datatemp;
                end
                
                generateTrcFile(C3Dkey, markers.data, glab.markersJameson, 1)
            catch err0r
                warning('File "%s" unable to be converted to trc, likely due to a missing marker')
            end
        end
        
        
        
        
    end


    function tf = tcd(dn) % test, then create directory
        tf = exist(dn,'dir');
        
        if tf == 0
            mkdir(dn);
        else
        end
    end


    function dnout = dirslash(dn)
        if ~strcmpi(dn(end),'\')
            dnout = [dn,'\'];
        else
            dnout = dn;
        end
    end

%     function strout = flipslash(strin)
%         backslash_tokens = (strin=='\');
%
%         strout = strin;
%         strout(backslash_tokens) = '/';
%     end

    function V = robustDiff(P)
        V1 = diff(P);
        V2 = -flipud(diff(flipud(P)));
        
        V1 = [V1;nan(1,size(V1,2))];
        V2 = [nan(1,size(V2,2));V2];
        
        Vcat = cat(3,V1,V2);
        V = nanmean(Vcat,3);
    end
















end
