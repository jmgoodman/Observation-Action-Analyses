function part = getPart(filename,partID)
% getPart gets a particular filepart from your string
%   part = getPart(filename,partID) parses filename to get the part
%   specified by partID
%
%   partID = 1 gets the filepath
%   partID = 2 gets the name without extension
%   partID = 3 gets the extension

[part1,part2,part3] = fileparts(filename);

switch partID
    case 1
        part = part1;
    case 2
        part = part2;
    case 3
        part = part3;
end

return