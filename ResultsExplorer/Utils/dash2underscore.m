function outstr = dash2underscore(instr)

dashLocations = regexp(instr,'\-');
outstr        = instr;
outstr(dashLocations) = '_';

return