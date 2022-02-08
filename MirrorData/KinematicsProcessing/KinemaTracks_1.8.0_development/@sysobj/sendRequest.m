function [] = sendRequest(SY,SO) %#eml
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                      SEND "SEND-REQUEST"                
%
% DESCRIPTION:
% 
% HELPFUL INFORMATION:  -
%                       -
% SYNTAX: 
%
% EXAMPLE:
%
% Author: ©Stefan Schaffelhofer, German Primate Center              Nov09 %
%                                                      last update  Jun10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
mode=get(SY,'transfermode');
switch mode       % binary or ASCII receiving method
    case 'binary'
%         fprintf(SO, 'BX 0001');
        fprintf(SO, 'BX 0001');
   
    case 'text'
        fprintf(SO, 'TX ');                                % API help page 6
        
    otherwise
        error(['Input argument "' kind '" is unknown.']);
end
        
          

