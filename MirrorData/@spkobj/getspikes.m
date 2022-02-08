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
%                                        06.09.2011
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
% % % % % elec = SPKOBJ.electrodeID;
cha  = SPKOBJ.channelID;
sor  = SPKOBJ.sortID;
if strcmpi(logic, 'OR')                                                     %logic is 'OR'
    if windowcheck == 1
        ind1 = find(spiketimes >= time_window(1) & spiketimes <= time_window(2));
        ind1 = ind1';                                                       %convert to a row vector
        if isempty(ind1)
            display('Warning: There are no spikes during the specified time window. Indices given by getspikes therefore consider only the other specified properties.');
        end
    end
    
% % % % %     if elcheck == 1
% % % % %         ind2 = find(SPKOBJ.electrodeID == el);                              %column vector since SPKOBJ.electrodeid is a column vector
% % % % %         ind2 = ind2';                                                       %convert to a row vector
% % % % %         if isempty(ind2) 
% % % % %             display('Warning: There are no spikes for the specified electrode. Indices given by getspikes therefore consider only the other specified properties.');
% % % % %         end
% % % % %     end
    
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
        display('Warning: There are no spikes with the specified properties.')
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
        if max(spiketimes) < time_window(1)                                 %windowcheck == 1
            display('Not enough data: Time window is later than last spike time.');
            IDs = [];
            return
        else
            indSm = spiketimes >= time_window(1);                           %gives vector with zeros and ones
            indBi = spiketimes <= time_window(2);                           %gives vector with zeros and ones
            ind1 = indSm == indBi;                                          %vector with ones in indices in time window
            if isempty(find(ind1==1,1)) == 1
                display(['There are no spikes in the time window ' num2str(time_window(1)) '-' num2str(time_window(2)) '.']);
                IDs = [];
                return
            else
                if param == 1
                    IDs = find(ind1 == 1);
                    IDs = IDs';
                    return
                end
            end
        end
    end
        
    if elcheck == 1
        indEl = elec == el;                                                 %vector with ones in indices with right electrode ID
        ind1 = indEl==1 & ind1==1;
        if isempty(find(ind1==1,1)) == 1
            display('There are no spikes in that time window for that electrode ID.');
            IDs = [];
            return
        end
    end  
    
    if channelcheck == 1;
        indCh = cha == ch; 
        ind1 = indCh==1 & ind1==1;
        if isempty(find(ind1==1,1))
            display('There are no spikes for the specified channel.');
            IDs = [];
            return
        end
    end
    
    if neuroncheck == 1;
        indNeu = sor == neu; 
        ind1 = indNeu==1 & ind1==1;
        if isempty(find(ind1==1,1))
            display('There are no spikes for the specified neuron.');
            IDs = [];
            return
        end
    end

    IDs = find(ind1 == 1);
    IDs = IDs';
end