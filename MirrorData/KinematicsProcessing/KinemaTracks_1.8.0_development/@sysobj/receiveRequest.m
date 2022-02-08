function [package] = receiveRequest(SY,SO) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%           RECEIVE DATA FROM AURORA TRACKING SYSTEM
%
% This function receives the tool-tranformations from the AURORA tracking
% system in binary or ASCII format
% 
% The transformation data as well as handle, port and system status is
% saved to the aurora object (aurobj)
%
% Helpful information:  -Aurora Application Program Interface Guid (Nov 07)
%                       -http://de.wikipedia.org/wiki/EIA-232
%                       -Matlab help: "What is a serial communication?".
%
% Author: Stefan Schaffelhofer                                     Jan 10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mode=get(SY,'transfermode');
switch mode        % binary or ASCII receiving method
    case 'binary'
        try
        first=fread(SO,4,'uint8'); %read out first 4 byte
        bytes=binary2uint16_mex([decimal2binary_mex(first(4)) decimal2binary_mex(first(3))])+4;
        data=fread(SO,bytes,'uint8'); %receive the missing package
        package=[first; data];    %write package to aurora object for further processing
        catch
            package=[];
            global err
            err=1;
        end
    case 'text'
        data = fscanf(SO); 
        package=data; %write package to aurora object for further processing

    otherwise
        error(['Input argument "' kind '" is unknown.']);
end

end