function value = getvalue(varargin)

%##########################################################################
%
%                    GET VALUE FOR A STRING                
%
% This routine searches for the value of a pop-up menue for a give option
% 
%
% Form:  value=getvalue(handle,string)
%           handle ......... handle of a GUI e.g. popup menu
%           string ......... string to search for e.g. 'COM1'
%    
% Example:
%       value=getvalue(popup_handle,'COM2');
%       This example searches within the available options of a popup-menu
%       and returns the the value of this optiion. If the options would be
%       'COM1','COM2','COM3' the returned value would be 2.
%
% Author: Stefan Schaffelhofer ©DPZ                         created May27 %
%         Stefan Schaffelhofer                         last updated -------
%
%##########################################################################


%########################ERROR CHECK#######################################
if nargin>2
    error('To many input arguements.');
end

if nargin<2
    error('Not enought input arguements.');
end

% Old check, does not work in newer Matlab versions
% if isnumeric(varargin{1})
%     handle=varargin{1};
% end

handle = varargin{1};

if ischar(varargin{2})
    string=varargin{2};
end

%######################## VALUE SEEKING ##################################

try
found=0;
menu_strings=get(handle,'String');
for ii=1:size(menu_strings,1)
    if strcmp(string,menu_strings(ii,1))
        value=ii;
        found=1;
    end
end

if ~found % string not found
    value=-1;
end
catch exception  % if error occured ...                                                          
    rethrow(exception); % output error                                          
end
