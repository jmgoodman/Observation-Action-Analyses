function [name] = getnameoftool(toolnum)

switch toolnum                                      % get the id of this tool
    case 1
        name='Sensor Thumb';
    case 2
        name='Sensor Index';
    case 3
        name='Sensor Middle';
    case 4
        name='Sensor Ring';
    case 5
        name='Sensor Little';
    case 6
        name='Sensor Wrist';
    case 8
        name='Sensor Reference';
end