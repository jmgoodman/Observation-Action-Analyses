function [s] = decimal2binary(d) %#eml
[f,e]=log2(d); % How many digits do we need to represent the numbers?
s=rem(floor(d*pow2([-7,-6,-5,-4,-3,-2,-1,0])),2);

