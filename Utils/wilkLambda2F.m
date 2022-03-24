%% Convert Wilks' Lambda to F-value
%--------------------------------------------------------------------------
% function F = wilkLambda2F(lamb, groupNum, depVarNum, totalObsN, dispInfo)
% 
% Inputs:
% 1. 'lamb' - Wilks' Lambda 
%                   
% 2. 'groupNum' - number of groups (classes) (k)
% 
% 3. 'depVarNum' - number of dependent variables (features) (p)              
%
% 4. 'totalObsN' - total number of obseravations (of all classes) (k*n)
%
% Optional inputs:
% 5. 'dispInfo' - display details: degrees of freedom for the numerator
%                (DF_num) and denominator (DF_denom)
%
% Outputs:
% 1. 'F' - F-value
%
% Reference: Rencher, Alvin C. Methods of multivariate analysis. Vol. 492. 
%            John Wiley & Sons, 2003., p156-163.
% from: https://de.mathworks.com/matlabcentral/fileexchange/67208-maxwellre-convert-wilk-lambda-to-f-value
% details corroborated on: https://support.sas.com/documentation/cdl/en/statug/63033/HTML/default/viewer.htm#statug_introreg_sect012.htm
%--------------------------------------------------------------------------
function [F,vnum,vdenom] = wilkLambda2F(lamb, groupNum, depVarNum, totalObsN, dispInfo)
% Author: Yitian Shao (yitianshao@ucsb.edu)
% Created on 05/03/2018
%==========================================================================
if nargin < 5
    dispInfo = 0;
end
vH = groupNum-1; % (k-1)
vE = totalObsN-groupNum; % k*(n-1)
% F statistic is exact if min(p,vH) = 1 or 2, otherwise it is approximate.
if (vH == 1) % exact F-value
    S = 1;
    DF_num = depVarNum;
    DF_denom = vE -depVarNum +1;
elseif (vH == 2) % exact F-value
    S = 2;
    DF_num = 2*depVarNum;
    DF_denom = 2*(vE -depVarNum +1);
elseif (depVarNum == 1) % exact F-value
    S = 1;
    DF_num = vH;
    DF_denom = vE;
elseif (depVarNum == 2) % exact F-value
    S = 2;
    DF_num = 2*vH;
    DF_denom = 2*(vE-1);
else % approximate F-value
    S = sqrt( (depVarNum^2*vH^2 -4)/(depVarNum^2+vH^2-5) );
    DF_num = depVarNum*vH;
    DF_denom = S*(vE+vH -0.5*(depVarNum+vH+1)) -0.5*(depVarNum*vH-2);
end
if dispInfo
    fprintf('vH = %.f, depVarNum = %.f, vE = %.f\n',vH, depVarNum, vE);
    fprintf('Degrees of freedom numerator = %f and denominator = %f\n',...
        DF_num,DF_denom);
end
Y = lamb^(1/S);
F = ((1-Y)/Y)*(DF_denom/DF_num);
vnum   = DF_num;
vdenom = DF_denom;