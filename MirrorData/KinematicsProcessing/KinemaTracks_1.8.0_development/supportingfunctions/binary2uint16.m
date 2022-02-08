function [dec] = binary2uint16(bin) %#eml
% Convert exactly 1 byte into a decimal number

dec = 2^0*bin(16) + 2^1*bin(15) + 2^2*bin(14) + 2^3*bin(13) + 2^4*bin(12) + 2^5*bin(11) + 2^6*bin(10) + 2^7*bin(9)...
    + 2^8*bin(8) + 2^9*bin(7) + 2^10*bin(6) + 2^11*bin(5) + 2^12*bin(4) + 2^13*bin(3) + 2^14*bin(2) + 2^15*bin(1);