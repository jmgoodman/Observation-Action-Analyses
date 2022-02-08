function [num] = getnumoftool(toolname)

switch toolname                                      % get the id of this tool
    case 'Sensor Thumb'
        num=1;
    case 'Sensor Index'
        num=2;
    case 'Sensor Middle'
        num=3;
    case 'Sensor Ring'
        num=4;
    case 'Sensor Little'
        num=5;
    case 'Sensor Wrist'
        num=6;
    case 'Sensor Reference'
        num=8;
end