function IDs = getspikes(varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%               GET INDICES OF SPIKES WITH DESIRED PROPERTIES
%
% DESCRIPTION: This routine finds the indices/numbers of spikes with
% specific properties specified in the input.
%
% HELPFUL INFORMATION: 
%
% SYNTAX: IDs = getspikes(SPKOBJ, 'property1', property1, 'property2', property2, ..., 'logic', logic)
%       IDs ......... row vector with the indices in SPKOBJ of spikes 
%                     with the specified properties
%       SPKOBJ ...... spkobj where all information about spikes is
%                     stored. Has to be the first input parameter.
%       'property1' . string specifying what kind of spikes the 
%                     function shall look for. Possible strings are:
%                     'time window'  spikes in during a specific 
%                                    time window 
%                     'electrode'  	 spikes of a specific electrode
%                     'channel'      spikes of a specific channel
%                     'neuron'       spikes of a specific neuron
%       property1 ... value of the 'property' specified before. 
%                     For 'time window', property has to be a 2dim vector.
%       logic ....... string. Possible strings are:
%                     'AND'  all properties shall be true
%                     'OR'   at least one of the properties shall be true
%
% EXAMPLE: IDs = getspikes(SPKOBJ, 'time window', [0 1000], 'electrode', 4, 'logic', 'AND')
%
% AUTHOR: ©Katharina Menz, German Primate Center                  July 2011
% last modified: Katharina Menz          18.07.2011
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%######################## CHECK INPUT PARAMETERS ##########################

if nargin < 5                       %check number of input arguments
    error('Not enough input arguments.');
end
if nargin > 11
    error('Too many input arguments.');
end


%check TRIALOBJ
if isobject(varargin{1}) == 0       %check if first input argument is an object
    error('Wrong input argument: First input argument has to be a SPKOBJ.');
else
    if strcmpi(class(varargin{1}), 'SPKOBJ') == 0
        error('Wrong input argument: First input argument has to be a SPKOBJ.');
    else
        SPKOBJ = varargin{1};
    end
end


windowcheck  = 0;
elcheck      = 0;   
channelcheck = 0;
neuroncheck  = 0;
logiccheck   = 0;
param = (numel(varargin)-3)/2;                                              %number of specified properties                            
for ii = 1:numel(varargin)
    if strcmpi(varargin{ii}, 'electrode')
        elid    = ii+1;
        elcheck = 1;
    elseif strcmpi(varargin{ii}, 'channel')
        channid      = ii+1;
        channelcheck = 1;
    elseif strcmpi(varargin{ii}, 'neuron')
        neuid       = ii+1;
        neuroncheck = 1;
    elseif strcmpi(varargin{ii}, 'time window')
        windowid    = ii+1;
        windowcheck = 1;
    elseif strcmpi(varargin{ii}, 'logic')
        logicid      = ii+1;
        logiccheck   = 1;
    end
end

%check for properties
if windowcheck == 0 &&  elcheck == 0 && channelcheck == 0 && neuroncheck == 0
    error('Wrong input: Choose at least one property for selecting spikes.')
end

%check 'logic' input
if logiccheck == 0;
    error('Wrong input argument: Specify if all or at least one of the properties have to be true with "logic".');
else
    logic = varargin{logicid};
end

if ischar(logic) == 0               %check if logic is a string
    error('Wrong input argument: "Logic" has to be a string.');
end

if strcmpi(logic, 'AND') == 0 && strcmpi(logic, 'OR') == 0  %check if logic is either 'AND' or 'OR'
    error('Wrong input argument: "Logic" has to be either "AND" or "OR".');
end

%check 'time window' input
if windowcheck == 1
    time_window = varargin{windowid};
    if isnumeric(time_window) == 0  %check if time window-input argument is a not a string
        error('Wrong input argument: Input argument for "time window" has to be a 2dim row vector with start and end time (in ms).');
    end

    if isequal(size(time_window), [1 2]) == 0   %check if time window-input argument is an 2-dim row vector
        error('Wrong input argument: Input argument for "time window" has to be a 2dim row vector with start and end time (in ms).');
    end

    if isequal(size(time_window), [1 2]) == 1
        if time_window(1) < 0       %check if time specified in the time window-input argument is positive
            error('Wrong input argument: Components of the input argument for "time window" have to be positive, since they specify time (in ms).');
        end
    
        if time_window(2) < 0       %check if time specified in the time window-input argument is positive
            error('Wrong input argument: Components of the input argument for "time window" have to be positive, since they specify time (in ms).');
        end

        if time_window(1) > time_window(2)  %check if specified time window is valid
            error('Wrong input argument: First component in the input argument for "time window" has to be smaller than the second component, since this vector specifies a time window.');
        end

        if time_window(1) == time_window(2) %check if specified time window has a duration greater than zero
            error('Wrong input argument: Specified time window has a duration of zero.');
        end
    end
end

%check 'electrode' input
if elcheck == 1
    el = varargin{elid};
    if isnumeric(el) == 0           %check if electrode is a number
        error('Wrong input argument: "Electrode" has to be a number.');
    end
end

%check 'channel' input
if channelcheck == 1
    ch = varargin{channid};
    if isnumeric(ch) == 0           %check if channel is a number
        error('Wrong input argument: "Channel" has to be a number.');
    end
end

%check 'neuron' input
if neuroncheck == 1
    neu = varargin{neuid};
    if isnumeric(neu) == 0          %check if neuron is a number
        error('Wrong input argument: "Neuron" has to be a number.');
    end
end

%check for wrong property inputs
for ii = 1:param
    if strcmpi(varargin{2*ii}, 'time window') == 0 && strcmpi(varargin{2*ii}, 'electrode') == 0 && strcmpi(varargin{2*ii}, 'channel') == 0 && strcmpi(varargin{2*ii}, 'neuron') == 0
        display(['Warning: "' varargin{2*ii} '" is no valid input property yet. Indices given by gettrials therefore only consider the other specified properties. Feel free to add "' varargin{2*ii} '" to the code.']);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%% FIND DESIRED TRIALS %%%%%%%%%%%%%%%%%%%%%%%%%%%%
ind1 = [];
ind2 = [];
ind3 = [];
ind4 = [];
spiketimes = SPKOBJ.spiketimes;
if strcmpi(logic, 'OR')                                                     %logic is 'OR'
    if windowcheck == 1
        ind1 = find(spiketimes >= time_window(1) & spiketimes <= time_window(2));
        ind1 = ind1';                                                       %convert to a row vector
        if isempty(ind1)
            display('Warning: There are no spikes during the specified time window. Indices given by getspikes therefore consider only the other specified properties.');
        end
    end
    
    if elcheck == 1
        ind2 = find(SPKOBJ.electrodeID == el);                              %column vector since SPKOBJ.electrodeid is a column vector
        ind2 = ind2';                                                       %convert to a row vector
        if isempty(ind2) 
            display('Warning: There are no spikes for the specified electrode. Indices given by getspikes therefore consider only the other specified properties.');
        end
    end
    
    if channelcheck == 1
        ind3 = find(SPKOBJ.channelID == ch);
        ind3 = ind3';
        if isempty(ind3) 
            display('Warning: There are no spikes for the specified channel. Indices given by getspikes therefore consider only the other specified properties.');
        end
    end
    
    if neuroncheck == 1
        ind4 = find(SPKOBJ.sortID == neu);
        ind4 = ind4';
        if isempty(ind4) 
            display('Warning: There are no spikes for the specified neuron. Indices given by getspikes therefore consider only the other specified properties.');
        end
    end

% add new properties to code here:
%     if propertycheck == 1
%         ind_i = find(SPKOBJ.property == propertyvalue);
%         ind_i = ind_i';
%         if isempty(ind_i)
%             display('The specified property does not exist. Indices given by getspikes therefore consider only the other specified properties.');
%         end
%     end
    
    IDs = [ind1 ind2 ind3 ind4];
    if isempty(IDs)
        error('Warning: There are no spikes with the specified properties.')
    else                                                                    %eliminate same entries in IDs
        IDs = sort(IDs);
        entry = IDs(1);
        ind(1) = 1;                                                         %indices of entries of IDs, which differ from each other
        mm = 2;
        for kk = 2:length(IDs)
            if IDs(kk) ~= entry
                ind(mm) = kk;
                mm = mm+1;
                entry = IDs(kk);
            end
        end
        IDs = IDs(ind);
    end
else                                                                        %logic is 'AND'
    if windowcheck == 1
        if max(spiketimes) < time_window(1)
            error('Not enough data: Time window is later than last spike time.');
        else
            ind1 = find(spiketimes >= time_window(1) & spiketimes <= time_window(2));
            ind1 = ind1';                                                       %convert to row vector
            if isempty(ind1)
                display(['There are no spikes in the time window ' num2str(time_window(1)) '-' num2str(time_window(2)) '.']);
                IDs = [];
                return
            else
                if param == 1
                    IDs = ind1;
                    return
                end
            end
        end
    end     
    if elcheck == 1;
        ind2 = find(SPKOBJ.electrodeID == el);                              %column vector since SPKOBJ.electrodeid is a column vector
        ind2 = ind2';                                                       %convert to row vector
        if isempty(ind2)
            error('There are no spikes for the specified electrode.');
        else
            if param == 1
                IDs = ind2;
                return
            end
        end
    end
    if channelcheck == 1;
        ind3 = find(SPKOBJ.channelID == ch); 
        ind3 = ind3';
        if isempty(ind3)
            error('There are no spikes for the specified channel.');
        else
            if param == 1
                IDs = ind3;
                return
            end
        end
    end
    if neuroncheck == 1;
        ind4 = find(SPKOBJ.sortID == neu); 
        ind4 = ind4';
        if isempty(ind4)
            error('There are no spikes for the specified neuron.');
        else
            if param == 1
                IDs = ind4;
                return
            end
        end
    end
%add new properties to code here
%        if propertycheck == 1;
%             ind_i = find(SPKOBJ.property == propertyvalue); 
%             ind_i = ind_i';
%             if isempty(ind_i)
%                 error('The specified property does not exist.');
%             else
%                 if param == 1
%                     IDs = ind_i;
%                     return
%                 end
%             end
%        end
    
    if elcheck == 1
        if windowcheck == 1                                                 %compare ind1 and ind2 and produce ind12
            ind12 = [];
            mm = 1;
            for ii = 1:length(ind1)
                same = find(ind2 == ind1(ii), 1);
                if isempty(same) == 0
                    ind12(mm) = ind1(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind12) 
                display('There are no spikes for that neuron in the specified time window.');
                IDs = [];
                return
            end
        end
    end
    
    if channelcheck == 1
        if windowcheck == 1 && elcheck == 1                                  %compare ind12 and ind 3 and produce ind123
            ind123 = [];
            mm = 1;
            for ii = 1:length(ind12)
                same = find(ind3 == ind12(ii), 1);
                if isempty(same) == 0
                    ind123(mm) = ind12(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind123) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            end
        elseif windowcheck == 0 && elcheck == 1                              %compare ind2 and ind3 and produce ind23
            ind23 = [];
            mm = 1;
            for ii = 1:length(ind2)
                same = find(ind3 == ind2(ii), 1);
                if isempty(same) == 0
                    ind23(mm) = ind2(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind23) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            end
        elseif windowcheck == 1 && elcheck == 0                              %compare ind1 and ind3 and produce ind13
            ind13 = [];
            mm = 1;
            for ii = 1:length(ind1)
                same = find(ind3 == ind1(ii), 1);
                if isempty(same) == 0
                    ind13(mm) = ind1(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind13) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            end
        end
    end
    
    if neuroncheck == 1
        if windowcheck == 1 && elcheck == 1 && channelcheck == 1              %compare ind123 and ind4 and produce ind1234
            ind1234 = [];
            mm = 1;
            for ii = 1:length(ind123)
                same = find(ind4 == ind123(ii), 1);
                if isempty(same) == 0
                    ind1234(mm) = ind123(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind1234) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind1234;
            end
        elseif windowcheck == 0 && elcheck == 1 && channelcheck == 1          %compare ind23 and ind4 and produce ind234
            ind234 = [];
            mm = 1;
            for ii = 1:length(ind23)
                same = find(ind4 == ind23(ii), 1);
                if isempty(same) == 0
                    ind234(mm) = ind23(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind234) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind234;
            end            
        elseif windowcheck == 1 && elcheck == 0 && channelcheck == 1          %compare ind13 and ind4 and produce ind134
            ind134 = [];
            mm = 1;
            for ii = 1:length(ind13)
                same = find(ind4 == ind13(ii), 1);
                if isempty(same) == 0
                    ind134(mm) = ind13(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind134) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind134;
            end
            
        elseif windowcheck == 0 && elcheck == 0 && channelcheck == 1          %compare ind3 and ind4 and produce ind34
            ind34 = [];
            mm = 1;
            for ii = 1:length(ind3)
                same = find(ind4 == ind3(ii), 1);
                if isempty(same) == 0
                    ind34(mm) = ind3(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind34) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind34;
            end
        elseif windowcheck == 1 && elcheck == 1 && channelcheck == 0          %compare ind12 and ind4 and produce ind124
            ind124 = [];
            mm = 1;
            for ii = 1:length(ind12)
                same = find(ind4 == ind12(ii), 1);
                if isempty(same) == 0
                    ind124(mm) = ind12(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind124) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind124;
            end
        elseif windowcheck == 0 && elcheck == 1 && channelcheck == 0          %compare ind2 and ind4 and produce ind24
            ind24 = [];
            mm = 1;
            for ii = 1:length(ind2)
                same = find(ind4 == ind2(ii), 1);
                if isempty(same) == 0
                    ind24(mm) = ind2(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind24) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind24;
            end
        elseif windowcheck == 1 && elcheck == 0 && channelcheck == 0          %compare ind1 and ind4 and produce ind14
            ind14 = [];
            mm = 1;
            for ii = 1:length(ind1)
                same = find(ind4 == ind1(ii), 1);
                if isempty(same) == 0
                    ind14(mm) = ind1(ii);
                    mm = mm+1;
                end
            end
            if isempty(ind14) 
                display('There are no spikes with all the specified properties.');
                IDs = [];
                return
            else
                IDs = ind14;
            end
        else  %windowcheck == 0 & elcheck == 0 & channelcheck == 0
            IDs = ind4;
        end
    else %neuroncheck == 0
        if windowcheck == 1 && elcheck == 1 && channelcheck == 1
            IDs = ind123;
        elseif windowcheck == 0 && elcheck == 1 && channelcheck == 1
            IDs = ind23;
        elseif windowcheck == 1 && elcheck == 0 && channelcheck == 1
            IDs = ind13;
        elseif windowcheck == 0 && elcheck == 0 && channelcheck == 1
            IDs = ind3;
        elseif windowcheck == 1 && elcheck == 1 && channelcheck == 0
            IDs = ind12;
        elseif windoecheck == 0 && elcheck == 1 && channelcheck == 0
            IDs = ind2;
        elseif windowcheck == 1 && elcheck == 0 && channelcheck == 0
            IDs = ind1;
        end
    end
end