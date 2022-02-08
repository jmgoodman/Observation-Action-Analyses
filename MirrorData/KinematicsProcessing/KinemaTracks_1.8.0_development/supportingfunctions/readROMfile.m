function [part] = readROMfile(path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                              READ SROM                
%
% This file reads a Aurora ROM file (incldugin tool specifications) and
% creates a Matrix including 64 bytes chucks which can be written to the
% Aurora-System to emulate SROMs of a tool.
% Helpful information:  -Aurora Application Program Interface Guid (Nov 07)
%
% Author: Stefan Schaffelhofer                                      Mar10 %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%ALLOCATE SPACE
emptychunck=zeros(1,132)';                                                 %create emtpy chunck; each chunck has 64 byte (data) + 2 byte (start adress of port handle). This means 132 hex characters.
emptychunck=num2str(emptychunck)';
for cc=1:6
    part(cc).chunck=emptychunck;
end



%READ ROM FILE
fid = fopen(path);
if fid==(-1)
    error('Unable to access ROM-file. Check path and filename.');
end
integ = fread(fid, 'uint8');
fclose(fid); %close file

%CONVERT ROM's INEGERS TO HEX CHARACTERS
ll=length(integ);
out=zeros(ll*2,1);                                                         %allocation
kk=1;
while kk<=ll                                                               %convert until all integers are converted
    bintemp=decimal2binary_mex(integ(kk));                                        %convert int to binary first...
    out(kk*2-1)=bin2hex(bintemp(1:4));                                     %... then convert binary to hex. (1 uint = 8 bit = 2 ASCCI numbers)
    out(kk*2  )=bin2hex(bintemp(5:8));
    kk=kk+1;
end

out=char(out); % convert ASCII number into ASCII character
out=out';

if size(out)~=658 %check if ROM file has appropriate size
    error('ROM - file is damaged or has wrong size');
end

%SPLIT ROM FILES IN APPROPRIATE CHUNCKS 
part(1).chunck(1:132)=['0000' out(1:128)];                                        %each chunck has 132 hex charecters; the first 4 charecters are including the adress of the port. Always incremented by 64 bytes.
part(2).chunck(1:132)=['0040' out(129:256)];
part(3).chunck(1:132)=['0080' out(257:384)];
part(4).chunck(1:132)=['00C0' out(385:512)];
part(5).chunck(1:132)=['0100' out(513:640)];
part(6).chunck(1:18) =['0140' out(641:654)];


