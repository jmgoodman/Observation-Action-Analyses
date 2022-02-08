function [dec] = binary2uint8(bin) %#eml
% Convert exactly 1 byte into a decimal number
dec = 2^0*bin(8) + 2^1*bin(7) + 2^2*bin(6) + 2^3*bin(5) + 2^4*bin(4) + 2^5*bin(3) + 2^6*bin(2) + 2^7*bin(1);