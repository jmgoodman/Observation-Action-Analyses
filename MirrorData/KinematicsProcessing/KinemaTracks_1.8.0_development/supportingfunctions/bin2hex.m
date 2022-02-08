function [hexval]=bin2hex(bininput) %#eml

if length(bininput)~=4
    error('Wrong input dimension');
end

if bininput == [0,0,0,0]
    hexval='0';
end
if bininput == [0,0,0,1]
    hexval='1';
end
if bininput == [0,0,1,0]
    hexval='2';
end
if bininput == [0,0,1,1]
    hexval='3';
end
if bininput == [0,1,0,0]
    hexval='4';
end
if bininput == [0,1,0,1]
    hexval='5';
end
if bininput == [0,1,1,0]
    hexval='6';
end
if bininput == [0,1,1,1]
    hexval='7';
end
if bininput == [1,0,0,0]
    hexval='8';
end
if bininput == [1,0,0,1]
    hexval='9';
end
if bininput == [1,0,1,0]
    hexval='A';
end
if bininput == [1,0,1,1]
    hexval='B';
end
if bininput == [1,1,0,0]
    hexval='C';
end
if bininput == [1,1,0,1]
    hexval='D';
end
if bininput == [1,1,1,0]
    hexval='E';
end
if bininput == [1,1,1,1]
    hexval='F';
end
