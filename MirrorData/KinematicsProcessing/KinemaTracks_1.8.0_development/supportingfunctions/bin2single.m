function [sing] = bin2single(binary) %#eml

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%            CONVERT BINARY STRING INTO SINGLE PRECSION FORMAT
%
% This function converts the variable (binstr) into the single precison 
% number(sing) according to norm IEEE 754-2008.
% 
% Formula:
%      -n = (-1)^s * (1+m*2^-23)*2^(x-127)
%
% Helpful information:
%      -http://en.wikipedia.org/wiki/Single_precision_floating-point_format
%
% Author: Stefan Schaffelhofer                                     Jan 10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


sign=(-1)^(binary(1));
exp=binary2decimal(binary(2:9));
base=[1 binary(10:32)];
sum=0;
for ii=1:24
    sum=sum+(base(ii)*(1/2^(ii-1)));
end
sing=sign*sum*2^(exp-127);




