classdef MirrorData < matlab.mixin.Copyable % consider removing the inheritance from the Copyable object for compatability with Octave
    % instantiates a "MirrorData" object
    % set, get, and loadobj methods copied from class definitions written
    % by Stefan Schaffelhofer.
    % Adapted for MirrorData by James Goodman, 2019 Dec 31, DPZ
    
    %%
    properties % (SetAccess=protected) % protect access to these variables so you don't ever do anything stupid to overwrite these fields. (un-set them in case locking access to them makes things annoying to work with tho)
        %   Some methods simply perform a "is / is not empty" check on
        %   these fields, so failing to restrict access could screw things
        %   up royally. Along that same line, let's deny access to the set
        %   & get methods.
        
        Neural           = []; % specifies spike times, in milliseconds
        Kinematic        = []; % specifies kinematics
        Event            = []; % specifies event times, in milliseconds
        Object           = []; % specifies object names
        TrialType        = []; % specifies trial / condition types
        SessionMetadata  = []; % specifies details such as animal, session #, and date of recording. Other details (e.g., recording system) may be supported in the future, although the scripts as they stand (as of 04.03.2020) ASSUME you're using a TDT system outright.
        Array            = []; % specifies details about the array in an arrayobj instance.
        KinematicFileTransitionTimes = []; % added 08.11.2020, for aligning kinematic data with behavioural & neural data
        
        %% THESE ARE DEPRECATED FIELDS THAT ARE KEPT TO RETAIN COMPATIBILITY OF DEPRECATED METHODS SUCH AS BINDATA AND ALIGNTRIALS
        % BinnedTrials  = []; % Binned data gets dumped in here, with time units 
        %         converted to SECONDS. All trials are aligned to trial start, 
        %         but can always be re-aligned via MirrorData.AlignTrials.
        % AlignedTrials = []; % Contains a struct full of different
        %         alignments of BinnedTrials. Not needed, because
        %         BinnedTrials will be updated to comprise an array of
        %         objects, with each element of the array being a different
        %         binning based on a different alignment. Kept in the
        %         interim between now (05.02.2020) and me finally fixing
        %         BinData and deleting the soon-to-be redundant (not to
        %         mention poorly-implemented) AlignTrials method.
        % TrializedData    = []; % a field for "trialized" data, i.e., data that 
        %         have been (in)conveniently split into separate trials & aligned 
        %         to each event.

    end
    
    %%
    methods
        %         function obj = set(obj,varargin) % allows to use "set" as command to manipulate object
        %
        %             if mod(numel(varargin),2)~=0
        %                 error('Wrong number of inputs: must come in name-value pairs.');
        %             end
        %
        %             propertyNames = varargin(1:2:end-1); % get property names
        %             propertyValues= varargin(2:2:end);   % get property values
        %
        %             fnames = fieldnames(obj);
        %
        %             for nn=1:length(propertyNames)       % read out all propertys
        %                 propertyName=propertyNames{nn};
        %                 propertyValue=propertyValues{nn};
        %                 notfound=true;
        %                 for ii=1:length(fnames)
        %                     if strcmpi(fnames(ii),propertyName)
        %                         obj.(fnames{ii})=propertyValue;
        %                         notfound=false;
        %                     end
        %                 end
        %                 % let the user know if property was not found in this
        %                 % class
        %                 if notfound; error(['Property "' propertyName '" not found in class "' class(obj) '".']); end
        %             end
        %         end
        %
        %         function propertyValue = get(obj,varargin) % allows to use "get" as command to manipulate object
        %
        %             propertyNames = varargin(:); % get property names
        %
        %             fnames = fieldnames(obj);
        %
        %             for nn=1:length(propertyNames)
        %                 propertyName=propertyNames{nn};
        %                 notfound=true;
        %                 for ii=1:length(fnames)
        %                     if strcmpi(fnames(ii),propertyName)
        %                         propertyValue=obj.(fnames{ii});
        %                         notfound=false;
        %                     end
        %                 end
        %                 if notfound; error(['Property "' propertyName '" not found in class "' class(obj) '".']); end
        %             end
        %
        %         end
        
        function obj = loadobj(obj,data) % if you have loaded the data as a struct (say, by accidentally importing it without having this class definition in your path), this lets you dump it in an instance of the class.
            %LOADOBJ Takes data from a struct or outdated MirrorData object and converts it into the most up-to-date MirrorData format.
            if isstruct(data) || isa(data,'MirrorData') % if load could not successfully load data to object structure (e.g. version conflict)
                %                 obj=MirrorData(); % holdover from when
                %                 this was a static method
                stcnames=fieldnames(data);
                objnames=fieldnames(obj);
                
                for ii=1:length(stcnames)
                    if strcmpi(stcnames(ii),objnames(ii))
                        obj.(objnames{ii})=data.(stcnames{ii});
                    else
                        error('Field names do not match');
                    end
                end
                
            else
                warning('Input is an invalid data type. No operation was performed')
            end
        end
        
    end
    
    %     methods (Static)
    %     end
    
    %     methods (Hidden)
    %     % hide these eventually if you ever get off your duff & write the
    %     % "big main master import function". But for now, keep 'em
    %     % visible because the user needs to have access to these methods
    %     % in order to import their session data. (10.03.2020: I did it, but do I wanna make these hidden?!?)
    %     % answer: NO, but I'm listing the functions here anyway. Just in
    %     case we ever do want to hide or render static any of these
    %     methods.
    %         obj         = ReadBehaviour(obj,varargin);
    %         obj         = ReadNeural(obj,varargin);
    %         obj         = ReadKinematics(obj,varargin);
    %         h_raster    = PlotRaster(obj,varargin);
    %         binned_data = BinData(obj,varargin);
    %     end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % TODO:
    % ~ incorporate Ben's spike sorter (requires one first to be able to read
    % raw binaries, .sev, of spiking data - Stefan, help!)
    %
    % ~ incorporate methods for reading in kinematic data & integrating it
    % with behavioural data
    %
    % (is this necessary? or even desirable?) incorporate a one-size-fits-all data import method that
    % simultaneously handles the behavioural, neural, and kinematic data import processes
    %
    % incorporate methods for: aligning trials, trial averaging,
    % down/upsampling, plotting rasters, plotting PETHs, performing
    % dimensionality reduction, performing classification of object or
    % trial type, performing all sorts of statistical tests (t-tests,
    % ANOVA, nonparametric variations thereof, regressions, permutation
    % tests, bootstrapping), organizing data for cross-validation
    %
    % add descriptions of OUTPUTS to your function definitions! GAWD
    %
    % consider whether a RMS or signal power-based SNR might be better than
    % one based on peak-to-peak amplitude. Peak-to-peak makes the most
    % sense in the context of the Rose criterion, but it's admittedly less
    % standard to measure SNR in this way, and there may well be other
    % criteria that make sense in terms of the more standard ways to assess
    % SNR (namely the relative signal power, as opposed to peak-to-peak,
    % sense). (That said, Blackrock auto-thresholding seeks waveforms with
    % PRECISELY the type of SNR I have defined in my ReadNeural function...
    % although they're a little more conservative since they don't assess
    % peak-to-peak, but rather amplitude-of-max-peak... but whatever, I'd
    % rather be conservative than restrictive when pruning things under the
    % hood, out of sight of the user.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Hidden=true,Static=true)
        [gripname]=getgripname(specification,gripid)
    end
end
