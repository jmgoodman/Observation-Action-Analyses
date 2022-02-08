function FL = checkforflag(SY,FL)

ROMtype=get(SY,'ROMtype');
ROMfile=get(SY,'ROMfile');


switch ROMtype
    case 'srom'
        FL.romset=1;
    case 'virtual' 
        if numel(ROMfile)==4
            if (isempty(ROMfile{1}) && isempty(ROMfile{2}) && isempty(ROMfile{3}) && isempty(ROMfile{4}))
                FL.romset=0;
            else %if ROM files are selected, save them to the system object
                FL.romset=1;
            end
        else 
            FL.romset=0;
        end
end
