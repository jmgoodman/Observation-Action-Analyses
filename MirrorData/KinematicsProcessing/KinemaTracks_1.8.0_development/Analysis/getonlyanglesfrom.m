function kinematic = getonlyanglesfrom(kinematic,varargin)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                 GET ONLY SPECIFIC PARTS OF KINEMATIC
%
% DESCRIPTION:
% This function provides only selected parts of the kinematic like only
% 'hand','wrist','arm', 
%
% SYNTAX:  kinematic = getonlyanglesfrom(kinematic,'selection1','selection2');
%
%          kinematic     ...  split data (input)
%          selection     ...  selection of angles (eg. 'hand', 'arm', ...)
%                
% EXAMPLE:   data = splitdata(datain,sr,timestruct,'equal','hold')
% 
% Possible selections:
%       'hand'
%       'arm'
%       'wrist'
%       
% AUTHOR: ©Stefan Schaffelhofer, German Primate Center              AUG11 %
%
%          DO NOT USE THIS CODE WITHOUT AUTHOR'S PERMISSION! 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if numel(varargin)<1
    error('No specification found.');
end

portfolio={'hand','arm','wrist','aperture'};

for ii=1:numel(varargin)
    if ~cell2mat(strfind(portfolio,lower(varargin{ii})))
        error(['Specification ' varargin{ii} ' not found.']);
    end
end

%-------------------------EXTRACT SELECTED ANGLES--------------------------

sel=zeros(1,27);


for ii=1:numel(varargin)
    name=lower(varargin{ii});
    switch name
        case 'aperture'
            sel(1:8)=1;
        case 'hand'
            sel(1:20)=1;
        case 'wrist'
            sel(21:23)=1;
        case 'arm'
            sel(24:27)=1;
        otherwise
            error(['Specification ' varargin{ii} ' not found.']);
    end 
end

sel=sel==1;

for nn=1:size(kinematic,2)
    data=kinematic{1,nn};
    if ~isempty(data)
        kinematic{1,nn}=data(sel,:);
    end
end
    

















