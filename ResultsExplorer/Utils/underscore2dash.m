function outstr = underscore2dash(instr)

dashLocations = regexp(instr,'\_');
outstr        = instr;
outstr(dashLocations) = '-';

return