function [LHO,GHO,SO,SY,sd,calibdata] = calibratehand2(LHO,GHO,SO,SY,numsamples)


% parameters:   number of samples used for calibration
%               LHO
%               GHO
%

try
status=get(SO,'Status');
if strcmp(status,'closed');
 fopen(SO);
end
% ENTER TRACKING MODE:
SY=tracking(SY,SO,'start');

% PREPARE DATA MATRIX
numtools=get(SY,'numtools');
% eventually check if all tools are enabled.

data=zeros(numtools+1,7); % 1 time 4 quaternions + 3 coordinats


sendRequest(SY,SO); % send first request
package=receiveRequest(SY,SO); % receive first package
% check... number of tools correct, is reference really reference??
sensoridentifier=get(LHO,'sensoridentifier');
numFingers=max(sensoridentifier(get(LHO,'sensoridentifier')<6));
calibdata=NaN(numsamples,numFingers,3);
depth=input('Projection depth: ', 's');
depth=str2double(depth);
for finger=1:numFingers
    input(['Bring calibration sensor to finger: ' num2str(finger) ' and press ENTER.']);
    
    for kk=1:numsamples
        sendRequest( SY,SO);
        package=receiveRequest(SY,SO);                                     % send request for package of t
        data=translate(data,SY,package);                                   % process package of t-1
        GHO = refreshGlobalHand(GHO,data);
        calibdata  = calibrationdata2(LHO,GHO,calibdata,kk,finger,depth);
                                                % receive package of t
    end
    
end



[LHO,sd] = calibratestatic(LHO,calibdata);

GHO  = refreshGlobalHand(GHO,data);
LHO  = updateLocalHand(LHO,GHO);



SY=tracking(SY,SO,'stop');
fclose(SO); % close serial object

catch exception  % if error occured ...
    SY=tracking(SY,SO,'stop');
    fclose(SO);      % ... close seial port
    rethrow(exception); % output error 
end